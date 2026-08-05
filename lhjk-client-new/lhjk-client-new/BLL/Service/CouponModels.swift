import Foundation

// MARK: - 优惠券领用 DTO
// Apifox: GET /v1/couponTake/getCouponTakeList
// https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330752e0.md

/// 优惠券领用记录 `CouponTaskListBO` / `MCouponTake`
struct CouponTakeItem: Decodable, Identifiable, Equatable {
    let id: Int64?
    let couponId: Int64?
    let name: String?
    let type: Int?
    let amount: Double?
    let couponAmount: Double?
    let discountRatio: Double?
    let conditionPrice: Double?
    let beginTime: String?
    let endTime: String?
    let getTime: String?
    let status: Int?
    /// 1：适用范围，0：不适用范围
    let rule: Int?
    let description: String?
    let categoryServiceName: String?
    /// 多个名称顿号分隔
    let packageNames: String?
    let hospitalNames: String?
    let commodityNames: String?

    private enum CodingKeys: String, CodingKey {
        case id, couponId, name, type, amount, couponAmount, discountRatio
        case conditionPrice, beginTime, endTime, getTime, status, rule
        case description, categoryServiceName, packageNames, hospitalNames, commodityNames
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.decodeFlexibleInt64(c, key: .id)
        couponId = Self.decodeFlexibleInt64(c, key: .couponId)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        type = HospitalPackageInt.decodeIfPresent(c, key: .type)
        amount = Self.decodeFlexibleDouble(c, key: .amount)
        couponAmount = Self.decodeFlexibleDouble(c, key: .couponAmount)
        discountRatio = Self.decodeFlexibleDouble(c, key: .discountRatio)
        conditionPrice = Self.decodeFlexibleDouble(c, key: .conditionPrice)
        beginTime = try c.decodeIfPresent(String.self, forKey: .beginTime)
        endTime = try c.decodeIfPresent(String.self, forKey: .endTime)
        getTime = try c.decodeIfPresent(String.self, forKey: .getTime)
        status = HospitalPackageInt.decodeIfPresent(c, key: .status)
        rule = HospitalPackageInt.decodeIfPresent(c, key: .rule)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        categoryServiceName = try c.decodeIfPresent(String.self, forKey: .categoryServiceName)
        packageNames = try c.decodeIfPresent(String.self, forKey: .packageNames)
        hospitalNames = try c.decodeIfPresent(String.self, forKey: .hospitalNames)
        commodityNames = try c.decodeIfPresent(String.self, forKey: .commodityNames)
    }

    var displayName: String {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "优惠券" : trimmed
    }

    var discountAmount: Double {
        // 减价券优先 couponAmount；其余用 amount（订单选券抵扣展示同源）
        if type == 2 {
            return max(0, couponAmount ?? amount ?? 0)
        }
        return max(0, amount ?? 0)
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

    /// 映射为卡包列表 UI 模型
    func toVoucherAsset() -> VoucherCouponAsset {
        let assetId: String
        if let id {
            assetId = String(id)
        } else if let couponId {
            assetId = "coupon-\(couponId)"
        } else {
            assetId = "coupon-\(displayName)-\(endTime ?? "")"
        }

        let mappedType = Self.mapType(type)
        let amountValue: Double? = mappedType == .discount ? nil : discountAmount
        let rateValue: Double? = mappedType == .discount ? Self.mapDiscountRate(discountRatio) : nil

        return VoucherCouponAsset(
            id: assetId,
            name: displayName,
            type: mappedType,
            threshold: thresholdAmount,
            discountAmount: amountValue,
            discountRate: rateValue,
            maxDiscount: nil,
            scopeRule: (rule == 0) ? .exclude : .include,
            businessCategories: Self.splitNames(categoryServiceName),
            packageNames: Self.splitNames(packageNames),
            institutionNames: Self.splitNames(hospitalNames),
            excludedProductNames: Self.splitNames(commodityNames),
            ruleDescription: Self.trimmedOrNil(description),
            receivedAt: Self.displayDateTime(getTime) ?? getTime ?? beginTime ?? "",
            effectiveEndAt: Self.displayDateTime(endTime) ?? endTime ?? "",
            status: Self.mapStatus(status),
            usedAt: nil
        )
    }

    private static func mapType(_ type: Int?) -> VoucherCouponType {
        switch type {
        case 2: return .priceOff
        case 3: return .discount
        default: return .fullReduction
        }
    }

    /// 响应 status：1 已领取 / 2 已使用 / 3 已过期
    private static func mapStatus(_ status: Int?) -> VoucherCouponStatus {
        switch status {
        case 2: return .used
        case 3: return .expired
        default: return .received
        }
    }

    /// 折扣比例：≤1 视为小数（0.88 → 8.8 折），否则按折数展示
    private static func mapDiscountRate(_ ratio: Double?) -> Double? {
        guard let ratio, ratio > 0 else { return nil }
        if ratio <= 1 {
            return (ratio * 10 * 100).rounded() / 100
        }
        return ratio
    }

    private static func splitNames(_ raw: String?) -> [String] {
        guard let raw else { return [] }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return trimmed
            .components(separatedBy: CharacterSet(charactersIn: "、,"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func trimmedOrNil(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    /// 将接口 date-time 格式化为展示串；解析失败则原样返回
    private static func displayDateTime(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let parsers: [DateFormatter] = {
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                "yyyy-MM-dd'T'HH:mm:ss",
                "yyyy-MM-dd HH:mm:ss",
                "yyyy-MM-dd",
            ]
            return formats.map { format in
                let f = DateFormatter()
                f.locale = Locale(identifier: "en_US_POSIX")
                f.dateFormat = format
                return f
            }
        }()

        let date = parsers.compactMap { $0.date(from: trimmed) }.first
            ?? ISO8601DateFormatter().date(from: trimmed)
        guard let date else { return trimmed }

        let out = DateFormatter()
        out.locale = Locale(identifier: "en_US_POSIX")
        out.dateFormat = "yyyy-MM-dd HH:mm"
        return out.string(from: date)
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
        // 部分网关可能用中文键（Apifox schema）
        case totalRecordsCN = "总记录数"
        case pageSizeCN = "每页记录数"
        case totalPagesCN = "总页数"
        case currentPageCN = "当前页数"
        case recordsCN = "数据集合"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalRecords = Self.decodeInt(c, .totalRecords) ?? Self.decodeInt(c, .totalRecordsCN)
        pageSize = Self.decodeInt(c, .pageSize) ?? Self.decodeInt(c, .pageSizeCN)
        totalPages = Self.decodeInt(c, .totalPages) ?? Self.decodeInt(c, .totalPagesCN)
        currentPage = Self.decodeInt(c, .currentPage) ?? Self.decodeInt(c, .currentPageCN)
        records = (try? c.decodeIfPresent([CouponTakeItem].self, forKey: .records))
            ?? (try? c.decodeIfPresent([CouponTakeItem].self, forKey: .recordsCN))
    }

    private static func decodeInt(
        _ c: KeyedDecodingContainer<CodingKeys>,
        _ key: CodingKeys
    ) -> Int? {
        if let v = try? c.decodeIfPresent(Int.self, forKey: key) { return v }
        if let s = try? c.decodeIfPresent(String.self, forKey: key) {
            return Int(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}

/// 领用列表查询结果（含总数，供角标）
struct CouponTakeListResult {
    let items: [CouponTakeItem]
    let total: Int
}
