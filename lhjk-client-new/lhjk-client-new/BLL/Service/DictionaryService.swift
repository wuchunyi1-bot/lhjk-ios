import Foundation

// MARK: - 字典服务 (BLL)

/// 数据字典 — `POST /v1/dictionary/getDictionaryByParentId2`
///
/// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330853e0
final class DictionaryService {

    static let shared = DictionaryService()

    /// 德系 9 大产品线父级字典 ID
    static let productLineParentId: Int64 = 2_074_711_686_115_364_864

    /// 服务首页「推荐服务」/ 套餐列表健康管理类目父级字典 ID
    static let serviceRecommendCategoryParentId: Int64 = 2_074_711_807_339_139_072

    private init() {}

    /// 原始字典节点（含父节点与 children）
    func fetchNodes(
        parentId: Int64,
        allStatus: Bool = true
    ) async throws -> [SDictionary] {
        let response: APIResponse<[SDictionary]> = try await APIManager.shared.postAsync(
            path: "/v1/dictionary/getDictionaryByParentId2",
            parameters: [
                "parentIds": [parentId],
                "allStatus": allStatus,
            ],
            responseType: APIResponse<[SDictionary]>.self
        )

        guard response.isSuccess else {
            throw DictionaryServiceError.requestFailed(response.msg ?? "获取字典失败")
        }

        return response.data ?? []
    }

    /// 获取服务首页德系产品矩阵
    func fetchProductMatrix(
        parentId: Int64 = DictionaryService.productLineParentId,
        allStatus: Bool = true
    ) async throws -> [ProductMatrixItem] {
        let response: APIResponse<[SDictionary]> = try await APIManager.shared.postAsync(
            path: "/v1/dictionary/getDictionaryByParentId2",
            parameters: [
                "parentIds": [parentId],
                "allStatus": allStatus,
            ],
            responseType: APIResponse<[SDictionary]>.self
        )

        guard response.isSuccess else {
            throw DictionaryServiceError.requestFailed(response.msg ?? "获取产品矩阵失败")
        }

        return ProductMatrixMapper.toMatrixItems(response.data ?? [])
    }

    /// 获取服务首页「推荐服务」类目 Tab
    func fetchRecommendCategories(
        parentId: Int64 = DictionaryService.serviceRecommendCategoryParentId,
        allStatus: Bool = true
    ) async throws -> [ServiceRecommendCategory] {
        let response: APIResponse<[SDictionary]> = try await APIManager.shared.postAsync(
            path: "/v1/dictionary/getDictionaryByParentId2",
            parameters: [
                "parentIds": [parentId],
                "allStatus": allStatus,
            ],
            responseType: APIResponse<[SDictionary]>.self
        )

        guard response.isSuccess else {
            throw DictionaryServiceError.requestFailed(response.msg ?? "获取推荐服务类目失败")
        }

        return ServiceRecommendCategoryMapper.toCategories(response.data ?? [])
    }
}

enum DictionaryServiceError: LocalizedError {
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .requestFailed(let message): return message
        }
    }
}
