import Foundation

/// `GET /v1/session/getGroupMembers` 响应 `data`
struct GroupMembersVO: Decodable {
    let groupName: String?
    let groupImg: String?
    let list: [ImSessionDetails]?
    let status: Int?
}

/// 群成员项（Apifox `ImSessionDetails`）
struct ImSessionDetails: Decodable {
    let userId: Int64?
    let userName: String?
    let userImg: String?
    let roleName: String?
    let identity: Int?

    /// 成员身份：1 健康管理师负责人 / 2 医生 / 3 用户 / 4 队员
    var displayName: String {
        let name = userName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "群成员" : name
    }

    var displayRole: String {
        let role = roleName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !role.isEmpty { return role }
        switch identity {
        case 1: return "健康管理师"
        case 2: return "医生"
        case 3: return "用户"
        case 4: return "队员"
        default: return ""
        }
    }

    private enum CodingKeys: String, CodingKey {
        case userId, userName, userImg, roleName, identity
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        userId = Self.decodeInt64(c, key: .userId)
        userName = try c.decodeIfPresent(String.self, forKey: .userName)
        userImg = try c.decodeIfPresent(String.self, forKey: .userImg)
        roleName = try c.decodeIfPresent(String.self, forKey: .roleName)
        if let v = try? c.decodeIfPresent(Int.self, forKey: .identity) {
            identity = v
        } else if let s = try? c.decodeIfPresent(String.self, forKey: .identity), let v = Int(s) {
            identity = v
        } else {
            identity = nil
        }
    }

    private static func decodeInt64(_ c: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Int64? {
        if let v = try? c.decodeIfPresent(Int64.self, forKey: key) { return v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: key) { return Int64(v) }
        if let s = try? c.decodeIfPresent(String.self, forKey: key), let v = Int64(s) { return v }
        return nil
    }
}

typealias GroupMembersResponse = APIResponse<GroupMembersVO>
