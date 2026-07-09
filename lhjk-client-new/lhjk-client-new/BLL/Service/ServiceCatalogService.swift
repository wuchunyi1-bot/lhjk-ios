import Foundation

// MARK: - 服务目录服务 (BLL)

/// 服务首页快照组装 — 机构/商城列表待后端 API，已接真实接口的数据不得使用 mock。
final class ServiceCatalogService {

    static let shared = ServiceCatalogService()

    private static let placeholderInstitution = ServiceInstitution(
        id: "placeholder",
        name: "服务",
        hospitalId: nil
    )

    private init() {}

    // MARK: - Hub

    func loadHubSnapshot(
        cardActivated: Bool,
        banners: [ServiceHubBanner],
        matrix: [ProductMatrixItem],
        categories: [ServiceRecommendCategory],
        selectedCategoryId: String,
        recommendedPackages: [HealthPackageItem]
    ) -> ServiceHubSnapshot {
        ServiceHubSnapshot(
            showActivateBanner: !cardActivated,
            institution: Self.placeholderInstitution,
            institutions: [],
            banners: banners,
            matrix: matrix,
            categories: categories,
            selectedCategoryId: selectedCategoryId,
            recommendedPackages: recommendedPackages
        )
    }

    /// 富德优选商品 — 待商城商品 API，当前返回空列表
    func loadMallProducts() -> [MallProduct] {
        []
    }

    /// 当前选中机构的后端 `hospitalId`；机构列表 API 接入前恒为 `nil`
    func selectedApiHospitalId() -> String? {
        Self.validApiHospitalId(Self.placeholderInstitution.hospitalId)
    }

    /// 仅当值为非空纯数字字符串时才可作为 API `hospitalId`（后端 `Long`）
    static func validApiHospitalId(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        guard trimmed.allSatisfy(\.isNumber) else { return nil }
        return trimmed
    }
}
