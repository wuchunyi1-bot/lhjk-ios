import Foundation

// MARK: - 套餐确认订单草稿
// 对齐 funde-client: package-order-draft:v4

struct PackageOrderDraftItem: Codable, Equatable {
    var name: String
    var qty: String
    var unit: String
    var price: Double
}

struct PackageOrderDraft: Codable, Equatable {
    var packageId: String
    var packageName: String
    var subtitle: String
    var amount: Double
    var selectedItems: [PackageOrderDraftItem]
    var hospitalId: String?
    var hospitalName: String?
    var hospitalAddress: String?
    var categoryServiceId: String?
    /// `express` | `self_pickup`；历史字段，确认页履约以结算 `orderExpress` 为准
    var contractedFulfillmentMethod: String?
    var hasPhysicalGoods: Bool
    /// 购物车 / 待支付订单 ID，有值时拉 `getOrderSettlement`
    var orderId: String?
    var serialNumber: Int?
    var updatedAt: TimeInterval

    var payableAmount: Double { max(0, amount) }

    var orderIdInt64: Int64? {
        guard let raw = orderId?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        return Int64(raw)
    }
}

/// 确认订单草稿持久化
final class PackageOrderDraftStore {

    static let shared = PackageOrderDraftStore()

    private let storageKey = "lhjk.packageOrderDraft.v1"
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var draft: PackageOrderDraft? {
        get {
            guard let data = defaults.data(forKey: storageKey) else { return nil }
            return try? decoder.decode(PackageOrderDraft.self, from: data)
        }
        set {
            if let newValue, let data = try? encoder.encode(newValue) {
                defaults.set(data, forKey: storageKey)
            } else {
                defaults.removeObject(forKey: storageKey)
            }
        }
    }

    func save(_ draft: PackageOrderDraft) {
        var copy = draft
        copy.updatedAt = Date().timeIntervalSince1970
        self.draft = copy
    }

    func draft(matchingPackageId packageId: String) -> PackageOrderDraft? {
        guard let draft, draft.packageId == packageId else { return nil }
        return draft
    }

    func clear() {
        draft = nil
    }
}

// MARK: - 草稿组装

extension PackageOrderDraft {

    /// 套餐详情「立即下单」快照
    static func fromPackageDetail(
        package: ServicePackageDetail,
        selectedItems: [ServicePackageComboItem],
        hospitalId: String?,
        hospitalName: String?,
        hospitalAddress: String?,
        categoryServiceId: String?,
        orderId: String? = nil
    ) -> PackageOrderDraft {
        let items = selectedItems.map {
            PackageOrderDraftItem(name: $0.name, qty: $0.qty, unit: $0.unit, price: $0.priceValue)
        }
        let amount = items.map(\.price).reduce(0, +)
        let fallback = Double(package.tiers.first?.price ?? 0)
        return PackageOrderDraft(
            packageId: package.id,
            packageName: package.name,
            subtitle: package.subtitle,
            amount: amount > 0 ? amount : fallback,
            selectedItems: items.isEmpty
                ? [PackageOrderDraftItem(name: package.name, qty: "1", unit: "份", price: fallback)]
                : items,
            hospitalId: hospitalId,
            hospitalName: hospitalName,
            hospitalAddress: hospitalAddress,
            categoryServiceId: categoryServiceId ?? package.categoryServiceId,
            contractedFulfillmentMethod: nil,
            hasPhysicalGoods: false,
            orderId: orderId,
            serialNumber: nil,
            updatedAt: Date().timeIntervalSince1970
        )
    }

    /// 购物车「去结算」快照
    static func fromCartLine(_ line: CartLineDisplay) -> PackageOrderDraft {
        let qty = max(1, line.quantity)
        return PackageOrderDraft(
            packageId: line.targetId,
            packageName: line.name,
            subtitle: line.subtitle,
            amount: Double(line.lineTotal),
            selectedItems: [
                PackageOrderDraftItem(
                    name: line.name,
                    qty: "\(qty)",
                    unit: "份",
                    price: Double(line.lineTotal)
                )
            ],
            hospitalId: line.hospitalId,
            hospitalName: line.hospitalName,
            hospitalAddress: nil,
            categoryServiceId: line.categoryServiceId,
            contractedFulfillmentMethod: nil,
            hasPhysicalGoods: false,
            orderId: line.orderId,
            serialNumber: line.serialNumber,
            updatedAt: Date().timeIntervalSince1970
        )
    }

    /// 商城商品详情「立即购买」最小快照
    static func fromMallProduct(id: String, name: String, subtitle: String, amount: Int, orderId: String? = nil) -> PackageOrderDraft {
        let price = Double(amount)
        return PackageOrderDraft(
            packageId: id,
            packageName: name,
            subtitle: subtitle,
            amount: price,
            selectedItems: [
                PackageOrderDraftItem(name: name, qty: "1", unit: "件", price: price)
            ],
            hospitalId: nil,
            hospitalName: nil,
            hospitalAddress: nil,
            categoryServiceId: nil,
            contractedFulfillmentMethod: nil,
            hasPhysicalGoods: true,
            orderId: orderId,
            serialNumber: nil,
            updatedAt: Date().timeIntervalSince1970
        )
    }
}
