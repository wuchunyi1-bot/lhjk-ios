import Combine
import Foundation

/// 体脂秤 / 体重秤 BLE 测量会话（Health BLL）
///
/// 启停 OKOK 广播 Handler；转发实时/锁定事件；锁定去重后写入最近一次缓存。
/// 体重 HTTP 保存随 Weight 模块恢复后再挂接；本期不传体脂算法字段。
final class ScaleBleSessionService {

    static let shared = ScaleBleSessionService()

    /// 实时体重（非锁定）
    let realtimePublisher = PassthroughSubject<OKOKScalePacket, Never>()
    /// 锁定测量（已去重）
    let lockedPublisher = PassthroughSubject<OKOKScalePacket, Never>()
    /// 最近一次成功锁定（供 UI / 后续落库）
    private(set) var lastLockedPacket: OKOKScalePacket?

    private let bluetooth: BluetoothManager
    private var handler: OKOKBroadcastScaleHandler?
    private var cancellables = Set<AnyCancellable>()
    private var isActive = false

    private let lastLockedStorageKey = "fd_okok_last_locked_scale"

    init(bluetooth: BluetoothManager = AppContainer.shared.bluetoothManager) {
        self.bluetooth = bluetooth
    }

    /// 开始测量会话（扫描广播，不连接）
    func startSession() {
        guard !isActive else { return }
        isActive = true

        guard let h = BLEDeviceRegistry.shared.handler(for: .okokBroadcastScale) as? OKOKBroadcastScaleHandler else {
            assertionFailure("OKOKBroadcastScaleHandler not registered")
            isActive = false
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

        h.start(bluetooth: bluetooth)
    }

    /// 结束会话
    func stopSession() {
        guard isActive else { return }
        isActive = false
        cancellables.removeAll()
        handler?.stop()
        handler = nil
    }

    // MARK: - Private

    private func handle(_ event: OKOKScaleEvent) {
        switch event {
        case .realtime(let packet):
            realtimePublisher.send(packet)
        case .locked(let packet):
            lastLockedPacket = packet
            persistLocally(packet)
            lockedPublisher.send(packet)
            // TODO: 恢复 WeightService 后在此调用保存接口（weightKg + mac，不传体脂算法字段）
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
}
