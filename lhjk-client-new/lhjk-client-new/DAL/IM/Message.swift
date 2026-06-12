import Foundation

// MARK: - 消息类型

/// 融云兼容的消息类型
enum MessageType: String, Codable {
    case text
    case image
    case voice
    case video
    case file
    case location
    case system
}

// MARK: - 消息状态

enum MessageStatus: String, Codable {
    case sending
    case sent
    case delivered
    case read
    case failed
}

// MARK: - 消息模型

/// 消息模型 — 映射融云 RCMessage
struct Message: Identifiable {
    /// 消息唯一 ID
    let id: String
    /// 消息类型
    let type: MessageType
    /// 发送者 ID
    let senderId: String
    /// 接收者 ID
    let receiverId: String
    /// 消息内容
    let content: String
    /// 扩展数据（图片 URL、语音 URL 等）
    let extra: [String: String]?
    /// 时间戳
    let timestamp: Date
    /// 消息状态
    var status: MessageStatus

    // MARK: - 初始化

    init(
        id: String = UUID().uuidString,
        type: MessageType,
        senderId: String,
        receiverId: String,
        content: String,
        extra: [String: String]? = nil,
        timestamp: Date = Date(),
        status: MessageStatus = .sending
    ) {
        self.id = id
        self.type = type
        self.senderId = senderId
        self.receiverId = receiverId
        self.content = content
        self.extra = extra
        self.timestamp = timestamp
        self.status = status
    }
}

// MARK: - 融云消息映射

extension Message {
    /// 从融云 RCMessage 转换为本地 Message 模型
    /// - Parameter rcMessage: 融云消息对象（RCMessage）
    static func fromRongCloud(rcMessage: Any) -> Message? {
        // TODO: 融云 SDK 消息类型映射
        // RCMessage → content (RCMessageContent) → 提取字段
        return nil
    }

    /// 将本地 Message 转换为融云 RCMessageContent
    func toRongCloudContent() -> Any? {
        // TODO: 根据 type 创建对应的 RCTextMessage / RCImageMessage 等
        return nil
    }
}
