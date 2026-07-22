import Foundation

// MARK: - 优惠券领用 DTO
// Apifox: GET /v1/couponTake/getCouponTakeList

/// 优惠券领用记录 `CouponTaskListBO` / `MCouponTake`
struct CouponTakeItem: Decodable, Identifiable, Equatable {
    let id: Int64?
    let couponId: Int64?
    let name: String?
    let type: Int?
    let amount: Double?
    let discountRatio: Double?
    let conditionPrice: Double?
    let beginTime: String?
    let endTime: String?
    let status: Int?

    private enum CodingKeys: String, CodingKey {
        case id, couponId, name, type, amount, discountRatio
        case conditionPrice, beginTime, endTime, status
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.decodeFlexibleInt64(c, key: .id)
        couponId = Self.decodeFlexibleInt64(c, key: .couponId)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        type = HospitalPackageInt.decodeIfPresent(c, key: .type)
        amount = Self.decodeFlexibleDouble(c, key: .amount)
        discountRatio = Self.decodeFlexibleDouble(c, key: .discountRatio)
        conditionPrice = Self.decodeFlexibleDouble(c, key: .conditionPrice)
        beginTime = try c.decodeIfPresent(String.self, forKey: .beginTime)
        endTime = try c.decodeIfPresent(String.self, forKey: .endTime)
        status = HospitalPackageInt.decodeIfPresent(c, key: .status)
    }

    var displayName: String {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "优惠券" : trimmed
    }

    var discountAmount: Double {
        max(0, amount ?? 0)
    }

    var thresholdAmount: Double {
        max(0, conditionPrice ?? 0)
    }

    var subtitle: String {
        if thresholdAmount > 0 {
            return String(format: "满 ¥%.2f 可用", thresholdAmount)
        }
        return "无门槛"
    }

    private static func decodeFlexibleInt64<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> Int64? {
        if let v = try? container.decodeIfPresent(Int64.self, forKey: key) { return v }
        if let s = try? container.decodeIfPresent(String.self, forKey: key) {
            return Int64(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    private static func decodeFlexibleDouble<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> Double? {
        if let v = try? container.decodeIfPresent(Double.self, forKey: key) { return v }
        if let v = try? container.decodeIfPresent(Int.self, forKey: key) { return Double(v) }
        if let s = try? container.decodeIfPresent(String.self, forKey: key) {
            return Double(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}

/// 优惠券领用分页数据
struct PaginatedCouponTakeData: Decodable {
    let totalRecords: Int?
    let pageSize: Int?
    let totalPages: Int?
    let currentPage: Int?
    let records: [CouponTakeItem]?

    enum CodingKeys: String, CodingKey {
        case totalRecords = "totalCount"
        case pageSize
        case totalPages = "totalPage"
        case currentPage = "currPage"
        case records = "list"
    }
}
