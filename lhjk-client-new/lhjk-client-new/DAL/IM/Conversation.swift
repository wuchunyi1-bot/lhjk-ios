import Foundation

/// 会话模型 — 参考 funde-im conversations.json
struct Conversation: Identifiable {
    let id: String
    let patientCid: String
    let name: String
    let doctorTeam: String
    let tags: [ConversationTag]
    let preview: String
    let lastMessageAt: Date
    var unreadCount: Int
    let priority: ConversationPriority
    let status: ConversationStatus

    var avatarChar: String { String(name.prefix(1)) }
}

enum ConversationTag: String, CaseIterable {
    case bmi, glucose, pressure, sleep, gut, uric, hyc

    var label: String {
        switch self {
        case .bmi: return "BMI"
        case .glucose: return "血糖"
        case .pressure: return "血压"
        case .sleep: return "睡眠"
        case .gut: return "肠道"
        case .uric: return "尿酸"
        case .hyc: return "HYC"
        }
    }

    var bgColor: String {
        switch self {
        case .bmi: return "#FFF3EE"
        case .glucose: return "#E6F7EF"
        case .pressure: return "#FFF3DC"
        case .sleep: return "#F3EFFC"
        case .gut: return "#EBF1FA"
        case .uric: return "#FCE9E6"
        case .hyc: return "#FFE9DF"
        }
    }

    var textColor: String {
        switch self {
        case .bmi: return "#FF7A50"
        case .glucose: return "#2DB983"
        case .pressure: return "#F5A524"
        case .sleep: return "#7B5E9F"
        case .gut: return "#5C8DC9"
        case .uric: return "#E5564B"
        case .hyc: return "#D6602B"
        }
    }
}

enum ConversationPriority: String {
    case high, normal, low
}

enum ConversationStatus: String {
    case active, pending, closed
}

// MARK: - Mock Data

extension Conversation {
    static func mockData() -> [Conversation] {
        [
            Conversation(id: "CV0001", patientCid: "C0001", name: "韩苑琪", doctorTeam: "黎医生团队", tags: [.bmi], preview: "本周体重回落 1.2kg，BMI 趋势已同步。", lastMessageAt: date("2026-04-25T11:52:00Z"), unreadCount: 24, priority: .high, status: .active),
            Conversation(id: "CV0002", patientCid: "C0002", name: "黄燕", doctorTeam: "林顾医生团队", tags: [.glucose], preview: "空腹血糖 7.8 mmol/L，建议补充早餐记录。", lastMessageAt: date("2026-04-25T10:46:00Z"), unreadCount: 3, priority: .high, status: .active),
            Conversation(id: "CV0003", patientCid: "C0003", name: "李志丽", doctorTeam: "朱素君医生团队", tags: [.sleep], preview: "昨夜睡眠效率 76%，凌晨醒来两次。", lastMessageAt: date("2026-04-24T06:17:00Z"), unreadCount: 0, priority: .normal, status: .active),
            Conversation(id: "CV0004", patientCid: "C0004", name: "刘娅", doctorTeam: "王阎医生团队", tags: [.gut], preview: "菌群报告已生成，建议补充三日饮食记录。", lastMessageAt: date("2026-04-23T06:11:00Z"), unreadCount: 1, priority: .high, status: .active),
            Conversation(id: "CV0005", patientCid: "C0005", name: "潘富贵", doctorTeam: "熊秋医生团队", tags: [.glucose, .pressure], preview: "【服务到期通知】高血糖管理 VIP 年度套餐将于 1 天后到期。", lastMessageAt: date("2026-04-25T18:36:00Z"), unreadCount: 0, priority: .high, status: .active),
            Conversation(id: "CV0006", patientCid: "C0001", name: "刘琪琪", doctorTeam: "熊秋医生团队", tags: [.pressure], preview: "今日晨间血压 148/96，已提醒复测。", lastMessageAt: date("2026-04-21T07:16:00Z"), unreadCount: 4, priority: .high, status: .active),
            Conversation(id: "CV0007", patientCid: "C0002", name: "万保吕", doctorTeam: "熊秋医生团队", tags: [.sleep], preview: "今日睡眠效率 88%，深睡时长略有改善。", lastMessageAt: date("2026-04-20T05:10:00Z"), unreadCount: 0, priority: .low, status: .active),
            Conversation(id: "CV0008", patientCid: "C0003", name: "刘彦希", doctorTeam: "杨金英医生团队", tags: [.gut], preview: "肠道菌群取样已回流实验室，待二次解读。", lastMessageAt: date("2026-04-20T04:28:00Z"), unreadCount: 0, priority: .normal, status: .active),
            Conversation(id: "CV0009", patientCid: "C0004", name: "钟钟亭", doctorTeam: "熊秋医生团队", tags: [.hyc], preview: "HYC 风险评分升至 82，建议今日电话回访。", lastMessageAt: date("2026-04-19T04:21:00Z"), unreadCount: 6, priority: .high, status: .pending),
            Conversation(id: "CV0010", patientCid: "C0005", name: "孙明明", doctorTeam: "黎医生团队", tags: [.pressure], preview: "血压今日数据已上传，午后收缩压偏高。", lastMessageAt: date("2026-04-18T03:55:00Z"), unreadCount: 0, priority: .normal, status: .closed),
            Conversation(id: "CV0011", patientCid: "C0001", name: "赵海岚", doctorTeam: "陈医生团队", tags: [.bmi], preview: "体脂率回落到 31%，建议继续保持晚餐控制。", lastMessageAt: date("2026-04-17T08:42:00Z"), unreadCount: 2, priority: .normal, status: .active),
            Conversation(id: "CV0012", patientCid: "C0002", name: "邓一宁", doctorTeam: "贺医生团队", tags: [.uric], preview: "尿酸 496 umol/L，已推送低嘌呤饮食建议。", lastMessageAt: date("2026-04-16T10:18:00Z"), unreadCount: 0, priority: .high, status: .active),
            Conversation(id: "CV0013", patientCid: "C0003", name: "蒋文茜", doctorTeam: "张医生团队", tags: [.hyc], preview: "HYC 评估问卷已完成，等待人工复核。", lastMessageAt: date("2026-04-15T09:35:00Z"), unreadCount: 0, priority: .normal, status: .active),
            Conversation(id: "CV0014", patientCid: "C0004", name: "许晨悦", doctorTeam: "李医生团队", tags: [.uric], preview: "夜间脚趾疼痛反馈已收到，建议追加复查。", lastMessageAt: date("2026-04-14T07:40:00Z"), unreadCount: 1, priority: .high, status: .pending),
            Conversation(id: "CV0015", patientCid: "C0005", name: "周书语", doctorTeam: "赵医生团队", tags: [.glucose, .bmi], preview: "本周血糖趋势稳定，减重计划进入第二阶段。", lastMessageAt: date("2026-04-13T06:12:00Z"), unreadCount: 0, priority: .normal, status: .active),
        ]
    }

    private static func date(_ iso: String) -> Date {
        let fmt = ISO8601DateFormatter()
        return fmt.date(from: iso) ?? Date()
    }
}
