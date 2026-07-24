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
    let hospitalId: String?
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
    let categoryServiceId: String?
    let categoryServiceName: String?

    private enum CodingKeys: String, CodingKey {
        case id, hospitalId, name, imageUrl, packageCarousel
        case imageDetailsUrl1, imageDetailsUrl2, imageDetailsUrl3
        case introduction, price, recommend, description
        case applicablePeople, categoryServiceId, categoryServiceName
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = HospitalPackageID.decode(c, key: .id)
        hospitalId = HospitalPackageID.decodeOptional(c, key: .hospitalId)
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
        categoryServiceId = HospitalPackageID.decodeOptional(c, key: .categoryServiceId)
        categoryServiceName = try c.decodeIfPresent(String.self, forKey: .categoryServiceName)
    }
}

/// 按批次号分组的套餐明细
struct PackageHospitalDetailListBO: Decodable {
    let number: Int?
    let packageHospitalDetailList: [PackageHospitalDetailBO]?
}

/// 套餐明细行（详情响应 / 加购提交共用字段）
struct PackageHospitalDetailBO: Decodable {
    let id: String
    let name: String?
    let quantity: Int?
    let price: Double?
    /// 续费金额（续费态展示与提交）
    let reprice: Double?
    let billingType: Int?
    let checkType: Int?
    let defaultCheck: Int?
    let categoryName: String?
    let categoryId: String?
    let imageUrl: String?
    let parentId: String?
    let packageDetailId: String?
    let commodityId: String?
    let saleFlag: Int?
    let children: [PackageHospitalDetailBO]?

    private enum CodingKeys: String, CodingKey {
        case id, name, quantity, price, reprice, billingType, checkType
        case defaultCheck, categoryName, categoryId, imageUrl
        case parentId, packageDetailId, commodityId, saleFlag, children
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = HospitalPackageID.decode(c, key: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        quantity = HospitalPackageInt.decodeIfPresent(c, key: .quantity)
        price = try c.decodeIfPresent(Double.self, forKey: .price)
        reprice = try c.decodeIfPresent(Double.self, forKey: .reprice)
        billingType = HospitalPackageInt.decodeIfPresent(c, key: .billingType)
        checkType = HospitalPackageInt.decodeIfPresent(c, key: .checkType)
        defaultCheck = HospitalPackageInt.decodeIfPresent(c, key: .defaultCheck)
        categoryName = try c.decodeIfPresent(String.self, forKey: .categoryName)
        categoryId = HospitalPackageID.decodeOptional(c, key: .categoryId)
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
        parentId = HospitalPackageID.decodeOptional(c, key: .parentId)
        packageDetailId = HospitalPackageID.decodeOptional(c, key: .packageDetailId)
        commodityId = HospitalPackageID.decodeOptional(c, key: .commodityId)
        saleFlag = HospitalPackageInt.decodeIfPresent(c, key: .saleFlag)
        children = try c.decodeIfPresent([PackageHospitalDetailBO].self, forKey: .children)
    }
}

enum HospitalPackageID {
    static func decode<K: CodingKey>(_ container: KeyedDecodingContainer<K>, key: K) -> String {
        decodeOptional(container, key: key) ?? ""
    }

    static func decodeOptional<K: CodingKey>(_ container: KeyedDecodingContainer<K>, key: K) -> String? {
        if let value = try? container.decodeIfPresent(String.self, forKey: key),
           !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return value
        }
        if let value = try? container.decodeIfPresent(Int64.self, forKey: key) { return String(value) }
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) { return String(value) }
        return nil
    }
}

enum HospitalPackageInt {
    static func decodeIfPresent<K: CodingKey>(_ container: KeyedDecodingContainer<K>, key: K) -> Int? {
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) { return value }
        if let value = try? container.decodeIfPresent(Int64.self, forKey: key) { return Int(value) }
        if let value = try? container.decodeIfPresent(String.self, forKey: key),
           let int = Int(value.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return int
        }
        return nil
    }
}

// MARK: - Mapper

enum HospitalPackageDetailMapper {

    /// `checkType`: 1 单选, 2 强制, 3 可选
    static func toServicePackageDetail(
        _ bo: HospitalPackageDetailBO,
        packageId: String,
        renewalMode: Bool = false
    ) -> ServicePackageDetail {
        let info = bo.packageInfo
        let name = nonEmpty(info?.name) ?? "套餐详情"
        let subtitle = nonEmpty(info?.introduction) ?? nonEmpty(info?.description) ?? ""
        let priceValue = max(0, info?.price ?? 0)
        let priceText = ServicePackageMoney.yenText(priceValue)
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
        let groups = (bo.packageHospitalDetailList ?? []).flatMap { mapGroups($0, renewalMode: renewalMode) }
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
            hospitalId: nonEmpty(info?.hospitalId),
            productCode: nonEmpty(info?.categoryServiceName) ?? "德好",
            name: name,
            subtitle: subtitle.isEmpty ? "综合健康管理服务" : subtitle,
            category: nonEmpty(info?.categoryServiceName) ?? "健康管理",
            categoryServiceId: nonEmpty(info?.categoryServiceId),
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

    /// 将一批明细按 checkType 拆成多个规则组，保证角标文案与控件一致
    private static func mapGroups(
        _ listBO: PackageHospitalDetailListBO,
        renewalMode: Bool
    ) -> [ServicePackageComboGroup] {
        let parents = listBO.packageHospitalDetailList ?? []
        guard !parents.isEmpty else { return [] }

        var buckets: [(checkType: Int, parents: [PackageHospitalDetailBO])] = []
        for parent in parents {
            let type = parent.checkType ?? 2
            if var last = buckets.last, last.checkType == type {
                last.parents.append(parent)
                buckets[buckets.count - 1] = last
            } else {
                buckets.append((type, [parent]))
            }
        }

        return buckets.compactMap { bucket in
            makeGroup(
                parents: bucket.parents,
                checkType: bucket.checkType,
                fallbackNumber: listBO.number,
                renewalMode: renewalMode
            )
        }
    }

    private static func makeGroup(
        parents: [PackageHospitalDetailBO],
        checkType: Int,
        fallbackNumber: Int?,
        renewalMode: Bool
    ) -> ServicePackageComboGroup? {
        guard !parents.isEmpty else { return nil }

        // 父行 + children 子行均保留；子行标记 isChild（对齐 funde parentGoodsId 缩进）
        let rows: [(bo: PackageHospitalDetailBO, isChild: Bool, parentId: String?)] = parents.flatMap { parent in
            [(parent, false, parent.parentId)]
                + (parent.children ?? []).map { ($0, true, parent.id) }
        }
        guard !rows.isEmpty else { return nil }

        let mode = selectMode(checkType)
        let title = nonEmpty(parents.first?.categoryName)
            ?? nonEmpty(parents.first?.name)
            ?? "分组\(fallbackNumber ?? 0)"

        let items = rows.map { row -> ServicePackageComboItem in
            let qty = row.bo.quantity.map(String.init) ?? "1"
            let unit = billingUnit(row.bo.billingType)
            let rawPrice = renewalMode ? (row.bo.reprice ?? row.bo.price) : row.bo.price
            let priceValue = max(0, rawPrice ?? 0)
            return ServicePackageComboItem(
                name: nonEmpty(row.bo.name) ?? "服务项",
                qty: qty,
                unit: unit,
                price: priceValue,
                defaultSelected: row.bo.defaultCheck == 1,
                isChild: row.isChild,
                detailId: row.bo.id,
                checkType: row.bo.checkType ?? checkType,
                billingType: row.bo.billingType,
                quantityValue: row.bo.quantity ?? 1,
                priceValue: priceValue,
                parentDetailId: row.parentId,
                packageDetailId: row.bo.packageDetailId,
                commodityId: row.bo.commodityId,
                imageUrl: row.bo.imageUrl,
                saleFlag: row.bo.saleFlag,
                categoryId: row.bo.categoryId,
                categoryName: row.bo.categoryName,
                groupNumber: fallbackNumber,
                defaultCheck: row.bo.defaultCheck
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
}
