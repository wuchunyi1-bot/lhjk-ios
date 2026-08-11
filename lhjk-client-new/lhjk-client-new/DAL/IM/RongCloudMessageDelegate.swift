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
        RongCloudManager.shared.messageReceivedPublisher.send(
            ChatMessage.fromRongCloud(rcMessage: message)
        )
        onMessageReceived?(message)
        print("[RongCloud] ← message received, type=\(message.objectName ?? "?") left=\(left)")
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
            content = textContent.content
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

    /// 调试：打印非文本 IM 消息体（encode JSON / 已知字段）
    private static func logNonTextMessageBody(_ rcMessage: RCMessage) {
        let objectName = rcMessage.objectName ?? "nil"
        let msgId = rcMessage.messageId
        let uid = rcMessage.messageUId ?? "nil"

        var body = "nil"
        if let content = rcMessage.content {
            if let data = content.encode(),
               let json = String(data: data, encoding: .utf8), !json.isEmpty {
                body = json
            } else if let image = content as? RCImageMessage {
                body = "{"
                    + "\"imageUrl\":\"\(image.imageUrl ?? "")\","
                    + "\"remoteUrl\":\"\(image.remoteUrl ?? "")\","
                    + "\"localPath\":\"\(image.localPath ?? "")\","
                    + "\"thumb\":\(image.thumWidth)x\(image.thumHeight),"
                    + "\"extra\":\"\(image.extra ?? "")\""
                    + "}"
            } else if let voice = content as? RCHQVoiceMessage {
                body = "{"
                    + "\"localPath\":\"\(voice.localPath ?? "")\","
                    + "\"remoteUrl\":\"\(voice.remoteUrl ?? "")\","
                    + "\"duration\":\(voice.duration),"
                    + "\"extra\":\"\(voice.extra ?? "")\""
                    + "}"
            } else if let file = content as? FileMessage {
                body = "{"
                    + "\"fileUrl\":\"\(file.fileUrl ?? "")\","
                    + "\"fileName\":\"\(file.fileName ?? "")\","
                    + "\"fileSize\":\"\(file.fileSize ?? "")\","
                    + "\"fileSuffix\":\"\(file.fileSuffix ?? "")\","
                    + "\"fileTime\":\(file.fileTime),"
                    + "\"imageUrl\":\"\(file.imageUrl ?? "")\","
                    + "\"lastMsgDisplayContent\":\"\(file.lastMsgDisplayContent ?? "")\","
                    + "\"extra\":\"\(file.extra ?? "")\""
                    + "}"
            } else if let video = content as? VideoMessage {
                body = "{"
                    + "\"videoUrl\":\"\(video.videoUrl ?? "")\","
                    + "\"videoCoverImg\":\"\(video.videoCoverImg ?? "")\","
                    + "\"videoName\":\"\(video.videoName ?? "")\","
                    + "\"videoTime\":\(video.videoTime),"
                    + "\"videoSuffix\":\"\(video.videoSuffix ?? "")\","
                    + "\"lastMsgDisplayContent\":\"\(video.lastMsgDisplayContent ?? "")\","
                    + "\"extra\":\"\(video.extra ?? "")\""
                    + "}"
            } else if let notify = content as? SysNotifyMessage {
                body = "{"
                    + "\"title\":\"\(notify.title ?? "")\","
                    + "\"content\":\"\(notify.content ?? "")\","
                    + "\"businessData\":\"\(notify.businessData ?? "")\","
                    + "\"imageUrl\":\"\(notify.imageUrl ?? "")\","
                    + "\"urlKey\":\"\(notify.urlKey ?? "")\","
                    + "\"isShowUser\":\(notify.isShowUser),"
                    + "\"lastMsgDisplayContent\":\"\(notify.lastMsgDisplayContent ?? "")\","
                    + "\"extra\":\"\(notify.extra ?? "")\""
                    + "}"
            } else if let vip = content as? VipMessage {
                body = "{"
                    + "\"objectName\":\"AD:Vip\","
                    + "\"title\":\"\(vip.title ?? "")\","
                    + "\"content\":\"\(vip.content ?? "")\","
                    + "\"urlKey\":\"\(vip.urlKey ?? "")\","
                    + "\"extra\":\"\(vip.extra ?? "")\""
                    + "}"
            } else if let comment = content as? ServiceCommentMessage {
                body = "{"
                    + "\"objectName\":\"AD:ServiceComment\","
                    + "\"title\":\"\(comment.title ?? "")\","
                    + "\"content\":\"\(comment.content ?? "")\","
                    + "\"extra\":\"\(comment.extra ?? "")\""
                    + "}"
            } else if let check = content as? CheckUserMessage {
                body = "{"
                    + "\"objectName\":\"AD:CheckUserMsg\","
                    + "\"title\":\"\(check.title ?? "")\","
                    + "\"content\":\"\(check.content ?? "")\","
                    + "\"extra\":\"\(check.extra ?? "")\""
                    + "}"
            } else {
                body = String(describing: content)
            }
        }

        print("[Chat][non-text] objectName=\(objectName) msgId=\(msgId) uid=\(uid) body=\(body)")
    }
}

// MARK: - Variant

/// 协议卡片子类型
/// - AD:SysNotify：仅 `monitor`（新 rows 卡）或 `sysNotify`（旧 C-sys）
/// - 其它 ObjectName：vip / serviceComment / checkUser
enum IMCardVariant: String {
    /// 监测上传新卡：`extra.rows` 非空，正文不读 `content`
    case monitor
    /// 旧版通用通知（C-sys）：无 rows；读 title + content
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
                let cells: [[String]] = cellsRaw.compactMap { row in
                    guard let arr = row as? [Any] else { return nil }
                    return arr.map { IMCardJSON.stringValue($0) ?? "" }
                }
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
}

// MARK: - Tap action（非 SysNotify 监测卡；套餐等已从 SysNotify 移除）

enum IMCardTapAction {
    case unavailable(String)
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
    let businessData: [String: Any]?
    let extra: [String: Any]?
    let isShowUser: Bool
    let lastMsgDisplayContent: String?
    /// 改造后监测卡行；仅 `monitor`
    let monitorRows: [IMMonitorRow]
    /// `extra.dataSourceTag`，如「手动记录」
    let dataSourceTag: String?
    /// `extra.monitorType`：pressure/sugar/weight/temperature/diet/sport
    let monitorType: String?

    /// 监测卡圆形图标主题色：仅按 `monitorType`（对齐 funde-client iconMeta）
    /// 结果行 `color` 只用于结果胶囊，不反哺图标
    var monitorAccentHex: String {
        switch monitorType {
        case "pressure": return "#B47300"
        case "sugar": return "#E5564B"
        case "weight": return "#1F9A6B"
        case "temperature": return "#2DB983"
        case "diet": return "#3D6FB8"
        case "sport": return "#FF7A50"
        default: return "#FF7A50"
        }
    }

    var monitorAccentColor: UIColor {
        UIColor(hexString: monitorAccentHex)
    }

    /// 左图：仅旧 C-sys 在有 imageUrl 时展示；监测新卡 / VIP / 评价 / 核对无封面
    var showsCover: Bool {
        switch variant {
        case .sysNotify:
            return !(imageUrl?.isEmpty ?? true)
        case .monitor, .serviceComment, .checkUser, .vip:
            return false
        }
    }

    var bodyText: String {
        switch variant {
        case .monitor:
            return "" // 正文来自 rows，不读 content
        case .sysNotify:
            return Self.appendStatus(to: rawContent, extra: extra)
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

    private static func appendStatus(to content: String, extra: [String: Any]?) -> String {
        // 旧格式：extra 有 date/status 无 rows 时，status 拼到 content
        guard IMMonitorRow.parseList(from: extra).isEmpty,
              let status = extra?["status"] as? [String: Any],
              let statusText = IMCardJSON.stringValue(status["content"]),
              !statusText.isEmpty else { return content }
        if content.isEmpty { return statusText }
        if content.contains(statusText) { return content }
        return "\(content) \(statusText)"
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
        lastMsgDisplayContent: String?
    ) -> IMCardResolved {
        let urlKey = urlKey ?? ""
        let title = title ?? ""
        let content = content ?? ""
        let businessData = IMCardJSON.parseObject(businessDataRaw)
        let extra = IMCardJSON.parseObject(extraRaw)
        let monitorRows = IMMonitorRow.parseList(from: extra)

        let variant = resolveVariant(
            objectName: objectName,
            monitorRows: monitorRows
        )

        return IMCardResolved(
            variant: variant,
            clickable: false,
            objectName: objectName,
            title: title.isEmpty && variant == .checkUser ? "核对信息消息" : title,
            rawContent: content,
            imageUrl: imageUrl,
            urlKey: urlKey,
            businessData: businessData,
            extra: extra,
            isShowUser: isShowUser,
            lastMsgDisplayContent: lastMsgDisplayContent,
            monitorRows: monitorRows,
            dataSourceTag: IMCardJSON.dataSourceTag(from: extra),
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
            let resolved = resolve(
                objectName: SysNotifyMessage.getObjectName(),
                title: n.title,
                content: n.content,
                imageUrl: n.imageUrl,
                urlKey: n.urlKey,
                businessDataRaw: n.businessData,
                extraRaw: extraRaw,
                isShowUser: n.isShowUser,
                lastMsgDisplayContent: n.lastMsgDisplayContent
            )
            if resolved.variant == .monitor {
                let rawPreview: String = {
                    if let s = extraRaw as? String { return String(s.prefix(180)) }
                    return String(String(describing: extraRaw).prefix(180))
                }()
                print("[IM-Card] resolve tag=\(resolved.dataSourceTag ?? "nil") rawExtra=\(rawPreview)")
            }
            return resolved
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

    /// AD:SysNotify：`extra.rows` 非空 → monitor；否则旧 C-sys。不再按 urlKey 拆 meal/detection 等。
    static func resolveVariant(objectName: String, monitorRows: [IMMonitorRow]) -> IMCardVariant {
        if objectName == "AD:ServiceComment" { return .serviceComment }
        if objectName == "AD:CheckUserMsg" { return .checkUser }
        if objectName == "AD:Vip" { return .vip }
        if objectName == "AD:SysNotify" {
            return monitorRows.isEmpty ? .sysNotify : .monitor
        }
        return .sysNotify
    }

    static func tapAction(for card: IMCardResolved) -> IMCardTapAction? {
        guard card.clickable else { return nil }
        return nil
    }
}

