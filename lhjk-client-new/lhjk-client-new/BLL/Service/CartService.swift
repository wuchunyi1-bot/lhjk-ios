import Foundation

// MARK: - 购物车服务 (BLL)

/// 本地购物车 — 对齐 Vue `services.json` cart；暂无服务端同步
final class CartService {

    static let shared = CartService()

    private static let storageKey = "service.cart.items.v1"
    private static let seededKey = "service.cart.seeded.v1"

    private let defaults: UserDefaults
    private let catalog: ServiceCatalogService

    private(set) var items: [CartItem] = []

    init(
        defaults: UserDefaults = .standard,
        catalog: ServiceCatalogService = .shared
    ) {
        self.defaults = defaults
        self.catalog = catalog
        load()
        if items.isEmpty, defaults.bool(forKey: Self.seededKey) == false {
            items = Self.prototypeSeed
            defaults.set(true, forKey: Self.seededKey)
            persist()
        }
    }

    // MARK: - Read

    func displayLines() -> [CartLineDisplay] {
        items.map(resolveDisplay)
    }

    var selectedCount: Int { items.filter(\.selected).count }

    var selectedTotal: Int {
        displayLines()
            .filter(\.selected)
            .reduce(0) { $0 + $1.linePrice }
    }

    // MARK: - Mutate

    @discardableResult
    func addPackage(_ package: ServicePackageDetail, quantity: Int = 1) -> CartItem {
        if let idx = items.firstIndex(where: { $0.targetId == package.id && $0.scene == "service" }) {
            items[idx].quantity += max(1, quantity)
            items[idx].selected = true
            persist()
            return items[idx]
        }
        let price = parsePrice(package.priceText) ?? package.tiers.first?.price ?? 0
        let item = CartItem(
            id: "cart-\(UUID().uuidString.prefix(8))",
            targetId: package.id,
            scene: "service",
            selected: true,
            quantity: max(1, quantity),
            serviceObject: "本人",
            deliveryMethod: "线上签约后开通",
            couponId: nil,
            snapshotName: package.name,
            snapshotSubtitle: package.subtitle,
            snapshotPrice: price,
            snapshotAccentHex: package.accentHex,
            snapshotCycle: package.priceUnit.contains("面议") ? "定制服务" : "按服务周期履约"
        )
        items.insert(item, at: 0)
        persist()
        return item
    }

    @discardableResult
    func addMallProduct(_ product: MallProduct, quantity: Int = 1) -> CartItem {
        if let idx = items.firstIndex(where: { $0.targetId == product.id && $0.scene == "mall" }) {
            items[idx].quantity += max(1, quantity)
            items[idx].selected = true
            persist()
            return items[idx]
        }
        let item = CartItem(
            id: "cart-\(UUID().uuidString.prefix(8))",
            targetId: product.id,
            scene: "mall",
            selected: true,
            quantity: max(1, quantity),
            serviceObject: "本人",
            deliveryMethod: "默认收货地址",
            couponId: nil,
            snapshotName: product.name,
            snapshotSubtitle: product.desc,
            snapshotPrice: parsePrice(product.price) ?? 0,
            snapshotAccentHex: product.accentHex,
            snapshotCycle: "下单后 48 小时内发货"
        )
        items.insert(item, at: 0)
        persist()
        return item
    }

    func setSelected(id: String, selected: Bool) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].selected = selected
        persist()
    }

    func toggleSelected(id: String) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].selected.toggle()
        persist()
    }

    @discardableResult
    func removeItem(id: String) -> Bool {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return false }
        items.remove(at: idx)
        persist()
        return true
    }

    func clear() {
        items = []
        persist()
    }

    // MARK: - Private

    private func load() {
        guard let data = defaults.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([CartItem].self, from: data) else {
            items = []
            return
        }
        items = decoded
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }

    private func resolveDisplay(_ item: CartItem) -> CartLineDisplay {
        if item.scene == "mall", let product = catalog.product(id: item.targetId) {
            return CartLineDisplay(
                id: item.id,
                targetId: item.targetId,
                scene: item.scene,
                selected: item.selected,
                name: product.name,
                subtitle: product.desc,
                unitPrice: parsePrice(product.price) ?? item.snapshotPrice,
                quantity: max(1, item.quantity),
                serviceObject: item.serviceObject,
                deliveryMethod: item.deliveryMethod,
                couponId: item.couponId,
                serviceCycle: "下单后 48 小时内发货",
                accentHex: product.accentHex
            )
        }
        // 仅非数字原型 id 走本地目录，避免数字 packageId 误 fallback 到 dehao-m
        if HospitalPackageService.apiHospitalId(item.targetId) == nil,
           let pkg = catalog.packageDetail(id: item.targetId) {
            let price = parsePrice(pkg.priceText) ?? pkg.tiers.first?.price ?? item.snapshotPrice
            return CartLineDisplay(
                id: item.id,
                targetId: item.targetId,
                scene: item.scene,
                selected: item.selected,
                name: pkg.name,
                subtitle: pkg.subtitle,
                unitPrice: price,
                quantity: max(1, item.quantity),
                serviceObject: item.serviceObject,
                deliveryMethod: item.deliveryMethod,
                couponId: item.couponId,
                serviceCycle: item.snapshotCycle.isEmpty ? "按服务周期履约" : item.snapshotCycle,
                accentHex: pkg.accentHex
            )
        }
        return CartLineDisplay(
            id: item.id,
            targetId: item.targetId,
            scene: item.scene,
            selected: item.selected,
            name: item.snapshotName,
            subtitle: item.snapshotSubtitle,
            unitPrice: item.snapshotPrice,
            quantity: max(1, item.quantity),
            serviceObject: item.serviceObject,
            deliveryMethod: item.deliveryMethod,
            couponId: item.couponId,
            serviceCycle: item.snapshotCycle,
            accentHex: item.snapshotAccentHex
        )
    }

    private func parsePrice(_ raw: String) -> Int? {
        let digits = raw.filter(\.isNumber)
        guard !digits.isEmpty else { return nil }
        return Int(digits)
    }

    /// 对齐 `services.json` → `cart.items`（仅首次空车注入一次）
    private static let prototypeSeed: [CartItem] = [
        CartItem(
            id: "cart-001", targetId: "dehao-m", scene: "service", selected: true, quantity: 1,
            serviceObject: "本人", deliveryMethod: "线上签约后开通", couponId: "coupon-service-300",
            snapshotName: "德好综合服务套餐", snapshotSubtitle: "基础版综合健康管理，覆盖服务、方案和可选设备",
            snapshotPrice: 1980, snapshotAccentHex: "#FF7A50", snapshotCycle: "按年履约"
        ),
        CartItem(
            id: "cart-002", targetId: "deyi-m", scene: "service", selected: true, quantity: 1,
            serviceObject: "母亲", deliveryMethod: "客服回访确认就医需求", couponId: "coupon-service-180",
            snapshotName: "德医尊享版", snapshotSubtitle: "全国三甲无忧就医",
            snapshotPrice: 3980, snapshotAccentHex: "#2C7BB0", snapshotCycle: "按年履约"
        ),
        CartItem(
            id: "cart-003", targetId: "m009", scene: "mall", selected: false, quantity: 1,
            serviceObject: "父亲", deliveryMethod: "上海市浦东新区杨高南路 1888 弄 6 号 1802", couponId: nil,
            snapshotName: "血糖连续监测贴", snapshotSubtitle: "免扎针14天连续监测",
            snapshotPrice: 186, snapshotAccentHex: "#1A7A6E", snapshotCycle: "下单后 48 小时内发货"
        ),
    ]
}
