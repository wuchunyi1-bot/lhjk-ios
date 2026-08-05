import Foundation

/// 首页相关接口
final class HomeService {

    static let shared = HomeService()

    private init() {}

    enum HomeServiceError: LocalizedError {
        case missingUserId
        case requestFailed(String)

        var errorDescription: String? {
            switch self {
            case .missingUserId: return "用户未登录"
            case .requestFailed(let msg): return msg
            }
        }
    }

    /// `GET /v1/scheme/getUserToDayMonitorTask`
    /// - Parameter userId: 当前用户 ID（雪花字符串）
    func getUserTodayMonitorTask(userId: String) async throws -> [UserTodayMonitorTask] {
        let trimmed = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw HomeServiceError.missingUserId }

        print("[HomeService] getUserTodayMonitorTask → userId=\(trimmed)")

        let response: APIResponse<[UserTodayMonitorTask]> = try await APIManager.shared.getAsync(
            path: "/v1/scheme/getUserToDayMonitorTask",
            parameters: ["userId": trimmed],
            responseType: APIResponse<[UserTodayMonitorTask]>.self
        )

        guard response.isSuccess else {
            print("[HomeService] getUserTodayMonitorTask ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw HomeServiceError.requestFailed(response.msg ?? "获取今日任务失败")
        }

        let list = response.data ?? []
        print("[HomeService] getUserTodayMonitorTask ✓ count=\(list.count)")
        return list
    }

    /// `GET /v1/session/getUserParticipateAllTeam`
    /// - Parameter userId: 当前用户 ID（雪花字符串）
    /// - Returns: 嵌套数组（外层=团队，内层=成员）
    func getUserParticipateAllTeam(userId: String) async throws -> [[MyDoctorTeamVO]] {
        let trimmed = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw HomeServiceError.missingUserId }

        print("[HomeService] getUserParticipateAllTeam → userId=\(trimmed)")

        let response: APIResponse<[[MyDoctorTeamVO]]> = try await APIManager.shared.getAsync(
            path: "/v1/session/getUserParticipateAllTeam",
            parameters: ["userId": trimmed],
            responseType: APIResponse<[[MyDoctorTeamVO]]>.self
        )

        guard response.isSuccess else {
            print("[HomeService] getUserParticipateAllTeam ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw HomeServiceError.requestFailed(response.msg ?? "获取健康管家团队失败")
        }

        let teams = response.data ?? []
        let memberCount = teams.reduce(0) { $0 + $1.count }
        print("[HomeService] getUserParticipateAllTeam ✓ teams=\(teams.count) members=\(memberCount)")
        return teams
    }
}

// MARK: - MyDoctorTeamVO
// 与 HomeService 同文件，避免未加入 Xcode target 导致 cannot find type。
// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/495580451e0.md

/// `GET /v1/session/getUserParticipateAllTeam` 单条团队成员
/// `data` 为嵌套数组 `[[MyDoctorTeamVO]]`（外层=团队，内层=成员）。
struct MyDoctorTeamVO: Decodable, Equatable {
    let groupId: String?
    /// 成员身份（文档未展开枚举；见 `resolvedRole`）
    let identity: Int?
    let userId: String?
    let userName: String?
    let imageUrl: String?
    /// 医生开通业务 code，逗号分隔（仅医生）
    let openBusiness: String?
    let openBusinessName: String?
    /// 职称
    let position: String?

    private enum CodingKeys: String, CodingKey {
        case groupId, identity, userId, userName, imageUrl
        case openBusiness, openBusinessName, position
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        groupId = Self.decodeFlexibleString(c, key: .groupId)
        identity = Self.decodeFlexibleInt(c, key: .identity)
        userId = Self.decodeFlexibleString(c, key: .userId)
        userName = try c.decodeIfPresent(String.self, forKey: .userName)
        imageUrl = Self.decodeFlexibleString(c, key: .imageUrl)
        openBusiness = try c.decodeIfPresent(String.self, forKey: .openBusiness)
        openBusinessName = try c.decodeIfPresent(String.self, forKey: .openBusinessName)
        position = try c.decodeIfPresent(String.self, forKey: .position)
    }

    private static func decodeFlexibleString<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> String? {
        if let s = try? container.decodeIfPresent(String.self, forKey: key) {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        }
        if let i = try? container.decodeIfPresent(Int64.self, forKey: key) { return String(i) }
        if let d = try? container.decodeIfPresent(Double.self, forKey: key) { return String(Int64(d)) }
        return nil
    }

    private static func decodeFlexibleInt<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> Int? {
        if let i = try? container.decodeIfPresent(Int.self, forKey: key) { return i }
        if let i = try? container.decodeIfPresent(Int64.self, forKey: key) { return Int(i) }
        if let s = try? container.decodeIfPresent(String.self, forKey: key), let i = Int(s) { return i }
        return nil
    }

    /// UI 角色：`doctor` / `nutrition` / `manager`
    func resolvedRole() -> String {
        let business = (openBusiness ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let businessName = (openBusinessName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !business.isEmpty || !businessName.isEmpty {
            return "doctor"
        }

        let haystack = "\(userName ?? "")\(position ?? "")\(businessName)"
        if haystack.contains("营养") {
            return "nutrition"
        }
        if haystack.contains("健管") || haystack.contains("顾问") {
            return "manager"
        }

        switch identity {
        case 1: return "doctor"
        case 2: return "manager"
        case 3: return "nutrition"
        default: return "manager"
        }
    }

    /// 取 `openBusinessName` 首段，过长截断
    func resolvedTags(fallback: String) -> String {
        let raw = (openBusinessName ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return fallback }
        let first = raw.split(separator: ",").first.map(String.init) ?? raw
        let trimmed = first.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fallback }
        return trimmed.count > 12 ? String(trimmed.prefix(12)) : trimmed
    }
}

extension Array where Element == [MyDoctorTeamVO] {

    /// 取第一个非空团队成员，排除当前用户并按 userId 去重
    func firstTeamStaff(excludingUserId currentUserId: String?) -> [MyDoctorTeamVO] {
        let selfId = currentUserId?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let team = first(where: { !$0.isEmpty }) ?? []
        var seen = Set<String>()
        var result: [MyDoctorTeamVO] = []

        for vo in team {
            let name = (vo.userName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }

            if let uid = vo.userId?.trimmingCharacters(in: .whitespacesAndNewlines),
               let selfId, !selfId.isEmpty, uid == selfId {
                continue
            }

            let dedupeKey = vo.userId ?? name
            if seen.contains(dedupeKey) { continue }
            seen.insert(dedupeKey)
            result.append(vo)
        }
        return result
    }
}
