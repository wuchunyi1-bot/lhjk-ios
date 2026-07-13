import Foundation
import UIKit

// MARK: - 购物车条目

/// 购物车持久化条目 — 对齐 `services.json` → `cart.items`
struct CartItem: Codable, Equatable, Identifiable {
    let id: String
    /// 套餐 / 商品 id（结算跳转用）
    let targetId: String
    /// `service` | `mall`
    let scene: String
    var selected: Bool
    var quantity: Int
    var serviceObject: String
    var deliveryMethod: String
    var couponId: String?
    /// 展示快照（catalog 无匹配时仍可渲染）
    var snapshotName: String
    var snapshotSubtitle: String
    var snapshotPrice: Int
    var snapshotAccentHex: String
    var snapshotCycle: String
}

/// 列表行展示模型 — 对齐 `CartView.vue` + `getOrderItemSummary`
struct CartLineDisplay: Equatable, Identifiable {
    let id: String
    let targetId: String
    let scene: String
    var selected: Bool
    let name: String
    let subtitle: String
    let unitPrice: Int
    let quantity: Int
    let serviceObject: String
    let deliveryMethod: String
    let couponId: String?
    let serviceCycle: String
    let accentHex: String

    var accent: UIColor { UIColor(hexString: accentHex) }
    var linePrice: Int { unitPrice * quantity }
    var deliveryLabel: String { scene == "mall" ? "收货方式" : "履约方式" }
    var couponText: String { couponId == nil || couponId?.isEmpty == true ? "可去确认单选择" : "已匹配优惠券" }

    var linePriceText: String {
        "¥\(Self.grouped(linePrice))"
    }

    private static func grouped(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
