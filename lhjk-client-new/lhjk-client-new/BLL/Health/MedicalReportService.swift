import Foundation

/// 体检报告 — `GET /v1/medicalReport/getMedicalReportStatistics`
final class MedicalReportService {

    static let shared = MedicalReportService()

    private init() {}

    enum MedicalReportServiceError: LocalizedError {
        case requestFailed(String)

        var errorDescription: String? {
            switch self {
            case .requestFailed(let message): return message
            }
        }
    }

    /// 统计当前用户体检报告
    func getMedicalReportStatistics(userId: String? = nil) async throws -> MedicalReportStatisticsVO {
        var parameters: [String: Any]?
        if let userId {
            let trimmed = userId.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                parameters = ["userId": trimmed]
            }
        }

        print("[MedicalReportService] getMedicalReportStatistics userId=\(parameters?["userId"] as? String ?? "nil")")

        let response: APIResponse<MedicalReportStatisticsVO> = try await APIManager.shared.getAsync(
            path: "/v1/medicalReport/getMedicalReportStatistics",
            parameters: parameters,
            responseType: APIResponse<MedicalReportStatisticsVO>.self
        )

        guard response.isSuccess, let statistics = response.data else {
            print(
                "[MedicalReportService] getMedicalReportStatistics ✗ code=\(response.code) msg=\(response.msg ?? "")"
            )
            throw MedicalReportServiceError.requestFailed(response.msg ?? "获取体检报告统计失败")
        }

        print(
            "[MedicalReportService] getMedicalReportStatistics ✓ reportNum=\(statistics.reportNum.map(String.init) ?? "nil") "
                + "pending=\(statistics.pendingInterpretNum.map(String.init) ?? "nil")"
        )
        return statistics
    }
}
