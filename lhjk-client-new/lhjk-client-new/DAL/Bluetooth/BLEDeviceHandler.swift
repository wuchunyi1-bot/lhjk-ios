import Combine
import Foundation

/// 设备种类 — 每种对应独立 Handler
enum BLEDeviceKind: String, Hashable {
    case okokBroadcastScale
}

/// 设备协议处理接口 — 只消费基础层原始事件，不持有 CBCentralManager
protocol BLEDeviceHandler: AnyObject {
    var kind: BLEDeviceKind { get }
    func start(bluetooth: BluetoothManager)
    func stop()
}

/// Handler 注册表 — 按 kind 取用，避免 Manager 内堆品牌分支
final class BLEDeviceRegistry {
    static let shared = BLEDeviceRegistry()

    private var handlers: [BLEDeviceKind: BLEDeviceHandler] = [:]
    private let lock = NSLock()

    private init() {
        register(OKOKBroadcastScaleHandler())
    }

    func register(_ handler: BLEDeviceHandler) {
        lock.lock()
        handlers[handler.kind] = handler
        lock.unlock()
    }

    func handler(for kind: BLEDeviceKind) -> BLEDeviceHandler? {
        lock.lock()
        defer { lock.unlock() }
        return handlers[kind]
    }
}
