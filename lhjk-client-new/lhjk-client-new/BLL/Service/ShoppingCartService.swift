import Foundation

// MARK: - 购物车 / 一键购买 (BLL · 服务·商城)

/// 购物车：加购 / 立即购买 / 列表 / 删除
/// - 加购：https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330718e0.md
/// - 列表：https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330722e0.md
/// - 删除：https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330724e0.md
final class ShoppingCartService {

    static let shared = ShoppingCartService()

    private init() {
        // 清掉旧版本地购物车 mock / 持久化残留
        UserDefaults.standard.removeObject(forKey: "service.cart.items.v1")
        UserDefaults.standard.removeObject(forKey: "service.cart.seeded.v1")
    }

    /// 添加购物车（flag=2）或立即购买（flag=1）
    @discardableResult
    func saveShoppingCartOrPurchase(_ request: SaveShoppingCartRequest) async throws -> EmptyResponse? {
        let response: APIResponse<EmptyResponse> = try await APIManager.shared.postAsync(
            path: "/v1/shoppingCart/saveShoppingCartOrPurchase",
            parameters: request.asDict(),
            responseType: APIResponse<EmptyResponse>.self
        )

        guard response.isSuccess else {
            throw ShoppingCartServiceError.requestFailed(response.msg ?? "操作失败")
        }
        return response.data
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

// MARK: - Error

enum ShoppingCartServiceError: LocalizedError {
    case invalidHospitalId
    case invalidPackageId
    case invalidCategoryServiceId
    case emptyDetails
    case missingSerialNumber
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidHospitalId: return "机构信息缺失"
        case .invalidPackageId: return "套餐信息无效"
        case .invalidCategoryServiceId: return "套餐类别缺失"
        case .emptyDetails: return "套餐内容配置异常"
        case .missingSerialNumber: return "无法删除该商品"
        case .requestFailed(let msg): return msg.isEmpty ? "操作失败" : msg
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
