import Foundation
import RongIMLibCore

/// AD:FileMsg — 文件 / 音频 / 团队知识 消息
///
/// Web 端三种场景复用此类型：
/// - 文件：fileSuffix = pdf/doc/xlsx 等
/// - 音频：fileSuffix = "mp3"，fileTime = 时长
/// - 团队知识：fileSuffix = "richText"，imageUrl = 封面
@objcMembers
final class FileMessage: RCMessageContent {

    // MARK: - Custom Fields

    var fileUrl: String?
    var fileName: String?
    var fileSize: String?
    var fileSuffix: String?
    /// 音频时长（秒），仅音频类型使用
    var fileTime: Int = 0
    /// 团队知识封面图，仅团队知识类型使用
    var imageUrl: String?
    /// 会话列表摘要展示
    var lastMsgDisplayContent: String?

    // MARK: - RCMessageCoding

    override class func getObjectName() -> String {
        "AD:FileMsg"
    }

    override class func persistentFlag() -> RCMessagePersistent {
        RCMessagePersistent(rawValue: 3)! // MessagePersistent_ISCOUNTED
    }

    override func encode() -> Data? {
        let dataDict = encodeBaseData()
        dataDict["fileUrl"] = fileUrl
        dataDict["fileName"] = fileName
        dataDict["fileSize"] = fileSize
        dataDict["fileSuffix"] = fileSuffix
        dataDict["fileTime"] = fileTime
        dataDict["imageUrl"] = imageUrl
        dataDict["lastMsgDisplayContent"] = lastMsgDisplayContent
        return try? JSONSerialization.data(withJSONObject: dataDict)
    }

    override func decode(with data: Data) {
        guard let json = Self.dictionary(fromJsonData: data) as? [String: Any] else {
            self.rawJSONData = data
            return
        }
        decodeBaseData(json)
        fileUrl = json["fileUrl"] as? String
        fileName = json["fileName"] as? String
        fileSize = json["fileSize"] as? String
        fileSuffix = json["fileSuffix"] as? String
        fileTime = json["fileTime"] as? Int ?? 0
        imageUrl = json["imageUrl"] as? String
        lastMsgDisplayContent = json["lastMsgDisplayContent"] as? String
    }

    override func conversationDigest() -> String? {
        lastMsgDisplayContent ?? "[文件]"
    }
}
