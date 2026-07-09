import Foundation

// MARK: - 展示位内容 DTO

/// `GET /v1/columnContent/getByCode` 响应 `data[]` 元素
/// Apifox: ColumnContentBo
///
/// 注意：后端 `id` / `contentId` 为雪花 ID，JSON 中可能为 String 或 Number，需兼容解码。
struct ColumnContentDTO: Decodable {
    let id: String
    let contentId: String
    let contentType: Int
    let name: String?
    let imageUrl: String?
    let categoryName: String?
    let status: Int?

    private enum CodingKeys: String, CodingKey {
        case id, contentId, contentType, name, imageUrl, categoryName, status
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.decodeFlexibleString(c, key: .id)
        contentId = Self.decodeFlexibleString(c, key: .contentId)
        contentType = try c.decode(Int.self, forKey: .contentType)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
        categoryName = try c.decodeIfPresent(String.self, forKey: .categoryName)
        status = try c.decodeIfPresent(Int.self, forKey: .status)
    }

    /// 兼容 String / Int64 雪花 ID
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

// MARK: - 跳转类型

/// 广告跳转类型，对应 `c_advertisement.content_type`
enum ColumnContentJumpType: Int {
    case advertisement = 1
    case product = 2
    case package = 3
    case activity = 4
    case article = 5
}

struct ColumnContentRoute {
    let path: String
    let paramId: String?
}

enum ColumnContentMapper {

    /// 将 API 记录映射为 Hub 轮播模型
    static func toHubBanner(_ dto: ColumnContentDTO) -> ServiceHubBanner {
        let route = resolveRoute(contentType: dto.contentType, contentId: dto.contentId)
        return ServiceHubBanner(
            id: dto.id,
            title: dto.name ?? "",
            subtitle: dto.categoryName ?? "",
            imageUrl: dto.imageUrl,
            codeLabel: nil,
            backgroundHex: "#FFF3EE",
            accentHex: "#FF7A50",
            routePath: route?.path,
            routeParamId: route?.paramId
        )
    }

    static func resolveRoute(contentType: Int, contentId: String) -> ColumnContentRoute? {
        guard !contentId.isEmpty else { return nil }
        switch ColumnContentJumpType(rawValue: contentType) {
        case .advertisement:
            return nil
        case .product:
            return ColumnContentRoute(path: "/mall/detail", paramId: contentId)
        case .package:
            return ColumnContentRoute(path: "/services/pkg", paramId: contentId)
        case .activity:
            return ColumnContentRoute(path: "/services/detail", paramId: contentId)
        case .article, .none:
            return nil
        }
    }
}
