import Foundation

// MARK: - 字典查询请求

/// `POST /v1/dictionary/getDictionaryByParentId2` 请求体
struct DictionaryQueryBO: Encodable {
    let parentIds: [Int64]
    let allStatus: Bool
}

// MARK: - 字典项 DTO

/// 数据字典项 — Apifox: SDictionary
struct SDictionary: Decodable {
    let id: String
    let sortId: Int?
    let parentId: String?
    let name: String?
    let value: String?
    let description: String?
    let english: String?
    let status: Int?
    let children: [SDictionary]?

    private enum CodingKeys: String, CodingKey {
        case id, sortId, parentId, name, value, description, english, status, children
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.decodeFlexibleString(c, key: .id)
        sortId = try c.decodeIfPresent(Int.self, forKey: .sortId)
        parentId = Self.decodeFlexibleStringIfPresent(c, key: .parentId)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        value = try c.decodeIfPresent(String.self, forKey: .value)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        english = try c.decodeIfPresent(String.self, forKey: .english)
        status = try c.decodeIfPresent(Int.self, forKey: .status)
        children = try c.decodeIfPresent([SDictionary].self, forKey: .children)
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

    private static func decodeFlexibleStringIfPresent<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> String? {
        if let value = try? container.decodeIfPresent(String.self, forKey: key) { return value }
        if let value = try? container.decodeIfPresent(Int64.self, forKey: key) { return String(value) }
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) { return String(value) }
        return nil
    }
}

// MARK: - 产品矩阵映射

enum ProductMatrixMapper {

    private static let defaultAccentHex = "#FF7A50"

    static func toMatrixItems(_ dictionaries: [SDictionary]) -> [ProductMatrixItem] {
        productLineDictionaries(from: dictionaries)
            .filter { $0.status == nil || $0.status == 1 }
            .sorted { ($0.sortId ?? Int.max) < ($1.sortId ?? Int.max) }
            .map(toMatrixItem)
    }

    /// 接口返回父节点 + `children` 嵌套结构，取子节点作为产品线列表
    private static func productLineDictionaries(from dictionaries: [SDictionary]) -> [SDictionary] {
        let children = dictionaries.compactMap(\.children).flatMap { $0 }
        if !children.isEmpty { return children }
        return dictionaries
    }

    static func toMatrixItem(_ dict: SDictionary) -> ProductMatrixItem {
        let code = dict.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let displayName = nonEmpty(dict.description) ?? code

        return ProductMatrixItem(
            code: code,
            name: displayName,
            desc: "",
            tier: nonEmpty(dict.english) ?? "",
            accentHex: dict.value.flatMap(parseAccentHex) ?? defaultAccentHex,
            current: false
        )
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private static func parseAccentHex(_ value: String) -> String? {
        guard value.hasPrefix("#"), value.count >= 4 else { return nil }
        return value
    }
}
