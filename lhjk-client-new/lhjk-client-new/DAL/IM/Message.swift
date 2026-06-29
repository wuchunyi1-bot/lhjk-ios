import Foundation

// MARK: - 消息类型

enum MessageType: String, Codable {
    case text
    case system
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

// MARK: - ChatMessage 模型

/// 聊天消息模型 — 参考 funde-client ConversationDetailView.vue ChatMessage 类型
struct ChatMessage: Identifiable, Codable {
    let id: String
    let type: MessageType
    let role: MessageRole
    let senderName: String?
    let senderRole: String?
    let avatar: String?
    let text: String?
    let time: String
    let card: ServiceCard?
    let meal: MealAnalysis?
    let report: AIWeeklyReport?
    /// 所属会话 ID（融云消息携带，mock 消息为 nil）
    let conversationId: String?

    var isStaff: Bool { role == .staff }
    var isUser: Bool { role == .user }
    var isSystem: Bool { type == .system }
}

// MARK: - Mock Data

extension ChatMessage {
    /// 按会话 ID 获取 mock 消息
    static func mockMessages(for conversationId: String) -> [ChatMessage] {
        switch conversationId {
        case "conv-001", "manager", "1": return mockManagerMessages
        case "conv-002", "doctor": return mockDoctorMessages
        case "conv-003", "nutrition": return mockNutritionMessages
        case "conv-ai-xd", "ai": return mockAIMessages
        case "conv-team", "team": return mockTeamMessages
        default: return mockDefaultMessages
        }
    }

    // 健管师会话
    private static let mockManagerMessages: [ChatMessage] = [
        .staff("MSG-M01", "李阿姨您好，我是您的专属健管师王顾问。", "王顾问", "健管师", "王", "今天 14:20"),
        .staffCard("MSG-M02", ServiceCard(title: "血压趋势提醒", icon: "heart.text.square", accent: nil, summary: "近 7 天收缩压平均 137 mmHg，舒张压平均 86 mmHg，整体处于偏高状态。", rows: [
            CardRow(label: "收缩压", value: "137 mmHg", status: "偏高"),
            CardRow(label: "舒张压", value: "86 mmHg", status: "正常"),
            CardRow(label: "测量天数", value: "7 / 7 天", status: nil),
        ], footnote: "建议本周减少高盐饮食摄入，每天早晚各测一次血压并同步记录。", action: "查看监测方案")),
        .user("MSG-M03", "好的，我晚上注意饮食。另外我最近睡眠不太好。", "今天 14:32"),
        .staff("MSG-M04", "您提到睡眠问题，我会请林老师给您一些放松技巧。", "王顾问", "健管师", "王", "今天 14:35"),
        .system("MSG-M05", "今天 14:36 已同步血压数据"),
    ]

    // 医生会话
    private static let mockDoctorMessages: [ChatMessage] = [
        .staff("MSG-D01", "您好，我看了您最近的血压和用药记录。", "张建国", "主任医师", "张", "今天 09:00"),
        .staffCard("MSG-D02", ServiceCard(title: "用药复核", icon: "pills", accent: nil, summary: "当前用药方案：硝苯地平控释片 30mg qd，二甲双胍 0.5g tid。", rows: [
            CardRow(label: "降压药", value: "硝苯地平控释片 30mg", status: "继续"),
            CardRow(label: "降糖药", value: "二甲双胍 0.5g", status: "继续"),
            CardRow(label: "用药周期", value: "已连续 12 周", status: nil),
        ], footnote: "降压药先不要自行调整剂量，下次复诊时根据血压监测数据评估是否需要调药。", action: "查看用药记录")),
        .user("MSG-D03", "好的医生，我按时吃药。那我下次什么时候来复诊？", "今天 09:10"),
        .staff("MSG-D04", "建议 2 周后复诊，届时带着这两周的血压记录来。", "张建国", "主任医师", "张", "今天 09:15"),
    ]

    // 营养师会话
    private static let mockNutritionMessages: [ChatMessage] = [
        .staff("MSG-N01", "陈梅给您搭配了一份低钠 7 日早餐表，请查收。", "陈梅", "营养师", "陈", "昨天 16:00"),
        .staffCard("MSG-N02", ServiceCard(title: "低钠 7 日早餐方案", icon: "fork.knife", accent: nil, summary: "总热量控制 1800 kcal/日，钠摄入 ≤ 2000 mg/日。", rows: [
            CardRow(label: "周一", value: "燕麦粥 + 水煮蛋 + 凉拌黄瓜", status: nil),
            CardRow(label: "周二", value: "全麦面包 + 牛油果 + 豆浆", status: nil),
            CardRow(label: "周三", value: "小米粥 + 蒸饺 + 焯西兰花", status: nil),
        ], footnote: "所有菜品请用低钠盐或薄盐酱油调味。早餐后 30 分钟散步有助于餐后血糖控制。", action: "查看完整方案")),
        .staffMeal("MSG-N03", MealAnalysis(label: "昨日 晚餐", annotations: [
            MealAnnotation(text: "红烧肉", tag: .danger, tip: "饱和脂肪较高，建议替换为清蒸鱼"),
            MealAnnotation(text: "炒青菜", tag: .success, tip: "低热量高纤维，继续保持"),
            MealAnnotation(text: "米饭（200g）", tag: .warning, tip: "碳水稍多，建议减至 150g"),
        ], comment: "晚餐总体热量偏高，红烧肉是主要问题。建议下周尽量减少红烧类菜品，多用清蒸或水煮方式。青菜搭配很好，继续保持。", from: "营养师 陈梅")),
        .user("MSG-N04", "谢谢陈老师！我明天开始按这个方案吃。红烧肉确实要戒了 😅", "昨天 16:30"),
    ]

    // AI 小德会话
    private static let mockAIMessages: [ChatMessage] = [
        .staff("MSG-A01", "主人早上好！☀️ 这是您本周的健康周报，请查收～", "小德", "AI 健康顾问", "德", "今天 08:00"),
        .aiReport("MSG-A02", AIWeeklyReport(weekNo: 24, scoreBefore: 72, scoreAfter: 88, highlights: [
            AIHighlight(icon: "figure.walk", text: "日均步数达到 8,200 步，超额完成目标"),
            AIHighlight(icon: "fork.knife", text: "晚餐热量控制明显改善，蔬菜占比提升"),
            AIHighlight(icon: "bed.double", text: "平均睡眠时长从 6.2h 提升至 7.1h"),
        ], medal: AIMedal(icon: "medal", name: "自律之星"), nextGoal: "下周尝试每天晨跑 20 分钟，进一步提升心肺耐力～")),
        .staff("MSG-A03", "主人，本周您的健康评分提升了 16 分！明天记得把晨跑数据同步过来。", "小德", "AI 健康顾问", "德", "今天 08:01"),
        .user("MSG-A04", "好的小德！这周确实感觉状态好多了 👍", "今天 08:10"),
    ]

    // 团队群会话
    private static let mockTeamMessages: [ChatMessage] = [
        .system("MSG-T01", "王顾问邀请张建国医生、陈梅营养师加入服务群"),
        .staff("MSG-T02", "大家好，我把李阿姨本周的监测数据同步到群里，请各位专家关注。", "王顾问", "健管师", "王", "今天 14:20"),
        .staffCard("MSG-T03", ServiceCard(title: "本周监测汇总", icon: "chart.line.uptrend.xyaxis", accent: nil, summary: "血压整体偏高、血糖趋于稳定、睡眠质量有所改善。", rows: [
            CardRow(label: "收缩压", value: "137 mmHg", status: "偏高"),
            CardRow(label: "空腹血糖", value: "6.2 mmol/L", status: "正常"),
            CardRow(label: "睡眠评分", value: "78 分", status: "改善中"),
        ], footnote: "本周重点：控制盐摄入 + 保持运动 + 监测晨间血压。", action: "查看详细数据")),
        .staff("MSG-T04", "收到，降压药方案维持不变，下周复诊时再评估。", "张建国", "主任医师", "张", "今天 14:35"),
        .staff("MSG-T05", "饮食方案已更新，早餐减钠增钾，晚餐控制碳水。@陈梅", "陈梅", "营养师", "陈", "今天 14:40"),
    ]

    // 默认会话
    private static let mockDefaultMessages: [ChatMessage] = [
        .staff("MSG-001", "您好！请问有什么可以帮您的？", "健康顾问", "客服", "顾", "今天 10:00"),
        .user("MSG-002", "我想了解一下我的健康管理方案", "今天 10:02"),
        .staff("MSG-003", "好的，我来为您查看。您的专属健管师会在 24 小时内与您联系。", "健康顾问", "客服", "顾", "今天 10:05"),
    ]

    // MARK: Factory helpers

    private static func staff(_ id: String, _ text: String, _ name: String, _ role: String, _ avatar: String, _ time: String) -> ChatMessage {
        ChatMessage(id: id, type: .text, role: .staff, senderName: name, senderRole: role, avatar: avatar, text: text, time: time, card: nil, meal: nil, report: nil, conversationId: nil)
    }

    private static func user(_ id: String, _ text: String, _ time: String) -> ChatMessage {
        ChatMessage(id: id, type: .text, role: .user, senderName: nil, senderRole: nil, avatar: nil, text: text, time: time, card: nil, meal: nil, report: nil, conversationId: nil)
    }

    private static func system(_ id: String, _ text: String) -> ChatMessage {
        ChatMessage(id: id, type: .system, role: .user, senderName: nil, senderRole: nil, avatar: nil, text: text, time: "", card: nil, meal: nil, report: nil, conversationId: nil)
    }

    private static func staffCard(_ id: String, _ card: ServiceCard) -> ChatMessage {
        ChatMessage(id: id, type: .metricCard, role: .staff, senderName: nil, senderRole: nil, avatar: nil, text: nil, time: "", card: card, meal: nil, report: nil, conversationId: nil)
    }

    private static func staffMeal(_ id: String, _ meal: MealAnalysis) -> ChatMessage {
        ChatMessage(id: id, type: .mealAnalysis, role: .staff, senderName: nil, senderRole: nil, avatar: nil, text: nil, time: "", card: nil, meal: meal, report: nil, conversationId: nil)
    }

    private static func aiReport(_ id: String, _ report: AIWeeklyReport) -> ChatMessage {
        ChatMessage(id: id, type: .aiWeeklyReport, role: .staff, senderName: "小德", senderRole: "AI 健康顾问", avatar: "德", text: nil, time: "今天 08:00", card: nil, meal: nil, report: report, conversationId: nil)
    }
}
