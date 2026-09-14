import Foundation
import Combine

// MARK: - 购物车 / 一键购买 (BLL · 服务·商城)

/// 购物车：加购 / 立即购买 / 列表 / 删除 / 数量角标
/// - 加购：https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330718e0.md
/// - 列表：https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330722e0.md
/// - 删除：https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330724e0.md
/// - 数量：`GET /v1/shoppingCart/getShoppingCartCount`（文档暂无 / 以代码 path 为准）
final class ShoppingCartService {

    static let shared = ShoppingCartService()

    private init() {
        // 清掉旧版本地购物车 mock / 持久化残留
        UserDefaults.standard.removeObject(forKey: "service.cart.items.v1")
        UserDefaults.standard.removeObject(forKey: "service.cart.seeded.v1")
    }

    /// 添加购物车（flag=2）或立即购买（flag=1）
    /// - Returns: 成功时 `data` 为订单 id（立即购买必用）；加购也可能返回 id，可忽略
    @discardableResult
    func saveShoppingCartOrPurchase(_ request: SaveShoppingCartRequest) async throws -> Int64? {
        let response: APIResponse<APIDataID> = try await APIManager.shared.postAsync(
            path: "/v1/shoppingCart/saveShoppingCartOrPurchase",
            parameters: request.asDict(),
            responseType: APIResponse<APIDataID>.self
        )

        guard response.isSuccess else {
            if response.code == ShoppingCartServiceError.incompleteExistingOrderCode {
                let message = (response.msg ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                throw ShoppingCartServiceError.incompleteExistingOrder(
                    orderId: response.data?.value ?? 0,
                    message: message.isEmpty
                        ? "您已购买该商品，相关订单尚未完成，暂不能再次下单。"
                        : message
                )
            }
            throw ShoppingCartServiceError.requestFailed(response.msg ?? "操作失败")
        }
        let orderId = response.data?.value
        print("[ShoppingCart] saveShoppingCartOrPurchase ✓ flag=\(request.flag) orderId=\(orderId?.description ?? "nil")")
        return orderId
    }

    /// 查询购物车列表（不传 hospitalId，展示当前用户全部医疗机构下的套餐）
    func getShoppingCartList(
        pageNum: Int = 1,
        pageSize: Int = 50
    ) async throws -> PaginatedShoppingCartData {
        let params: [String: Any] = [
            "pageNum": String(pageNum),
            "pageSize": String(pageSize),
        ]

        let response: APIResponse<PaginatedShoppingCartData> = try await APIManager.shared.getAsync(
            path: "/v1/shoppingCart/getShoppingCartList",
            parameters: params,
            responseType: APIResponse<PaginatedShoppingCartData>.self
        )

        guard response.isSuccess else {
            throw ShoppingCartServiceError.requestFailed(response.msg ?? "查询购物车失败")
        }

        return response.data ?? PaginatedShoppingCartData(
            totalRecords: 0,
            pageSize: pageSize,
            totalPages: 0,
            currentPage: pageNum,
            records: []
        )
    }

    /// 查询当前用户购物车数量（`ResultLong.data` 为 int64）
    func getShoppingCartCount() async throws -> Int {
        let response: APIResponse<APIDataID> = try await APIManager.shared.getAsync(
            path: "/v1/shoppingCart/getShoppingCartCount",
            parameters: nil,
            responseType: APIResponse<APIDataID>.self
        )

        guard response.isSuccess else {
            throw ShoppingCartServiceError.requestFailed(response.msg ?? "查询购物车数量失败")
        }
        let raw = response.data?.value ?? 0
        return Int(min(max(raw, 0), Int64(Int.max)))
    }

    /// 删除购物车 — Query 必填 `serialNumber`
    func deleteShoppingCart(serialNumber: Int) async throws {
        let response: APIResponse<EmptyResponse> = try await APIManager.shared.deleteAsync(
            path: "/v1/shoppingCart/deleteShoppingCart",
            parameters: ["serialNumber": String(serialNumber)],
            responseType: APIResponse<EmptyResponse>.self
        )

        guard response.isSuccess else {
            throw ShoppingCartServiceError.requestFailed(response.msg ?? "删除失败")
        }
    }
}

// MARK: - 购物车角标

/// 服务 Tab / 套餐选择页购物车入口的数量角标；失败时保留上次值
final class ShoppingCartBadgeStore: ObservableObject {

    static let shared = ShoppingCartBadgeStore()

    @Published private(set) var count: Int = 0

    private let shoppingCartService: ShoppingCartService
    private var refreshTask: Task<Void, Never>?

    private init(shoppingCartService: ShoppingCartService = .shared) {
        self.shoppingCartService = shoppingCartService
    }

    /// 角标文案；`nil` 表示隐藏
    static func displayText(for count: Int) -> String? {
        guard count > 0 else { return nil }
        return count > 99 ? "99+" : "\(count)"
    }

    func refresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            do {
                let n = try await self.shoppingCartService.getShoppingCartCount()
                guard !Task.isCancelled else { return }
                await MainActor.run { self.count = n }
            } catch {
                // 失败保留上次数量，不得用假数据
            }
        }
    }

    func reset() {
        refreshTask?.cancel()
        Task { @MainActor in
            self.count = 0
        }
    }
}

// MARK: - Error

enum ShoppingCartServiceError: LocalizedError {
    /// `saveShoppingCartOrPurchase` 业务码：已有未完成订单，禁止重复下单
    static let incompleteExistingOrderCode = "M0087"

    case invalidHospitalId
    case invalidPackageId
    case invalidCategoryServiceId
    case emptyDetails
    case missingSerialNumber
    case missingOrderId
    case requestFailed(String)
    /// `code == M0087`：`orderId` 取响应 `data`，文案取 `msg`
    case incompleteExistingOrder(orderId: Int64, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidHospitalId: return "机构信息缺失"
        case .invalidPackageId: return "套餐信息无效"
        case .invalidCategoryServiceId: return "套餐类别缺失"
        case .emptyDetails: return "套餐内容配置异常"
        case .missingSerialNumber: return "无法删除该商品"
        case .missingOrderId: return "未获取到订单号，请重试"
        case .requestFailed(let msg): return msg.isEmpty ? "操作失败" : msg
        case .incompleteExistingOrder(_, let message): return message
        }
    }
}

// MARK: - Encodable → [String: Any]

private extension Encodable {
    func asDict() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [:] }
        return dict
    }
}
