import Combine
import Foundation

/// 体重蓝牙状态 — 与 H5 `ble.getStatus` / `ble.statusChange` 字段一致
struct BleWeightStatus: Equatable {
    var metric: String = "weight"
    var bound: Bool
    var connected: Bool
    var deviceName: String
    var lastSyncAt: String

    var dictionary: [String: Any] {
        [
            "metric": metric,
            "bound": bound,
            "connected": connected,
            "deviceName": deviceName,
            "lastSyncAt": lastSyncAt,
        ]
    }
}

/// 体脂秤 / 体重秤 BLE 测量会话（Health BLL）
///
/// 启停 OKOK 广播 Handler；转发实时/锁定事件；向 H5 Bridge 提供 Status / synced / error。
final class ScaleBleSessionService {

    static let shared = ScaleBleSessionService()

    let realtimePublisher = PassthroughSubject<OKOKScalePacket, Never>()
    let lockedPublisher = PassthroughSubject<OKOKScalePacket, Never>()
    let statusPublisher = PassthroughSubject<BleWeightStatus, Never>()
    /// `ble.synced` payload
    let syncedPublisher = PassthroughSubject<[String: Any], Never>()
    /// `ble.error` payload
    let errorPublisher = PassthroughSubject<[String: Any], Never>()

    private(set) var lastLockedPacket: OKOKScalePacket?

    private let bluetooth: BluetoothManager
    private var handler: OKOKBroadcastScaleHandler?
    private var cancellables = Set<AnyCancellable>()
    private var isActive = false
    private var bluetoothStateCancellable: AnyCancellable?

    private let lastLockedStorageKey = "fd_okok_last_locked_scale"
    private let boundMacStorageKey = "fd_okok_bound_mac"
    private let boundNameStorageKey = "fd_okok_bound_name"

    init(bluetooth: BluetoothManager = AppContainer.shared.bluetoothManager) {
        self.bluetooth = bluetooth
        bluetoothStateCancellable = bluetooth.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                if state == .unauthorized || state == .poweredOff {
                    self.emitError(code: "bluetooth_unavailable", message: self.errorMessage(for: state))
                }
                self.publishStatus()
            }
    }

    /// 开始测量会话（扫描广播，不连接）
    func startSession() {
        guard !isActive else {
            print("[Scale-BLL] startSession ignored — already active")
            publishStatus()
            return
        }
        guard bluetooth.state == .poweredOn else {
            print("[Scale-BLL] startSession failed — bluetooth=\(bluetooth.state)")
            emitError(code: "bluetooth_unavailable", message: errorMessage(for: bluetooth.state))
            publishStatus()
            return
        }

        isActive = true

        guard let h = BLEDeviceRegistry.shared.handler(for: .okokBroadcastScale) as? OKOKBroadcastScaleHandler else {
            isActive = false
            print("[Scale-BLL] startSession failed — OKOK handler missing")
            emitError(code: "handler_missing", message: "体重秤协议未注册")
            return
        }
        handler = h
        cancellables.removeAll()

        h.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handle(event)
            }
            .store(in: &cancellables)

        print("[Scale-BLL] startSession — begin broadcast scan")
        h.start(bluetooth: bluetooth)
        publishStatus()
    }

    func stopSession() {
        guard isActive else { return }
        print("[Scale-BLL] stopSession")
        isActive = false
        cancellables.removeAll()
        handler?.stop()
        handler = nil
        publishStatus()
    }

    /// 供 Bridge `ble.getStatus`
    func statusDictionary(metric: String = "weight") -> [String: Any] {
        currentStatus(metric: metric).dictionary
    }

    func currentStatus(metric: String = "weight") -> BleWeightStatus {
        let mac = UserDefaults.standard.string(forKey: boundMacStorageKey)
        let name = UserDefaults.standard.string(forKey: boundNameStorageKey)
        let bound = (mac?.isEmpty == false) || lastLockedPacket != nil
        let deviceName: String
        if let name, !name.isEmpty {
            deviceName = name
        } else if let mac, !mac.isEmpty {
            deviceName = "体脂秤 \(mac.suffix(5))"
        } else if let last = lastLockedPacket {
            deviceName = "体脂秤 \(last.macString.suffix(5))"
        } else {
            deviceName = ""
        }
        return BleWeightStatus(
            metric: metric,
            bound: bound,
            connected: isActive && bluetooth.state == .poweredOn,
            deviceName: deviceName,
            lastSyncAt: formattedLastSyncAt()
        )
    }

    func publishStatus() {
        statusPublisher.send(currentStatus())
    }

    // MARK: - Private

    private func handle(_ event: OKOKScaleEvent) {
        switch event {
        case .realtime(let packet):
            print("[Scale-BLL] realtime \(packet.debugDescription)")
            realtimePublisher.send(packet)
            // 收到实时数据时刷新 connected 语义
            publishStatus()
        case .locked(let packet):
            print("[Scale-BLL] locked \(packet.debugDescription) → persist + synced")
            lastLockedPacket = packet
            bindDevice(from: packet)
            persistLocally(packet)
            lockedPublisher.send(packet)
            publishStatus()

            var payload = currentStatus().dictionary
            payload["metric"] = "weight"
            // monitorId 待 HTTP 上报返回后再填
            syncedPublisher.send(payload)
        }
    }

    private func bindDevice(from packet: OKOKScalePacket) {
        UserDefaults.standard.set(packet.macString, forKey: boundMacStorageKey)
        if UserDefaults.standard.string(forKey: boundNameStorageKey)?.isEmpty != false {
            UserDefaults.standard.set("OKOK体脂秤", forKey: boundNameStorageKey)
        }
    }

    private func persistLocally(_ packet: OKOKScalePacket) {
        let payload: [String: Any] = [
            "weightKg": packet.weightKg,
            "resistanceRaw": packet.resistanceRaw,
            "mac": packet.macString,
            "productId": packet.productId,
            "serial": packet.serial,
            "measuredAt": ISO8601DateFormatter().string(from: Date()),
        ]
        UserDefaults.standard.set(payload, forKey: lastLockedStorageKey)
    }

    private func formattedLastSyncAt() -> String {
        guard let dict = UserDefaults.standard.dictionary(forKey: lastLockedStorageKey),
              let iso = dict["measuredAt"] as? String,
              let date = ISO8601DateFormatter().date(from: iso) else {
            return ""
        }
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "今天 HH:mm"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "昨天 HH:mm"
        } else {
            formatter.dateFormat = "MM-dd HH:mm"
        }
        return formatter.string(from: date)
    }

    private func emitError(code: String, message: String) {
        print("[Scale-BLL] error code=\(code) message=\(message)")
        errorPublisher.send([
            "metric": "weight",
            "code": code,
            "message": message,
        ])
    }

    private func errorMessage(for state: BluetoothState) -> String {
        switch state {
        case .poweredOff: return "请打开手机蓝牙"
        case .unauthorized: return "请在系统设置中允许蓝牙权限"
        case .unsupported: return "当前设备不支持蓝牙"
        default: return "蓝牙暂不可用"
        }
    }
}
