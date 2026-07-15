import Foundation

// MARK: - 零售类目解析 (BLL)

/// 富德优选零售套包 — 从字典解析「电商零售」二级业务分类的 `value`（Integer）作为 `packageMainCategory`
final class RetailCategoryService {

    static let shared = RetailCategoryService()

    private let dictionaryService: DictionaryService
    private var cachedCategory: ServiceRecommendCategory?

    init(dictionaryService: DictionaryService = .shared) {
        self.dictionaryService = dictionaryService
    }

    func invalidate() {
        cachedCategory = nil
    }

    /// 解析可用于套包分页的零售类目（带数值 `packageMainCategory`）
    func resolvePackageCategory() async throws -> ServiceRecommendCategory {
        if let cachedCategory, cachedCategory.packageMainCategoryInt != nil {
            return cachedCategory
        }

        let category = try await discoverRetailCategory()
        cachedCategory = category
        return category
    }

    // MARK: - Private

    private func discoverRetailCategory() async throws -> ServiceRecommendCategory {
        if let fromRetailTree = try await fetchRetailSecondaryCategory() {
            return fromRetailTree
        }
        throw RetailCategoryServiceError.unresolved
    }

    /// 通过健康管理节点反查业务分类根 → 电商零售一级 → 二级类目
    private func fetchRetailSecondaryCategory() async throws -> ServiceRecommendCategory? {
        let healthNodes = try await dictionaryService.fetchNodes(
            parentId: DictionaryService.serviceRecommendCategoryParentId
        )
        guard let healthRoot = healthNodes.first else { return nil }

        guard let businessRootId = Self.nonEmpty(healthRoot.parentId),
              let businessRootParentId = Int64(businessRootId) else {
            return nil
        }

        let businessRootNodes = try await dictionaryService.fetchNodes(parentId: businessRootParentId)
        let primaryCategories = Self.primaryNodes(from: businessRootNodes)

        guard let retailPrimary = primaryCategories.first(where: { Self.isRetailPrimary($0) }),
              let retailPrimaryId = Int64(retailPrimary.id.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }

        let retailNodes = try await dictionaryService.fetchNodes(parentId: retailPrimaryId)
        let retailCategories = ServiceRecommendCategoryMapper.toCategories(retailNodes)
        return retailCategories.first { $0.packageMainCategoryInt != nil }
    }

    private static func primaryNodes(from nodes: [SDictionary]) -> [SDictionary] {
        let children = nodes.compactMap(\.children).flatMap { $0 }
        return children.isEmpty ? nodes : children
    }

    private static func isRetailPrimary(_ node: SDictionary) -> Bool {
        let name = node.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name == "电商零售"
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}

enum RetailCategoryServiceError: LocalizedError {
    case unresolved

    var errorDescription: String? {
        switch self {
        case .unresolved:
            return "未找到电商零售字典类目，无法查询零售套包"
        }
    }
}
