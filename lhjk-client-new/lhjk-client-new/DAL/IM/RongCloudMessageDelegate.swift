import Foundation
import UIKit
import RongIMLibCore

// MARK: - 融云消息接收代理 (DAL)

/// 实现融云 RCIMClientReceiveMessageDelegate 协议
/// 负责接收融云 SDK 的消息回调，解析后分发给 BLL 层
final class RongCloudMessageDelegate: NSObject {

    // MARK: - Singleton

    static let shared = RongCloudMessageDelegate()

    // MARK: - Properties

    /// 消息接收回调闭包（BLL 层注入）
    var onMessageReceived: ((RCMessage) -> Void)?

    // MARK: - Setup

    /// 注册为融云消息接收代理
    func register() {
        RCCoreClient.shared().addReceiveMessageDelegate(self)
        print("[RongCloud] Message delegate registered")
    }
}

// MARK: - RCIMClientReceiveMessageDelegate

extension RongCloudMessageDelegate: RCIMClientReceiveMessageDelegate {

    /// 收到消息回调
    func onReceived(_ message: RCMessage, left: Int32, object: Any?) {
        let objectName = message.objectName ?? "?"
        let uid = message.messageUId ?? "nil"
        let body = ChatMessage.rawContentJSON(from: message.content)
        print("[RongCloud][raw] objectName=\(objectName) uid=\(uid) msgId=\(message.messageId) left=\(left) body=\(body)")

        RongCloudManager.shared.messageReceivedPublisher.send(
            ChatMessage.fromRongCloud(rcMessage: message)
        )
        onMessageReceived?(message)
        print("[RongCloud] ← message received, type=\(objectName) left=\(left)")
    }
}

// MARK: - RCMessage → ChatMessage 转换

extension ChatMessage {
    /// 将融云 RCMessage 转换为 App 内部的 ChatMessage 模型
    static func fromRongCloud(rcMessage: RCMessage) -> ChatMessage {
        let role: MessageRole
        switch rcMessage.messageDirection {
        case .MessageDirection_SEND:
            role = .user
        case .MessageDirection_RECEIVE:
            role = .staff
        @unknown default:
            role = .staff
        }

        let content: String
        let type: MessageType
        let imagePath: String?
        let thumbWidth: Int?
        let thumbHeight: Int?

        if let recallContent = rcMessage.content as? RCRecallNotificationMessage {
            let operatorName = recallContent.senderUserInfo?.name ?? recallContent.operatorId
            content = "\(operatorName) 撤回了一条消息"
            type = .recall
            imagePath = nil
            thumbWidth = nil
            thumbHeight = nil
            Self.logNonTextMessageBody(rcMessage)
        } else if let textContent = rcMessage.content as? RCTextMessage {
            content = RongEmoji.symbolToEmoji(textContent.content ?? "")
            type = .text
            imagePath = nil
            thumbWidth = nil
            thumbHeight = nil
        } else if let imageContent = rcMessage.content as? RCImageMessage {
            content = "[图片]"
            type = .image
            imagePath = imageContent.imageUrl ?? imageContent.remoteUrl ?? imageContent.localPath
            thumbWidth = imageContent.thumWidth > 0 ? imageContent.thumWidth : nil
            thumbHeight = imageContent.thumHeight > 0 ? imageContent.thumHeight : nil
            Self.logNonTextMessageBody(rcMessage)
        } else if let voiceContent = rcMessage.content as? RCHQVoiceMessage {
            // 高清语音 RC:HQVCMsg
            content = "[语音]"
            type = .voice
            imagePath = voiceContent.localPath ?? voiceContent.remoteUrl
            thumbWidth = nil
            thumbHeight = Int(voiceContent.duration)
            Self.logNonTextMessageBody(rcMessage)
        } else {
            // 自定义消息类型：尝试 downcast 到具体子类，fallback 到 RCMessageContent 基类
            type = mapObjectName(rcMessage.objectName)
            imagePath = nil
            thumbWidth = nil
            thumbHeight = nil
            content = ""
            Self.logNonTextMessageBody(rcMessage)
        }

        let senderInfo = rcMessage.content?.senderUserInfo
        let senderName = senderInfo?.name
        let senderAvatar = senderName?.prefix(1).description
        let extra = rcMessage.content?.extra
        let reply = ReplyMessage.fromExtra(extra)
        let sentDate = Date(timeIntervalSince1970: TimeInterval(rcMessage.sentTime / 1000))
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm"

        // 自定义消息内容
        let fileContent = rcMessage.content as? FileMessage
        let videoContent = rcMessage.content as? VideoMessage
        let sysNotifyContent = rcMessage.content as? SysNotifyMessage
        let vipContent = rcMessage.content as? VipMessage
        let serviceCommentContent = rcMessage.content as? ServiceCommentMessage
        let checkUserContent = rcMessage.content as? CheckUserMessage

        print("[RongCloud] fromRongCloud senderUserInfo → name=\(senderName ?? "nil") portraitUri=\(senderInfo?.portraitUri ?? "nil") userId=\(senderInfo?.userId ?? "nil")")

        // 远端消息若本地未入库，messageId 为 -1，改用服务端 messageUId
        let msgId: String = {
            if rcMessage.messageId > 0 {
                return "\(rcMessage.messageId)"
            }
            if let uid = rcMessage.messageUId, !uid.isEmpty {
                return uid
            }
            return "rm-\(rcMessage.sentTime)"
        }()
        print("[RongCloud] fromRongCloud msgId → localId=\(rcMessage.messageId) resolved=\(msgId)")

        var msg = ChatMessage(
            id: msgId,
            type: type,
            role: role,
            senderName: senderName,
            senderRole: nil,
            avatar: senderAvatar,
            portraitUrl: senderInfo?.portraitUri,
            text: content,
            time: timeFmt.string(from: sentDate),
            sentTime: rcMessage.sentTime,
            card: nil,
            meal: nil,
            report: nil,
            imagePath: imagePath,
            thumbWidth: thumbWidth,
            thumbHeight: thumbHeight,
            conversationId: rcMessage.targetId,
            conversationTypeRaw: rcMessage.conversationType.rawValue,
            extra: extra,
            reply: reply,
            messageId: rcMessage.messageId
        )
        msg.fileContent = fileContent
        msg.videoContent = videoContent
        msg.sysNotifyContent = sysNotifyContent
        msg.vipContent = vipContent
        msg.serviceCommentContent = serviceCommentContent
        msg.checkUserContent = checkUserContent
        return msg
    }

    /// objectName → MessageType 映射
    private static func mapObjectName(_ objectName: String?) -> MessageType {
        switch objectName {
        case "AD:FileMsg":          return .file
        case "AD:VideoMsg":         return .video
        case "AD:SysNotify":        return .sysNotify
        case "AD:Vip":              return .vip
        case "AD:ServiceComment":   return .serviceComment
        case "AD:CheckUserMsg":     return .checkUserMsg
        default:                    return .text
        }
    }

    /// 融云 content 原始 JSON（decode 入参）；没有则回退 encode
    static func rawContentJSON(from content: RCMessageContent?) -> String {
        guard let content else { return "nil" }
        if let data = content.rawJSONData, !data.isEmpty,
           let text = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !text.isEmpty {
            return text
        }
        if let data = content.encode(),
           let text = String(data: data, encoding: .utf8),
           !text.isEmpty {
            return text
        }
        if let text = content as? RCTextMessage {
            return text.content ?? ""
        }
        return String(describing: content)
    }

    /// 调试：打印 IM 消息体，优先原始 JSON（含尚未接入的新字段）
    private static func logNonTextMessageBody(_ rcMessage: RCMessage) {
        let objectName = rcMessage.objectName ?? "nil"
        let msgId = rcMessage.messageId
        let uid = rcMessage.messageUId ?? "nil"
        let body = rawContentJSON(from: rcMessage.content)
        print("[Chat][non-text] objectName=\(objectName) msgId=\(msgId) uid=\(uid) body=\(body)")
    }
}

// MARK: - Variant

/// 协议卡片子类型
/// - AD:SysNotify：统一 `sysNotify`（按顶层 `messageType` 1/2/3 取字段）
/// - 其它 ObjectName：vip / serviceComment / checkUser
enum IMCardVariant: String {
    /// AD:SysNotify 统一卡（数据上传样式）
    case sysNotify = "sys-notify"
    case vip
    case serviceComment = "service-comment"
    case checkUser = "check-user"
}

// MARK: - Monitor row models（改造后 extra.rows）

enum IMMonitorRow {
    case text(label: String, value: String, colorHex: String?)
    case table(headers: [String], cells: [[String]])

    static func parseList(from extra: [String: Any]?) -> [IMMonitorRow] {
        guard let raw = extra?["rows"] as? [Any], !raw.isEmpty else { return [] }
        return raw.compactMap { item -> IMMonitorRow? in
            let dict: [String: Any]?
            if let d = item as? [String: Any] {
                dict = d
            } else if let d = item as? NSDictionary {
                var mapped: [String: Any] = [:]
                d.enumerateKeysAndObjects { key, value, _ in
                    if let k = key as? String { mapped[k] = value }
                }
                dict = mapped
            } else {
                dict = nil
            }
            guard let dict else { return nil }
            let kind = IMCardJSON.stringValue(dict["kind"]) ?? "text"
            if kind == "table" {
                let headers = (dict["headers"] as? [Any])?.compactMap { IMCardJSON.stringValue($0) } ?? []
                let cellsRaw = dict["cells"] as? [Any] ?? []
                let cells = parseTableCells(cellsRaw)
                guard !headers.isEmpty else { return nil }
                return .table(headers: headers, cells: cells)
            }
            let label = IMCardJSON.stringValue(dict["label"]) ?? ""
            let value = IMCardJSON.stringValue(dict["value"]) ?? ""
            guard !label.isEmpty || !value.isEmpty else { return nil }
            return .text(
                label: label,
                value: value,
                colorHex: IMCardJSON.stringValue(dict["color"])
            )
        }
    }

    /// 兼容 `cells` 标准 `[[String]]` 与多包一层 `[[[String]]]`（安卓部分消息会多嵌套）
    private static func parseTableCells(_ cellsRaw: [Any]) -> [[String]] {
        cellsRaw.flatMap { flattenTableRows($0) }
    }

    private static func flattenTableRows(_ item: Any) -> [[String]] {
        guard let arr = item as? [Any], !arr.isEmpty else { return [] }

        let isScalarRow = arr.allSatisfy { element in
            !(element is [Any]) && !(element is NSArray)
        }
        if isScalarRow {
            return [arr.map { IMCardJSON.stringValue($0) ?? "" }]
        }
        return arr.flatMap { flattenTableRows($0) }
    }
}

// MARK: - Tap action

enum IMCardTapAction {
    /// `FundeApp:` / `FundeH5:` 等 pageUrl
    case openPageUrl(String)
    case openRoute(String)
    case unavailable(String)
}

// MARK: - 实时提醒跳转

/// 对齐 funde-client `monitor-reminder-routes.ts` + 生产 `urlKey`（AngelDoctor://…）
enum IMMonitorReminderRoute {
    private static let typePaths: [String: String] = [
        "pressure": "/health/metrics/blood-pressure/add",
        "sugar": "/health/metrics/blood-sugar/add",
        "glucose": "/health/metrics/blood-sugar/add",
        "weight": "/health/metrics/weight/add",
        "temperature": "/health/metrics/temperature/add",
        "diet": "/health/metrics/exercise",
        "sport": "/health/metrics/exercise/add-motion",
        "exercise": "/health/metrics/exercise/add-motion",
    ]

    private static let titleKeywords: [(String, String)] = [
        ("血压", "/health/metrics/blood-pressure/add"),
        ("血糖", "/health/metrics/blood-sugar/add"),
        ("体重", "/health/metrics/weight/add"),
        ("体温", "/health/metrics/temperature/add"),
        ("饮食", "/health/metrics/exercise"),
        ("运动", "/health/metrics/exercise/add-motion"),
    ]

    static func entryPath(urlKey: String?, monitorType: String?, title: String?) -> String {
        let normalizedType = Self.normalizeMonitorType(monitorType)
        if let path = typePaths[normalizedType] {
            return path
        }

        let key = (urlKey ?? "").lowercased()
        if key.contains("tizhong") || key.contains("weight") {
            return "/health/metrics/weight/add"
        }
        if key.contains("xueya") || key.contains("pressure") {
            return "/health/metrics/blood-pressure/add"
        }
        if key.contains("xuetang") || key.contains("sugar") || key.contains("glucose") {
            return "/health/metrics/blood-sugar/add"
        }
        if key.contains("tiwen") || key.contains("temperature") || key.contains("temp") {
            return "/health/metrics/temperature/add"
        }
        if key.contains("yinshi") || key.contains("diet") {
            return "/health/metrics/exercise"
        }
        if key.contains("yundong") || key.contains("sport") || key.contains("exercise") {
            return "/health/metrics/exercise/add-motion"
        }

        if let title {
            for (keyword, path) in titleKeywords where title.contains(keyword) {
                return path
            }
        }
        return "/health/metrics"
    }

    static func normalizeMonitorType(_ raw: String?) -> String {
        let t = (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if t == "glucose" { return "sugar" }
        return t
    }

    static func isCompleted(extra: [String: Any]?) -> Bool {
        guard let extra else { return false }
        if let s = IMCardJSON.stringValue(extra["completed"]) {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return t == "1" || t == "true" || t == "yes"
        }
        if let n = extra["completed"] as? NSNumber {
            return n.intValue == 1
        }
        if let b = extra["completed"] as? Bool {
            return b
        }
        return false
    }
}

// MARK: - Resolved model

struct IMCardResolved {
    let variant: IMCardVariant
    let clickable: Bool
    let objectName: String
    let title: String
    let rawContent: String
    let imageUrl: String?
    let urlKey: String
    let skipTxt: String?
    /// 顶层 `messageType`：1 / 2 / 3；缺省按 1
    let protocolMessageType: Int?
    let businessData: [String: Any]?
    let extra: [String: Any]?
    let isShowUser: Bool
    let lastMsgDisplayContent: String?
    let monitorRows: [IMMonitorRow]
    let dataSourceTag: String?
    let monitorType: String?

    /// 1 / 2 / 3；其它值按 1
    var resolvedMessageType: Int {
        switch protocolMessageType {
        case 2: return 2
        case 3: return 3
        default: return 1
        }
    }

    var isUnifiedSysNotify: Bool {
        variant == .sysNotify && objectName == "AD:SysNotify"
    }

    var showsLeadingIcon: Bool {
        guard isUnifiedSysNotify else { return false }
        let url = imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !url.isEmpty
    }

    var showsBodyContent: Bool {
        guard isUnifiedSysNotify else { return false }
        return resolvedMessageType == 1 || resolvedMessageType == 3
    }

    var showsExtraRows: Bool {
        guard isUnifiedSysNotify else { return variant == .vip }
        return resolvedMessageType == 2 || resolvedMessageType == 3
    }

    var displayRows: [IMMonitorRow] {
        showsExtraRows && isUnifiedSysNotify ? monitorRows : []
    }

    /// 上传卡（type 2/3）展示 `extra.dataSourceTag`；空则隐藏
    var showsDataSourceTag: Bool {
        guard isUnifiedSysNotify, showsExtraRows else { return false }
        let tag = dataSourceTag?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !tag.isEmpty
    }

    var showsJumpButton: Bool {
        guard isUnifiedSysNotify else { return false }
        return !urlKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var jumpButtonTitle: String {
        let text = skipTxt?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? "去查看" : text
    }

    var monitorAccentHex: String {
        switch IMMonitorReminderRoute.normalizeMonitorType(monitorType) {
        case "pressure": return "#B47300"
        case "sugar": return "#E5564B"
        case "weight": return "#1F9A6B"
        case "temperature": return "#2DB983"
        case "diet": return "#3D6FB8"
        case "sport": return "#FF7A50"
        default: return "#1F9A6B"
        }
    }

    var monitorAccentColor: UIColor {
        UIColor(hexString: monitorAccentHex)
    }

    var isReminderCompleted: Bool {
        IMMonitorReminderRoute.isCompleted(extra: extra)
    }

    /// SysNotify 圆标用 imageUrl，不再用封面大图
    var showsCover: Bool {
        false
    }

    var bodyText: String {
        switch variant {
        case .sysNotify:
            guard showsBodyContent else { return "" }
            return rawContent
        case .vip:
            return rawContent
        case .serviceComment:
            return rawContent.isEmpty ? "请对本次服务进行评价" : rawContent
        case .checkUser:
            return rawContent.isEmpty ? "请核对以下信息" : rawContent
        }
    }

    /// VIP：按 `\n` + `：` 分行
    var contentRows: [(label: String, value: String)] {
        guard variant == .vip else { return [] }
        return rawContent
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { line in
                if let range = line.range(of: "：") {
                    return (String(line[..<range.lowerBound]), String(line[range.upperBound...]))
                }
                return ("", line)
            }
    }
}

// MARK: - Resolver

enum IMCardResolver {

    static func resolve(
        objectName: String,
        title: String?,
        content: String?,
        imageUrl: String?,
        urlKey: String?,
        businessDataRaw: Any?,
        extraRaw: Any?,
        isShowUser: Bool,
        lastMsgDisplayContent: String?,
        skipTxt: String? = nil,
        protocolMessageType: Int? = nil
    ) -> IMCardResolved {
        let urlKey = urlKey ?? ""
        let title = title ?? ""
        let content = content ?? ""
        let businessData = IMCardJSON.parseObject(businessDataRaw)
        let extra = IMCardJSON.parseObject(extraRaw)
        let monitorRows = IMMonitorRow.parseList(from: extra)
        let variant = resolveVariant(objectName: objectName)
        let tag = IMCardJSON.dataSourceTag(from: extra)

        return IMCardResolved(
            variant: variant,
            clickable: false,
            objectName: objectName,
            title: title.isEmpty && variant == .checkUser ? "核对信息消息" : title,
            rawContent: content,
            imageUrl: imageUrl,
            urlKey: urlKey,
            skipTxt: skipTxt,
            protocolMessageType: protocolMessageType,
            businessData: businessData,
            extra: extra,
            isShowUser: isShowUser,
            lastMsgDisplayContent: lastMsgDisplayContent,
            monitorRows: monitorRows,
            dataSourceTag: tag,
            monitorType: IMCardJSON.stringValue(extra?["monitorType"])
        )
    }

    static func resolve(from message: ChatMessage) -> IMCardResolved? {
        if let n = message.sysNotifyContent {
            // content.extra 优先；若空则回退 ChatMessage.extra（同为 RCMessageContent.extra 拷贝）
            let extraRaw: Any? = {
                if let e = n.extra, !e.isEmpty { return e }
                return message.extra
            }()
            return resolve(
                objectName: SysNotifyMessage.getObjectName(),
                title: n.title,
                content: n.content,
                imageUrl: n.imageUrl,
                urlKey: n.urlKey,
                businessDataRaw: n.businessData,
                extraRaw: extraRaw,
                isShowUser: n.isShowUser,
                lastMsgDisplayContent: n.lastMsgDisplayContent,
                skipTxt: n.skipTxt,
                protocolMessageType: n.messageType
            )
        }
        if let n = message.vipContent {
            return resolve(
                objectName: VipMessage.getObjectName(),
                title: n.title,
                content: n.content,
                imageUrl: n.imageUrl,
                urlKey: n.urlKey,
                businessDataRaw: n.businessData,
                extraRaw: n.extra,
                isShowUser: n.isShowUser,
                lastMsgDisplayContent: n.lastMsgDisplayContent
            )
        }
        if let n = message.serviceCommentContent {
            return resolve(
                objectName: ServiceCommentMessage.getObjectName(),
                title: n.title,
                content: n.content,
                imageUrl: n.imageUrl,
                urlKey: n.urlKey,
                businessDataRaw: n.businessData,
                extraRaw: n.extra,
                isShowUser: n.isShowUser,
                lastMsgDisplayContent: n.lastMsgDisplayContent
            )
        }
        if let n = message.checkUserContent {
            return resolve(
                objectName: CheckUserMessage.getObjectName(),
                title: n.title,
                content: n.content,
                imageUrl: n.imageUrl,
                urlKey: n.urlKey,
                businessDataRaw: n.businessData,
                extraRaw: n.extra,
                isShowUser: n.isShowUser,
                lastMsgDisplayContent: n.lastMsgDisplayContent
            )
        }
        return nil
    }

    /// AD:SysNotify 统一为 `sysNotify`；其它 ObjectName 各自 variant。不再按 extra.type / rows 拆三态。
    static func resolveVariant(objectName: String) -> IMCardVariant {
        if objectName == "AD:ServiceComment" { return .serviceComment }
        if objectName == "AD:CheckUserMsg" { return .checkUser }
        if objectName == "AD:Vip" { return .vip }
        return .sysNotify
    }

    static func tapAction(for card: IMCardResolved) -> IMCardTapAction? {
        guard card.showsJumpButton else { return nil }
        return .openPageUrl(card.urlKey)
    }
}

