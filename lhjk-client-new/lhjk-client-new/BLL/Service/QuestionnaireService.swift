import Foundation

/// 测评问卷 — `GET /v1/questionnaire/getSchoolExamUserListCount`
final class QuestionnaireService {

    static let shared = QuestionnaireService()

    private init() {}

    enum QuestionnaireServiceError: LocalizedError {
        case requestFailed(String)

        var errorDescription: String? {
            switch self {
            case .requestFailed(let message): return message
            }
        }
    }

    /// 当前用户的测评记录数（静默只查 type=1）
    func getSchoolExamUserListCount() async throws -> [ExamUserListCountVO] {
        print("[QuestionnaireService] getSchoolExamUserListCount")

        let response: APIResponse<[ExamUserListCountVO]> = try await APIManager.shared.getAsync(
            path: "/v1/questionnaire/getSchoolExamUserListCount",
            parameters: nil,
            responseType: APIResponse<[ExamUserListCountVO]>.self
        )

        guard response.isSuccess, let items = response.data else {
            print(
                "[QuestionnaireService] getSchoolExamUserListCount ✗ code=\(response.code) msg=\(response.msg ?? "")"
            )
            throw QuestionnaireServiceError.requestFailed(response.msg ?? "获取健康测评统计失败")
        }

        let pending = items.first(where: { $0.value == 0 })?.count ?? 0
        print("[QuestionnaireService] getSchoolExamUserListCount ✓ pending=\(pending) totalGroups=\(items.count)")
        return items
    }
}
