import Foundation
import UIKit

// MARK: - 购物车列表展示

/// 列表行展示模型 — 对齐 `CartView.vue`；数据来自 `ShoppingCartListBO`
struct CartLineDisplay: Equatable, Identifiable {
    let id: String
    let targetId: String
    let scene: String
    var selected: Bool
    let name: String
    let subtitle: String
    let unitPrice: Int
    let quantity: Int
    /// 行总价（优先用接口 `totalPrice`）
    let lineTotal: Int
    /// 删除接口必填：列表 `serialNumber`
    let serialNumber: Int?
    let serviceObject: String
    let deliveryMethod: String
    let couponId: String?
    let serviceCycle: String
    let accentHex: String

    var accent: UIColor { UIColor(hexString: accentHex) }
    var linePrice: Int { lineTotal }
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

enum ShoppingCartListMapper {
    static func toLineDisplay(_ bo: ShoppingCartListBO, selected: Bool = true) -> CartLineDisplay {
        let qty = max(1, bo.totalQuantity ?? 1)
        let total = Int((bo.totalPrice ?? 0).rounded())
        let unit = qty > 0 ? max(0, total / qty) : total
        let subtitle: String = {
            if let intro = bo.introduction?.trimmingCharacters(in: .whitespacesAndNewlines), !intro.isEmpty {
                return intro
            }
            return bo.hospitalName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }()
        let serviceObject = {
            if let name = bo.username?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
                return name
            }
            return "本人"
        }()
        let hospital = bo.hospitalName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "线上履约"
        return CartLineDisplay(
            id: bo.lineId,
            targetId: bo.packageId,
            scene: "service",
            selected: selected,
            name: {
                let raw = bo.packageName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return raw.isEmpty ? "套餐" : raw
            }(),
            subtitle: subtitle,
            unitPrice: unit,
            quantity: qty,
            lineTotal: total,
            serialNumber: bo.serialNumber,
            serviceObject: serviceObject,
            deliveryMethod: hospital.isEmpty ? "线上签约后开通" : hospital,
            couponId: nil,
            serviceCycle: "按服务周期履约",
            accentHex: "#FF7A50"
        )
    }
}
