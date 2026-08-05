import Foundation

/// 我的卡券资产服务 — 权益卡暂 Mock；优惠券走 `CouponService.getCouponTakeList`
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

    /// 待使用权益卡（未转赠锁定）
    var availableBenefitCount: Int {
        getBenefitCards().filter { $0.status == .available && $0.pendingTransferId == nil }.count
    }

    /// 待使用优惠券（接口 status=1 缓存总数）
    var availableCouponCount: Int {
        CouponService.shared.cachedAvailableCouponCount
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

    /// 异步刷新优惠券待使用数（供「我的」角标）
    func refreshAvailableCouponCount() async {
        _ = try? await CouponService.shared.refreshAvailableCouponCount()
    }

    // MARK: - Mock（仅权益卡；对齐 funde seed）

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
}
