import Foundation

// MARK: - 医院搜索服务

/// `GET /v1/hospital/searchPage` — 分页搜索医疗机构
///
/// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/488248475e0
///
/// - Important: `longitude` / `latitude` 须为**腾讯地图坐标系**（文档写高德，后端按腾讯）。
final class HospitalService {

    static let shared = HospitalService()

    private init() {}

    /// 分页搜索医院
    /// - Parameters:
    ///   - keyword: 名称或地址关键词
    ///   - longitude: 腾讯坐标系经度字符串；无定位传 nil
    ///   - latitude: 腾讯坐标系纬度字符串；无定位传 nil
    func searchPage(
        keyword: String? = nil,
        longitude: String? = nil,
        latitude: String? = nil,
        pageNum: Int = 1,
        pageSize: Int = 20
    ) async throws -> PaginatedHospitalSearchData {
        var params: [String: Any] = [
            "pageNum": String(pageNum),
            "pageSize": String(pageSize),
        ]
        if let keyword = keyword?.trimmingCharacters(in: .whitespacesAndNewlines), !keyword.isEmpty {
            params["keyword"] = keyword
        }
        if let longitude, !longitude.isEmpty, let latitude, !latitude.isEmpty {
            params["longitude"] = longitude
            params["latitude"] = latitude
        }

        let response: APIResponse<PaginatedHospitalSearchData> = try await APIManager.shared.getAsync(
            path: "/v1/hospital/searchPage",
            parameters: params,
            responseType: APIResponse<PaginatedHospitalSearchData>.self
        )

        guard response.isSuccess else {
            throw HospitalServiceError.requestFailed(response.msg ?? "搜索机构失败")
        }

        return response.data ?? PaginatedHospitalSearchData(
            totalRecords: 0,
            pageSize: pageSize,
            totalPages: 0,
            currentPage: pageNum,
            records: []
        )
    }

    /// 根据医院 id 查询详情（自提地址）
    /// - Parameter id: 医院 ID（int64）
    func getById(id: Int64) async throws -> OHospital {
        let response: APIResponse<OHospital> = try await APIManager.shared.getAsync(
            path: "/v1/hospital/getById",
            parameters: ["id": String(id)],
            responseType: APIResponse<OHospital>.self
        )

        guard response.isSuccess, let data = response.data else {
            throw HospitalServiceError.requestFailed(response.msg ?? "获取机构信息失败")
        }
        return data
    }
}

enum HospitalServiceError: Error, LocalizedError {
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .requestFailed(let msg): return msg
        }
    }
}
