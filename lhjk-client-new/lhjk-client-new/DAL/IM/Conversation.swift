import Foundation

// MARK: - 会话类型

/// 融云兼容的会话类型
enum ConversationType: Int {
    /// 单聊
    case privateChat = 1
    /// 群聊
    case groupChat = 2
    /// 系统会话
    case system = 3
}

// MARK: - 会话模型

/// 会话模型 — 映射融云 RCConversation
struct Conversation: Identifiable {
    /// 会话 ID（融云 targetId）
    let id: String
    /// 会话类型
    let type: ConversationType
    /// 会话标题
    var title: String?
    /// 最后一条消息摘要
    var lastMessage: String?
    /// 最后消息时间
    var updatedAt: Date
    /// 未读消息数
    var unreadCount: Int
    /// 是否置顶
    var isPinned: Bool

    // MARK: - 初始化

    init(
        id: String,
        type: ConversationType = .privateChat,
        title: String? = nil,
        lastMessage: String? = nil,
        updatedAt: Date = Date(),
        unreadCount: Int = 0,
        isPinned: Bool = false
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.lastMessage = lastMessage
        self.updatedAt = updatedAt
        self.unreadCount = unreadCount
        self.isPinned = isPinned
    }
}

// MARK: - 融云会话映射

extension Conversation {
    /// 从融云 RCConversation 转换为本地 Conversation 模型
    static func fromRongCloud(rcConversation: Any) -> Conversation? {
        // TODO: 融云 SDK 会话类型映射
        // RCConversation → 提取字段
        return nil
    }
}
