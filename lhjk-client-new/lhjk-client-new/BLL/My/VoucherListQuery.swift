import Foundation

/// 卡包列表筛选 / 排序 — 供各状态 Tab VC 复用
enum VoucherListQuery {

    // MARK: - Benefit

    static func benefitEntries(
        cards: [BenefitCard],
        transfers: [BenefitTransferRecord],
        filter: BenefitStatusFilter
    ) -> [BenefitListEntry] {
        let visible: [BenefitCardStatus] = [.pendingBind, .pendingReceive, .available, .redeemed, .expired]
        let filteredCards = cards
            .filter { visible.contains($0.status) }
            .filter { $0.status == .pendingReceive || $0.pendingTransferId == nil }
            .filter { filter.cardStatus == nil || $0.status == filter.cardStatus }
            .sorted { compareCards($0, $1) }

        if filter == .transferRecords {
            return transfers.sorted(by: compareTransfers).map { .transfer($0) }
        }
        return filteredCards.map { .card($0) }
    }

    /// 「全部」Tab：保持 `getCustomerPage` records 顺序，不按待领取/待使用等状态重排
    static func allTabEntries(_ entries: [BenefitListEntry]) -> [BenefitListEntry] {
        let visible: [BenefitCardStatus] = [.pendingBind, .pendingReceive, .available, .redeemed, .expired]
        return entries.filter { entry in
            switch entry {
            case .card(let card):
                return visible.contains(card.status)
                    && (card.status == .pendingReceive || card.pendingTransferId == nil)
            case .transfer(let record):
                return record.status == .waiting
            }
        }
    }

    static func showsBindEntry(for filter: BenefitStatusFilter) -> Bool {
        filter != .transferRecords
    }

    // MARK: - Private

    private static func compareCards(_ a: BenefitCard, _ b: BenefitCard) -> Bool {
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
        // 原型：不展示动态倒计时，固定文案 + 赠送日期
        _ = expiresAt
        _ = now
        return "24小时未领取自动退回"
    }

    static func waitingTransferMeta(sharedAt: String) -> String {
        let day: String = {
            guard let d = parseDate(sharedAt) else {
                let s = sharedAt.replacingOccurrences(of: "T", with: " ")
                return s.isEmpty ? "--" : String(s.prefix(10))
            }
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: d)
        }()
        return "24小时未领取自动退回\n赠送时间 \(day)"
    }
}
