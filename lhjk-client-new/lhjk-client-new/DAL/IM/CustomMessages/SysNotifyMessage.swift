import Foundation
import RongIMLibCore

// MARK: - JSON helpers（businessData / extra 对象与字符串双兼容）

enum IMCardJSON {

    static func parseObject(_ raw: Any?) -> [String: Any]? {
        guard let raw else { return nil }
        if let dict = raw as? [String: Any] { return dict }
        if let dict = raw as? NSDictionary {
            var result: [String: Any] = [:]
            dict.enumerateKeysAndObjects { key, value, _ in
                if let k = key as? String { result[k] = value }
            }
            return result.isEmpty ? nil : result
        }
        if let s = raw as? String {
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty,
                  let data = trimmed.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data) else { return nil }
            return parseObject(obj)
        }
        if let data = raw as? Data {
            guard let obj = try? JSONSerialization.jsonObject(with: data) else { return nil }
            return parseObject(obj)
        }
        return nil
    }

    static func stringify(_ raw: Any?) -> String? {
        guard let raw else { return nil }
        if let s = raw as? String { return s }
        if let s = raw as? NSString { return s as String }
        guard JSONSerialization.isValidJSONObject(raw),
              let data = try? JSONSerialization.data(withJSONObject: raw),
              let s = String(data: data, encoding: .utf8) else { return nil }
        return s
    }

    static func stringValue(_ raw: Any?) -> String? {
        if let s = raw as? String { return s }
        if let s = raw as? NSString { return s as String }
        if let n = raw as? NSNumber { return n.stringValue }
        if let b = raw as? Bool { return b ? "true" : "false" }
        return nil
    }

    static func boolValue(_ raw: Any?, default defaultValue: Bool) -> Bool {
        if let b = raw as? Bool { return b }
        if let n = raw as? NSNumber { return n.boolValue }
        if let s = raw as? String {
            let lower = s.lowercased()
            if ["1", "true", "yes"].contains(lower) { return true }
            if ["0", "false", "no"].contains(lower) { return false }
        }
        return defaultValue
    }

    /// 协议卡顶层 `messageType`：兼容 Int / NSNumber / 数字字符串
    static func intValue(_ raw: Any?) -> Int? {
        if let i = raw as? Int { return i }
        if let i = raw as? Int64 { return Int(i) }
        if let n = raw as? NSNumber { return n.intValue }
        if let s = raw as? String {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if let i = Int(t) { return i }
        }
        return nil
    }

    /// 监测卡来源 tag：兼容 dataSourceTag / sourceLabel
    static func dataSourceTag(from extra: [String: Any]?) -> String? {
        guard let extra else { return nil }
        let raw = stringValue(extra["dataSourceTag"])
            ?? stringValue(extra["sourceLabel"])
            ?? stringValue(extra["dataSource"])
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed?.isEmpty == false) ? trimmed : nil
    }
}

// MARK: - Shared encode / decode

enum IMCardMessageCoding {

    static func encodeFields(
        businessData: String?,
        title: String?,
        content: String?,
        isShowUser: Bool,
        imageUrl: String?,
        urlKey: String?,
        lastMsgDisplayContent: String?,
        extra: String?,
        messageType: Int?,
        into dataDict: NSMutableDictionary
    ) {
        dataDict["businessData"] = businessData
        dataDict["title"] = title
        dataDict["content"] = content
        dataDict["isShowUser"] = isShowUser
        dataDict["imageUrl"] = imageUrl
        dataDict["urlKey"] = urlKey
        dataDict["lastMsgDisplayContent"] = lastMsgDisplayContent
        // 协议卡 extra 必须写入 content JSON；不能只依赖基类属性，否则本地回读可能丢 rows/tag
        if let extra, !extra.isEmpty {
            dataDict["extra"] = extra
        }
        if let messageType {
            dataDict["messageType"] = messageType
        }
    }

    static func decodeFields(
        from json: [String: Any],
        into message: RCMessageContent,
        setBusinessData: (String?) -> Void,
        setTitle: (String?) -> Void,
        setContent: (String?) -> Void,
        setIsShowUser: (Bool) -> Void,
        setImageUrl: (String?) -> Void,
        setUrlKey: (String?) -> Void,
        setLastMsgDisplayContent: (String?) -> Void,
        setMessageType: (Int?) -> Void
    ) {
        message.decodeBaseData(json)
        setBusinessData(IMCardJSON.stringify(json["businessData"]))
        setTitle(IMCardJSON.stringValue(json["title"]))
        setContent(IMCardJSON.stringValue(json["content"]))
        setIsShowUser(IMCardJSON.boolValue(json["isShowUser"], default: true))
        setImageUrl(IMCardJSON.stringValue(json["imageUrl"]))
        setUrlKey(IMCardJSON.stringValue(json["urlKey"]))
        setLastMsgDisplayContent(IMCardJSON.stringValue(json["lastMsgDisplayContent"]))
        setMessageType(IMCardJSON.intValue(json["messageType"]))
        // 显式写回协议 extra（对象/字符串双兼容）；覆盖基类可能的截断/丢失
        if let extraString = IMCardJSON.stringify(json["extra"]), !extraString.isEmpty {
            message.extra = extraString
        }
        applySenderUserInfo(from: json, into: message)
    }

    static func applySenderUserInfo(from json: [String: Any], into message: RCMessageContent) {
        // 安卓侧 user 常为 JSON 字符串；iOS encodeBaseData 则为对象
        guard let user = IMCardJSON.parseObject(json["user"]) else { return }
        let info = RCUserInfo()
        info.userId = IMCardJSON.stringValue(user["id"]) ?? ""
        info.name = IMCardJSON.stringValue(user["name"]) ?? ""
        info.portraitUri = IMCardJSON.stringValue(user["portraitUri"])
            ?? IMCardJSON.stringValue(user["portrait"])
            ?? IMCardJSON.stringValue(user["icon"])
        message.senderUserInfo = info
    }
}

// MARK: - AD:SysNotify

/// AD:SysNotify — 系统通知 / 套餐消息
@objcMembers
final class SysNotifyMessage: RCMessageContent {

    var businessData: String?
    var title: String?
    var content: String?
    var isShowUser: Bool = true
    var imageUrl: String?
    var urlKey: String?
    var lastMsgDisplayContent: String?
    /// 协议卡顶层类型（安卓 `messageType`，如监测上传为 2）；与 `extra.type` 不是同一字段
    var messageType: Int?

    override class func getObjectName() -> String { "AD:SysNotify" }

    override class func persistentFlag() -> RCMessagePersistent {
        RCMessagePersistent(rawValue: 3)!
    }

    override func encode() -> Data? {
        let dataDict = encodeBaseData()
        IMCardMessageCoding.encodeFields(
            businessData: businessData, title: title, content: content,
            isShowUser: isShowUser, imageUrl: imageUrl, urlKey: urlKey,
            lastMsgDisplayContent: lastMsgDisplayContent, extra: extra,
            messageType: messageType, into: dataDict
        )
        return try? JSONSerialization.data(withJSONObject: dataDict)
    }

    override func decode(with data: Data) {
        self.rawJSONData = data
        guard let json = Self.dictionary(fromJsonData: data) as? [String: Any] else {
            return
        }
        IMCardMessageCoding.decodeFields(
            from: json, into: self,
            setBusinessData: { self.businessData = $0 },
            setTitle: { self.title = $0 },
            setContent: { self.content = $0 },
            setIsShowUser: { self.isShowUser = $0 },
            setImageUrl: { self.imageUrl = $0 },
            setUrlKey: { self.urlKey = $0 },
            setLastMsgDisplayContent: { self.lastMsgDisplayContent = $0 },
            setMessageType: { self.messageType = $0 }
        )
    }

    override func conversationDigest() -> String? {
        lastMsgDisplayContent ?? "[套餐]"
    }
}

// MARK: - AD:Vip

/// AD:Vip — VIP / 产检安排类卡片
@objcMembers
final class VipMessage: RCMessageContent {

    var businessData: String?
    var title: String?
    var content: String?
    var isShowUser: Bool = true
    var imageUrl: String?
    var urlKey: String?
    var lastMsgDisplayContent: String?
    /// 协议卡顶层类型（安卓 `messageType`，如监测上传为 2）；与 `extra.type` 不是同一字段
    var messageType: Int?

    override class func getObjectName() -> String { "AD:Vip" }

    override class func persistentFlag() -> RCMessagePersistent {
        RCMessagePersistent(rawValue: 3)!
    }

    override func encode() -> Data? {
        let dataDict = encodeBaseData()
        IMCardMessageCoding.encodeFields(
            businessData: businessData, title: title, content: content,
            isShowUser: isShowUser, imageUrl: imageUrl, urlKey: urlKey,
            lastMsgDisplayContent: lastMsgDisplayContent, extra: extra,
            messageType: messageType, into: dataDict
        )
        return try? JSONSerialization.data(withJSONObject: dataDict)
    }

    override func decode(with data: Data) {
        self.rawJSONData = data
        guard let json = Self.dictionary(fromJsonData: data) as? [String: Any] else {
            return
        }
        IMCardMessageCoding.decodeFields(
            from: json, into: self,
            setBusinessData: { self.businessData = $0 },
            setTitle: { self.title = $0 },
            setContent: { self.content = $0 },
            setIsShowUser: { self.isShowUser = $0 },
            setImageUrl: { self.imageUrl = $0 },
            setUrlKey: { self.urlKey = $0 },
            setLastMsgDisplayContent: { self.lastMsgDisplayContent = $0 },
            setMessageType: { self.messageType = $0 }
        )
    }

    override func conversationDigest() -> String? {
        lastMsgDisplayContent ?? title ?? "[VIP]"
    }
}

// MARK: - AD:ServiceComment

/// AD:ServiceComment — 服务评价卡片（IM 侧只读）
@objcMembers
final class ServiceCommentMessage: RCMessageContent {

    var businessData: String?
    var title: String?
    var content: String?
    var isShowUser: Bool = true
    var imageUrl: String?
    var urlKey: String?
    var lastMsgDisplayContent: String?
    /// 协议卡顶层类型（安卓 `messageType`，如监测上传为 2）；与 `extra.type` 不是同一字段
    var messageType: Int?

    override class func getObjectName() -> String { "AD:ServiceComment" }

    override class func persistentFlag() -> RCMessagePersistent {
        RCMessagePersistent(rawValue: 3)!
    }

    override func encode() -> Data? {
        let dataDict = encodeBaseData()
        IMCardMessageCoding.encodeFields(
            businessData: businessData, title: title, content: content,
            isShowUser: isShowUser, imageUrl: imageUrl, urlKey: urlKey,
            lastMsgDisplayContent: lastMsgDisplayContent, extra: extra,
            messageType: messageType, into: dataDict
        )
        return try? JSONSerialization.data(withJSONObject: dataDict)
    }

    override func decode(with data: Data) {
        self.rawJSONData = data
        guard let json = Self.dictionary(fromJsonData: data) as? [String: Any] else {
            return
        }
        IMCardMessageCoding.decodeFields(
            from: json, into: self,
            setBusinessData: { self.businessData = $0 },
            setTitle: { self.title = $0 },
            setContent: { self.content = $0 },
            setIsShowUser: { self.isShowUser = $0 },
            setImageUrl: { self.imageUrl = $0 },
            setUrlKey: { self.urlKey = $0 },
            setLastMsgDisplayContent: { self.lastMsgDisplayContent = $0 },
            setMessageType: { self.messageType = $0 }
        )
    }

    override func conversationDigest() -> String? {
        lastMsgDisplayContent ?? "[服务评价]"
    }
}

// MARK: - AD:CheckUserMsg

/// AD:CheckUserMsg — 信息核对卡片（IM 侧只读）
@objcMembers
final class CheckUserMessage: RCMessageContent {

    var businessData: String?
    var title: String?
    var content: String?
    var isShowUser: Bool = true
    var imageUrl: String?
    var urlKey: String?
    var lastMsgDisplayContent: String?
    /// 协议卡顶层类型（安卓 `messageType`，如监测上传为 2）；与 `extra.type` 不是同一字段
    var messageType: Int?

    override class func getObjectName() -> String { "AD:CheckUserMsg" }

    override class func persistentFlag() -> RCMessagePersistent {
        RCMessagePersistent(rawValue: 3)!
    }

    override func encode() -> Data? {
        let dataDict = encodeBaseData()
        IMCardMessageCoding.encodeFields(
            businessData: businessData, title: title, content: content,
            isShowUser: isShowUser, imageUrl: imageUrl, urlKey: urlKey,
            lastMsgDisplayContent: lastMsgDisplayContent, extra: extra,
            messageType: messageType, into: dataDict
        )
        return try? JSONSerialization.data(withJSONObject: dataDict)
    }

    override func decode(with data: Data) {
        self.rawJSONData = data
        guard let json = Self.dictionary(fromJsonData: data) as? [String: Any] else {
            return
        }
        IMCardMessageCoding.decodeFields(
            from: json, into: self,
            setBusinessData: { self.businessData = $0 },
            setTitle: { self.title = $0 },
            setContent: { self.content = $0 },
            setIsShowUser: { self.isShowUser = $0 },
            setImageUrl: { self.imageUrl = $0 },
            setUrlKey: { self.urlKey = $0 },
            setLastMsgDisplayContent: { self.lastMsgDisplayContent = $0 },
            setMessageType: { self.messageType = $0 }
        )
    }

    override func conversationDigest() -> String? {
        lastMsgDisplayContent ?? "[核对信息]"
    }
}
