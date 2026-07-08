import Foundation

// MARK: - 消息类型

enum MessageType: String, Codable {
    case text
    case image
    case system
    case file
    case video
    case sysNotify
    case timeMarker   // 日期分隔
    case recall       // 撤回通知
    case voice        // 语音消息
    case metricCard = "metric-card"
    case reportCard = "report-card"
    case dietCard = "diet-card"
    case appointmentCard = "appointment-card"
    case caseCard = "case-card"
    case planCard = "plan-card"
    case mealAnalysis = "meal-analysis"
    case aiWeeklyReport = "ai-weekly-report"

    var isCard: Bool {
        switch self {
        case .metricCard, .reportCard, .dietCard, .appointmentCard, .caseCard, .planCard: return true
        default: return false
        }
    }
}

// MARK: - 发送方角色

enum MessageRole: String, Codable {
    case user, staff
}

// MARK: - 服务卡片

struct ServiceCard: Codable {
    let title: String
    let icon: String        // SF Symbol 名
    let accent: String?     // hex 主题色，nil 时用 roleTone fallback
    let summary: String
    let rows: [CardRow]
    let footnote: String?
    let action: String?
}

struct CardRow: Codable {
    let label: String
    let value: String
    let status: String?     // 状态文字，有值时渲染 status badge
}

// MARK: - 餐食分析

struct MealAnalysis: Codable {
    let label: String                   // 餐食标签，如"昨日 晚餐"
    let annotations: [MealAnnotation]
    let comment: String                 // 营养师点评
    let from: String                    // 点评人署名
}

struct MealAnnotation: Codable {
    let text: String
    let tag: MealAnnotationTag
    let tip: String
}

enum MealAnnotationTag: String, Codable {
    case danger, success, warning
}

// MARK: - AI 周报

struct AIWeeklyReport: Codable {
    let weekNo: Int
    let scoreBefore: Int
    let scoreAfter: Int
    let highlights: [AIHighlight]
    let medal: AIMedal?
    let nextGoal: String
}

struct AIHighlight: Codable {
    let icon: String
    let text: String
}

struct AIMedal: Codable {
    let icon: String
    let name: String
}

// MARK: - 引用回复

/// 消息引用回复信息 — 从 content.extra JSON 解析
struct ReplyMessage: Codable {
    /// 被引用消息的内容（文本）或远程 URL（图片/语音/视频/文件）
    let text: String
    /// 被引用消息的发送者名
    let senderName: String
    /// 被引用消息的类型（RC:TxtMsg / RC:ImgMsg / RC:HQVCMsg / AD:VideoMsg / AD:FileMsg / AD:SysNotify）
    let messageType: String
    /// 语音/视频时长（秒），仅 isVoice / isVideo 时有值
    var duration: Int?
    /// 文件名，仅 isFile / isVideo 时有值
    var fileName: String?
    /// 文件大小，仅 isFile 时有值
    var fileSize: String?

    enum CodingKeys: String, CodingKey {
        case text = "calcLastText"
        case senderName = "calcLastName"
        case messageType = "calcLastType"
        case duration, fileName, fileSize
    }

    // MARK: - 类型判断

    var isImage: Bool { messageType == "RC:ImgMsg" }
    var isVoice: Bool { messageType == "RC:HQVCMsg" }
    var isVideo: Bool { messageType == "AD:VideoMsg" }
    var isFile: Bool  { messageType == "AD:FileMsg" }
    /// 是否为媒体类型（图片/语音/视频），展示时渲染缩略图/图标而非文本
    var isMediaType: Bool { isImage || isVoice || isVideo }

    /// 从 content.extra JSON 字符串解析引用回复
    static func fromExtra(_ extra: String?) -> ReplyMessage? {
        guard let extra, !extra.isEmpty,
              let data = extra.data(using: .utf8) else { return nil }
        let payload = try? JSONDecoder().decode(ExtraPayload.self, from: data)
        return payload?.replyMessage
    }

    /// 从 ChatMessage 构建引用信息
    static func from(_ msg: ChatMessage) -> ReplyMessage {
        ReplyMessage(
            text: msg.quotePreviewText,
            senderName: msg.senderName ?? "",
            messageType: msg.quoteObjectName,
            duration: msg.quoteMediaDuration,
            fileName: msg.quoteMediaFileName,
            fileSize: msg.quoteMediaFileSize
        )
    }

    /// 将引用信息序列化为 content.extra JSON 字符串
    static func toExtraJSON(_ reply: ReplyMessage) -> String? {
        let payload = ExtraPayload(replyMessage: reply)
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

/// extra JSON 的顶层结构
struct ExtraPayload: Codable {
    let replyMessage: ReplyMessage?
}

// MARK: - ChatMessage 模型

/// 聊天消息模型 — 参考 funde-client ConversationDetailView.vue ChatMessage 类型
struct ChatMessage: Identifiable {
    let id: String
    let type: MessageType
    let role: MessageRole
    let senderName: String?
    let senderRole: String?
    let avatar: String?
    /// 发送者头像 URL，优先于 avatar 文字展示
    let portraitUrl: String?
    let text: String?
    let time: String
    /// 发送时间戳（毫秒），用于日期比较
    let sentTime: Int64?
    let card: ServiceCard?
    let meal: MealAnalysis?
    let report: AIWeeklyReport?
    /// 图片本地路径或远端 URL（type=image 时使用）
    let imagePath: String?
    /// 缩略图宽度（type=image 时使用）
    let thumbWidth: Int?
    /// 缩略图高度（type=image 时使用）
    let thumbHeight: Int?
    /// 所属会话 ID（融云消息携带，mock 消息为 nil）
    let conversationId: String?
    /// 消息附加字段（自定义类型时从 RCMessageContent.extra 提取）
    let extra: String?
    /// 引用回复信息（从 extra JSON 解析）
    let reply: ReplyMessage?
    /// 融云消息 ID（用于下载媒体等操作），remote 消息未入库时为 -1
    let messageId: Int

    // MARK: - 自定义消息内容（非 Codable，fromRongCloud 填充）

    /// AD:FileMsg 消息体
    var fileContent: FileMessage? = nil
    /// AD:VideoMsg 消息体
    var videoContent: VideoMessage? = nil
    /// AD:SysNotify 消息体
    var sysNotifyContent: SysNotifyMessage? = nil

    var isStaff: Bool { role == .staff }
    var isUser: Bool { role == .user }
    var isSystem: Bool { type == .system || type == .timeMarker || type == .recall }
}

// MARK: - Codable

extension ChatMessage: Codable {
    enum CodingKeys: String, CodingKey {
        case id, type, role, senderName, senderRole, avatar, portraitUrl
        case text, time, card, meal, report
        case imagePath, thumbWidth, thumbHeight
        case conversationId, extra, reply, sentTime
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        type = try c.decode(MessageType.self, forKey: .type)
        role = try c.decode(MessageRole.self, forKey: .role)
        senderName = try c.decodeIfPresent(String.self, forKey: .senderName)
        senderRole = try c.decodeIfPresent(String.self, forKey: .senderRole)
        avatar = try c.decodeIfPresent(String.self, forKey: .avatar)
        portraitUrl = try c.decodeIfPresent(String.self, forKey: .portraitUrl)
        text = try c.decodeIfPresent(String.self, forKey: .text)
        time = try c.decode(String.self, forKey: .time)
        card = try c.decodeIfPresent(ServiceCard.self, forKey: .card)
        meal = try c.decodeIfPresent(MealAnalysis.self, forKey: .meal)
        report = try c.decodeIfPresent(AIWeeklyReport.self, forKey: .report)
        imagePath = try c.decodeIfPresent(String.self, forKey: .imagePath)
        thumbWidth = try c.decodeIfPresent(Int.self, forKey: .thumbWidth)
        thumbHeight = try c.decodeIfPresent(Int.self, forKey: .thumbHeight)
        conversationId = try c.decodeIfPresent(String.self, forKey: .conversationId)
        extra = try c.decodeIfPresent(String.self, forKey: .extra)
        reply = try c.decodeIfPresent(ReplyMessage.self, forKey: .reply)
        sentTime = try c.decodeIfPresent(Int64.self, forKey: .sentTime)
        fileContent = nil
        videoContent = nil
        sysNotifyContent = nil
        messageId = -1
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(type, forKey: .type)
        try c.encode(role, forKey: .role)
        try c.encodeIfPresent(senderName, forKey: .senderName)
        try c.encodeIfPresent(senderRole, forKey: .senderRole)
        try c.encodeIfPresent(avatar, forKey: .avatar)
        try c.encodeIfPresent(portraitUrl, forKey: .portraitUrl)
        try c.encodeIfPresent(text, forKey: .text)
        try c.encode(time, forKey: .time)
        try c.encodeIfPresent(card, forKey: .card)
        try c.encodeIfPresent(meal, forKey: .meal)
        try c.encodeIfPresent(report, forKey: .report)
        try c.encodeIfPresent(imagePath, forKey: .imagePath)
        try c.encodeIfPresent(thumbWidth, forKey: .thumbWidth)
        try c.encodeIfPresent(thumbHeight, forKey: .thumbHeight)
        try c.encodeIfPresent(conversationId, forKey: .conversationId)
        try c.encodeIfPresent(extra, forKey: .extra)
        try c.encodeIfPresent(reply, forKey: .reply)
        try c.encodeIfPresent(sentTime, forKey: .sentTime)
    }
}

// MARK: - 消息操作能力

extension ChatMessage {
    /// 是否可撤回：自己发的，发送距今 ≤ 60 分钟
    var canRecall: Bool {
        guard role == .user, let sent = sentTime, sent > 0 else { return false }
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        return (nowMs - sent) <= 60 * 60 * 1000
    }

    /// 是否可复制：仅文本消息
    var canCopy: Bool { type == .text }

    /// 是否可引用：非撤回、非时间标记
    var canQuote: Bool { type != .recall && type != .timeMarker }

    /// 引用所需的 objectName（融云消息类型标识）
    var quoteObjectName: String {
        switch type {
        case .text:   return "RC:TxtMsg"
        case .image:  return "RC:ImgMsg"
        case .voice:  return "RC:HQVCMsg"
        case .file:   return "AD:FileMsg"
        case .video:  return "AD:VideoMsg"
        case .sysNotify: return "AD:SysNotify"
        default:      return "RC:TxtMsg"
        }
    }

    /// 引用所需的预览文本（文本消息用内容，媒体类型用远程 URL）
    var quotePreviewText: String {
        switch type {
        case .text:
            return text ?? ""
        case .image:
            return imagePath ?? ""       // 远程图片 URL
        case .voice:
            return imagePath ?? ""       // 远程语音 URL
        case .video:
            return videoContent?.videoCoverImg ?? videoContent?.videoUrl ?? ""
        case .file:
            return fileContent?.fileUrl ?? ""
        case .sysNotify:
            return sysNotifyContent?.title ?? "[套餐]"
        default:
            return ""
        }
    }

    /// 引用消息的媒体时长（语音/视频），单位秒
    var quoteMediaDuration: Int? {
        switch type {
        case .voice: return thumbHeight  // duration 复用 thumbHeight 字段
        case .video: return videoContent?.videoTime
        default:     return nil
        }
    }

    /// 引用消息的文件名
    var quoteMediaFileName: String? {
        switch type {
        case .file:  return fileContent?.fileName
        case .video: return videoContent?.videoName
        default:     return nil
        }
    }

    /// 引用消息的文件大小
    var quoteMediaFileSize: String? {
        switch type {
        case .file: return fileContent?.fileSize
        default:    return nil
        }
    }
}

