import Foundation

/// 康养小屋列表。`GET /v1/cabin/list`
///
/// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/529266269e0
/// 经纬度按文档传高德 GCJ-02。有坐标时服务端按距离由近到远排序。
final class CabinService {

    static let shared = CabinService()

    private init() {}

    func listStores(
        keyword: String? = nil,
        longitude: String? = nil,
        latitude: String? = nil,
        pageNum: Int = 1,
        pageSize: Int = 20
    ) async throws -> PaginatedCabinListData {
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

        let response: APIResponse<PaginatedCabinListData> = try await APIManager.shared.getAsync(
            path: "/v1/cabin/list",
            parameters: params,
            responseType: APIResponse<PaginatedCabinListData>.self
        )
        guard response.isSuccess else {
            throw CabinServiceError.requestFailed(response.msg ?? "获取康养小屋失败")
        }
        return response.data ?? PaginatedCabinListData.empty(pageNum: pageNum, pageSize: pageSize)
    }

    /// 门店详情。`GET /v1/cabin/detail`
    ///
    /// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/529266267e0
    func storeDetail(hospitalId: String) async throws -> CabinStoreVO {
        let response: APIResponse<CabinStoreVO> = try await APIManager.shared.getAsync(
            path: "/v1/cabin/detail",
            parameters: ["hospitalId": hospitalId],
            responseType: APIResponse<CabinStoreVO>.self
        )
        guard response.isSuccess, let store = response.data, !store.id.isEmpty else {
            throw CabinServiceError.requestFailed(response.msg ?? "未找到该驿站")
        }
        return store
    }

    /// 服务分类。`GET /v1/cabin/categoryList`
    ///
    /// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/529785605e0
    func categories(hospitalId: String) async throws -> [CabinCategoryVO] {
        let response: APIResponse<[CabinCategoryVO]> = try await APIManager.shared.getAsync(
            path: "/v1/cabin/categoryList",
            parameters: ["hospitalId": hospitalId],
            responseType: APIResponse<[CabinCategoryVO]>.self
        )
        guard response.isSuccess else {
            throw CabinServiceError.requestFailed(response.msg ?? "获取服务分类失败")
        }
        return (response.data ?? []).sorted { lhs, rhs in
            if lhs.sortId != rhs.sortId { return lhs.sortId < rhs.sortId }
            return lhs.id < rhs.id
        }
    }

    /// 分类下的服务项目。`GET /v1/cabin/configList`
    ///
    /// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/529266270e0
    func serviceItems(hospitalId: String, parentId: String) async throws -> [CabinConfigItemVO] {
        let response: APIResponse<[CabinConfigItemVO]> = try await APIManager.shared.getAsync(
            path: "/v1/cabin/configList",
            parameters: ["hospitalId": hospitalId, "parentId": parentId],
            responseType: APIResponse<[CabinConfigItemVO]>.self
        )
        guard response.isSuccess else {
            throw CabinServiceError.requestFailed(response.msg ?? "获取服务项目失败")
        }
        return response.data ?? []
    }

    /// 预约页详情。`GET /v1/cabin/bookDetail`
    ///
    /// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/529785607e0
    /// `date` 不传时服务端按当天返回。换日期时传 `yyyy-MM-dd`。
    func bookDetail(configId: String, date: String? = nil) async throws -> CabinBookDetailVO {
        var params: [String: Any] = ["configId": configId]
        if let date, !date.isEmpty {
            params["date"] = date
        }
        let response: APIResponse<CabinBookDetailVO> = try await APIManager.shared.getAsync(
            path: "/v1/cabin/bookDetail",
            parameters: params,
            responseType: APIResponse<CabinBookDetailVO>.self
        )
        guard response.isSuccess, let detail = response.data, detail.hasContent else {
            throw CabinServiceError.requestFailed(response.msg ?? "未找到该项目")
        }
        return detail
    }

    /// 提交预约。`POST /v1/cabin/book`
    ///
    /// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/530062590e0
    /// `sourceType = 3` 时必须带支付成功后的 `orderId`。
    @discardableResult
    func book(
        configId: String,
        reserveDate: String,
        sourceType: Int,
        startTime: String,
        endTime: String,
        quantity: Int = 1,
        orderId: Int64? = nil
    ) async throws -> Int64? {
        guard let config = Int64(configId) else {
            throw CabinServiceError.requestFailed("未找到该项目")
        }
        var body: [String: Any] = [
            "configId": NSNumber(value: config),
            "reserveDate": reserveDate,
            "sourceType": sourceType,
            "startTime": startTime,
            "endTime": endTime,
            "quantity": quantity,
        ]
        if let orderId, orderId > 0 {
            body["orderId"] = NSNumber(value: orderId)
        }
        let response: APIResponse<CabinBookID> = try await APIManager.shared.postAsync(
            path: "/v1/cabin/book",
            parameters: body,
            responseType: APIResponse<CabinBookID>.self
        )
        guard response.isSuccess else {
            throw CabinServiceError.requestFailed(response.msg ?? "提交失败，请重试")
        }
        return response.data?.value
    }

    /// 当前登录人的预约记录。`GET /v1/cabin/appointments`
    ///
    /// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/529785606e0
    /// `status` 空为全部：3 待服务，4 服务中，5 已完成，6 已取消，7 已过期。
    func appointments(
        status: String? = nil,
        pageNum: Int = 1,
        pageSize: Int = 20
    ) async throws -> PaginatedCabinAppointmentData {
        var params: [String: Any] = [
            "pageNum": String(pageNum),
            "pageSize": String(pageSize),
        ]
        if let status, !status.isEmpty {
            params["status"] = status
        }
        let response: APIResponse<PaginatedCabinAppointmentData> = try await APIManager.shared.getAsync(
            path: "/v1/cabin/appointments",
            parameters: params,
            responseType: APIResponse<PaginatedCabinAppointmentData>.self
        )
        guard response.isSuccess else {
            throw CabinServiceError.requestFailed(response.msg ?? "获取预约记录失败")
        }
        return response.data ?? PaginatedCabinAppointmentData(
            totalRecords: 0,
            pageSize: pageSize,
            totalPages: 0,
            currentPage: pageNum,
            records: []
        )
    }
}

/// 预约接口 `data` 是预约单 id，可能是数字或字符串。
private struct CabinBookID: Decodable {
    let value: Int64

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let number = try? container.decode(Int64.self) {
            value = number
            return
        }
        if let number = try? container.decode(Int.self) {
            value = Int64(number)
            return
        }
        if let text = try? container.decode(String.self), let number = Int64(text) {
            value = number
            return
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "预约单 id 无效")
    }
}

extension PaginatedCabinListData {
    static func empty(pageNum: Int, pageSize: Int) -> PaginatedCabinListData {
        PaginatedCabinListData(
            totalRecords: 0,
            pageSize: pageSize,
            totalPages: 0,
            currentPage: pageNum,
            records: []
        )
    }

    fileprivate init(
        totalRecords: Int?,
        pageSize: Int?,
        totalPages: Int?,
        currentPage: Int?,
        records: [CabinStoreVO]?
    ) {
        self.totalRecords = totalRecords
        self.pageSize = pageSize
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.records = records
    }
}

enum CabinServiceError: Error, LocalizedError {
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .requestFailed(let message): return message
        }
    }
}
