import Foundation

// MARK: - 套餐详情 DTO
// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/485486161e0

/// `GET /v1/hospitalPackage/getHospitalPackageDetail` → `data`
struct HospitalPackageDetailBO: Decodable {
    let packageInfo: MPackageVO?
    let packageHospitalDetailList: [PackageHospitalDetailListBO]?
    let bannerList: [String]?
}

/// 套餐主信息 `MPackage`
struct MPackageVO: Decodable {
    let id: String
    let name: String?
    let imageUrl: String?
    let packageCarousel: String?
    let imageDetailsUrl1: String?
    let imageDetailsUrl2: String?
    let imageDetailsUrl3: String?
    let introduction: String?
    let price: Double?
    let recommend: Int?
    let description: String?
    let applicablePeople: String?
    let categoryServiceName: String?

    private enum CodingKeys: String, CodingKey {
        case id, name, imageUrl, packageCarousel
        case imageDetailsUrl1, imageDetailsUrl2, imageDetailsUrl3
        case introduction, price, recommend, description
        case applicablePeople, categoryServiceName
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = HospitalPackageID.decode(c, key: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
        packageCarousel = try c.decodeIfPresent(String.self, forKey: .packageCarousel)
        imageDetailsUrl1 = try c.decodeIfPresent(String.self, forKey: .imageDetailsUrl1)
        imageDetailsUrl2 = try c.decodeIfPresent(String.self, forKey: .imageDetailsUrl2)
        imageDetailsUrl3 = try c.decodeIfPresent(String.self, forKey: .imageDetailsUrl3)
        introduction = try c.decodeIfPresent(String.self, forKey: .introduction)
        price = try c.decodeIfPresent(Double.self, forKey: .price)
        recommend = try c.decodeIfPresent(Int.self, forKey: .recommend)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        applicablePeople = try c.decodeIfPresent(String.self, forKey: .applicablePeople)
        categoryServiceName = try c.decodeIfPresent(String.self, forKey: .categoryServiceName)
    }
}

/// 按批次号分组的套餐明细
struct PackageHospitalDetailListBO: Decodable {
    let number: Int?
    let packageHospitalDetailList: [PackageHospitalDetailBO]?
}

/// 套餐明细行
struct PackageHospitalDetailBO: Decodable {
    let id: String
    let name: String?
    let quantity: Int?
    let price: Double?
    let billingType: Int?
    let checkType: Int?
    let defaultCheck: Int?
    let categoryName: String?
    let imageUrl: String?
    let children: [PackageHospitalDetailBO]?

    private enum CodingKeys: String, CodingKey {
        case id, name, quantity, price, billingType, checkType
        case defaultCheck, categoryName, imageUrl, children
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = HospitalPackageID.decode(c, key: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        quantity = try c.decodeIfPresent(Int.self, forKey: .quantity)
        price = try c.decodeIfPresent(Double.self, forKey: .price)
        billingType = try c.decodeIfPresent(Int.self, forKey: .billingType)
        checkType = try c.decodeIfPresent(Int.self, forKey: .checkType)
        defaultCheck = try c.decodeIfPresent(Int.self, forKey: .defaultCheck)
        categoryName = try c.decodeIfPresent(String.self, forKey: .categoryName)
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
        children = try c.decodeIfPresent([PackageHospitalDetailBO].self, forKey: .children)
    }
}

enum HospitalPackageID {
    static func decode<K: CodingKey>(_ container: KeyedDecodingContainer<K>, key: K) -> String {
        if let value = try? container.decode(String.self, forKey: key) { return value }
        if let value = try? container.decode(Int64.self, forKey: key) { return String(value) }
        if let value = try? container.decode(Int.self, forKey: key) { return String(value) }
        return ""
    }
}

// MARK: - Mapper

enum HospitalPackageDetailMapper {

    /// `checkType`: 1 单选, 2 强制, 3 可选
    static func toServicePackageDetail(
        _ bo: HospitalPackageDetailBO,
        packageId: String
    ) -> ServicePackageDetail {
        let info = bo.packageInfo
        let name = nonEmpty(info?.name) ?? "套餐详情"
        let subtitle = nonEmpty(info?.introduction) ?? nonEmpty(info?.description) ?? ""
        let priceValue = Int((info?.price ?? 0).rounded())
        let priceText = priceValue > 0 ? "¥\(grouped(priceValue))" : "面议"
        let tag: String = {
            switch info?.recommend {
            case 1: return "推荐"
            default: return ""
            }
        }()
        let tags = splitPeople(info?.applicablePeople)
        let detailText = nonEmpty(info?.description)
            ?? nonEmpty(info?.introduction)
            ?? "\(name)包含核心服务权益，购买后按套餐有效期履约。"
        let banners = resolveBanners(bo: bo, info: info, fallbackName: name)
        let groups = (bo.packageHospitalDetailList ?? []).compactMap(mapGroup)
        let tier = ServicePackageTier(
            id: nonEmpty(info?.id) ?? packageId,
            name: name,
            priceLabel: priceText,
            price: priceValue,
            priceUnit: priceValue > 0 ? "元起" : "面议",
            groups: groups.isEmpty ? [emptyRequiredGroup()] : groups
        )

        return ServicePackageDetail(
            id: nonEmpty(info?.id) ?? packageId,
            productCode: nonEmpty(info?.categoryServiceName) ?? "德好",
            name: name,
            subtitle: subtitle.isEmpty ? "综合健康管理服务" : subtitle,
            category: nonEmpty(info?.categoryServiceName) ?? "健康管理",
            tag: tag,
            priceText: priceText,
            priceUnit: priceValue > 0 ? "元起" : "面议",
            tags: tags,
            detailText: detailText,
            detailImageURLs: [
                info?.imageDetailsUrl1,
                info?.imageDetailsUrl2,
                info?.imageDetailsUrl3
            ].compactMap { nonEmpty($0) },
            carouselLabels: banners.labels,
            carouselImageURLs: banners.urls,
            tiers: [tier],
            accentHex: "#FF7A50"
        )
    }

    private static func mapGroup(_ listBO: PackageHospitalDetailListBO) -> ServicePackageComboGroup? {
        let parents = listBO.packageHospitalDetailList ?? []
        guard !parents.isEmpty else { return nil }

        let rows: [PackageHospitalDetailBO] = parents.flatMap { parent in
            if let children = parent.children, !children.isEmpty {
                return children
            }
            return [parent]
        }
        guard !rows.isEmpty else { return nil }

        let checkType = parents.first?.checkType ?? rows.first?.checkType ?? 2
        let mode = selectMode(checkType)
        let title = nonEmpty(parents.first?.categoryName)
            ?? nonEmpty(parents.first?.name)
            ?? "分组\(listBO.number ?? 0)"

        let items = rows.map { row -> ServicePackageComboItem in
            let qty = row.quantity.map(String.init) ?? "1"
            let unit = billingUnit(row.billingType)
            let price = Int((row.price ?? 0).rounded())
            return ServicePackageComboItem(
                name: nonEmpty(row.name) ?? "服务项",
                qty: qty,
                unit: unit,
                price: price,
                defaultSelected: row.defaultCheck == 1
            )
        }

        return ServicePackageComboGroup(
            name: title,
            selectMode: mode,
            emoji: mode == .required ? "🩺" : (mode == .radio ? "⌚" : "🌿"),
            items: items
        )
    }

    private static func selectMode(_ checkType: Int?) -> ServicePackageSelectMode {
        switch checkType {
        case 1: return .radio
        case 3: return .checkbox
        default: return .required
        }
    }

    /// `billingType`: 1 天, 2 月, 3 次, 4 件
    private static func billingUnit(_ type: Int?) -> String {
        switch type {
        case 1: return "天"
        case 2: return "月"
        case 3: return "次"
        case 4: return "件"
        default: return "项"
        }
    }

    private static func emptyRequiredGroup() -> ServicePackageComboGroup {
        ServicePackageComboGroup(
            name: "核心服务",
            selectMode: .required,
            emoji: "🩺",
            items: [ServicePackageComboItem(name: "暂无明细", qty: "1", unit: "项", price: 0)]
        )
    }

    private static func resolveBanners(
        bo: HospitalPackageDetailBO,
        info: MPackageVO?,
        fallbackName: String
    ) -> (urls: [String], labels: [String]) {
        var urls: [String] = (bo.bannerList ?? []).compactMap(nonEmpty)
        if urls.isEmpty, let carousel = nonEmpty(info?.packageCarousel) {
            urls = carousel
                .split { $0 == "," || $0 == "、" || $0 == ";" }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        if urls.isEmpty, let cover = nonEmpty(info?.imageUrl) {
            urls = [cover]
        }
        if urls.isEmpty {
            return ([], ["\(fallbackName)轮播图 1", "\(fallbackName)轮播图 2"])
        }
        let labels = urls.enumerated().map { "\(fallbackName)轮播图 \($0.offset + 1)" }
        return (urls, labels)
    }

    private static func splitPeople(_ raw: String?) -> [String] {
        guard let raw = nonEmpty(raw) else { return [] }
        return raw
            .split { "，,；;、 ".contains($0) }
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private static func grouped(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
