import Foundation

// MARK: - 医生 / 业务经理列表

/// `GET /v1/doctor/getDoctorPage` — 按机构分页查询医生（完善资料业务经理）
///
/// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330896e0.md
final class DoctorService {

    static let shared = DoctorService()

    private init() {}

    /// 分页查询医生列表
    /// - Parameters:
    ///   - hospitalId: 所属机构 id（必填场景）
    ///   - name: 姓名关键词
    ///   - status: 医生状态，默认 `"1"` 启用
    func getDoctorPage(
        hospitalId: String,
        name: String? = nil,
        status: String = "1",
        pageNum: Int = 1,
        pageSize: Int = 50
    ) async throws -> PaginatedDoctorData {
        var params: [String: Any] = [
            "pageNum": String(pageNum),
            "pageSize": String(pageSize),
            "status": status,
        ]
        let hid = hospitalId.trimmingCharacters(in: .whitespacesAndNewlines)
        if !hid.isEmpty {
            params["hospitalId"] = hid
        }
        if let name = name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            params["name"] = name
        }

        print("[DoctorService] getDoctorPage → hospitalId=\(hid) name=\(name ?? "") page=\(pageNum)")

        let response: APIResponse<PaginatedDoctorData> = try await APIManager.shared.getAsync(
            path: "/v1/doctor/getDoctorPage",
            parameters: params,
            responseType: APIResponse<PaginatedDoctorData>.self
        )

        guard response.isSuccess else {
            throw DoctorServiceError.requestFailed(response.msg ?? "获取业务经理失败")
        }

        return response.data ?? PaginatedDoctorData(
            totalRecords: 0,
            pageSize: pageSize,
            totalPages: 0,
            currentPage: pageNum,
            records: []
        )
    }
}

enum DoctorServiceError: Error, LocalizedError {
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .requestFailed(let msg): return msg.isEmpty ? "获取业务经理失败" : msg
        }
    }
}
