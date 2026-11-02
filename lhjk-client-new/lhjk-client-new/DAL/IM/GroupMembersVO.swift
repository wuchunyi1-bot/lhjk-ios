import Foundation

/// 群成员项 — 现网 `GET /v1/session/getGroupMembers` 的 `data[]` 元素
///
/// 现网字段以 `userId` / `userName` / `imageUrl` / `roleName` 为主。
/// OAS `ImSessionDetails` 额外字段按需解码，缺失为 nil。
struct ImSessionDetails: Decodable {
    let id: Int64?
    let sessionId: Int64?
    let groupId: String?
    let identity: Int?
    let userId: String?
    let mute: Int?
    let createTime: String?
    let createId: Int64?
    let modifyTime: String?
    let modifyId: Int64?
    let userName: String?
    /// 昵称。仅当前用户在群成员列表展示；空则回退 `userName`。
    let nickname: String?
    let userImg: String?
    let imageUrl: String?
    let roleName: String?
    let repeatMark: Int?
    let departmentName: String?
    let doctorType: Int?
    let healthId: Int64?

    /// 现网用 `imageUrl`，OAS 为 `userImg`
    var portraitURL: String? {
        let image = imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !image.isEmpty { return image }
        let img = userImg?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return img.isEmpty ? nil : img
    }

    var displayName: String {
        let name = userName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "群成员" : name
    }

    /// 自己展示昵称；没有昵称时用姓名。其他成员始终用姓名。
    func listDisplayName(isSelf: Bool) -> String {
        guard isSelf else { return displayName }
        let nick = nickname?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return nick.isEmpty ? displayName : nick
    }

    var displayRole: String {
        let role = roleName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !role.isEmpty { return role }
        switch identity {
        case 1: return "健康管理师负责人"
        case 2: return "医生"
        case 3: return "用户"
        case 4: return "队员"
        default: return ""
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, sessionId, groupId, identity, userId, mute
        case createTime, createId, modifyTime, modifyId
        case userName, nickname, nickName, userImg, imageUrl, roleName, repeatMark
        case departmentName, doctorType, healthId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeFlexibleInt64(.id)
        sessionId = c.decodeFlexibleInt64(.sessionId)
        groupId = c.decodeFlexibleString(.groupId)
        identity = c.decodeFlexibleInt(.identity)
        userId = c.decodeFlexibleString(.userId)
        mute = c.decodeFlexibleInt(.mute)
        createTime = try c.decodeIfPresent(String.self, forKey: .createTime)
        createId = c.decodeFlexibleInt64(.createId)
        modifyTime = try c.decodeIfPresent(String.self, forKey: .modifyTime)
        modifyId = c.decodeFlexibleInt64(.modifyId)
        userName = try c.decodeIfPresent(String.self, forKey: .userName)
        nickname = Self.firstNonEmpty(
            try c.decodeIfPresent(String.self, forKey: .nickname),
            try c.decodeIfPresent(String.self, forKey: .nickName)
        )
        userImg = try c.decodeIfPresent(String.self, forKey: .userImg)
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
        roleName = try c.decodeIfPresent(String.self, forKey: .roleName)
        repeatMark = c.decodeFlexibleInt(.repeatMark)
        departmentName = try c.decodeIfPresent(String.self, forKey: .departmentName)
        doctorType = c.decodeFlexibleInt(.doctorType)
        healthId = c.decodeFlexibleInt64(.healthId)
    }

    private static func firstNonEmpty(_ values: String?...) -> String? {
        for value in values {
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }
}

/// 现网 `data` 为成员数组，不是 OAS 的 `GroupMembersVO` 对象
typealias GroupMembersResponse = APIResponse<[ImSessionDetails]>

private extension KeyedDecodingContainer {
    func decodeFlexibleInt64(_ key: Key) -> Int64? {
        if let v = try? decodeIfPresent(Int64.self, forKey: key) { return v }
        if let v = try? decodeIfPresent(Int.self, forKey: key) { return Int64(v) }
        if let s = try? decodeIfPresent(String.self, forKey: key), let v = Int64(s) { return v }
        return nil
    }

    func decodeFlexibleInt(_ key: Key) -> Int? {
        if let v = try? decodeIfPresent(Int.self, forKey: key) { return v }
        if let v = try? decodeIfPresent(Int64.self, forKey: key) { return Int(v) }
        if let s = try? decodeIfPresent(String.self, forKey: key), let v = Int(s) { return v }
        return nil
    }

    func decodeFlexibleString(_ key: Key) -> String? {
        if let s = try? decodeIfPresent(String.self, forKey: key) { return s }
        if let v = try? decodeIfPresent(Int64.self, forKey: key) { return String(v) }
        if let v = try? decodeIfPresent(Int.self, forKey: key) { return String(v) }
        return nil
    }
}
