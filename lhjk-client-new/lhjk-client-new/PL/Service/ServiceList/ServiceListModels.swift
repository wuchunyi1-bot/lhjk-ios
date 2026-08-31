import UIKit

/// 套餐列表左栏类目 — `getCategoryServiceListByType` / `getEnabledHospitalPackageListByCategory`
struct ServiceListCategory: Equatable, Identifiable {
    let id: String
    let title: String
    let imageUrl: String?
}

/// 右栏扁平套餐行（含所属业务类别 id）
struct ServiceListPackageRow: Equatable {
    let item: HealthPackageItem
    let categoryServiceId: String
}

/// 右栏按类目分组：header + 套餐卡片
struct ServiceListPackageSection: Equatable {
    let category: ServiceListCategory
    let rows: [ServiceListPackageRow]
}

/// 列表页机构展示（机构 API 未接时的默认态）
struct ServiceListInstitutionDisplay: Equatable {
    let name: String
    let typeLabel: String
    let address: String
    let distance: String

    static let `default` = ServiceListInstitutionDisplay(
        name: "富德联好健康",
        typeLabel: "品牌机构",
        address: "全国服务网络",
        distance: "距离最近"
    )
}

struct SvcPkg {
    let id: String
    let productCode: String
    let name: String
    let subtitle: String
    let price: String
    let priceUnit: String
    let tag: String
    let benefits: [String]
    let audience: [String]
    let detail: String
}

struct SvcMatrix {
    let code: String
    let name: String
    let desc: String
    let tier: String
    let accent: UIColor
    let current: Bool
}
