import Foundation

// MARK: - 推荐服务类目（服务/商城模块）

/// 服务首页「推荐服务」Tab — 来自字典 `children`，字段与 `SDictionary` 对齐
struct ServiceRecommendCategory: Equatable {
    let id: String
    let sortId: Int?
    let parentId: String?
    let name: String?
    let value: String?
    let description: String?
    let english: String?
    let status: Int?

    /// Tab 展示文案：`name` → `description` → `value`
    var title: String {
        Self.nonEmpty(name) ?? Self.nonEmpty(description) ?? Self.nonEmpty(value) ?? id
    }

    /// 套包分页接口 `categoryServiceId`
    var categoryServiceId: String { id }

    /// 套包分页接口 `name` 查询参数
    var packageQueryName: String? {
        Self.nonEmpty(name)
    }

    /// 套包分页接口 `packageMainCategory`（字典 `value`）
    var packageMainCategory: String? {
        Self.nonEmpty(value)
    }

    /// 套包分页接口 `packageMainCategory`（后端要求 Integer）
    var packageMainCategoryInt: Int? {
        guard let raw = packageMainCategory else { return nil }
        return Int(raw)
    }

    /// 套包分页接口 `packageSeries`（字典 `english`）
    var packageSeries: String? {
        Self.nonEmpty(english)
    }

    var isEnabled: Bool {
        status == nil || status == 1
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}

// MARK: - 医院套包 DTO

/// `GET /v1/hospitalPackage/getEnabledHospitalPackagePage` 列表项
struct HospitalPackagePageVO: Decodable {
    /// 商品 / 套餐主键（详情接口 `packageId`）
    let id: String
    let name: String?
    let imageUrl: String?
    let price: Double?
    let introduction: String?
    let recommend: Int?

    private enum CodingKeys: String, CodingKey {
        case id, name, imageUrl, price, introduction, recommend
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.decodeFlexibleString(c, key: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
        price = try c.decodeIfPresent(Double.self, forKey: .price)
        introduction = try c.decodeIfPresent(String.self, forKey: .introduction)
        recommend = try c.decodeIfPresent(Int.self, forKey: .recommend)
    }

    private static func decodeFlexibleString<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> String {
        if let value = try? container.decode(String.self, forKey: key) { return value }
        if let value = try? container.decode(Int64.self, forKey: key) { return String(value) }
        if let value = try? container.decode(Int.self, forKey: key) { return String(value) }
        return ""
    }
}

/// 套包分页数据
struct PaginatedHospitalPackageData: Decodable {
    let totalRecords: Int?
    let pageSize: Int?
    let totalPages: Int?
    let currentPage: Int?
    let records: [HospitalPackagePageVO]?

    enum CodingKeys: String, CodingKey {
        case totalRecords = "totalCount"
        case pageSize
        case totalPages = "totalPage"
        case currentPage = "currPage"
        case records = "list"
    }
}

// MARK: - 零售业务分类

/// `GET /v1/hospitalPackage/getCategoryServiceListByType` 列表项
struct CategoryServiceListVO: Decodable {
    let id: String
    let serviceName: String?
    let imgUrl: String?

    private enum CodingKeys: String, CodingKey {
        case id, serviceName, imgUrl
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.decodeFlexibleString(c, key: .id)
        serviceName = try c.decodeIfPresent(String.self, forKey: .serviceName)
        imgUrl = try c.decodeIfPresent(String.self, forKey: .imgUrl)
    }

    private static func decodeFlexibleString<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> String {
        if let value = try? container.decode(String.self, forKey: key) { return value }
        if let value = try? container.decode(Int64.self, forKey: key) { return String(value) }
        if let value = try? container.decode(Int.self, forKey: key) { return String(value) }
        return ""
    }
}

enum CategoryServiceListMapper {

    static func toServiceListCategories(_ items: [CategoryServiceListVO]) -> [ServiceListCategory] {
        items.compactMap { vo in
            let id = vo.id.trimmingCharacters(in: .whitespacesAndNewlines)
            let title = vo.serviceName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !id.isEmpty, !title.isEmpty else { return nil }
            let imageUrl = vo.imgUrl?.trimmingCharacters(in: .whitespacesAndNewlines)
            return ServiceListCategory(
                id: id,
                title: title,
                imageUrl: imageUrl?.isEmpty == false ? imageUrl : nil
            )
        }
    }
}

enum HospitalPackageCategoryType {
    /// 医院服务
    static let hospitalService = 1
    /// 零售类（富德优选）
    static let retail = 2
}

// MARK: - 映射

enum ServiceRecommendCategoryMapper {

    static func toCategories(_ dictionaries: [SDictionary]) -> [ServiceRecommendCategory] {
        categoryDictionaries(from: dictionaries)
            .compactMap(toCategory)
            .filter(\.isEnabled)
            .sorted { ($0.sortId ?? Int.max) < ($1.sortId ?? Int.max) }
    }

    private static func categoryDictionaries(from dictionaries: [SDictionary]) -> [SDictionary] {
        let children = dictionaries.compactMap(\.children).flatMap { $0 }
        return children.isEmpty ? dictionaries : children
    }

    private static func toCategory(_ dict: SDictionary) -> ServiceRecommendCategory? {
        let id = dict.id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return nil }
        guard hasDisplayContent(dict) else { return nil }

        return ServiceRecommendCategory(
            id: id,
            sortId: dict.sortId,
            parentId: dict.parentId,
            name: dict.name,
            value: dict.value,
            description: dict.description,
            english: dict.english,
            status: dict.status
        )
    }

    private static func hasDisplayContent(_ dict: SDictionary) -> Bool {
        nonEmpty(dict.name) != nil
            || nonEmpty(dict.description) != nil
            || nonEmpty(dict.value) != nil
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}

enum HospitalPackageMapper {

    static func toPackageItem(_ vo: HospitalPackagePageVO, index: Int) -> HealthPackageItem {
        let packageName = nonEmpty(vo.name) ?? nonEmpty(vo.introduction) ?? "健康服务套餐"
        let intro = nonEmpty(vo.introduction) ?? ""
        let priceText = formatPrice(vo.price)
        let badge: String? = vo.recommend == 1 ? "推荐" : nil
        let packageId = nonEmpty(vo.id) ?? "hospital-pkg-\(index)"

        return HealthPackageItem(
            id: packageId,
            productCode: coverCode(from: packageName),
            name: packageName,
            subtitle: intro.isEmpty ? packageName : intro,
            price: priceText,
            badge: badge,
            accentHex: "#FF7A50",
            audienceTags: [],
            sortRank: index,
            imageUrl: nonEmpty(vo.imageUrl)
        )
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private static func coverCode(from name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 4 { return trimmed }
        return String(trimmed.prefix(2))
    }

    private static func formatPrice(_ price: Double?) -> String {
        guard let price else { return "面议" }
        if price == price.rounded() && price.truncatingRemainder(dividingBy: 1) == 0 {
            return "¥\(Int(price))"
        }
        return String(format: "¥%.2f", price)
    }
}
