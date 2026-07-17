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
    let imageUrl: String?

    var accent: UIColor { UIColor(hexString: accentHex) }
    var displayTitle: String { "\(productCode) · \(name)" }
}

// MARK: - 套餐详情（健康包组合）

/// 组合行 — 对齐 `health-packages.json` items / funde combo-row
struct ServicePackageComboItem: Equatable {
    let name: String
    let qty: String
    let unit: String
    let price: Int
    /// `defaultCheck == 1` 时默认选中（单选/可选）
    let defaultSelected: Bool
    /// 来自父节点 `children` 的子行，UI 需缩进
    let isChild: Bool

    init(
        name: String,
        qty: String,
        unit: String,
        price: Int,
        defaultSelected: Bool = false,
        isChild: Bool = false
    ) {
        self.name = name
        self.qty = qty
        self.unit = unit
        self.price = price
        self.defaultSelected = defaultSelected
        self.isChild = isChild
    }

    var qtyLabel: String {
        unit.isEmpty ? qty : "\(qty)\(unit)"
    }

    var priceLabel: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        let num = f.string(from: NSNumber(value: price)) ?? "\(price)"
        return "¥\(num)"
    }
}
/// 组合分组选择模式
enum ServicePackageSelectMode: String {
    case required = "强制"
    case radio = "单选"
    case checkbox = "多选"

    var displayLabel: String {
        switch self {
        case .required: return "必选"
        case .radio: return "单选"
        case .checkbox: return "可选"
        }
    }
}

struct ServicePackageComboGroup: Equatable {
    let name: String
    let selectMode: ServicePackageSelectMode
    let emoji: String
    let items: [ServicePackageComboItem]
}

struct ServicePackageTier: Equatable {
    let id: String
    let name: String
    let priceLabel: String
    let price: Int
    let priceUnit: String
    let groups: [ServicePackageComboGroup]
}

/// 服务套餐详情 — 对齐图示 + `getHospitalPackageDetail` / `HealthPackageDetailView`
struct ServicePackageDetail {
    let id: String
    let productCode: String
    let name: String
    let subtitle: String
    let category: String
    let tag: String
    let priceText: String
    let priceUnit: String
    let tags: [String]
    let detailText: String
    let detailImageURLs: [String]
    let carouselLabels: [String]
    let carouselImageURLs: [String]
    let tiers: [ServicePackageTier]
    let accentHex: String

    var accent: UIColor { UIColor(hexString: accentHex) }
    var displayName: String { name }

    init(
        id: String,
        productCode: String,
        name: String,
        subtitle: String,
        category: String,
        tag: String,
        priceText: String,
        priceUnit: String,
        tags: [String],
        detailText: String,
        detailImageURLs: [String] = [],
        carouselLabels: [String],
        carouselImageURLs: [String] = [],
        tiers: [ServicePackageTier],
        accentHex: String
    ) {
        self.id = id
        self.productCode = productCode
        self.name = name
        self.subtitle = subtitle
        self.category = category
        self.tag = tag
        self.priceText = priceText
        self.priceUnit = priceUnit
        self.tags = tags
        self.detailText = detailText
        self.detailImageURLs = detailImageURLs
        self.carouselLabels = carouselLabels
        self.carouselImageURLs = carouselImageURLs
        self.tiers = tiers
        self.accentHex = accentHex
    }
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
    let emoji: String
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
    let institution: ServiceInstitution
    let institutions: [ServiceInstitution]
    let banners: [ServiceHubBanner]
    let matrix: [ProductMatrixItem]
    let mallPreviewPackages: [HealthPackageItem]
}
