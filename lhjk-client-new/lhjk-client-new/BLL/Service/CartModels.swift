import Foundation
import UIKit

// MARK: - 购物车行状态

/// `ShoppingCartListBO.status`
enum ShoppingCartLineStatus: Int, Equatable {
    /// 已生成
    case generated = 1
    /// 未生成
    case pending = 2
    /// 已失效
    case invalid = 3

    var isInvalid: Bool { self == .invalid }

    var badgeText: String? {
        switch self {
        case .invalid: return "已失效"
        case .generated, .pending: return nil
        }
    }
}

// MARK: - 购物车列表展示

/// 列表行展示模型 — 对齐 funde `CartView.vue`；数据来自 `ShoppingCartListBO`
struct CartLineDisplay: Equatable, Identifiable {
    let id: String
    /// packageId，确认订单路由用
    let targetId: String
    let name: String
    /// 一句话卖点 / 简介
    let subtitle: String
    let unitPrice: Double
    let quantity: Int
    /// 行总价（接口 `totalPrice`）
    let lineTotal: Double
    let serialNumber: Int?
    let hospitalId: String?
    let hospitalName: String?
    let categoryServiceId: String?
    /// 已生成订单 ID，确认页拉结算用
    let orderId: String?
    let imageUrl: String?
    let accentHex: String
    /// 列表 status：1 已生成 / 2 未生成 / 3 已失效
    let status: ShoppingCartLineStatus?

    var accent: UIColor { UIColor(hexString: accentHex) }
    var linePrice: Double { lineTotal }
    var isInvalid: Bool { status?.isInvalid == true }
    /// 可进确认订单（仅「去结算」按钮）
    var canCheckout: Bool { !isInvalid }

    var displayInstitutionName: String {
        let name = hospitalName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "服务机构" : name
    }

    var linePriceText: String {
        "¥\(Self.grouped(linePrice))"
    }

    private static func grouped(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.groupingSeparator = ","
        f.roundingMode = .down
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

/// 购物车去结算成功后进入确认订单页的路由参数
struct CartConfirmRoute: Equatable {
    let orderId: Int64
    let serialNumber: Int?
}

enum ShoppingCartListMapper {
    static func toLineDisplay(_ bo: ShoppingCartListBO) -> CartLineDisplay {
        let qty = max(1, bo.totalQuantity ?? 1)
        let total = max(0, bo.totalPrice ?? 0)
        let unit = qty > 0 ? max(0, total / Double(qty)) : total
        let hospital = bo.hospitalName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let intro = bo.introduction?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let image = bo.imgUrl?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lineStatus = bo.status.flatMap { ShoppingCartLineStatus(rawValue: $0) }
        return CartLineDisplay(
            id: bo.lineId,
            targetId: bo.packageId,
            name: {
                let raw = bo.packageName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return raw.isEmpty ? "套餐" : raw
            }(),
            subtitle: intro,
            unitPrice: unit,
            quantity: qty,
            lineTotal: total,
            serialNumber: bo.serialNumber,
            hospitalId: bo.hospitalId,
            hospitalName: hospital.isEmpty ? nil : hospital,
            categoryServiceId: bo.categoryServiceId,
            orderId: {
                let raw = bo.orderId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return raw.isEmpty ? nil : raw
            }(),
            imageUrl: image.isEmpty ? nil : image,
            accentHex: "#FF7A50",
            status: lineStatus
        )
    }
}
