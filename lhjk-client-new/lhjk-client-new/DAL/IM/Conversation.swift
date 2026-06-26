import Foundation
import RongIMLibCore

// MARK: - 会话角色

/// 健管团队角色类型，控制头像颜色、主色调和快捷回复
enum ConversationRole: String, Codable {
    case ai, team, manager, doctor, nutrition, service, caseManager = "case", psychology

    /// 角色显示标签
    var label: String {
        switch self {
        case .ai: return "AI 健康顾问"
        case .team: return "三好共管服务群"
        case .manager: return "健管师 · 专属"
        case .doctor: return "主任医师 · 内科"
        case .nutrition: return "营养师"
        case .service: return "家庭服务台"
        case .caseManager: return "个案管理师 · 专项"
        case .psychology: return "心理咨询师"
        }
    }

    /// 角色主色调 (hex)
    var toneHex: String {
        switch self {
        case .ai, .team, .manager: return "#FF7A50"
        case .doctor: return "#3D6FB8"
        case .nutrition: return "#1F9A6B"
        case .caseManager: return "#7B5E9F"
        case .psychology: return "#5C8DC9"
        case .service: return "#B47300"
        }
    }
}

// MARK: - 通知类型

/// 系统通知分类，控制图标颜色
enum NotificationTag: String, Codable {
    case appointment, insurance, device, report

    var iconBg: String {
        switch self {
        case .appointment: return "#EAF3FF"
        case .insurance: return "#FFF3DC"
        case .device: return "#FFE9DF"
        case .report: return "#E6F7EF"
        }
    }

    var iconColor: String {
        switch self {
        case .appointment: return "#3D6FB8"
        case .insurance: return "#B47300"
        case .device: return "#FF7A50"
        case .report: return "#1F9A6B"
        }
    }

    var displayName: String {
        switch self {
        case .appointment: return "预约提醒"
        case .insurance: return "保单"
        case .device: return "设备"
        case .report: return "报告"
        }
    }
}

// MARK: - Conversation 模型

/// 会话模型 — 参考 funde-client conversations.json
struct Conversation: Identifiable, Codable {
    let id: String
    let role: ConversationRole
    let roleLabel: String
    let name: String
    let title: String
    let avatar: String
    let status: String
    let serviceScope: String
    let lastMessage: String
    let lastTime: String
    var unread: Int
    let important: Bool

    var unreadBadge: String? {
        unread > 0 ? (unread > 99 ? "99+" : "\(unread)") : nil
    }
}

// MARK: - Notification 模型

/// 系统通知模型 — 参考 funde-client conversations.json notifications 数组
struct AppNotification: Identifiable, Codable {
    let id: String
    let icon: String          // SF Symbol 名
    let iconBg: String        // 图标背景色 hex
    let iconColor: String     // 图标前景色 hex
    let title: String
    let tag: String           // 分类标签文案
    let body: String
    let time: String
    var unread: Bool
}

// MARK: - 预定义角色元数据

extension Conversation {
    /// 通过 conversation id 查找预定义角色元数据
    private static let roleMetaMap: [String: (role: ConversationRole, roleLabel: String, name: String, title: String, avatar: String, status: String, serviceScope: String, important: Bool)] = [
        "conv-ai-xd": (.ai, "AI 健康顾问", "小德", "7×24h AI 健康顾问", "德", "AI 在线", "周报推送 · 目标提醒 · 健康问答", false),
        "conv-team": (.team, "三好共管服务群", "德好慢病逆转服务群", "医生 + 营养师 + 健管师协同服务", "群", "3 人在线", "血压血糖达标 · 饮食运动干预 · 随访协同", true),
        "conv-001": (.manager, "健管师 · 专属", "王顾问", "健康管理专家", "王", "在线", "慢病逆转 · 日常随访", true),
        "conv-002": (.doctor, "主任医师 · 内科", "张建国", "内科主任医师", "张", "今日可咨询", "用药建议 · 指标复核", false),
        "conv-003": (.nutrition, "营养师", "陈梅", "国家注册营养师", "陈", "在线", "饮食方案 · 热量管理", false),
        "conv-004": (.service, "家庭服务台", "家庭服务台", "预约与履约支持", "家", "服务中", "预约确认 · 订单履约", false),
        "conv-005": (.caseManager, "个案管理师 · 专项", "刘个管", "肿瘤与疑难病个案管理师", "刘", "专项跟进", "转诊协调 · MDT 跟进", true),
        "conv-006": (.psychology, "心理咨询师", "林老师", "国家二级心理咨询师", "林", "在线", "情绪管理 · 睡眠认知行为", false),
    ]

    /// 从融云 RCConversation 转换为 Conversation 模型
    /// - Parameter rc: 融云会话对象
    /// - Returns: 合并了预定义元数据的 Conversation，未匹配时使用默认元数据
    static func fromRongCloud(_ rc: RCConversation) -> Conversation {
        let convId = rc.targetId
        let meta = roleMetaMap[convId] ?? (
            role: .manager,
            roleLabel: "健管师",
            name: convId,
            title: "健康管理",
            avatar: String(convId.prefix(1)),
            status: "在线",
            serviceScope: "日常随访",
            important: false
        )

        // 提取最后一条消息文本
        var lastMsg = ""
        if let textMsg = rc.latestMessage as? RCTextMessage {
            lastMsg = textMsg.content
        }

        return Conversation(
            id: convId,
            role: meta.role,
            roleLabel: meta.roleLabel,
            name: meta.name,
            title: meta.title,
            avatar: meta.avatar,
            status: meta.status,
            serviceScope: meta.serviceScope,
            lastMessage: lastMsg.isEmpty ? "暂无消息" : lastMsg,
            lastTime: formatRCTime(rc.sentTime),
            unread: Int(rc.unreadMessageCount),
            important: meta.important
        )
    }

    /// 从 GroupVO + RCConversation 合并创建 Conversation
    /// 仅在融云存在该会话时调用
    /// - Parameters:
    ///   - group: 后端群组数据（展示元数据）
    ///   - rc: 融云会话数据（实时未读数、最后消息）
    static func fromGroupVO(_ group: GroupVO, rc: RCConversation) -> Conversation {
        let convId = group.groupId ?? ""

        // 实时数据：融云
        let unread = Int(rc.unreadMessageCount)
        let lastTimeStr = formatRCTime(rc.sentTime)
        let lastMsg: String
        if let textMsg = rc.latestMessage as? RCTextMessage, !textMsg.content.isEmpty {
            lastMsg = textMsg.content
        } else {
            lastMsg = group.lastContent ?? "暂无消息"
        }

        // 角色映射：serviceId → ConversationRole
        let role = mapServiceIdToRole(group.serviceId)

        let name = group.principalName ?? group.groupName ?? convId
        let avatarChar = group.groupImg?.isEmpty == false
            ? String((group.groupImg ?? name).prefix(1))
            : String(name.prefix(1))

        let statusStr: String
        if let n = group.numbers, n > 0 {
            statusStr = "\(n) 人在线"
        } else {
            statusStr = "在线"
        }

        return Conversation(
            id: convId,
            role: role,
            roleLabel: group.serviceName ?? role.label,
            name: name,
            title: group.serviceName ?? "健康管理",
            avatar: avatarChar,
            status: statusStr,
            serviceScope: group.groupName ?? "日常随访",
            lastMessage: lastMsg,
            lastTime: lastTimeStr,
            unread: unread,
            important: group.labelType == 1
        )
    }

    /// serviceId → ConversationRole 映射
    private static func mapServiceIdToRole(_ serviceId: String?) -> ConversationRole {
        switch serviceId {
        case "ai": return .ai
        case "team": return .team
        case "nutrition": return .nutrition
        case "doctor": return .doctor
        case "case": return .caseManager
        case "psychology": return .psychology
        case "service": return .service
        default: return .manager
        }
    }

    /// 融云时间戳 → 友好格式
    private static func formatRCTime(_ timestamp: Int64) -> String {
        guard timestamp > 0 else { return "" }
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
        let now = Date()
        let cal = Calendar.current

        if cal.isDateInToday(date) {
            let f = DateFormatter(); f.dateFormat = "HH:mm"
            return "今天 \(f.string(from: date))"
        } else if cal.isDateInYesterday(date) {
            let f = DateFormatter(); f.dateFormat = "HH:mm"
            return "昨天 \(f.string(from: date))"
        } else if cal.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let f = DateFormatter(); f.dateFormat = "EEE"
            return f.string(from: date)
        } else {
            let f = DateFormatter(); f.dateFormat = "MM/dd"
            return f.string(from: date)
        }
    }
}

// MARK: - Mock Data

extension Conversation {
    static func mockData() -> [Conversation] { [
        Conversation(id: "conv-ai-xd", role: .ai, roleLabel: "AI 健康顾问", name: "小德", title: "7×24h AI 健康顾问", avatar: "德", status: "AI 在线", serviceScope: "周报推送 · 目标提醒 · 健康问答", lastMessage: "主人，本周您的健康评分提升了 16 分！明天记得把晨跑数据同步过来。", lastTime: "今天 08:00", unread: 1, important: false),
        Conversation(id: "conv-team", role: .team, roleLabel: "三好共管服务群", name: "德好慢病逆转服务群", title: "医生 + 营养师 + 健管师协同服务", avatar: "群", status: "3 人在线", serviceScope: "血压血糖达标 · 饮食运动干预 · 随访协同", lastMessage: "王顾问已同步本周监测目标，张医生和陈营养师会在群内协同跟进。", lastTime: "今天 14:40", unread: 3, important: true),
        Conversation(id: "conv-001", role: .manager, roleLabel: "健管师 · 专属", name: "王顾问", title: "健康管理专家", avatar: "王", status: "在线", serviceScope: "慢病逆转 · 日常随访", lastMessage: "李阿姨，您的血压近 7 天平均 137/86，我已更新本周监测建议。", lastTime: "今天 14:32", unread: 2, important: true),
        Conversation(id: "conv-002", role: .doctor, roleLabel: "主任医师 · 内科", name: "张建国", title: "内科主任医师", avatar: "张", status: "今日可咨询", serviceScope: "用药建议 · 指标复核", lastMessage: "我看了您最近的血压和用药记录，降压药先不要自行调整。", lastTime: "今天 09:15", unread: 1, important: false),
        Conversation(id: "conv-003", role: .nutrition, roleLabel: "营养师", name: "陈梅", title: "国家注册营养师", avatar: "陈", status: "在线", serviceScope: "饮食方案 · 热量管理", lastMessage: "给您搭配了一份低钠 7 日早餐表，请查收。", lastTime: "昨天", unread: 0, important: false),
        Conversation(id: "conv-004", role: .service, roleLabel: "家庭服务台", name: "家庭服务台", title: "预约与履约支持", avatar: "家", status: "服务中", serviceScope: "预约确认 · 订单履约", lastMessage: "您预约的 5 月 28 日体检已确认，注意事项已发送。", lastTime: "周一", unread: 0, important: false),
        Conversation(id: "conv-005", role: .caseManager, roleLabel: "个案管理师 · 专项", name: "刘个管", title: "肿瘤与疑难病个案管理师", avatar: "刘", status: "专项跟进", serviceScope: "转诊协调 · MDT 跟进", lastMessage: "MDT 会诊资料已收齐，我会在今天下午同步排期结果。", lastTime: "今天 11:20", unread: 1, important: true),
        Conversation(id: "conv-006", role: .psychology, roleLabel: "心理咨询师", name: "林老师", title: "国家二级心理咨询师", avatar: "林", status: "在线", serviceScope: "情绪管理 · 睡眠认知行为", lastMessage: "上次教您的正念呼吸练习每天都坚持了吗？", lastTime: "昨天", unread: 0, important: false),
    ] }
}

extension AppNotification {
    static func mockData() -> [AppNotification] { [
        AppNotification(id: "n1", icon: "calendar.badge.clock", iconBg: "#EAF3FF", iconColor: "#3D6FB8", title: "体检预约已确认", tag: "预约提醒", body: "您预约的慈铭体检（中关村店）已确认，体检时间为 5 月 28 日 08:30，请携带身份证空腹前往。", time: "今天 06:30", unread: true),
        AppNotification(id: "n2", icon: "shield.checkered", iconBg: "#FFF3DC", iconColor: "#B47300", title: "您的保单将于 60 天后到期", tag: "保单", body: "富德一生安康重疾险将于 2026 年 8 月 25 日到期，点击查看续保方案与保障升级权益。", time: "昨天", unread: true),
        AppNotification(id: "n3", icon: "heart.text.square", iconBg: "#FFE9DF", iconColor: "#FF7A50", title: "血压数据已同步", tag: "设备", body: "今晨血压测量数据已自动同步至您的健康档案：收缩压 138 / 舒张压 88 mmHg，较昨日略有上升。", time: "今天 07:15", unread: false),
        AppNotification(id: "n4", icon: "doc.text.magnifyingglass", iconBg: "#E6F7EF", iconColor: "#1F9A6B", title: "本月健康报告已生成", tag: "报告", body: "2026 年 5 月个人健康月报已生成，健管师王顾问已添加批注建议，点击查看完整报告。", time: "昨天 18:00", unread: false),
    ] }
}
