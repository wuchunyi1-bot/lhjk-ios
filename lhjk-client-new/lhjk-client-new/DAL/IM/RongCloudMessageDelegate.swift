import Foundation
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
        return msg
    }

    /// objectName → MessageType 映射
    private static func mapObjectName(_ objectName: String?) -> MessageType {
        switch objectName {
        case "AD:FileMsg":   return .file
        case "AD:VideoMsg":  return .video
        case "AD:SysNotify": return .sysNotify
        default:             return .text
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
            } else {
                body = String(describing: content)
            }
        }

        print("[Chat][non-text] objectName=\(objectName) msgId=\(msgId) uid=\(uid) body=\(body)")
    }
}
