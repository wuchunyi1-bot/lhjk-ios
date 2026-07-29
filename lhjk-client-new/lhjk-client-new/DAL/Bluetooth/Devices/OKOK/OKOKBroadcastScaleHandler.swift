import Combine
import Foundation

/// OKOK 广播秤领域事件
enum OKOKScaleEvent {
    /// 非锁定：实时体重（仅 UI）
    case realtime(OKOKScalePacket)
    /// 锁定：稳定测量（可落库）
    case locked(OKOKScalePacket)
}

/// OKOK 单向广播体脂秤 Handler — 不 connect，只扫广播
final class OKOKBroadcastScaleHandler: BLEDeviceHandler {

    let kind: BLEDeviceKind = .okokBroadcastScale

    let eventPublisher = PassthroughSubject<OKOKScaleEvent, Never>()

    private weak var bluetooth: BluetoothManager?
    private var cancellables = Set<AnyCancellable>()
    private var isRunning = false

    /// 最近一次已发出的锁定键，用于去重（serial + weightRaw + mac）
    private var lastEmittedLockKey: String?

    func start(bluetooth: BluetoothManager) {
        stop()
        self.bluetooth = bluetooth
        isRunning = true
        lastEmittedLockKey = nil

        bluetooth.advertisementPublisher
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] event in
                self?.handleAdvertisement(event)
            }
            .store(in: &cancellables)

        bluetooth.startScan(serviceUUIDs: nil, allowDuplicates: true)
    }

    func stop() {
        isRunning = false
        cancellables.removeAll()
        bluetooth?.stopScan()
        bluetooth = nil
        lastEmittedLockKey = nil
    }

    // MARK: - Private

    private func handleAdvertisement(_ event: BLEAdvertisementEvent) {
        guard isRunning, let raw = event.manufacturerData else { return }
        guard let packet = OKOKV3PacketParser.parse(manufacturerData: raw) else { return }

        if packet.isLocked {
            let key = "\(packet.macString)|\(packet.serial)|\(packet.weightRaw)"
            if key == lastEmittedLockKey { return }
            lastEmittedLockKey = key
            eventPublisher.send(.locked(packet))
        } else {
            eventPublisher.send(.realtime(packet))
        }
    }
}
