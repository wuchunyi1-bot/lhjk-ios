import Foundation

// MARK: - 收货地址模型 (Codable)

/// 收货地址完整模型，对应后端 `MAddress` schema
///
/// snake_case JSON key 由 `APIManager.jsonDecoder` 自动转换（keyDecodingStrategy = .convertFromSnakeCase）
/// 注意：后端 id/userId/createId/modifyId 可能返回 String，需要兼容解码
struct MAddress: Codable {
    /// 主键（新增时不传，修改时必传）
    let id: Int64?
    /// 用户 ID
    let userId: Int64?
    /// 收货人名称
    let name: String?
    /// 收货人电话
    let mobile: String?
    /// 是否默认地址（1=是，0=否）
    let isDefault: Int?
    /// 所在省份
    let province: String?
    /// 所在城市
    let city: String?
    /// 所在区
    let area: String?
    /// 详细地址
    let address: String?
    /// 邮政编码
    let code: String?
    /// 创建时间
    let createTime: String?
    /// 创建人 ID
    let createId: Int64?
    /// 修改时间
    let modifyTime: String?
    /// 修改人 ID
    let modifyId: Int64?

    /// 拼接完整地址字符串
    var fullAddress: String {
        let parts = [province, city, area, address].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.joined()
    }

    /// 是否默认地址
    var isDefaultAddress: Bool { isDefault == 1 }

    // MARK: - 兼容 String/Int64 解码

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = Self.decodeFlexibleInt64(c, key: .id)
        userId      = Self.decodeFlexibleInt64(c, key: .userId)
        name        = try c.decodeIfPresent(String.self, forKey: .name)
        mobile      = try c.decodeIfPresent(String.self, forKey: .mobile)
        isDefault   = try c.decodeIfPresent(Int.self, forKey: .isDefault)
        province    = try c.decodeIfPresent(String.self, forKey: .province)
        city        = try c.decodeIfPresent(String.self, forKey: .city)
        area        = try c.decodeIfPresent(String.self, forKey: .area)
        address     = try c.decodeIfPresent(String.self, forKey: .address)
        code        = try c.decodeIfPresent(String.self, forKey: .code)
        createTime  = try c.decodeIfPresent(String.self, forKey: .createTime)
        createId    = Self.decodeFlexibleInt64(c, key: .createId)
        modifyTime  = try c.decodeIfPresent(String.self, forKey: .modifyTime)
        modifyId    = Self.decodeFlexibleInt64(c, key: .modifyId)
    }

    /// 兼容解码 Int64 字段：先尝试 Int64，失败则尝试 String 再转 Int64
    private static func decodeFlexibleInt64<K: CodingKey>(_ container: KeyedDecodingContainer<K>, key: K) -> Int64? {
        if let v = try? container.decodeIfPresent(Int64.self, forKey: key) { return v }
        if let s = try? container.decodeIfPresent(String.self, forKey: key) { return Int64(s) }
        return nil
    }
}

// MARK: - 地址分页数据

/// 分页地址列表数据，对应 `GET /mobile/v1/address/getAddressList` 的 `data` 字段
struct PaginatedAddressData: Decodable {
    /// 总记录数
    let totalRecords: Int?
    /// 每页记录数
    let pageSize: Int?
    /// 总页数
    let totalPages: Int?
    /// 当前页数
    let currentPage: Int?
    /// 地址列表
    let records: [MAddress]?

    enum CodingKeys: String, CodingKey {
        case totalRecords = "totalCount"
        case pageSize
        case totalPages = "totalPage"
        case currentPage = "currPage"
        case records = "list"
    }
}

// MARK: - 地址保存请求体 (Encodable)

/// 新增/修改地址请求体，对应 `POST /mobile/v1/address/saveOrUpdateAddress`
struct AddressSavePayload: Encodable {
    /// 主键（修改时传入，新增时为 nil）
    var id: Int64?
    /// 收货人名称
    var name: String
    /// 收货人电话
    var mobile: String
    /// 是否默认（1=是，0=否）
    var isDefault: Int
    /// 所在省份
    var province: String
    /// 所在城市
    var city: String
    /// 所在区
    var area: String
    /// 详细地址
    var address: String
    /// 邮政编码
    var code: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case mobile
        case isDefault
        case province
        case city
        case area
        case address
        case code
    }
}
