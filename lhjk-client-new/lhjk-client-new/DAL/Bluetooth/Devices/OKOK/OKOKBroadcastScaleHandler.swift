import Combine
import Foundation

/// OKOK 广播秤领域事件
enum OKOKScaleEvent {
    /// 非锁定：实时体重（仅 UI）
    case realtime(OKOKScaleDiscovery)
    /// 锁定：稳定测量（可落库）
    case locked(OKOKScaleDiscovery)
}

/// OKOK 单向广播体脂秤 Handler — 不 connect，只扫广播
final class OKOKBroadcastScaleHandler: BLEDeviceHandler {

    let kind: BLEDeviceKind = .okokBroadcastScale

    let eventPublisher = PassthroughSubject<OKOKScaleEvent, Never>()

    /// 锁定后立刻停扫；体重 H5 由 BLL 在 `saveOrUpdateMonitorData` 开始时停扫，此处保持 false
    var stopOnLock = false

    /// 主线程同步回调，避免 Combine `receive(on:)` 把锁定帧排到停扫之后丢掉
    var onEvent: ((OKOKScaleEvent) -> Void)?

    private weak var bluetooth: BluetoothManager?
    private var cancellables = Set<AnyCancellable>()
    private var isRunning = false
    private let processQueue = DispatchQueue(label: "lhjk.okok.broadcast.handler")

    /// 最近一次已发出的锁定键，用于去重（serial + weightRaw + mac）
    private var lastEmittedLockKey: String?

    /// 实时帧日志去重（mac + serial + weight + resistance）
    private var lastRealtimeLogKey: String?

    /// 已打印过设备身份的 MAC，避免实时帧刷屏
    private var loggedIdentityMacs = Set<String>()

    func start(bluetooth: BluetoothManager) {
        stop()
        self.bluetooth = bluetooth
        isRunning = true
        lastEmittedLockKey = nil
        lastRealtimeLogKey = nil
        loggedIdentityMacs.removeAll()
        print("[OKOK-DAL] handler start — subscribe ads + scan allowDuplicates stopOnLock=\(stopOnLock)")

        bluetooth.advertisementPublisher
            .receive(on: processQueue)
            .sink { [weak self] event in
                self?.handleAdvertisement(event)
            }
            .store(in: &cancellables)

        bluetooth.startScan(serviceUUIDs: nil, allowDuplicates: true)
    }

    func stop() {
        let shouldLog = isRunning || bluetooth != nil || !cancellables.isEmpty
        isRunning = false
        cancellables.removeAll()
        lastEmittedLockKey = nil
        lastRealtimeLogKey = nil
        loggedIdentityMacs.removeAll()
        let manager = bluetooth
        bluetooth = nil
        guard shouldLog else { return }
        print("[OKOK-DAL] handler stop")
        manager?.stopScan()
    }

    // MARK: - Private

    private func handleAdvertisement(_ event: BLEAdvertisementEvent) {
        guard isRunning else { return }
        guard let raw = event.manufacturerData else { return }
        guard let packet = OKOKV3PacketParser.parse(manufacturerData: raw) else { return }

        let discovery = OKOKScaleDiscovery(
            packet: packet,
            bluetoothName: event.localName,
            rssi: event.rssi
        )
        logDeviceIdentity(discovery, phase: packet.isLocked ? "锁定" : "实时")

        if packet.isLocked {
            let key = "\(packet.macString)|\(packet.serial)|\(packet.weightRaw)"
            if key == lastEmittedLockKey {
                print("[OKOK-DAL] locked duplicate ignored key=\(key)")
                return
            }
            lastEmittedLockKey = key
            packet.printFullMeasurementLog(
                phase: "锁定",
                discovery: discovery,
                peripheralId: event.peripheralId,
                rawManufacturerHex: raw.bleHexString
            )
            deliver(.locked(discovery), stopAfter: stopOnLock)
        } else {
            let logKey = "\(packet.macString)|\(packet.serial)|\(packet.weightRaw)|\(packet.resistanceRaw)"
            if logKey != lastRealtimeLogKey {
                lastRealtimeLogKey = logKey
                packet.printFullMeasurementLog(
                    phase: "实时",
                    discovery: discovery,
                    peripheralId: event.peripheralId,
                    rawManufacturerHex: raw.bleHexString
                )
            }
            deliver(.realtime(discovery), stopAfter: false)
        }
    }

    private func deliver(_ event: OKOKScaleEvent, stopAfter: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.isRunning else {
                print("[OKOK-DAL] drop event — handler already stopped")
                return
            }
            self.onEvent?(event)
            self.eventPublisher.send(event)
            if stopAfter {
                print("[OKOK-DAL] locked — stop broadcast scan")
                self.stop()
            }
        }
    }

    private func logDeviceIdentity(_ discovery: OKOKScaleDiscovery, phase: String) {
        let mac = discovery.packet.macString
        guard loggedIdentityMacs.insert(mac).inserted || phase == "锁定" else { return }
        print("[OKOK-DAL] 体脂秤[\(phase)] \(discovery.identityLogLine)")
    }
}
