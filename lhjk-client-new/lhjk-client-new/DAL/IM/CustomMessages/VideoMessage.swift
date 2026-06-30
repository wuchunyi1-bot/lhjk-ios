import Foundation
import RongIMLibCore

/// AD:VideoMsg — 视频消息
@objcMembers
final class VideoMessage: RCMessageContent {

    // MARK: - Custom Fields

    var videoUrl: String?
    /// 视频封面图 URL
    var videoCoverImg: String?
    var videoName: String?
    /// 视频时长（秒）
    var videoTime: Int = 0
    /// 视频后缀，固定 "mp4"
    var videoSuffix: String?
    /// 会话列表摘要展示
    var lastMsgDisplayContent: String?

    // MARK: - RCMessageCoding

    override class func getObjectName() -> String {
        "AD:VideoMsg"
    }

    override class func persistentFlag() -> RCMessagePersistent {
        RCMessagePersistent(rawValue: 3)! // MessagePersistent_ISCOUNTED
    }

    override func encode() -> Data? {
        let dataDict = encodeBaseData()
        dataDict["videoUrl"] = videoUrl
        dataDict["videoCoverImg"] = videoCoverImg
        dataDict["videoName"] = videoName
        dataDict["videoTime"] = videoTime
        dataDict["videoSuffix"] = videoSuffix
        dataDict["lastMsgDisplayContent"] = lastMsgDisplayContent
        return try? JSONSerialization.data(withJSONObject: dataDict)
    }

    override func decode(with data: Data) {
        guard let json = Self.dictionary(fromJsonData: data) as? [String: Any] else {
            self.rawJSONData = data
            return
        }
        decodeBaseData(json)
        videoUrl = json["videoUrl"] as? String
        videoCoverImg = json["videoCoverImg"] as? String
        videoName = json["videoName"] as? String
        videoTime = json["videoTime"] as? Int ?? 0
        videoSuffix = json["videoSuffix"] as? String
        lastMsgDisplayContent = json["lastMsgDisplayContent"] as? String
    }

    override func conversationDigest() -> String? {
        lastMsgDisplayContent ?? "[视频]"
    }
}
