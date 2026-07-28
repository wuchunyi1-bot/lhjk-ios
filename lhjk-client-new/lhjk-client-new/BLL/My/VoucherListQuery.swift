import Foundation

/// 卡包列表筛选 / 排序 — 供各状态 Tab VC 复用
enum VoucherListQuery {

    // MARK: - Benefit

    static func benefitEntries(
        cards: [BenefitCard],
        transfers: [BenefitTransferRecord],
        filter: BenefitStatusFilter
    ) -> [BenefitListEntry] {
        let visible: [BenefitCardStatus] = [.available, .redeemed, .expired]
        let filteredCards = cards
            .filter { visible.contains($0.status) }
            .filter { $0.pendingTransferId == nil }
            .filter { filter.cardStatus == nil || $0.status == filter.cardStatus }
            .sorted { compareCards($0, $1, filter: filter) }

        let filteredTransfers: [BenefitTransferRecord]
        switch filter {
        case .all:
            filteredTransfers = transfers.filter { $0.status == .waiting }.sorted(by: compareTransfers)
        case .transferRecords:
            filteredTransfers = transfers.sorted(by: compareTransfers)
        default:
            filteredTransfers = []
        }

        if filter == .transferRecords {
            return filteredTransfers.map { .transfer($0) }
        }
        if filter == .all {
            var entries: [BenefitListEntry] =
                filteredCards.map { .card($0) } + filteredTransfers.map { .transfer($0) }
            entries.sort { lhs, rhs in
                let lr = entryRank(lhs)
                let rr = entryRank(rhs)
                if lr != rr { return lr < rr }
                switch (lhs, rhs) {
                case (.card(let a), .card(let b)): return compareCards(a, b, filter: filter)
                case (.transfer(let a), .transfer(let b)): return compareTransfers(a, b)
                default: return false
                }
            }
            return entries
        }
        return filteredCards.map { .card($0) }
    }

    static func showsBindEntry(for filter: BenefitStatusFilter) -> Bool {
        filter != .transferRecords
    }

    // MARK: - Coupon

    static func coupons(
        assets: [VoucherCouponAsset],
        filter: CouponStatusFilter
    ) -> [VoucherCouponAsset] {
        assets
            .filter { filter.status == nil || $0.status == filter.status }
            .sorted { compareCoupons($0, $1, filter: filter) }
    }

    // MARK: - Private

    private static func entryRank(_ entry: BenefitListEntry) -> Int {
        switch entry {
        case .card(let c):
            switch c.status {
            case .available: return 0
            case .redeemed: return 2
            case .expired: return 3
            case .pendingBind: return 4
            }
        case .transfer:
            return 1
        }
    }

    private static func compareCards(_ a: BenefitCard, _ b: BenefitCard, filter: BenefitStatusFilter) -> Bool {
        if filter == .all, a.status != b.status {
            return statusRank(a.status) < statusRank(b.status)
        }
        switch a.status {
        case .available:
            let va = parseDate(a.validUntil)?.timeIntervalSince1970 ?? 0
            let vb = parseDate(b.validUntil)?.timeIntervalSince1970 ?? 0
            if va != vb { return va < vb }
            let ba = parseDate(a.boundAt ?? "")?.timeIntervalSince1970 ?? 0
            let bb = parseDate(b.boundAt ?? "")?.timeIntervalSince1970 ?? 0
            if ba != bb { return ba > bb }
        case .redeemed:
            let ra = parseDate(a.redeemedAt ?? "")?.timeIntervalSince1970 ?? 0
            let rb = parseDate(b.redeemedAt ?? "")?.timeIntervalSince1970 ?? 0
            if ra != rb { return ra > rb }
        default:
            let va = parseDate(a.validUntil)?.timeIntervalSince1970 ?? 0
            let vb = parseDate(b.validUntil)?.timeIntervalSince1970 ?? 0
            if va != vb { return va > vb }
        }
        return a.id < b.id
    }

    private static func compareTransfers(_ a: BenefitTransferRecord, _ b: BenefitTransferRecord) -> Bool {
        if a.status != b.status { return a.status == .waiting }
        if a.status == .waiting {
            let ea = parseDate(a.expiresAt)?.timeIntervalSince1970 ?? 0
            let eb = parseDate(b.expiresAt)?.timeIntervalSince1970 ?? 0
            if ea != eb { return ea < eb }
        } else {
            let ca = parseDate(a.claimedAt ?? a.sharedAt)?.timeIntervalSince1970 ?? 0
            let cb = parseDate(b.claimedAt ?? b.sharedAt)?.timeIntervalSince1970 ?? 0
            if ca != cb { return ca > cb }
        }
        return a.id < b.id
    }

    private static func compareCoupons(
        _ a: VoucherCouponAsset,
        _ b: VoucherCouponAsset,
        filter: CouponStatusFilter
    ) -> Bool {
        if filter == .all, a.status != b.status {
            return couponRank(a.status) < couponRank(b.status)
        }
        switch a.status {
        case .received:
            let ta = parseDate(a.receivedAt)?.timeIntervalSince1970 ?? 0
            let tb = parseDate(b.receivedAt)?.timeIntervalSince1970 ?? 0
            if ta != tb { return ta > tb }
        case .used:
            let ta = parseDate(a.usedAt ?? "")?.timeIntervalSince1970 ?? 0
            let tb = parseDate(b.usedAt ?? "")?.timeIntervalSince1970 ?? 0
            if ta != tb { return ta > tb }
        case .expired:
            let ta = parseDate(a.effectiveEndAt)?.timeIntervalSince1970 ?? 0
            let tb = parseDate(b.effectiveEndAt)?.timeIntervalSince1970 ?? 0
            if ta != tb { return ta > tb }
        }
        return a.id < b.id
    }

    private static func statusRank(_ s: BenefitCardStatus) -> Int {
        switch s {
        case .available: return 0
        case .redeemed: return 1
        case .expired: return 2
        case .pendingBind: return 3
        }
    }

    private static func couponRank(_ s: VoucherCouponStatus) -> Int {
        switch s {
        case .received: return 0
        case .used: return 1
        case .expired: return 2
        }
    }

    static func parseDate(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        for format in [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd",
            "yyyy/MM/dd",
        ] {
            f.dateFormat = format
            if let d = f.date(from: trimmed) { return d }
        }
        return ISO8601DateFormatter().date(from: trimmed)
    }

    static func remainingTransferText(expiresAt: String, now: Date = Date()) -> String {
        guard let expires = parseDate(expiresAt) else { return "-- 后自动退回" }
        let remaining = max(0, expires.timeIntervalSince(now))
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d:%02d 后自动退回", hours, minutes, seconds)
    }
}
