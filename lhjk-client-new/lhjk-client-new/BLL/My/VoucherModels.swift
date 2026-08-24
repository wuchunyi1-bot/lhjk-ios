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
    case pendingReceive = "待领取"
    case available = "待使用"
    case redeemed = "已兑换"
    case expired = "已过期"
    case transferred = "已转赠"

    var stampImageName: String? {
        switch self {
        case .available: return "benefit_stamp_active"
        case .pendingReceive, .pendingBind: return "benefit_stamp_claiming"
        case .redeemed: return "benefit_stamp_redeemed"
        case .expired: return "benefit_stamp_expired"
        case .transferred: return "benefit_stamp_transferred"
        }
    }

    var sealTint: UIColor {
        switch self {
        case .available: return .fdWarning
        case .redeemed: return .fdSuccess
        case .expired, .pendingBind, .pendingReceive, .transferred: return .fdMuted
        }
    }

    var sealBackground: UIColor {
        switch self {
        case .available: return .fdWarningSoft
        case .redeemed: return .fdSuccessSoft
        case .expired, .pendingBind, .pendingReceive, .transferred: return .fdBg2
        }
    }

    /// API status → UI
    static func fromAPI(_ status: Int) -> BenefitCardStatus? {
        switch status {
        case BenefitAPIStatus.pendingBind.rawValue: return .pendingBind
        case BenefitAPIStatus.pendingReceive.rawValue: return .pendingReceive
        case BenefitAPIStatus.available.rawValue: return .available
        case BenefitAPIStatus.redeemed.rawValue: return .redeemed
        case BenefitAPIStatus.expired.rawValue: return .expired
        default: return nil
        }
    }
}

enum BenefitTransferStatus: String {
    case waiting = "等待领取"
    case transferred = "已转赠"

    var stampImageName: String {
        switch self {
        case .waiting: return "benefit_stamp_claiming"
        case .transferred: return "benefit_stamp_transferred"
        }
    }

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
    case pendingBind
    case pendingReceive
    case available
    case redeemed
    case expired
    case transferRecords

    var title: String {
        switch self {
        case .all: return "全部"
        case .pendingBind: return "待绑定"
        case .pendingReceive: return "待领取"
        case .available: return "待使用"
        case .redeemed: return "已兑换"
        case .expired: return "已过期"
        case .transferRecords: return "转赠记录"
        }
    }

    var cardStatus: BenefitCardStatus? {
        switch self {
        case .pendingBind: return .pendingBind
        case .pendingReceive: return .pendingReceive
        case .available: return .available
        case .redeemed: return .redeemed
        case .expired: return .expired
        default: return nil
        }
    }

    /// `getCustomerPage` Query status；全部 / 转赠记录不传
    var apiStatus: Int? {
        switch self {
        case .pendingBind: return BenefitAPIStatus.pendingBind.rawValue
        case .pendingReceive: return BenefitAPIStatus.pendingReceive.rawValue
        case .available: return BenefitAPIStatus.available.rawValue
        case .redeemed: return BenefitAPIStatus.redeemed.rawValue
        case .expired: return BenefitAPIStatus.expired.rawValue
        case .all, .transferRecords: return nil
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
    let imageUrl: String?
    /// 好友转赠 / 员工发放领取后的来源方快照
    let sourcePartyName: String?

    /// 待使用且未处于转赠锁定
    var canGift: Bool {
        status == .available && (pendingTransferId?.isEmpty ?? true)
    }

    var isExpiringSoon: Bool {
        guard status == .available,
              let date = Self.parseDate(validUntil) else { return false }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? -1
        return days >= 0 && days <= 7
    }

    private static func parseDate(_ value: String) -> Date? {
        VoucherListQuery.parseDate(value)
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
    let imageUrl: String?
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
    case used = "已使用"
    case expired = "已过期"

    var displayLabel: String {
        switch self {
        case .received: return "待使用"
        case .used: return "已使用"
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
        case .used: return "已使用"
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

// MARK: - 权益卡 API DTO（C 端）
// Apifox: App端/商城/员工权益卡管理（含普通用户接口）
// 文档：benefits-card-frontend-api.md

/// 实例状态：C 端常用 2 待领取 / 3 待使用 / 4 已兑换 / 5 已过期
enum BenefitAPIStatus: Int {
    case pendingBind = 1
    case pendingReceive = 2
    case available = 3
    case redeemed = 4
    case expired = 5
}

/// `BenefitsTakePageVO`
struct BenefitsTakePageItem: Decodable, Equatable {
    let id: Int64?
    let benefitsNumber: String?
    let benefitsName: String?
    let imageUrl: String?
    let price: Double?
    let status: Int?
    let endTime: String?
    let pendingTransferId: Int64?
    let pendingTransferNo: String?
    let giftedAt: String?
    let expiresAt: String?
    let redeemedAt: String?
    let operationNo: String?
    let orderId: Int64?
    let orderNo: String?
    let sourcePartyUserId: Int64?
    let sourcePartyName: String?
    let createTime: String?

    private enum CodingKeys: String, CodingKey {
        case id, benefitsNumber, benefitsName, imageUrl, price, status, endTime
        case pendingTransferId, pendingTransferNo, giftedAt, expiresAt, redeemedAt
        case operationNo, orderId, orderNo, sourcePartyUserId, sourcePartyName, createTime
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.int64(c, .id)
        benefitsNumber = try c.decodeIfPresent(String.self, forKey: .benefitsNumber)
        benefitsName = try c.decodeIfPresent(String.self, forKey: .benefitsName)
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
        price = Self.double(c, .price)
        status = HospitalPackageInt.decodeIfPresent(c, key: .status)
        endTime = try c.decodeIfPresent(String.self, forKey: .endTime)
        pendingTransferId = Self.int64(c, .pendingTransferId)
        pendingTransferNo = try c.decodeIfPresent(String.self, forKey: .pendingTransferNo)
        giftedAt = try c.decodeIfPresent(String.self, forKey: .giftedAt)
        expiresAt = try c.decodeIfPresent(String.self, forKey: .expiresAt)
        redeemedAt = try c.decodeIfPresent(String.self, forKey: .redeemedAt)
        operationNo = try c.decodeIfPresent(String.self, forKey: .operationNo)
        orderId = Self.int64(c, .orderId)
        orderNo = try c.decodeIfPresent(String.self, forKey: .orderNo)
        sourcePartyUserId = Self.int64(c, .sourcePartyUserId)
        sourcePartyName = try c.decodeIfPresent(String.self, forKey: .sourcePartyName)
        createTime = try c.decodeIfPresent(String.self, forKey: .createTime)
    }

    private static func int64<K: CodingKey>(_ c: KeyedDecodingContainer<K>, _ key: K) -> Int64? {
        if let v = try? c.decodeIfPresent(Int64.self, forKey: key) { return v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: key) { return Int64(v) }
        if let s = try? c.decodeIfPresent(String.self, forKey: key) {
            return Int64(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    private static func double<K: CodingKey>(_ c: KeyedDecodingContainer<K>, _ key: K) -> Double? {
        if let v = try? c.decodeIfPresent(Double.self, forKey: key) { return v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: key) { return Double(v) }
        if let s = try? c.decodeIfPresent(String.self, forKey: key) {
            return Double(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}

/// `BenefitsGiftRecordVO`
struct BenefitsGiftRecordItem: Decodable, Equatable {
    let benefitsTakeId: Int64?
    let operationNo: String?
    let benefitsName: String?
    let imageUrl: String?
    let price: Double?
    /// `PENDING_RECEIVE` / `TRANSFERRED`
    let status: String?
    let giftedAt: String?
    let expiresAt: String?
    let recipientName: String?
    let claimedAt: String?

    private enum CodingKeys: String, CodingKey {
        case benefitsTakeId, operationNo, benefitsName, imageUrl, price, status
        case giftedAt, expiresAt, recipientName, claimedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        benefitsTakeId = Self.int64(c, .benefitsTakeId)
        operationNo = try c.decodeIfPresent(String.self, forKey: .operationNo)
        benefitsName = try c.decodeIfPresent(String.self, forKey: .benefitsName)
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
        price = Self.double(c, .price)
        status = try c.decodeIfPresent(String.self, forKey: .status)
        giftedAt = try c.decodeIfPresent(String.self, forKey: .giftedAt)
        expiresAt = try c.decodeIfPresent(String.self, forKey: .expiresAt)
        recipientName = try c.decodeIfPresent(String.self, forKey: .recipientName)
        claimedAt = try c.decodeIfPresent(String.self, forKey: .claimedAt)
    }

    private static func int64<K: CodingKey>(_ c: KeyedDecodingContainer<K>, _ key: K) -> Int64? {
        if let v = try? c.decodeIfPresent(Int64.self, forKey: key) { return v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: key) { return Int64(v) }
        if let s = try? c.decodeIfPresent(String.self, forKey: key) {
            return Int64(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    private static func double<K: CodingKey>(_ c: KeyedDecodingContainer<K>, _ key: K) -> Double? {
        if let v = try? c.decodeIfPresent(Double.self, forKey: key) { return v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: key) { return Double(v) }
        if let s = try? c.decodeIfPresent(String.self, forKey: key) {
            return Double(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}

/// `BenefitsTakeStatusCountVO`
struct BenefitsTakeStatusCountItem: Decodable, Equatable {
    let name: String?
    let value: String?
    let count: Int?

    private enum CodingKeys: String, CodingKey {
        case name, value, count
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        if let s = try? c.decodeIfPresent(String.self, forKey: .value) {
            value = s
        } else if let i = try? c.decodeIfPresent(Int.self, forKey: .value) {
            value = String(i)
        } else {
            value = nil
        }
        count = HospitalPackageInt.decodeIfPresent(c, key: .count)
    }
}

/// `BenefitsBindPreCheckVO`
struct BenefitsBindPreCheckVO: Decodable, Equatable {
    /// 1 可绑定 / 2 已绑定 / 3 已过期 / 4 不存在
    let checkStatus: String?
    let benefitsTakeId: Int64?
    let benefitsName: String?
    let imageUrl: String?
    let price: Double?
    let endTime: String?

    private enum CodingKeys: String, CodingKey {
        case checkStatus, benefitsTakeId, benefitsName, imageUrl, price, endTime
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let s = try? c.decodeIfPresent(String.self, forKey: .checkStatus) {
            checkStatus = s
        } else if let i = try? c.decodeIfPresent(Int.self, forKey: .checkStatus) {
            checkStatus = String(i)
        } else {
            checkStatus = nil
        }
        benefitsTakeId = {
            if let v = try? c.decodeIfPresent(Int64.self, forKey: .benefitsTakeId) { return v }
            if let v = try? c.decodeIfPresent(Int.self, forKey: .benefitsTakeId) { return Int64(v) }
            return nil
        }()
        benefitsName = try c.decodeIfPresent(String.self, forKey: .benefitsName)
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
        price = {
            if let v = try? c.decodeIfPresent(Double.self, forKey: .price) { return v }
            if let v = try? c.decodeIfPresent(Int.self, forKey: .price) { return Double(v) }
            return nil
        }()
        endTime = try c.decodeIfPresent(String.self, forKey: .endTime)
    }

    var checkStatusCode: Int {
        Int(checkStatus?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") ?? 0
    }
}

/// `BenefitsIssueVO`（转赠/发放返回）
///
/// 示例字段：`operationNo` / `pageStatus` / `expireTime` / `giftMessage` / `giverName` /
/// `appId`（小程序 AppID）/ `path`（领取页，可空）/ `cards`
struct BenefitsIssueVO: Decodable, Equatable {
    let operationNo: String?
    let pageStatus: String?
    let expireTime: String?
    let giftMessage: String?
    let giverName: String?
    /// 小程序 AppID（`wx…`）；分享 SDK 仍用 `WeChatConfig.miniProgramUserName`（`gh_`）
    let appId: String?
    /// 服务端下发的领取 path；空则客户端用 `WeChatConfig.benefitClaimPath`
    let path: String?
    let cards: [BenefitsIssueCardVO]?

    init(
        operationNo: String? = nil,
        pageStatus: String? = nil,
        expireTime: String? = nil,
        giftMessage: String? = nil,
        giverName: String? = nil,
        appId: String? = nil,
        path: String? = nil,
        cards: [BenefitsIssueCardVO]? = nil
    ) {
        self.operationNo = operationNo
        self.pageStatus = pageStatus
        self.expireTime = expireTime
        self.giftMessage = giftMessage
        self.giverName = giverName
        self.appId = appId
        self.path = path
        self.cards = cards
    }

    /// 分享用主卡（首张）
    var primaryCard: BenefitsIssueCardVO? { cards?.first }
}

/// 转赠返回中的卡摘要（`BenefitsIssueVO.cards[]`）
struct BenefitsIssueCardVO: Decodable, Equatable {
    let id: String?
    let benefitsNumber: String?
    let benefitsName: String?
    let imageUrl: String?
    let price: Double?
    let status: Int?
    let endTime: String?

    private enum CodingKeys: String, CodingKey {
        case id, benefitsNumber, benefitsName, imageUrl, price, status, endTime
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let s = try? c.decodeIfPresent(String.self, forKey: .id) {
            id = s
        } else if let i = try? c.decodeIfPresent(Int64.self, forKey: .id) {
            id = String(i)
        } else {
            id = nil
        }
        benefitsNumber = try c.decodeIfPresent(String.self, forKey: .benefitsNumber)
        benefitsName = try c.decodeIfPresent(String.self, forKey: .benefitsName)
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
        if let d = try? c.decodeIfPresent(Double.self, forKey: .price) {
            price = d
        } else if let i = try? c.decodeIfPresent(Int.self, forKey: .price) {
            price = Double(i)
        } else if let s = try? c.decodeIfPresent(String.self, forKey: .price) {
            price = Double(s)
        } else {
            price = nil
        }
        if let i = try? c.decodeIfPresent(Int.self, forKey: .status) {
            status = i
        } else if let s = try? c.decodeIfPresent(String.self, forKey: .status) {
            status = Int(s)
        } else {
            status = nil
        }
        endTime = try c.decodeIfPresent(String.self, forKey: .endTime)
    }
}

struct PaginatedBenefitsTakeData: Decodable {
    let totalRecords: Int?
    let pageSize: Int?
    let totalPages: Int?
    let currentPage: Int?
    let records: [BenefitsTakePageItem]?

    enum CodingKeys: String, CodingKey {
        case totalRecords = "totalCount"
        case pageSize
        case totalPages = "totalPage"
        case currentPage = "currPage"
        case records = "list"
        case totalRecordsCN = "总记录数"
        case pageSizeCN = "每页记录数"
        case totalPagesCN = "总页数"
        case currentPageCN = "当前页数"
        case recordsCN = "数据集合"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalRecords = Self.decodeInt(c, .totalRecords) ?? Self.decodeInt(c, .totalRecordsCN)
        pageSize = Self.decodeInt(c, .pageSize) ?? Self.decodeInt(c, .pageSizeCN)
        totalPages = Self.decodeInt(c, .totalPages) ?? Self.decodeInt(c, .totalPagesCN)
        currentPage = Self.decodeInt(c, .currentPage) ?? Self.decodeInt(c, .currentPageCN)
        records = (try? c.decodeIfPresent([BenefitsTakePageItem].self, forKey: .records))
            ?? (try? c.decodeIfPresent([BenefitsTakePageItem].self, forKey: .recordsCN))
    }

    private static func decodeInt(
        _ c: KeyedDecodingContainer<CodingKeys>,
        _ key: CodingKeys
    ) -> Int? {
        if let v = try? c.decodeIfPresent(Int.self, forKey: key) { return v }
        if let s = try? c.decodeIfPresent(String.self, forKey: key) {
            return Int(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}

struct PaginatedBenefitsGiftData: Decodable {
    let totalRecords: Int?
    let pageSize: Int?
    let totalPages: Int?
    let currentPage: Int?
    let records: [BenefitsGiftRecordItem]?

    enum CodingKeys: String, CodingKey {
        case totalRecords = "totalCount"
        case pageSize
        case totalPages = "totalPage"
        case currentPage = "currPage"
        case records = "list"
        case totalRecordsCN = "总记录数"
        case pageSizeCN = "每页记录数"
        case totalPagesCN = "总页数"
        case currentPageCN = "当前页数"
        case recordsCN = "数据集合"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalRecords = Self.decodeInt(c, .totalRecords) ?? Self.decodeInt(c, .totalRecordsCN)
        pageSize = Self.decodeInt(c, .pageSize) ?? Self.decodeInt(c, .pageSizeCN)
        totalPages = Self.decodeInt(c, .totalPages) ?? Self.decodeInt(c, .totalPagesCN)
        currentPage = Self.decodeInt(c, .currentPage) ?? Self.decodeInt(c, .currentPageCN)
        records = (try? c.decodeIfPresent([BenefitsGiftRecordItem].self, forKey: .records))
            ?? (try? c.decodeIfPresent([BenefitsGiftRecordItem].self, forKey: .recordsCN))
    }

    private static func decodeInt(
        _ c: KeyedDecodingContainer<CodingKeys>,
        _ key: CodingKeys
    ) -> Int? {
        if let v = try? c.decodeIfPresent(Int.self, forKey: key) { return v }
        if let s = try? c.decodeIfPresent(String.self, forKey: key) {
            return Int(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}

// MARK: - Domain mapping

enum BenefitMapper {

    static func card(from item: BenefitsTakePageItem) -> BenefitCard? {
        guard let apiStatus = item.status, let mapped = BenefitCardStatus.fromAPI(apiStatus) else {
            return nil
        }
        // status=2 走转赠展示，不进普通卡列表
        if apiStatus == BenefitAPIStatus.pendingReceive.rawValue { return nil }

        let id = item.id.map(String.init) ?? UUID().uuidString
        let pendingId = item.pendingTransferId.map(String.init)
        return BenefitCard(
            id: id,
            code: item.benefitsNumber ?? "",
            name: nonEmpty(item.benefitsName) ?? "权益卡",
            amount: max(0, item.price ?? 0),
            validUntil: displayDay(item.endTime) ?? (item.endTime ?? ""),
            status: mapped,
            boundAt: item.createTime,
            redeemedAt: item.redeemedAt,
            orderId: item.orderId.map(String.init) ?? item.orderNo,
            pendingTransferId: pendingId,
            imageUrl: item.imageUrl,
            sourcePartyName: nonEmpty(item.sourcePartyName)
        )
    }

    /// 卡包中 status=2（转赠中）→ 等待领取样式
    static func pendingTransfer(from item: BenefitsTakePageItem) -> BenefitTransferRecord? {
        guard item.status == BenefitAPIStatus.pendingReceive.rawValue
                || item.pendingTransferId != nil else { return nil }
        let id = item.pendingTransferId.map(String.init)
            ?? item.pendingTransferNo
            ?? item.id.map { "pending-\($0)" }
            ?? UUID().uuidString
        return BenefitTransferRecord(
            id: id,
            cardId: item.id.map(String.init) ?? "",
            cardName: nonEmpty(item.benefitsName) ?? "权益卡",
            amount: max(0, item.price ?? 0),
            validUntil: displayDay(item.endTime) ?? (item.endTime ?? ""),
            status: .waiting,
            sharedAt: item.giftedAt ?? "",
            expiresAt: item.expiresAt ?? "",
            claimedAt: nil,
            recipientName: nil,
            message: nil,
            imageUrl: item.imageUrl
        )
    }

    static func transfer(from item: BenefitsGiftRecordItem) -> BenefitTransferRecord {
        let raw = (item.status ?? "").uppercased()
        let status: BenefitTransferStatus =
            raw.contains("TRANSFERRED") ? .transferred : .waiting
        let id = item.operationNo
            ?? item.benefitsTakeId.map(String.init)
            ?? UUID().uuidString
        return BenefitTransferRecord(
            id: id,
            cardId: item.benefitsTakeId.map(String.init) ?? "",
            cardName: nonEmpty(item.benefitsName) ?? "权益卡",
            amount: max(0, item.price ?? 0),
            validUntil: "",
            status: status,
            sharedAt: item.giftedAt ?? "",
            expiresAt: item.expiresAt ?? "",
            claimedAt: item.claimedAt,
            recipientName: item.recipientName,
            message: nil,
            imageUrl: item.imageUrl
        )
    }

    private static func nonEmpty(_ value: String?) -> String? {
        let t = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return t.isEmpty ? nil : t
    }

    private static func displayDay(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        let normalized = value.replacingOccurrences(of: "T", with: " ")
        return String(normalized.prefix(10))
    }
}

// MARK: - 激活兑换 / 兑换套餐 / 订单权益卡

/// `BenefitsActivationOverviewVO`
struct BenefitsActivationOverviewVO: Decodable, Equatable {
    let availableBenefitsCount: Int64?

    var count: Int { max(0, Int(availableBenefitsCount ?? 0)) }

    private enum CodingKeys: String, CodingKey {
        case availableBenefitsCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        availableBenefitsCount = Self.int64(c, .availableBenefitsCount)
    }

    private static func int64(
        _ c: KeyedDecodingContainer<CodingKeys>,
        _ key: CodingKeys
    ) -> Int64? {
        if let v = try? c.decodeIfPresent(Int64.self, forKey: key) { return v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: key) { return Int64(v) }
        if let s = try? c.decodeIfPresent(String.self, forKey: key) {
            return Int64(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}

/// `BenefitsRedeemCategoryVO`
struct BenefitsRedeemCategoryVO: Decodable, Equatable {
    let id: Int64?
    let name: String?

    var idString: String? {
        guard let id else { return nil }
        return String(id)
    }

    private enum CodingKeys: String, CodingKey { case id, name }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = {
            if let v = try? c.decodeIfPresent(Int64.self, forKey: .id) { return v }
            if let v = try? c.decodeIfPresent(Int.self, forKey: .id) { return Int64(v) }
            if let s = try? c.decodeIfPresent(String.self, forKey: .id) {
                return Int64(s.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            return nil
        }()
        name = try c.decodeIfPresent(String.self, forKey: .name)
    }
}

/// `BenefitsRedeemPageInfoVO`
struct BenefitsRedeemPageInfoVO: Decodable, Equatable {
    let availableBenefitsCount: Int64?
    let hospitalId: Int64?
    let hospitalName: String?
    let hospitalLogo: String?
    let hospitalAddress: String?
    let categories: [BenefitsRedeemCategoryVO]?

    var availableCount: Int { max(0, Int(availableBenefitsCount ?? 0)) }

    var hospitalIdString: String? {
        guard let hospitalId else { return nil }
        return String(hospitalId)
    }

    private enum CodingKeys: String, CodingKey {
        case availableBenefitsCount, hospitalId, hospitalName, hospitalLogo, hospitalAddress, categories
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        availableBenefitsCount = Self.int64(c, .availableBenefitsCount)
        hospitalId = Self.int64(c, .hospitalId)
        hospitalName = try c.decodeIfPresent(String.self, forKey: .hospitalName)
        hospitalLogo = try c.decodeIfPresent(String.self, forKey: .hospitalLogo)
        hospitalAddress = try c.decodeIfPresent(String.self, forKey: .hospitalAddress)
        categories = try c.decodeIfPresent([BenefitsRedeemCategoryVO].self, forKey: .categories)
    }

    private static func int64(
        _ c: KeyedDecodingContainer<CodingKeys>,
        _ key: CodingKeys
    ) -> Int64? {
        if let v = try? c.decodeIfPresent(Int64.self, forKey: key) { return v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: key) { return Int64(v) }
        if let s = try? c.decodeIfPresent(String.self, forKey: key) {
            return Int64(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}

/// `HospitalPackagePageVO`（权益卡可兑套餐）
struct BenefitsRedeemPackageItem: Decodable, Equatable {
    let id: String?
    let hospitalId: Int64?
    let imageUrl: String?
    let price: Double?
    let introduction: String?
    let recommend: Int?
    /// Apifox 主 schema 未列；后端若返回则用于标题
    let name: String?
    let packageName: String?

    var packageId: String {
        let raw = id?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return raw
    }

    var displayTitle: String {
        let n = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !n.isEmpty { return n }
        let p = packageName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !p.isEmpty { return p }
        let intro = introduction?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return intro.isEmpty ? "健康服务套餐" : intro
    }

    var displaySubtitle: String {
        let intro = introduction?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if intro.isEmpty { return "" }
        if intro == displayTitle { return "" }
        return intro
    }

    var hospitalIdString: String? {
        guard let hospitalId else { return nil }
        return String(hospitalId)
    }

    private enum CodingKeys: String, CodingKey {
        case id, hospitalId, imageUrl, price, introduction, recommend, name, packageName
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let s = try? c.decodeIfPresent(String.self, forKey: .id) {
            id = s
        } else if let i = try? c.decodeIfPresent(Int64.self, forKey: .id) {
            id = String(i)
        } else if let i = try? c.decodeIfPresent(Int.self, forKey: .id) {
            id = String(i)
        } else {
            id = nil
        }
        hospitalId = {
            if let v = try? c.decodeIfPresent(Int64.self, forKey: .hospitalId) { return v }
            if let v = try? c.decodeIfPresent(Int.self, forKey: .hospitalId) { return Int64(v) }
            if let s = try? c.decodeIfPresent(String.self, forKey: .hospitalId) {
                return Int64(s.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            return nil
        }()
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
        price = {
            if let v = try? c.decodeIfPresent(Double.self, forKey: .price) { return v }
            if let v = try? c.decodeIfPresent(Int.self, forKey: .price) { return Double(v) }
            if let s = try? c.decodeIfPresent(String.self, forKey: .price) {
                return Double(s.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            return nil
        }()
        introduction = try c.decodeIfPresent(String.self, forKey: .introduction)
        recommend = HospitalPackageInt.decodeIfPresent(c, key: .recommend)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        packageName = try c.decodeIfPresent(String.self, forKey: .packageName)
    }
}

struct PaginatedBenefitsRedeemPackageData: Decodable {
    let totalRecords: Int?
    let pageSize: Int?
    let totalPages: Int?
    let currentPage: Int?
    let records: [BenefitsRedeemPackageItem]?

    enum CodingKeys: String, CodingKey {
        case totalRecords = "totalCount"
        case pageSize
        case totalPages = "totalPage"
        case currentPage = "currPage"
        case records = "list"
        case totalRecordsCN = "总记录数"
        case pageSizeCN = "每页记录数"
        case totalPagesCN = "总页数"
        case currentPageCN = "当前页数"
        case recordsCN = "数据集合"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalRecords = Self.decodeInt(c, .totalRecords) ?? Self.decodeInt(c, .totalRecordsCN)
        pageSize = Self.decodeInt(c, .pageSize) ?? Self.decodeInt(c, .pageSizeCN)
        totalPages = Self.decodeInt(c, .totalPages) ?? Self.decodeInt(c, .totalPagesCN)
        currentPage = Self.decodeInt(c, .currentPage) ?? Self.decodeInt(c, .currentPageCN)
        records = (try? c.decodeIfPresent([BenefitsRedeemPackageItem].self, forKey: .records))
            ?? (try? c.decodeIfPresent([BenefitsRedeemPackageItem].self, forKey: .recordsCN))
    }

    private static func decodeInt(
        _ c: KeyedDecodingContainer<CodingKeys>,
        _ key: CodingKeys
    ) -> Int? {
        if let v = try? c.decodeIfPresent(Int.self, forKey: key) { return v }
        if let s = try? c.decodeIfPresent(String.self, forKey: key) {
            return Int(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}

/// `BenefitsRedeemCardVO`（下单可选权益卡）
struct BenefitsRedeemCardVO: Decodable, Equatable {
    let benefitsTakeId: Int64?
    let benefitsId: Int64?
    let benefitsNumber: String?
    let benefitsName: String?
    let imageUrl: String?
    let price: Double?
    let beginTime: String?
    let endTime: String?
    let selected: Bool?
    let available: Bool?
    let deductAmount: Double?

    var id: String {
        if let benefitsTakeId { return String(benefitsTakeId) }
        return benefitsNumber?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    var displayName: String {
        let n = benefitsName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return n.isEmpty ? "权益卡" : n
    }

    var isSelected: Bool { selected == true }
    var isAvailable: Bool { available != false }

    /// 展示/试算抵扣：优先本次实际抵扣，否则面值
    var effectiveDeduct: Double {
        if let deductAmount { return max(0, deductAmount) }
        return max(0, price ?? 0)
    }

    private enum CodingKeys: String, CodingKey {
        case benefitsTakeId, benefitsId, benefitsNumber, benefitsName, imageUrl
        case price, beginTime, endTime, selected, available, deductAmount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        benefitsTakeId = Self.int64(c, .benefitsTakeId)
        benefitsId = Self.int64(c, .benefitsId)
        benefitsNumber = try c.decodeIfPresent(String.self, forKey: .benefitsNumber)
        benefitsName = try c.decodeIfPresent(String.self, forKey: .benefitsName)
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
        price = Self.double(c, .price)
        beginTime = try c.decodeIfPresent(String.self, forKey: .beginTime)
        endTime = try c.decodeIfPresent(String.self, forKey: .endTime)
        selected = try c.decodeIfPresent(Bool.self, forKey: .selected)
        available = try c.decodeIfPresent(Bool.self, forKey: .available)
        deductAmount = Self.double(c, .deductAmount)
    }

    private static func int64(
        _ c: KeyedDecodingContainer<CodingKeys>,
        _ key: CodingKeys
    ) -> Int64? {
        if let v = try? c.decodeIfPresent(Int64.self, forKey: key) { return v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: key) { return Int64(v) }
        if let s = try? c.decodeIfPresent(String.self, forKey: key) {
            return Int64(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    private static func double(
        _ c: KeyedDecodingContainer<CodingKeys>,
        _ key: CodingKeys
    ) -> Double? {
        if let v = try? c.decodeIfPresent(Double.self, forKey: key) { return v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: key) { return Double(v) }
        if let s = try? c.decodeIfPresent(String.self, forKey: key) {
            return Double(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}
