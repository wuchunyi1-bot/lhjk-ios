import Foundation

// MARK: - 消息类型

enum MessageType: String, Codable {
    case text, image, notification, system, file
}

// MARK: - 发送者类型

enum MessageSender: String, Codable {
    case patient, staff, system
}

// MARK: - 健康通知卡片

struct NotificationPayload: Codable {
    let title: String
    let icon: NotificationIcon
    let accent: NotificationAccent
    let rows: [NotificationRow]
    let footnote: String?
}

struct NotificationRow: Codable {
    let label: String
    let value: String
    let statusText: String?
    let statusTone: StatusTone?
}

enum NotificationIcon: String, Codable {
    case glucose, ecg, pressure, spo2, weight, sleep, temperature, bmi
    case diet, medicine, retina, lung, gut, report, plan, call, profile

    var sfSymbol: String {
        switch self {
        case .glucose: return "drop"
        case .ecg: return "waveform.path.ecg"
        case .pressure: return "heart"
        case .spo2: return "lungs"
        case .weight: return "scalemass"
        case .sleep: return "moon.zzz"
        case .temperature: return "thermometer"
        case .bmi: return "figure.stand"
        case .diet: return "fork.knife"
        case .medicine: return "pills"
        case .retina: return "eye"
        case .lung: return "nose"
        case .gut: return "stethoscope"
        case .report: return "doc.text"
        case .plan: return "calendar"
        case .call: return "phone"
        case .profile: return "person.crop.circle"
        }
    }
}

enum NotificationAccent: String, Codable {
    case coral, pink, gold, green, purple, blue

    var mainHex: String {
        switch self {
        case .coral: return "#FF7A50"
        case .pink: return "#E5564B"
        case .gold: return "#F5A524"
        case .green: return "#2DB983"
        case .purple: return "#7B5E9F"
        case .blue: return "#5C8DC9"
        }
    }

    var softHex: String {
        switch self {
        case .coral: return "#FFF3EE"
        case .pink: return "#FCE9E6"
        case .gold: return "#FFF3DC"
        case .green: return "#E6F7EF"
        case .purple: return "#F3EFFC"
        case .blue: return "#EBF1FA"
        }
    }
}

enum StatusTone: String, Codable {
    case danger, warning, success
}

// MARK: - 消息模型

struct Message: Identifiable {
    let id: String
    let conversationId: String
    let type: MessageType
    let sender: MessageSender
    let senderName: String?
    let senderRole: String?
    let avatarText: String?
    let content: String
    let payload: NotificationPayload?
    let createdAt: Date
    let recalled: Bool
    var status: MessageStatus

    var isStaff: Bool { sender == .staff }
    var isPatient: Bool { sender == .patient }
    var isSystem: Bool { sender == .system || type == .system }
}

enum MessageStatus: String {
    case sending, sent, delivered, read, failed
}

// MARK: - Mock Data

extension Message {
    static func mockMessages(for conversationId: String) -> [Message] {
        [
            Message(id: "MSG0001", conversationId: conversationId, type: .text, sender: .patient, senderName: nil, senderRole: nil, avatarText: nil, content: "你好，我最近血糖有点高，空腹都到8.2了", payload: nil, createdAt: Mock.date("08:30"), recalled: false, status: .sent),
            Message(id: "MSG0002", conversationId: conversationId, type: .text, sender: .staff, senderName: "顾问五号", senderRole: "健康管理师", avatarText: "管", content: "收到，空腹血糖8.2确实偏高，正常应在3.9-6.1之间。请告诉我最近的饮食和运动情况。", payload: nil, createdAt: Mock.date("08:35"), recalled: false, status: .sent),
            Message(id: "MSG0003", conversationId: conversationId, type: .text, sender: .patient, senderName: nil, senderRole: nil, avatarText: nil, content: "这周应酬比较多，吃了几顿大餐，甜食和酒水都摄入较多。运动也少了。", payload: nil, createdAt: Mock.date("08:40"), recalled: false, status: .sent),
            Message(id: "MSG0004", conversationId: conversationId, type: .notification, sender: .staff, senderName: "顾问五号", senderRole: "健康管理师", avatarText: "管", content: "血糖上传通知", payload: NotificationPayload(
                title: "血糖上传通知",
                icon: .glucose, accent: .coral,
                rows: [
                    NotificationRow(label: "测量值", value: "8.2 mmol/L", statusText: "偏高", statusTone: .danger),
                    NotificationRow(label: "今日范围", value: "7.6 ~ 8.4 mmol/L", statusText: nil, statusTone: nil),
                    NotificationRow(label: "今日平均", value: "8.0 mmol/L", statusText: nil, statusTone: nil),
                    NotificationRow(label: "测量时间", value: "2026-04-22 08:48", statusText: nil, statusTone: nil),
                ],
                footnote: "建议恢复低糖饮食一周，并持续监测餐后 2 小时血糖。"
            ), createdAt: Mock.date("08:50"), recalled: false, status: .sent),
            Message(id: "MSG0005", conversationId: conversationId, type: .text, sender: .patient, senderName: nil, senderRole: nil, avatarText: nil, content: "好的，我照做。另外想问一下，我上次开的药还要继续吃吗？", payload: nil, createdAt: Mock.date("09:00"), recalled: false, status: .sent),
            Message(id: "MSG0006", conversationId: conversationId, type: .text, sender: .staff, senderName: "顾问五号", senderRole: "健康管理师", avatarText: "管", content: "二甲双胍请按原剂量继续服用。如果一周后空腹血糖仍高于7.0，我会安排熊医生给您调整方案。", payload: nil, createdAt: Mock.date("09:10"), recalled: false, status: .sent),
            Message(id: "MSG0007", conversationId: conversationId, type: .text, sender: .patient, senderName: nil, senderRole: nil, avatarText: nil, content: "明白了，谢谢。我会注意的。", payload: nil, createdAt: Mock.date("09:15"), recalled: false, status: .sent),
            Message(id: "MSG0008", conversationId: conversationId, type: .system, sender: .system, senderName: nil, senderRole: nil, avatarText: nil, content: "已为您创建随访计划：一周后复查血糖", payload: nil, createdAt: Mock.date("09:16"), recalled: false, status: .sent),
            Message(id: "MSG0050", conversationId: conversationId, type: .notification, sender: .staff, senderName: "顾问五号", senderRole: "健康管理师", avatarText: "管", content: "心电上传通知", payload: NotificationPayload(
                title: "心电上传通知",
                icon: .ecg, accent: .pink,
                rows: [
                    NotificationRow(label: "心电结论", value: "夜间偶发室性早搏", statusText: "需关注", statusTone: .danger),
                    NotificationRow(label: "最高心率", value: "108 次/分", statusText: nil, statusTone: nil),
                    NotificationRow(label: "异常时段", value: "04-23 22:14 - 22:20", statusText: nil, statusTone: nil),
                ],
                footnote: "建议今日减少熬夜，保持复测，并关注胸闷心悸情况。"
            ), createdAt: Mock.date("14:18"), recalled: false, status: .sent),
            Message(id: "MSG0051", conversationId: conversationId, type: .notification, sender: .staff, senderName: "顾问五号", senderRole: "健康管理师", avatarText: "管", content: "血压上传通知", payload: NotificationPayload(
                title: "血压上传通知",
                icon: .pressure, accent: .gold,
                rows: [
                    NotificationRow(label: "测量值", value: "146 / 94 mmHg", statusText: "偏高", statusTone: .danger),
                    NotificationRow(label: "今日范围", value: "138/88 ~ 149/96", statusText: nil, statusTone: nil),
                    NotificationRow(label: "今日平均", value: "144 / 92 mmHg", statusText: nil, statusTone: nil),
                    NotificationRow(label: "测量时间", value: "2026-04-24 08:32", statusText: nil, statusTone: nil),
                ],
                footnote: "建议晚间复测，并减少高盐饮食。"
            ), createdAt: Mock.date("15:00"), recalled: false, status: .sent),
        ]
    }

    private enum Mock {
        static func date(_ time: String) -> Date {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            return fmt.date(from: "2026-04-22T\(time):00+0800") ?? Date()
        }
    }
}
