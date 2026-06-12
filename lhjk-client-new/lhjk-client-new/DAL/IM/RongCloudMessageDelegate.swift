import Foundation

// MARK: - 融云消息接收代理 (DAL)

/// 实现融云 RCIMClientReceiveMessageDelegate 协议
/// 负责接收融云 SDK 的消息回调，解析后分发给 BLL 层
final class RongCloudMessageDelegate: NSObject {

    // MARK: - Singleton

    static let shared = RongCloudMessageDelegate()

    // MARK: - Properties

    /// 消息接收回调闭包（BLL 层注入）
    var onMessageReceived: ((Message) -> Void)?
    /// 消息已读回执回调
    var onMessageReadReceipt: ((String, Date) -> Void)?

    // MARK: - Initialization

    private override init() {
        super.init()
        // TODO: RCIMClient.shared().receiveMessageDelegate = self
    }
}

// MARK: - 融云代理实现（伪代码，实际需继承 NSObject + 协议）

/*
extension RongCloudMessageDelegate: RCIMClientReceiveMessageDelegate {

    /// 收到消息回调
    func onReceived(_ message: RCMessage, left: Int32, object: Any?) {
        guard let localMessage = Message.fromRongCloud(rcMessage: message) else { return }
        RongCloudManager.shared.messageReceivedPublisher.send(localMessage)
        onMessageReceived?(localMessage)
    }

    /// 消息已读回执
    func onMessageReceiptResponse(_ conversationType: RCConversationType, targetId: String, messageUId: String, readerList: [RCReadReceiptInfo]) {
        onMessageReadReceipt?(targetId, Date())
    }
}
*/
