import Foundation

// MARK: - 订单服务 (BLL)

/// 订单管理服务 — 提供订单列表查询能力
///
/// 封装后端接口：
/// - `GET /mobile/v1/order/getAppOrderList` — 分页查询用户订单列表
final class OrderService {

    // MARK: - Singleton

    static let shared = OrderService()

    private init() {}

    // MARK: - 查询订单列表

    /// 分页查询订单列表
    /// - Parameters:
    ///   - status: 单个状态筛选（1-9），nil 表示全部
    ///   - statusList: 多状态筛选（逗号分隔），如 "2,3"
    ///   - pageNum: 当前页码，默认 1
    ///   - pageSize: 每页记录数，默认 10
    /// - Returns: 分页订单数据
    func getOrderList(
        status: Int? = nil,
        statusList: String? = nil,
        pageNum: Int = 1,
        pageSize: Int = 10
    ) async throws -> PaginatedOrderData {
        var params: [String: Any] = [
            "pageNum": String(pageNum),
            "pageSize": String(pageSize),
            "source": "2", // App端
        ]
        if let status = status {
            params["status"] = String(status)
        }
        if let statusList = statusList {
            params["statusList"] = statusList
        }

        print("[OrderService] getOrderList → status=\(status?.description ?? "nil") statusList=\(statusList ?? "nil") page=\(pageNum) size=\(pageSize)")

        let response: APIResponse<PaginatedOrderData> = try await APIManager.shared
            .getAsync(
                path: "/mobile/v1/order/getAppOrderList",
                parameters: params,
                responseType: APIResponse<PaginatedOrderData>.self
            )

        guard response.isSuccess else {
            print("[OrderService] getOrderList ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw OrderServiceError.queryFailed(response.msg ?? "查询订单列表失败")
        }

        let data = response.data ?? PaginatedOrderData(totalRecords: 0, pageSize: pageSize, totalPages: 0, currentPage: pageNum, records: [])
        print("[OrderService] getOrderList ✓ total=\(data.totalRecords ?? 0) count=\(data.records?.count ?? 0)")
        return data
    }
}

// MARK: - Error

enum OrderServiceError: Error, LocalizedError {
    case queryFailed(String)

    var errorDescription: String? {
        switch self {
        case .queryFailed(let msg): return msg.isEmpty ? "查询订单列表失败" : msg
        }
    }
}
