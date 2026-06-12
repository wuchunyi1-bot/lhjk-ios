import Foundation
import Combine

// MARK: - 融云连接状态

/// 融云连接状态（映射 RCConnectionStatus）
enum RCConnectionStatus: Int {
    case connected = 0
    case connecting = 1
    case disconnected = 2
    case tokenIncorrect = 3
    case cellularDenied = 4

    var description: String {
        switch self {
        case .connected:      return "已连接"
        case .connecting:     return "连接中"
        case .disconnected:   return "未连接"
        case .tokenIncorrect: return "Token 错误"
        case .cellularDenied: return "蜂窝网络被拒绝"
        }
    }
}

// MARK: - 融云 SDK 管理器 (DAL)

/// 融云 SDK 封装管理器
final class RongCloudManager {

    // MARK: - Singleton

    static let shared = RongCloudManager()

    // MARK: - Publishers

    /// 连接状态变化
    let connectionStatusPublisher = PassthroughSubject<RCConnectionStatus, Never>()
    /// 收到的新消息
    let messageReceivedPublisher = PassthroughSubject<Message, Never>()

    // MARK: - Properties

    /// 是否已初始化
    private(set) var isInitialized: Bool = false
    /// 当前连接状态
    private(set) var connectionStatus: RCConnectionStatus = .disconnected

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// 初始化融云 SDK
    /// - Parameter appKey: 融云应用 Key
    func initialize(appKey: String) {
        // TODO: RCIMClient.shared().initWithAppKey(appKey)
        // RCIMClient.initWithAppKey(appKey)
        isInitialized = true
        print("[RongCloud] SDK initialized with appKey: \(appKey)")
    }

    /// 连接融云服务
    /// - Parameter token: 融云 Token（从服务端获取）
    func connect(with token: String) {
        guard isInitialized else {
            print("[RongCloud] Error: SDK not initialized")
            return
        }

        // TODO: RCIMClient.shared().connect(withToken: token) { [weak self] userId in
        //     self?.connectionStatus = .connected
        //     self?.connectionStatusPublisher.send(.connected)
        // } error: { [weak self] errorCode in
        //     self?.handleConnectionError(errorCode)
        // } tokenIncorrect: {
        //     // Token 错误，需要重新获取
        // }

        connectionStatus = .connecting
        connectionStatusPublisher.send(.connecting)
        print("[RongCloud] Connecting with token: \(token.prefix(8))...")
    }

    /// 断开融云连接
    func disconnect() {
        // TODO: RCIMClient.shared().disconnect()
        connectionStatus = .disconnected
        connectionStatusPublisher.send(.disconnected)
    }

    /// 获取会话列表
    func getConversationList() -> [Conversation] {
        // TODO: RCIMClient.shared().getConversationList([.private, .group, .system])
        return []
    }

    /// 获取指定会话的消息列表
    /// - Parameters:
    ///   - conversationId: 会话 ID
    ///   - beforeMessageId: 起始消息 ID（向前翻页），nil 表示最新
    ///   - count: 每页数量
    func getMessages(
        conversationId: String,
        beforeMessageId: String? = nil,
        count: Int = 20
    ) -> [Message] {
        // TODO: RCIMClient.shared().getHistoryMessages(.private, targetId: conversationId, oldestMessageId: beforeMessageId, count: count)
        return []
    }

    /// 清除会话未读数
    func clearUnreadCount(for conversationId: String) {
        // TODO: RCIMClient.shared().clearMessagesUnreadStatus(.private, targetId: conversationId)
    }

    /// 删除会话
    func deleteConversation(_ conversationId: String) {
        // TODO: RCIMClient.shared().remove(.private, targetId: conversationId)
    }

    // MARK: - Private Methods

    private func handleConnectionError(_ errorCode: Int) {
        // 融云错误码映射
        switch errorCode {
        case 31004:
            connectionStatus = .tokenIncorrect
        case 31010:
            connectionStatus = .cellularDenied
        default:
            connectionStatus = .disconnected
        }
        connectionStatusPublisher.send(connectionStatus)
    }
}
