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

        if let textContent = rcMessage.content as? RCTextMessage {
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
            print("[RongCloud] fromRongCloud image → imageUrl=\(imageContent.imageUrl ?? "nil") remoteUrl=\(imageContent.remoteUrl ?? "nil") localPath=\(imageContent.localPath ?? "nil") thumbSize=\(thumbWidth ?? 0)x\(thumbHeight ?? 0)")
        } else {
            content = ""
            type = .text
            imagePath = nil
            thumbWidth = nil
            thumbHeight = nil
            print("[RongCloud] fromRongCloud unknown type objectName=\(rcMessage.objectName ?? "nil")")
        }

        let sentDate = Date(timeIntervalSince1970: TimeInterval(rcMessage.sentTime / 1000))
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm"

        return ChatMessage(
            id: "\(rcMessage.messageId)",
            type: type,
            role: role,
            senderName: nil,
            senderRole: nil,
            avatar: nil,
            text: content,
            time: timeFmt.string(from: sentDate),
            card: nil,
            meal: nil,
            report: nil,
            imagePath: imagePath,
            thumbWidth: thumbWidth,
            thumbHeight: thumbHeight,
            conversationId: rcMessage.targetId
        )
    }
}
