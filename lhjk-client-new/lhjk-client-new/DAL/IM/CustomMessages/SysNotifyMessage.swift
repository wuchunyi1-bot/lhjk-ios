import Foundation
import RongIMLibCore

/// AD:SysNotify — 系统通知 / 套餐消息
@objcMembers
final class SysNotifyMessage: RCMessageContent {

    // MARK: - Custom Fields

    /// 套餐业务数据 JSON string
    var businessData: String?
    /// 套餐名称
    var title: String?
    /// 套餐描述
    var content: String?
    /// 是否展示发送者信息
    var isShowUser: Bool = true
    /// 套餐图片 URL
    var imageUrl: String?
    /// 跳转标识，固定 "SET_MEAL"
    var urlKey: String?
    /// 会话列表摘要展示
    var lastMsgDisplayContent: String?

    // MARK: - RCMessageCoding

    override class func getObjectName() -> String {
        "AD:SysNotify"
    }

    override class func persistentFlag() -> RCMessagePersistent {
        RCMessagePersistent(rawValue: 3)! // MessagePersistent_ISCOUNTED
    }

    override func encode() -> Data? {
        let dataDict = encodeBaseData()
        dataDict["businessData"] = businessData
        dataDict["title"] = title
        dataDict["content"] = content
        dataDict["isShowUser"] = isShowUser
        dataDict["imageUrl"] = imageUrl
        dataDict["urlKey"] = urlKey
        dataDict["lastMsgDisplayContent"] = lastMsgDisplayContent
        return try? JSONSerialization.data(withJSONObject: dataDict)
    }

    override func decode(with data: Data) {
        guard let json = Self.dictionary(fromJsonData: data) as? [String: Any] else {
            self.rawJSONData = data
            return
        }
        decodeBaseData(json)
        businessData = json["businessData"] as? String
        title = json["title"] as? String
        content = json["content"] as? String
        isShowUser = json["isShowUser"] as? Bool ?? true
        imageUrl = json["imageUrl"] as? String
        urlKey = json["urlKey"] as? String
        lastMsgDisplayContent = json["lastMsgDisplayContent"] as? String
    }

    override func conversationDigest() -> String? {
        lastMsgDisplayContent ?? "[套餐]"
    }
}
