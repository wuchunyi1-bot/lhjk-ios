import Network
import Combine

/// 网络状态监控器
final class NetworkMonitor {

    // MARK: - Singleton

    static let shared = NetworkMonitor()

    // MARK: - Published State

    /// 当前是否联网
    @Published private(set) var isConnected: Bool = true
    /// 当前网络类型
    @Published private(set) var connectionType: ConnectionType = .unknown

    // MARK: - Private Properties

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.lhjk.network-monitor")

    // MARK: - Initialization

    private init() {
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = (path.status == .satisfied)
                self?.connectionType = ConnectionType(from: path)
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

// MARK: - Connection Type

enum ConnectionType: String {
    case wifi
    case cellular
    case wiredEthernet
    case unknown

    init(from path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            self = .wifi
        } else if path.usesInterfaceType(.cellular) {
            self = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            self = .wiredEthernet
        } else {
            self = .unknown
        }
    }
}
