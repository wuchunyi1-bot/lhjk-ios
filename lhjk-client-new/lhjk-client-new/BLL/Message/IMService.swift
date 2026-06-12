import Foundation
import Combine

/// IM 业务服务 — 消息收发协调、会话管理
final class IMService {

    // MARK: - Singleton

    static let shared = IMService()

    // MARK: - Dependencies

    private let rongCloudManager = RongCloudManager.shared
    private let messageDelegate = RongCloudMessageDelegate.shared

    // MARK: - Publishers

    /// 新消息
    var newMessagePublisher: AnyPublisher<Message, Never> {
        rongCloudManager.messageReceivedPublisher.eraseToAnyPublisher()
    }

    /// 连接状态
    var connectionStatusPublisher: AnyPublisher<RCConnectionStatus, Never> {
        rongCloudManager.connectionStatusPublisher.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    private init() {
        setupMessageHandler()
    }

    // MARK: - Public Methods

    /// 初始化并连接融云
    func connect(appKey: String, token: String) {
        rongCloudManager.initialize(appKey: appKey)
        rongCloudManager.connect(with: token)
    }

    /// 断开连接
    func disconnect() {
        rongCloudManager.disconnect()
    }

    /// 获取会话列表
    func getConversations() -> [Conversation] {
        return rongCloudManager.getConversationList()
    }

    /// 获取消息列表
    func getMessages(conversationId: String, before messageId: String? = nil) -> [Message] {
        return rongCloudManager.getMessages(
            conversationId: conversationId,
            beforeMessageId: messageId
        )
    }

    /// 标记会话已读
    func markAsRead(_ conversationId: String) {
        rongCloudManager.clearUnreadCount(for: conversationId)
    }

    /// 删除会话
    func deleteConversation(_ conversationId: String) {
        rongCloudManager.deleteConversation(conversationId)
    }

    // MARK: - Private

    private func setupMessageHandler() {
        messageDelegate.onMessageReceived = { [weak self] message in
            self?.handleIncomingMessage(message)
        }
    }

    private func handleIncomingMessage(_ message: Message) {
        // 处理收到的消息：更新未读计数、触发本地通知等
        print("[IM] Received message from \(message.senderId): \(message.content.prefix(30))")
    }
}
