import UIKit

// MARK: - 服务机构

/// 服务机构，对应 `ServicesView.vue` → `serviceInstitutions`
struct ServiceInstitution {
    let id: String
    let name: String
    /// 后端医院 id（`Long` 字符串）；无真实医院数据时为 `nil`
    let hospitalId: String?
}

// MARK: - 推荐健康包

/// 推荐服务健康包，对应 `health-package-source` + `services.json` packages
struct HealthPackageItem {
    let id: String
    let productCode: String
    let name: String
    let subtitle: String
    let price: String
    let badge: String?
    let accentHex: String
    let audienceTags: [String]
    let sortRank: Int

    var accent: UIColor { UIColor(hexString: accentHex) }
    var displayTitle: String { "\(productCode) · \(name)" }
}

// MARK: - 产品矩阵

/// 德系 9 大产品线，对应 `services.json` → `matrix[]`
struct ProductMatrixItem {
    let code: String
    let name: String
    let desc: String
    let tier: String
    let accentHex: String
    let current: Bool

    var accent: UIColor { UIColor(hexString: accentHex) }
}

// MARK: - 商城商品

/// 富德优选商品，对应 `services.json` → `mall[]`
struct MallProduct {
    let id: String
    let name: String
    let desc: String
    let price: String
    let unit: String
    let tag: String
    let accentHex: String
    let category: String

    var accent: UIColor { UIColor(hexString: accentHex) }
}

// MARK: - Hub 轮播

/// 服务首页运营 Banner — API `columnContent/getByCode`
struct ServiceHubBanner {
    let id: String
    let title: String
    let subtitle: String
    let imageUrl: String?
    let codeLabel: String?
    let backgroundHex: String
    let accentHex: String
    let routePath: String?
    let routeParamId: String?

    var background: UIColor { UIColor(hexString: backgroundHex) }
    var accent: UIColor { UIColor(hexString: accentHex) }
    var hasImage: Bool { !(imageUrl?.isEmpty ?? true) }
}

// MARK: - Hub 快照

/// 服务首页一次性加载的数据快照
struct ServiceHubSnapshot {
    let showActivateBanner: Bool
    let institution: ServiceInstitution
    let institutions: [ServiceInstitution]
    let banners: [ServiceHubBanner]
    let matrix: [ProductMatrixItem]
    let categories: [ServiceRecommendCategory]
    let selectedCategoryId: String
    let recommendedPackages: [HealthPackageItem]

    var categoryTitles: [String] { categories.map(\.title) }

    var selectedCategoryTitle: String? {
        categories.first { $0.id == selectedCategoryId }?.title
    }
}
