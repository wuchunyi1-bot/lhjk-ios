import Foundation
import UIKit

// MARK: - 顶层 Tab

enum VoucherTopTab: Int, CaseIterable {
    case benefit = 0
    case coupon = 1

    var title: String {
        switch self {
        case .benefit: return "权益卡"
        case .coupon: return "优惠券"
        }
    }
}

// MARK: - 权益卡

enum BenefitCardStatus: String, CaseIterable {
    case pendingBind = "待绑定"
    case available = "待使用"
    case redeemed = "已兑换"
    case expired = "已过期"

    var sealTint: UIColor {
        switch self {
        case .available: return .fdWarning
        case .redeemed: return .fdSuccess
        case .expired, .pendingBind: return .fdMuted
        }
    }

    var sealBackground: UIColor {
        switch self {
        case .available: return .fdWarningSoft
        case .redeemed: return .fdSuccessSoft
        case .expired, .pendingBind: return .fdBg2
        }
    }
}

enum BenefitTransferStatus: String {
    case waiting = "等待领取"
    case transferred = "已转赠"

    var sealTint: UIColor {
        switch self {
        case .waiting: return .fdWarning
        case .transferred: return .fdSuccess
        }
    }

    var sealBackground: UIColor {
        switch self {
        case .waiting: return .fdWarningSoft
        case .transferred: return .fdSuccessSoft
        }
    }
}

enum BenefitStatusFilter: Int, CaseIterable {
    case all = 0
    case available
    case redeemed
    case expired
    case transferRecords

    var title: String {
        switch self {
        case .all: return "全部"
        case .available: return "待使用"
        case .redeemed: return "已兑换"
        case .expired: return "已过期"
        case .transferRecords: return "转赠记录"
        }
    }

    var cardStatus: BenefitCardStatus? {
        switch self {
        case .available: return .available
        case .redeemed: return .redeemed
        case .expired: return .expired
        default: return nil
        }
    }
}

struct BenefitCard: Equatable {
    let id: String
    let code: String
    let name: String
    let amount: Double
    let validUntil: String
    let status: BenefitCardStatus
    let boundAt: String?
    let redeemedAt: String?
    let orderId: String?
    let pendingTransferId: String?
    let transferredOnce: Bool

    var isExpiringSoon: Bool {
        guard status == .available,
              let date = Self.parseDate(validUntil) else { return false }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? -1
        return days >= 0 && days <= 7
    }

    private static func parseDate(_ value: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        for format in ["yyyy-MM-dd", "yyyy-MM-dd HH:mm:ss", "yyyy/MM/dd"] {
            f.dateFormat = format
            if let d = f.date(from: value) { return d }
        }
        return ISO8601DateFormatter().date(from: value)
    }
}

struct BenefitTransferRecord: Equatable {
    let id: String
    let cardId: String
    let cardName: String
    let amount: Double
    let validUntil: String
    let status: BenefitTransferStatus
    let sharedAt: String
    let expiresAt: String
    let claimedAt: String?
    let recipientName: String?
    let message: String?
}

enum BenefitListEntry: Equatable {
    case card(BenefitCard)
    case transfer(BenefitTransferRecord)

    var id: String {
        switch self {
        case .card(let c): return "card-\(c.id)"
        case .transfer(let t): return "transfer-\(t.id)"
        }
    }
}

// MARK: - 卡包优惠券

enum VoucherCouponStatus: String {
    /// 内部「已领取」——面向用户展示「待使用」
    case received = "已领取"
    case used = "已领用"
    case expired = "已过期"

    var displayLabel: String {
        switch self {
        case .received: return "待使用"
        case .used: return "已领用"
        case .expired: return "已过期"
        }
    }
}

enum VoucherCouponType: String {
    case fullReduction = "满减券"
    case priceOff = "减价券"
    case discount = "折扣券"
}

enum VoucherCouponScopeRule: String {
    case include = "仅以下业务适用"
    case exclude = "以下业务不适用"

    var prefix: String {
        self == .include ? "适用" : "不适用"
    }
}

enum CouponStatusFilter: Int, CaseIterable {
    case all = 0
    case available
    case used
    case expired

    var title: String {
        switch self {
        case .all: return "全部"
        case .available: return "待使用"
        case .used: return "已领用"
        case .expired: return "已过期"
        }
    }

    var status: VoucherCouponStatus? {
        switch self {
        case .available: return .received
        case .used: return .used
        case .expired: return .expired
        default: return nil
        }
    }

    /// Query `status`：1 待使用 / 2 已领用 / 3 已过期；全部不传
    var apiStatus: Int? {
        switch self {
        case .available: return 1
        case .used: return 2
        case .expired: return 3
        case .all: return nil
        }
    }
}

struct VoucherCouponAsset: Equatable {
    let id: String
    let name: String
    let type: VoucherCouponType
    let threshold: Double
    let discountAmount: Double?
    let discountRate: Double?
    let maxDiscount: Double?
    let scopeRule: VoucherCouponScopeRule
    let businessCategories: [String]
    let packageNames: [String]
    let institutionNames: [String]
    let excludedProductNames: [String]
    /// 使用规则说明（`description`）
    let ruleDescription: String?
    let receivedAt: String
    let effectiveEndAt: String
    let status: VoucherCouponStatus
    let usedAt: String?

    var benefitText: String {
        if type == .discount, let rate = discountRate {
            return String(format: "%g折", rate)
        }
        let amount = discountAmount ?? 0
        if amount == floor(amount) {
            return "¥\(Int(amount))"
        }
        return String(format: "¥%.2f", amount)
    }

    var thresholdText: String {
        if threshold <= 0 { return "无门槛" }
        if threshold == floor(threshold) {
            return "满 ¥\(Int(threshold)) 可用"
        }
        return String(format: "满 ¥%.2f 可用", threshold)
    }

    /// 是否有可展开的使用规则内容（对齐 Apifox 非空才展示）
    var hasExpandableRules: Bool {
        !businessCategories.isEmpty
            || !packageNames.isEmpty
            || !institutionNames.isEmpty
            || !excludedProductNames.isEmpty
            || !(ruleDescription?.isEmpty ?? true)
    }
}
