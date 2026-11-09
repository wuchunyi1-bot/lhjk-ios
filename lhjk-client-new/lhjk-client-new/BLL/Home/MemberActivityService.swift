import Foundation

/// 会员活动 C 端接口
final class MemberActivityService {

    static let shared = MemberActivityService()

    private init() {}

    enum ServiceError: LocalizedError {
        case requestFailed(String)
        case missingActivity

        var errorDescription: String? {
            switch self {
            case .requestFailed(let message): return message
            case .missingActivity: return "未找到该活动"
            }
        }
    }

    /// 已签到且当天可见的活动。无 query。
    func listMyActivities() async throws -> [MemberActivityClientListVO] {
        let response: APIResponse<[MemberActivityClientListVO]> = try await APIManager.shared.getAsync(
            path: "/v1/memberActivity/client/listMyActivitiesForClient",
            parameters: nil,
            responseType: APIResponse<[MemberActivityClientListVO]>.self
        )
        guard response.isSuccess else {
            throw ServiceError.requestFailed(response.msg ?? "获取活动失败")
        }
        return response.data ?? []
    }

    /// 活动详情。`activityId` 为列表返回的活动 id。
    func getDetail(activityId: String) async throws -> MemberActivityDetailVO {
        let trimmed = activityId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ServiceError.missingActivity }
        let response: APIResponse<MemberActivityDetailVO> = try await APIManager.shared.getAsync(
            path: "/v1/memberActivity/client/getDetailForClient",
            parameters: ["activityId": trimmed],
            responseType: APIResponse<MemberActivityDetailVO>.self
        )
        guard response.isSuccess, let detail = response.data else {
            throw ServiceError.requestFailed(response.msg ?? "未找到该活动")
        }
        return detail
    }
}
