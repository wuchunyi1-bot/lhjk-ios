import Foundation

// MARK: - 服务目录服务 (BLL)

/// 服务首页快照组装 — 机构/商城列表待后端 API，已接真实接口的数据不得使用 mock。
final class ServiceCatalogService {

    static let shared = ServiceCatalogService()

    private static let placeholderInstitution = ServiceInstitution(
        id: "placeholder",
        name: "服务",
        hospitalId: nil
    )

    private init() {}

    // MARK: - Hub

    func loadHubSnapshot(
        banners: [ServiceHubBanner],
        matrix: [ProductMatrixItem],
        mallPreviewPackages: [HealthPackageItem]
    ) -> ServiceHubSnapshot {
        ServiceHubSnapshot(
            institution: Self.placeholderInstitution,
            institutions: [],
            banners: banners,
            matrix: matrix,
            mallPreviewPackages: mallPreviewPackages
        )
    }

    /// 富德优选商品 — 待商城商品 API；当前对齐 `services.json` mall 本地原型（不进入真实 API 参数）
    func loadMallProducts() -> [MallProduct] {
        Self.prototypeMallProducts
    }

    /// 按 id 查询商品；无匹配返回 `nil`
    func product(id: String) -> MallProduct? {
        loadMallProducts().first { $0.id == id }
    }

    // MARK: - 套餐详情

    /// 套餐详情 — 优先原型健康包；其次 Hub 缓存推荐套餐映射；最后 fallback `dehao-m`
    func packageDetail(
        id: String,
        hubCache: ServiceHubCacheService = ServiceHubCacheService.shared
    ) -> ServicePackageDetail? {
        if let match = Self.prototypeServicePackages.first(where: { $0.id == id }) {
            return match
        }
        if let item = hubCache.findCachedPackage(id: id) {
            return Self.mapHealthPackage(item, matrix: hubCache.getStatic()?.matrix ?? [])
        }
        if !id.isEmpty, let fallback = Self.prototypeServicePackages.first(where: { $0.id == "dehao-m" }) {
            return fallback
        }
        return Self.prototypeServicePackages.first
    }

    func accentHex(for productCode: String, matrix: [ProductMatrixItem]) -> String {
        matrix.first { $0.code == productCode }?.accentHex ?? "#FF7A50"
    }

    private static func mapHealthPackage(_ item: HealthPackageItem, matrix: [ProductMatrixItem]) -> ServicePackageDetail {
        let accent = matrix.first { $0.code == item.productCode }?.accentHex ?? item.accentHex
        let priceValue = parsePriceDouble(item.price)
        let tags = item.audienceTags.isEmpty
            ? (item.badge.map { [$0] } ?? ["健康管理"])
            : item.audienceTags
        // API 字段不全时用健康包默认必选组，避免空白「适用人群」式残缺页
        let groups: [ServicePackageComboGroup] = {
            if item.audienceTags.count >= 3 {
                return [
                    ServicePackageComboGroup(
                        name: "核心服务",
                        selectMode: .required,
                        emoji: "🩺",
                        items: item.audienceTags.map {
                            ServicePackageComboItem(name: $0, qty: "1", unit: "项", price: 0)
                        }
                    )
                ]
            }
            return defaultRequiredGroup(archivePrice: 0)
        }()
        let tier = ServicePackageTier(
            id: "\(item.id)-tier",
            name: item.name.isEmpty ? "标准版" : item.name,
            priceLabel: item.price,
            price: priceValue > 0 ? priceValue : 1980,
            priceUnit: item.price.contains("面议") ? "面议" : "元起",
            groups: groups
        )
        let displayName = item.name.isEmpty ? "综合服务套餐" : item.name
        let subtitle = item.subtitle.isEmpty ? "综合健康管理，覆盖服务、方案和可选设备" : item.subtitle
        let priceText: String = {
            if item.price.contains("面议") { return "面议" }
            if item.price.hasPrefix("¥") { return item.price }
            if priceValue > 0 { return ServicePackageMoney.yen(priceValue) }
            return ServicePackageMoney.yen(1980)
        }()
        return ServicePackageDetail(
            id: item.id,
            hospitalId: item.hospitalId,
            productCode: item.productCode.isEmpty ? "德好" : item.productCode,
            name: displayName,
            subtitle: subtitle,
            category: item.badge ?? "健康管理",
            tag: item.badge ?? "新品",
            priceText: priceText,
            priceUnit: "元起",
            tags: tags.isEmpty ? ["慢病管理", "长期改善", "三高风险"] : tags,
            detailText: subtitle,
            carouselLabels: ["\(displayName)轮播图 1", "\(displayName)轮播图 2"],
            tiers: [tier],
            accentHex: accent
        )
    }

    private static func parsePriceDouble(_ raw: String) -> Double {
        let digits = raw.filter { $0.isNumber || $0 == "." }
        return Double(digits) ?? 0
    }

    private static func groupedYen(_ value: Double) -> String {
        ServicePackageMoney.yen(value)
    }

    // MARK: - Prototype Service Packages (delete when package detail API lands)

    private static let prototypeServicePackages: [ServicePackageDetail] = [
        makePackage(
            id: "dehao-m", code: "德好", name: "德好综合服务套餐",
            subtitle: "基础版综合健康管理，覆盖服务、方案和可选设备",
            category: "慢病管理", tag: "新品", price: 1980, priceUnit: "元起",
            tags: ["慢病管理", "长期改善", "三高风险"],
            detail: "德好综合服务套餐面向慢病与三高风险人群，提供三好共管协同服务、方案定制与可选设备，购买后按服务周期履约。",
            tiers: [
                makeTier("dehao-m-base", "基础版", 1980, "元起", defaultRequiredGroup(archivePrice: 1680)),
                makeTier("dehao-m-std", "标准版", 2980, "元起", defaultRequiredGroup(archivePrice: 1680) + [
                    ServicePackageComboGroup(
                        name: "健康产品",
                        selectMode: .checkbox,
                        emoji: "🌿",
                        items: [
                            ServicePackageComboItem(name: "营养品", qty: "1", unit: "项", price: 330),
                            ServicePackageComboItem(name: "体质辩证茶饮方案", qty: "1", unit: "次", price: 300),
                        ]
                    )
                ])
            ]
        ),
        makePackage(
            id: "dehao-s", code: "德好", name: "德好入门版",
            subtitle: "慢病逆转基础方案", category: "慢病管理", tag: "",
            price: 1580, priceUnit: "元起", tags: ["慢病逆转", "入门"],
            detail: "慢病逆转入门方案，主治医师每月会诊，健管师每周跟进。",
            tiers: [makeTier("dehao-s-1", "入门版", 1580, "元起", defaultRequiredGroup(archivePrice: 0))]
        ),
        makePackage(
            id: "dehao-l", code: "德好", name: "德好旗舰版",
            subtitle: "精准医疗个性化管理", category: "慢病管理", tag: "精选",
            price: 5800, priceUnit: "元起", tags: ["精准医疗", "旗舰"],
            detail: "5人专家团队专属陪伴，结合基因检测制定个性化方案。",
            tiers: [makeTier("dehao-l-1", "旗舰版", 5800, "元起", defaultRequiredGroup(archivePrice: 0))]
        ),
        makePackage(
            id: "dekang-s", code: "德康", name: "德康入门版",
            subtitle: "亚健康基础干预", category: "亚健康/6高", tag: "",
            price: 680, priceUnit: "元起", tags: ["亚健康", "基础干预"],
            detail: "适合刚开始关注健康的用户，月度随访与六维测评。",
            tiers: [makeTier("dekang-s-1", "入门版", 680, "元起", defaultRequiredGroup(archivePrice: 0))]
        ),
        makePackage(
            id: "dekang-m", code: "德康", name: "德康标准版",
            subtitle: "六高全面干预方案", category: "亚健康/6高", tag: "推荐",
            price: 1280, priceUnit: "元起", tags: ["六高", "全面干预"],
            detail: "针对六高人群定制干预方案，双周随访与季度报告。",
            tiers: [makeTier("dekang-m-1", "标准版", 1280, "元起", defaultRequiredGroup(archivePrice: 0))]
        ),
        makePackage(
            id: "dehu-s", code: "德护", name: "德护专病版",
            subtitle: "全病程专项管护", category: "专病管护", tag: "",
            price: 3800, priceUnit: "元起", tags: ["专病", "全病程"],
            detail: "针对特定慢病提供全病程专项管护。",
            tiers: [makeTier("dehu-s-1", "专病版", 3800, "元起", defaultRequiredGroup(archivePrice: 0))]
        ),
        makePackage(
            id: "deyi-s", code: "德医", name: "德医标准版",
            subtitle: "三甲就医全程协助", category: "就医协助", tag: "",
            price: 1980, priceUnit: "元起", tags: ["挂号协助", "陪诊"],
            detail: "覆盖全国主要城市三甲医院，提供挂号协助与陪诊服务。",
            tiers: [makeTier("deyi-s-1", "标准版", 1980, "元起", defaultRequiredGroup(archivePrice: 0))]
        ),
        makePackage(
            id: "deyi-m", code: "德医", name: "德医尊享版",
            subtitle: "全国三甲无忧就医", category: "就医协助", tag: "推荐",
            price: 3980, priceUnit: "元起", tags: ["绿色通道", "不限次陪诊"],
            detail: "全国三甲医院绿色通道，专属医疗协调员一对一服务。",
            tiers: [makeTier("deyi-m-1", "尊享版", 3980, "元起", defaultRequiredGroup(archivePrice: 0))]
        ),
        makePackage(
            id: "deyuan-s", code: "德元", name: "德元标准版",
            subtitle: "肿瘤全程管理", category: "肿瘤", tag: "高端",
            price: 0, priceUnit: "面议", tags: ["肿瘤", "MDT"],
            detail: "面向肿瘤患者及高风险人群，个案管理师全程陪伴。",
            tiers: [makeTier("deyuan-s-1", "标准版", 0, "面议", defaultRequiredGroup(archivePrice: 0))]
        ),
        makePackage(
            id: "deyu-s", code: "德愈", name: "德愈标准版",
            subtitle: "疑难重症全程支持", category: "疑难重症", tag: "高端",
            price: 0, priceUnit: "面议", tags: ["疑难", "MDT"],
            detail: "整合国内顶级医疗资源，提供第二诊疗意见。",
            tiers: [makeTier("deyu-s-1", "标准版", 0, "面议", defaultRequiredGroup(archivePrice: 0))]
        ),
        makePackage(
            id: "dezhen-s", code: "德甄", name: "德甄标准版",
            subtitle: "全球特药甄选配送", category: "特药", tag: "",
            price: 0, priceUnit: "面议", tags: ["特药", "全球"],
            detail: "通过合规渠道甄选全球特效药品。",
            tiers: [makeTier("dezhen-s-1", "标准版", 0, "面议", defaultRequiredGroup(archivePrice: 0))]
        ),
        makePackage(
            id: "deji-s", code: "德际", name: "德际标准版",
            subtitle: "境外就医全程服务", category: "国际", tag: "旗舰",
            price: 0, priceUnit: "面议", tags: ["境外就医"],
            detail: "境外知名医院预约、医疗签证与全程翻译陪同。",
            tiers: [makeTier("deji-s-1", "标准版", 0, "面议", defaultRequiredGroup(archivePrice: 0))]
        ),
        makePackage(
            id: "dezun-s", code: "德尊", name: "德尊旗舰版",
            subtitle: "长寿医学极致定制", category: "长寿医学", tag: "旗舰",
            price: 0, priceUnit: "面议", tags: ["抗衰老", "长寿"],
            detail: "基因检测、干细胞评估等极致定制服务。",
            tiers: [makeTier("dezun-s-1", "旗舰版", 0, "面议", defaultRequiredGroup(archivePrice: 0))]
        ),
        makePackage(
            id: "hp-01", code: "德康", name: "肠道便秘",
            subtitle: "亚健康·六高基础干预", category: "亚健康/6高", tag: "",
            price: 1980, priceUnit: "元起", tags: ["核心服务", "体检服务", "穿戴设备"],
            detail: "肠道便秘健康包包含核心服务、体检、穿戴设备与健康产品组合。",
            tiers: [
                makeTier("pkg-r05", "基础守护", 1980, "/月", defaultRequiredGroup(archivePrice: 0) + [
                    ServicePackageComboGroup(
                        name: "穿戴设备",
                        selectMode: .radio,
                        emoji: "⌚",
                        items: [
                            ServicePackageComboItem(name: "设备押金", qty: "1", unit: "件", price: 0),
                            ServicePackageComboItem(name: "体脂秤", qty: "1", unit: "件", price: 0),
                            ServicePackageComboItem(name: "健康智能戒指", qty: "1", unit: "件", price: 0),
                        ]
                    ),
                    ServicePackageComboGroup(
                        name: "健康产品",
                        selectMode: .checkbox,
                        emoji: "🌿",
                        items: [
                            ServicePackageComboItem(name: "营养品", qty: "1", unit: "项", price: 330),
                            ServicePackageComboItem(name: "体质辩证茶饮方案", qty: "1", unit: "次", price: 300),
                        ]
                    )
                ])
            ]
        ),
    ]

    private static func defaultRequiredGroup(archivePrice: Double) -> [ServicePackageComboGroup] {
        [
            ServicePackageComboGroup(
                name: "核心服务",
                selectMode: .required,
                emoji: "🩺",
                items: [
                    ServicePackageComboItem(name: "AI服务", qty: "1", unit: "项", price: 0),
                    ServicePackageComboItem(name: "执业医师", qty: "1", unit: "项", price: 0),
                    ServicePackageComboItem(name: "营养师", qty: "1", unit: "项", price: 0),
                    ServicePackageComboItem(name: "健管师", qty: "1", unit: "项", price: 0),
                    ServicePackageComboItem(name: "健康档案建档", qty: "1", unit: "项", price: archivePrice),
                ]
            )
        ]
    }

    private static func makeTier(
        _ id: String, _ name: String, _ price: Double, _ unit: String,
        _ groups: [ServicePackageComboGroup]
    ) -> ServicePackageTier {
        ServicePackageTier(
            id: id,
            name: name,
            priceLabel: price == 0 ? "面议" : "\(groupedYen(price))\(unit.contains("面议") ? "" : unit)",
            price: price,
            priceUnit: unit,
            groups: groups
        )
    }

    private static func makePackage(
        id: String, code: String, name: String, subtitle: String,
        category: String, tag: String, price: Double, priceUnit: String,
        tags: [String], detail: String, tiers: [ServicePackageTier]
    ) -> ServicePackageDetail {
        let accent = matrixAccent[code] ?? "#FF7A50"
        let priceText = price == 0 ? "面议" : groupedYen(price)
        return ServicePackageDetail(
            id: id,
            productCode: code,
            name: name,
            subtitle: subtitle,
            category: category,
            tag: tag,
            priceText: priceText,
            priceUnit: priceUnit,
            tags: tags,
            detailText: detail,
            carouselLabels: ["\(name)轮播图 1", "\(name)轮播图 2"],
            tiers: tiers,
            accentHex: accent
        )
    }

    private static let matrixAccent: [String: String] = [
        "德康": "#1F9A6B", "德好": "#FF7A50", "德护": "#3D6FB8", "德元": "#7B5E9F",
        "德愈": "#5C8DC9", "德医": "#2C7BB0", "德甄": "#1A7A6E", "德际": "#4A6A8A", "德尊": "#B7905F",
    ]

    // MARK: - Prototype Mall (delete when mall API lands)

    private static let prototypeMallProducts: [MallProduct] = [
        MallProduct(id: "m001", name: "德好·控糖益生菌", desc: "餐后血糖平稳配方", price: "¥128", unit: "60粒/盒", tag: "热销", emoji: "🦠", accentHex: "#FF7A50", category: "营养补充"),
        MallProduct(id: "m002", name: "深海鱼油软胶囊", desc: "EPA+DHA 心脑血管养护", price: "¥98", unit: "90粒/瓶", tag: "", emoji: "🐟", accentHex: "#2C7BB0", category: "营养补充"),
        MallProduct(id: "m003", name: "膳食纤维复合粉", desc: "助消化·促代谢·饱腹感", price: "¥76", unit: "30袋/盒", tag: "推荐", emoji: "🌿", accentHex: "#1F9A6B", category: "功能食品"),
        MallProduct(id: "m004", name: "辅酶Q10胶囊", desc: "心肌细胞能量代谢支持", price: "¥168", unit: "60粒/瓶", tag: "", emoji: "❤️", accentHex: "#D6602B", category: "营养补充"),
        MallProduct(id: "m005", name: "维生素D3+K2", desc: "钙吸收协同·骨骼强健", price: "¥88", unit: "120粒/瓶", tag: "", emoji: "☀️", accentHex: "#B47300", category: "营养补充"),
        MallProduct(id: "m006", name: "乳清蛋白质粉", desc: "肌肉维持·体重管理首选", price: "¥218", unit: "500g/罐", tag: "精选", emoji: "💪", accentHex: "#7B5E9F", category: "功能食品"),
        MallProduct(id: "m007", name: "血压臂式监测仪", desc: "医疗级精准·家庭自测", price: "¥298", unit: "1台", tag: "", emoji: "🩺", accentHex: "#3D6FB8", category: "健康器械"),
        MallProduct(id: "m008", name: "德康·抗氧化套装", desc: "白藜芦醇+虾青素+葡萄籽", price: "¥368", unit: "3瓶组合", tag: "套装", emoji: "🍇", accentHex: "#5C8DC9", category: "营养补充"),
        MallProduct(id: "m009", name: "血糖连续监测贴", desc: "免扎针14天连续监测", price: "¥186", unit: "2片/盒", tag: "新品", emoji: "📡", accentHex: "#1A7A6E", category: "健康器械"),
    ]

    /// 当前选中机构的后端 `hospitalId`
    func selectedApiHospitalId() -> String? {
        if let id = InstitutionSelectionStore.shared.selectedHospitalId {
            return id
        }
        if let id = Self.validApiHospitalId(Self.placeholderInstitution.hospitalId) {
            return id
        }
        return HospitalPackageService.temporaryHospitalId
    }

    /// 仅当值为非空纯数字字符串时才可作为 API `hospitalId`（后端 `Long`）
    static func validApiHospitalId(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        guard trimmed.allSatisfy(\.isNumber) else { return nil }
        return trimmed
    }
}
