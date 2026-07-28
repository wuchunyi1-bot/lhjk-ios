import Foundation

/// 我的卡券资产服务 — 对齐 funde `benefit-card-state` / `coupon-state`
///
/// 当前为本地 Mock；卡包优惠券与订单 `CouponService` 独立维护。
final class VoucherService {

    static let shared = VoucherService()

    private init() {}

    // MARK: - Query

    func getBenefitCards() -> [BenefitCard] {
        Self.mockBenefitCards
    }

    func getTransferRecords() -> [BenefitTransferRecord] {
        Self.mockTransfers
    }

    func getCouponAssets() -> [VoucherCouponAsset] {
        Self.mockCoupons
    }

    /// 待使用权益卡（未转赠锁定）
    var availableBenefitCount: Int {
        getBenefitCards().filter { $0.status == .available && $0.pendingTransferId == nil }.count
    }

    /// 待使用优惠券（内部已领取）
    var availableCouponCount: Int {
        getCouponAssets().filter { $0.status == .received }.count
    }

    /// 我的页角标
    var meBadgeCount: Int {
        availableBenefitCount + availableCouponCount
    }

    var meBadgeText: String? {
        let n = meBadgeCount
        if n <= 0 { return nil }
        if n > 99 { return "99+" }
        return "\(n)"
    }

    // MARK: - Mock（对齐 funde seed，去掉演示专用卡）

    private static let mockBenefitCards: [BenefitCard] = [
        BenefitCard(id: "benefit-card-001", code: "SGHK-2026-0201", name: "三好健康权益卡", amount: 300, validUntil: "2026-12-31", status: .available, boundAt: "2026-07-15", redeemedAt: nil, orderId: nil, pendingTransferId: nil, transferredOnce: false),
        BenefitCard(id: "benefit-card-002", code: "SGHK-2026-0512", name: "企业健康权益卡", amount: 500, validUntil: "2026-10-20", status: .available, boundAt: "2026-06-12", redeemedAt: nil, orderId: nil, pendingTransferId: nil, transferredOnce: false),
        BenefitCard(id: "benefit-card-003", code: "SGHK-2025-1108", name: "尊享健康权益卡", amount: 1000, validUntil: "2026-11-07", status: .redeemed, boundAt: "2025-11-08", redeemedAt: "2026-05-20", orderId: "demo-benefit-order-001", pendingTransferId: nil, transferredOnce: false),
        BenefitCard(id: "benefit-card-004", code: "SGHK-2024-0318", name: "企业健康权益卡", amount: 300, validUntil: "2025-12-31", status: .expired, boundAt: "2024-03-18", redeemedAt: nil, orderId: nil, pendingTransferId: nil, transferredOnce: false),
        BenefitCard(id: "benefit-card-hbs-200", code: "HBS-2026-0200", name: "三好卡", amount: 200, validUntil: "2026-09-30", status: .available, boundAt: "2026-07-26", redeemedAt: nil, orderId: nil, pendingTransferId: nil, transferredOnce: false),
        BenefitCard(id: "benefit-card-hbs-500", code: "HBS-2026-0500", name: "金穗卡", amount: 500, validUntil: "2026-12-31", status: .available, boundAt: "2026-07-26", redeemedAt: nil, orderId: nil, pendingTransferId: nil, transferredOnce: true),
        BenefitCard(id: "benefit-card-pending", code: "SGHK-DEMO-PENDING", name: "等待领取演示权益卡", amount: 500, validUntil: "2026-10-20", status: .available, boundAt: "2026-07-21", redeemedAt: nil, orderId: nil, pendingTransferId: "transfer-record-pending", transferredOnce: false),
    ]

    private static var mockTransfers: [BenefitTransferRecord] {
        let pendingExpires = Date().addingTimeInterval(22 * 3600)
        let iso = ISO8601DateFormatter()
        return [
            BenefitTransferRecord(
                id: "transfer-record-001",
                cardId: "benefit-card-old-001",
                cardName: "三好健康权益卡",
                amount: 300,
                validUntil: "2026-12-31",
                status: .transferred,
                sharedAt: "2026-07-16T09:00:00Z",
                expiresAt: "2026-07-17T09:00:00Z",
                claimedAt: "2026-07-16T10:12:00Z",
                recipientName: "王建国",
                message: nil
            ),
            BenefitTransferRecord(
                id: "transfer-record-pending",
                cardId: "benefit-card-pending",
                cardName: "等待领取演示权益卡",
                amount: 500,
                validUntil: "2026-10-20",
                status: .waiting,
                sharedAt: iso.string(from: Date().addingTimeInterval(-2 * 3600)),
                expiresAt: iso.string(from: pendingExpires),
                claimedAt: nil,
                recipientName: nil,
                message: "送你一份健康关怀"
            ),
        ]
    }

    private static let mockCoupons: [VoucherCouponAsset] = [
        VoucherCouponAsset(id: "coupon-01", name: "会员健康满减券-满100减50", type: .fullReduction, threshold: 100, discountAmount: 50, discountRate: nil, maxDiscount: nil, scopeRule: .include, businessCategories: ["高血压管理"], packageNames: ["高血压年度管理套餐"], institutionNames: ["富德健康广州机构"], excludedProductNames: ["营养补充剂"], receivedAt: "2026-07-26 10:00:00", effectiveEndAt: "2026-12-31 23:59:59", status: .received, usedAt: nil),
        VoucherCouponAsset(id: "coupon-02", name: "健管服务满减券-满200减80", type: .fullReduction, threshold: 200, discountAmount: 80, discountRate: nil, maxDiscount: nil, scopeRule: .exclude, businessCategories: ["健康体检"], packageNames: ["健康体检基础套餐"], institutionNames: ["富德健康深圳机构"], excludedProductNames: ["营养补充剂"], receivedAt: "2026-07-25 10:00:00", effectiveEndAt: "2026-12-31 23:59:59", status: .received, usedAt: nil),
        VoucherCouponAsset(id: "coupon-03", name: "会员服务折扣券-8.8折", type: .discount, threshold: 100, discountAmount: nil, discountRate: 8.8, maxDiscount: 100, scopeRule: .include, businessCategories: ["会员综合服务"], packageNames: [], institutionNames: [], excludedProductNames: [], receivedAt: "2026-07-24 10:00:00", effectiveEndAt: "2026-12-31 23:59:59", status: .received, usedAt: nil),
        VoucherCouponAsset(id: "coupon-04", name: "复购服务折扣券-9.5折", type: .discount, threshold: 200, discountAmount: nil, discountRate: 9.5, maxDiscount: 50, scopeRule: .include, businessCategories: ["会员综合服务"], packageNames: [], institutionNames: [], excludedProductNames: [], receivedAt: "2026-06-20 10:00:00", effectiveEndAt: "2026-12-31 23:59:59", status: .used, usedAt: "2026-07-12 14:30:00"),
        VoucherCouponAsset(id: "coupon-05", name: "会员服务减价券-满100减50", type: .priceOff, threshold: 100, discountAmount: 50, discountRate: nil, maxDiscount: nil, scopeRule: .include, businessCategories: ["会员综合服务"], packageNames: [], institutionNames: [], excludedProductNames: [], receivedAt: "2026-06-18 10:00:00", effectiveEndAt: "2026-12-31 23:59:59", status: .used, usedAt: "2026-07-08 09:20:00"),
        VoucherCouponAsset(id: "coupon-06", name: "健管服务减价券-满200减80", type: .priceOff, threshold: 200, discountAmount: 80, discountRate: nil, maxDiscount: nil, scopeRule: .exclude, businessCategories: ["健康体检"], packageNames: [], institutionNames: [], excludedProductNames: [], receivedAt: "2026-04-20 10:00:00", effectiveEndAt: "2026-06-30 23:59:59", status: .expired, usedAt: nil),
    ]
}
