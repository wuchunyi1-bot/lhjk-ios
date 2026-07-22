import Foundation

// MARK: - 订单服务 (BLL)

/// 订单管理服务 — 提供订单列表 / 结算查询能力
///
/// 封装后端接口：
/// - `GET /v1/order/getAppOrderList` — 分页查询用户订单列表
/// - `GET /v1/order/getOrderSettlement` — 确认订单结算信息
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
                path: "/v1/order/getAppOrderList",
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

    // MARK: - 确认订单结算

    /// 获取订单最新结算信息
    /// - Parameters:
    ///   - orderId: 订单 ID（必填，禁止 mock）
    ///   - serialNumber: 分组编号（可选）
    func getOrderSettlement(
        orderId: Int64,
        serialNumber: Int? = nil
    ) async throws -> OrderSettlementBO {
        var params: [String: Any] = [
            "orderId": String(orderId)
        ]
        if let serialNumber {
            params["serialNumber"] = String(serialNumber)
        }

        print("[OrderService] getOrderSettlement → orderId=\(orderId) serial=\(serialNumber?.description ?? "nil")")

        let response: APIResponse<OrderSettlementBO> = try await APIManager.shared
            .getAsync(
                path: "/v1/order/getOrderSettlement",
                parameters: params,
                responseType: APIResponse<OrderSettlementBO>.self
            )

        guard response.isSuccess, let data = response.data else {
            print("[OrderService] getOrderSettlement ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw OrderServiceError.queryFailed(response.msg ?? "获取结算信息失败")
        }

        print("[OrderService] getOrderSettlement ✓ package=\(data.packageName ?? "") orderExpress=\(data.orderExpress?.description ?? "nil")")
        return data
    }

    // MARK: - 修改订单备注

    /// `POST /v1/order/updateOrderDescription`（Query：orderId 必填，description 可选，≤300）
    func updateOrderDescription(orderId: Int64, description: String?) async throws {
        var params: [String: Any] = ["orderId": String(orderId)]
        if let description {
            params["description"] = String(description.prefix(300))
        }

        print("[OrderService] updateOrderDescription → orderId=\(orderId) len=\(description?.count ?? 0)")

        let response: APIResponse<EmptyResponse> = try await APIManager.shared
            .postFormURLEncodedAsync(
                path: "/v1/order/updateOrderDescription",
                parameters: params,
                responseType: APIResponse<EmptyResponse>.self
            )

        guard response.isSuccess else {
            print("[OrderService] updateOrderDescription ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw OrderServiceError.queryFailed(response.msg ?? "保存备注失败")
        }
        print("[OrderService] updateOrderDescription ✓")
    }

    // MARK: - 修改订单配送信息

    /// `POST /v1/order/updateOrderDelivery`（JSON body）
    /// - Parameters:
    ///   - orderId: 订单 ID（必填）
    ///   - typeOrder: 0 医院自提 / 1 快递
    ///   - addressId: 收货地址 ID（快递时传）
    ///   - receiver: 收货人
    ///   - phone: 联系电话
    ///   - address: 收货地址
    func updateOrderDelivery(
        orderId: Int64,
        typeOrder: Int,
        addressId: Int64? = nil,
        receiver: String? = nil,
        phone: String? = nil,
        address: String? = nil
    ) async throws {
        var body: [String: Any] = [
            "orderId": orderId,
            "typeOrder": typeOrder,
        ]
        if let addressId { body["addressId"] = addressId }
        if let receiver { body["receiver"] = receiver }
        if let phone { body["phone"] = phone }
        if let address { body["address"] = address }

        print("[OrderService] updateOrderDelivery → orderId=\(orderId) typeOrder=\(typeOrder) addressId=\(addressId?.description ?? "nil")")

        let response: APIResponse<EmptyResponse> = try await APIManager.shared
            .postAsync(
                path: "/v1/order/updateOrderDelivery",
                parameters: body,
                responseType: APIResponse<EmptyResponse>.self
            )

        guard response.isSuccess else {
            print("[OrderService] updateOrderDelivery ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw OrderServiceError.queryFailed(response.msg ?? "保存配送信息失败")
        }
        print("[OrderService] updateOrderDelivery ✓")
    }
}

// MARK: - Error

enum OrderServiceError: Error, LocalizedError {
    case queryFailed(String)

    var errorDescription: String? {
        switch self {
        case .queryFailed(let msg): return msg.isEmpty ? "查询订单失败" : msg
        }
    }
}
