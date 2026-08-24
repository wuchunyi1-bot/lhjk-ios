import Foundation

// MARK: - 展示位内容 DTO

/// `GET /v1/columnContent/getByCode` 响应 `data[]` 元素
/// Apifox: ColumnContentBo
///
/// 注意：后端 `id` / `contentId` / `param` 为雪花 ID，JSON 中可能为 String 或 Number，需兼容解码。
struct ColumnContentDTO: Decodable {
    let id: String
    let contentId: String
    let contentType: Int
    let name: String?
    let imageUrl: String?
    let categoryName: String?
    let status: Int?
    let pageUrl: String?
    let param: String?
    let detail: ColumnContentDetailDTO?

    private enum CodingKeys: String, CodingKey {
        case id, contentId, contentType, name, imageUrl, categoryName, status
        case pageUrl, param, detail
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
        pageUrl = try c.decodeIfPresent(String.self, forKey: .pageUrl)
        param = Self.decodeOptionalFlexibleString(c, key: .param)
        detail = try c.decodeIfPresent(ColumnContentDetailDTO.self, forKey: .detail)
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

    private static func decodeOptionalFlexibleString<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> String? {
        let value = decodeFlexibleString(container, key: key)
        return value.isEmpty ? nil : value
    }
}

/// Apifox: ColumnContentDetailBo
struct ColumnContentDetailDTO: Decodable {
    let adContentType: Int?
    let pageUrl: String?
    let param: String?
    let description: String?
    let recommend: String?
    let contentUrl: String?
    let authorName: String?
    let contentDuration: Int?
    let clickCount: Int?
    let likeCount: Int?
    let categoryName: String?
    let labelName: String?

    private enum CodingKeys: String, CodingKey {
        case adContentType, pageUrl, param, description, recommend, contentUrl
        case authorName, contentDuration, clickCount, likeCount, categoryName, labelName
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        adContentType = try c.decodeIfPresent(Int.self, forKey: .adContentType)
        pageUrl = try c.decodeIfPresent(String.self, forKey: .pageUrl)
        param = Self.decodeOptionalFlexibleString(c, key: .param)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        recommend = try c.decodeIfPresent(String.self, forKey: .recommend)
        contentUrl = try c.decodeIfPresent(String.self, forKey: .contentUrl)
        authorName = try c.decodeIfPresent(String.self, forKey: .authorName)
        contentDuration = try c.decodeIfPresent(Int.self, forKey: .contentDuration)
        clickCount = try c.decodeIfPresent(Int.self, forKey: .clickCount)
        likeCount = try c.decodeIfPresent(Int.self, forKey: .likeCount)
        categoryName = try c.decodeIfPresent(String.self, forKey: .categoryName)
        labelName = try c.decodeIfPresent(String.self, forKey: .labelName)
    }

    private static func decodeOptionalFlexibleString<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> String? {
        if let value = try? container.decode(String.self, forKey: key) {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if let value = try? container.decode(Int64.self, forKey: key) { return String(value) }
        if let value = try? container.decode(Int.self, forKey: key) { return String(value) }
        return nil
    }
}

// MARK: - 跳转类型

/// 广告跳转类型，对应 `c_advertisement.content_type` / detail.adContentType
enum ColumnContentJumpType: Int {
    case advertisement = 1
    case product = 2
    case package = 3
    case activity = 4
    case article = 5
    /// 套餐中间页 H5（`#/package/bridge?packageId=`）
    case packageBridge = 6
}

struct ColumnContentRoute {
    let path: String
    let paramId: String?
}

enum ColumnContentMapper {

    /// 将 API 记录映射为 Hub 轮播 / 栏位通用模型
    static func toHubBanner(_ dto: ColumnContentDTO) -> ServiceHubBanner {
        let paramId = nonEmpty(dto.param)
            ?? nonEmpty(dto.detail?.param)
            ?? nonEmpty(dto.contentId)
        let contentId = nonEmpty(dto.contentId)
            ?? nonEmpty(dto.param)
            ?? nonEmpty(dto.detail?.param)
        let route = resolveRoute(contentType: dto.contentType, contentId: paramId ?? "")
        let pageUrl = firstNonEmpty([dto.pageUrl, dto.detail?.pageUrl])
        let contentUrl = nonEmpty(dto.detail?.contentUrl)
        return ServiceHubBanner(
            id: dto.id,
            title: dto.name ?? "",
            subtitle: dto.categoryName ?? dto.detail?.categoryName ?? "",
            imageUrl: dto.imageUrl,
            codeLabel: nil,
            backgroundHex: "#FFF3EE",
            accentHex: "#FF7A50",
            routePath: route?.path,
            routeParamId: route?.paramId ?? paramId,
            contentType: dto.contentType,
            authorName: nonEmpty(dto.detail?.authorName),
            clickCount: dto.detail?.clickCount,
            labelName: nonEmpty(dto.detail?.labelName)
                ?? nonEmpty(dto.detail?.categoryName)
                ?? nonEmpty(dto.categoryName),
            contentId: contentId,
            pageUrl: pageUrl,
            contentUrl: contentUrl
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
        case .packageBridge:
            return ColumnContentRoute(path: "/package/bridge", paramId: contentId)
        case .article, .none:
            return nil
        }
    }

    static func formatReadCount(_ count: Int?) -> String {
        guard let count, count >= 0 else { return "" }
        if count >= 10_000 {
            let v = Double(count) / 10_000.0
            return String(format: "%.1f万 阅读", v)
        }
        if count >= 1000 {
            let v = Double(count) / 1000.0
            return String(format: "%.1fK 阅读", v)
        }
        return "\(count) 阅读"
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private static func firstNonEmpty(_ values: [String?]) -> String? {
        for value in values {
            if let v = nonEmpty(value) { return v }
        }
        return nil
    }
}
