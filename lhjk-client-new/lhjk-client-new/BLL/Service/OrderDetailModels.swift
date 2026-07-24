import Foundation

// MARK: - 订单详情 DTO
// Apifox: GET /v1/order/getAppOrderDetail
// https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330739e0.md

/// 订单详情 `AppOrderDetailBO`
struct AppOrderDetailBO: Decodable {
    let id: Int64?
    let orderName: String?
    let status: Int?
    let payable: Double?
    let price: Double?
    let paymentType: Int?
    let paymentNo: String?
    let createTime: String?
    let hospitalName: String?
    let doctorName: String?
    let packageDescription: String?
    let packageType: Int?
    let packageImageUrl: String?
    let typeOrder: Int?
    let address: String?
    let receiver: String?
    let phone: String?
    let expressAmount: Double?
    let couponAmount: Double?
    let description: String?
    let logisticsNumber: String?
    let logisticsVendor: String?
    let logisticsChineseName: String?
    let shipmentTime: String?
    let beginTime: String?
    let endTime: String?
    let serviceTime: String?
    let shoppingCartPackageDetailList: [OrderDetailPackageLineBO]?
    let refundId: Int64?
    let refundReasons: String?
    let refuseReasons: String?
    let refundApplyTime: String?
    let applyRefund: Double?
    let refundApplyChannel: String?
    let packageId: String?
    let hospitalId: String?
    let categoryServiceId: String?

    private enum CodingKeys: String, CodingKey {
        case id, orderName, status, payable, price, paymentType, paymentNo, createTime
        case hospitalName, doctorName, packageDescription, packageType, packageImageUrl
        case typeOrder, address, receiver, phone, expressAmount, couponAmount
        case description, logisticsNumber, logisticsVendor, logisticsChineseName
        case shipmentTime, beginTime, endTime, serviceTime
        case shoppingCartPackageDetailList
        case refundId, refundReasons, refuseReasons, refundApplyTime, applyRefund, refundApplyChannel
        case packageId, hospitalId, categoryServiceId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.decodeFlexibleInt64(c, key: .id)
        orderName = try c.decodeIfPresent(String.self, forKey: .orderName)
        status = Self.decodeFlexibleInt(c, key: .status)
        payable = Self.decodeFlexibleDouble(c, key: .payable)
        price = Self.decodeFlexibleDouble(c, key: .price)
        paymentType = Self.decodeFlexibleInt(c, key: .paymentType)
        paymentNo = try c.decodeIfPresent(String.self, forKey: .paymentNo)
        createTime = try c.decodeIfPresent(String.self, forKey: .createTime)
        hospitalName = try c.decodeIfPresent(String.self, forKey: .hospitalName)
        doctorName = try c.decodeIfPresent(String.self, forKey: .doctorName)
        packageDescription = try c.decodeIfPresent(String.self, forKey: .packageDescription)
        packageType = Self.decodeFlexibleInt(c, key: .packageType)
        packageImageUrl = try c.decodeIfPresent(String.self, forKey: .packageImageUrl)
        typeOrder = Self.decodeFlexibleInt(c, key: .typeOrder)
        address = try c.decodeIfPresent(String.self, forKey: .address)
        receiver = try c.decodeIfPresent(String.self, forKey: .receiver)
        phone = try c.decodeIfPresent(String.self, forKey: .phone)
        expressAmount = Self.decodeFlexibleDouble(c, key: .expressAmount)
        couponAmount = Self.decodeFlexibleDouble(c, key: .couponAmount)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        logisticsNumber = try c.decodeIfPresent(String.self, forKey: .logisticsNumber)
        logisticsVendor = try c.decodeIfPresent(String.self, forKey: .logisticsVendor)
        logisticsChineseName = try c.decodeIfPresent(String.self, forKey: .logisticsChineseName)
        shipmentTime = try c.decodeIfPresent(String.self, forKey: .shipmentTime)
        beginTime = try c.decodeIfPresent(String.self, forKey: .beginTime)
        endTime = try c.decodeIfPresent(String.self, forKey: .endTime)
        serviceTime = try c.decodeIfPresent(String.self, forKey: .serviceTime)
        shoppingCartPackageDetailList = Self.decodePackageLines(c, key: .shoppingCartPackageDetailList)
        refundId = Self.decodeFlexibleInt64(c, key: .refundId)
        refundReasons = try c.decodeIfPresent(String.self, forKey: .refundReasons)
        refuseReasons = try c.decodeIfPresent(String.self, forKey: .refuseReasons)
        refundApplyTime = try c.decodeIfPresent(String.self, forKey: .refundApplyTime)
        applyRefund = Self.decodeFlexibleDouble(c, key: .applyRefund)
        refundApplyChannel = try c.decodeIfPresent(String.self, forKey: .refundApplyChannel)
        packageId = HospitalPackageID.decodeOptional(c, key: .packageId)
        hospitalId = HospitalPackageID.decodeOptional(c, key: .hospitalId)
        categoryServiceId = HospitalPackageID.decodeOptional(c, key: .categoryServiceId)
    }

    var resolvedPackageId: String? {
        guard let raw = packageId?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        return raw
    }

    /// 是否展示「续费订单」（租赁套餐）
    var canShowRenewAction: Bool {
        AppPackageType.supportsRenewal(packageType: packageType)
    }

    var orderStatus: AppOrderStatus? {
        guard let status else { return nil }
        return AppOrderStatus(rawValue: status)
    }

    var isExpressDelivery: Bool { typeOrder == 1 }

    var displayInstitutionName: String {
        let name = hospitalName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "服务机构" : name
    }

    var fulfillmentTitle: String {
        isExpressDelivery ? "收货信息" : "自提信息"
    }

    /// 状态区主文案（驳回时仍展示原主状态）
    var statusTitle: String {
        orderStatus?.label ?? "订单详情"
    }

    var statusHint: String {
        if let reject = afterSaleRejectHint { return reject }
        switch orderStatus {
        case .pendingShip: return "商家备货中，请耐心等待"
        case .pendingReceive: return "商品已发货，请注意查收"
        case .inProgress: return "服务进行中，如有疑问请联系机构"
        case .completed: return "订单已完成，感谢您的信任"
        case .refundReview: return "退款申请审核中，请耐心等待"
        case .refund: return "退款处理中，请耐心等待"
        case .overdue: return "订单已逾期，可联系机构续费或结算"
        case .cancelled: return "订单已取消"
        case .pendingPayment: return "请尽快完成支付"
        case .none: return ""
        }
    }

    var paymentTypeLabel: String {
        switch paymentType {
        case 1: return "微信支付"
        case 2: return "支付宝"
        case 3: return "现金支付"
        case 4: return "银行卡转账"
        default: return "—"
        }
    }

    var packageAmount: Double {
        let express = max(0, expressAmount ?? 0)
        let coupon = max(0, couponAmount ?? 0)
        let itemTotal = (shoppingCartPackageDetailList ?? []).reduce(0) { $0 + max(0, $1.price ?? 0) }
        if itemTotal > 0 { return itemTotal }
        if let payable {
            return max(0, payable - express + coupon)
        }
        return max(0, (price ?? 0) + coupon - express)
    }

    var paidAmount: Double {
        max(0, price ?? payable ?? 0)
    }

    var expressFee: Double { max(0, expressAmount ?? 0) }
    var couponDiscount: Double { max(0, couponAmount ?? 0) }

    var logisticsSummary: String? {
        let number = logisticsNumber?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !number.isEmpty else { return nil }
        let vendor = logisticsChineseName?.nilIfEmpty
            ?? logisticsVendor?.nilIfEmpty
            ?? "物流"
        return "\(vendor)：\(number)"
    }

    var remarkText: String? {
        description?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    var detailLines: [OrderDetailPackageLineBO] {
        shoppingCartPackageDetailList ?? []
    }

    /// 需展示物流/自提信息的商品行（`shipmentStatus` 有值）
    var logisticsLines: [OrderDetailPackageLineBO] {
        detailLines.filter { $0.shipmentStatus != nil }
    }

    // MARK: - 详情区块可见性（对齐 funde PaidOrderDetailView）

    var showsDeliveryAddressCard: Bool {
        guard isExpressDelivery else { return false }
        return hasNonEmpty(receiver) || hasNonEmpty(phone) || hasNonEmpty(address)
    }

    var showsInstitutionCard: Bool {
        !isExpressDelivery
    }

    var showsExpressLogisticsCard: Bool {
        isExpressDelivery && !logisticsLines.isEmpty
    }

    var showsPickupLogisticsCard: Bool {
        !isExpressDelivery && !logisticsLines.isEmpty
    }

    var institutionCardTitle: String {
        isExpressDelivery ? "服务机构" : "自提地址"
    }

    var institutionAddressText: String {
        let addr = address?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !addr.isEmpty { return addr }
        return "机构地址待补充"
    }

    var contactPhone: String? {
        phone?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    private func hasNonEmpty(_ text: String?) -> Bool {
        !(text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    // MARK: - 售后

    var isInAfterSaleFlow: Bool {
        switch orderStatus {
        case .refund, .refundReview: return true
        default: return false
        }
    }

    var showsAfterSaleInfoCard: Bool {
        if refuseReasons?.nilIfEmpty != nil, !isInAfterSaleFlow {
            return false
        }
        if isInAfterSaleFlow { return true }
        return refundApplyTime?.nilIfEmpty != nil
            || refundReasons?.nilIfEmpty != nil
            || refundId != nil
            || (applyRefund ?? 0) > 0
    }

    var afterSaleRejectHint: String? {
        guard let reason = refuseReasons?.nilIfEmpty, !isInAfterSaleFlow else { return nil }
        return "退款未通过：\(reason)"
    }

    var refundNoText: String? {
        guard let refundId, refundId > 0 else { return nil }
        return String(refundId)
    }

    var refundReasonText: String? {
        refundReasons?.nilIfEmpty
    }

    var refundApplyTimeText: String? {
        refundApplyTime?.nilIfEmpty
    }

    var refundApplyChannelText: String? {
        refundApplyChannel?.nilIfEmpty
    }

    var refundAmountValue: Double? {
        guard let applyRefund, applyRefund > 0 else { return nil }
        return applyRefund
    }

    private static func decodePackageLines<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> [OrderDetailPackageLineBO]? {
        guard var array = try? container.nestedUnkeyedContainer(forKey: key) else { return nil }
        var lines: [OrderDetailPackageLineBO] = []
        while !array.isAtEnd {
            if let line = try? array.decode(OrderDetailPackageLineBO.self) {
                lines.append(line)
            } else {
                _ = try? array.decode(FlexibleJSONValue.self)
            }
        }
        return lines.isEmpty ? nil : lines
    }

    private static func decodeFlexibleInt<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> Int? {
        if let v = try? container.decodeIfPresent(Int.self, forKey: key) { return v }
        if let v = try? container.decodeIfPresent(Int64.self, forKey: key) { return Int(v) }
        if let s = try? container.decodeIfPresent(String.self, forKey: key) {
            return Int(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    private static func decodeFlexibleInt64<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> Int64? {
        if let v = try? container.decodeIfPresent(Int64.self, forKey: key) { return v }
        if let v = try? container.decodeIfPresent(Int.self, forKey: key) { return Int64(v) }
        if let s = try? container.decodeIfPresent(String.self, forKey: key) {
            return Int64(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    private static func decodeFlexibleDouble<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> Double? {
        if let v = try? container.decodeIfPresent(Double.self, forKey: key) { return v }
        if let v = try? container.decodeIfPresent(Int.self, forKey: key) { return Double(v) }
        if let s = try? container.decodeIfPresent(String.self, forKey: key) {
            return Double(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}

/// 订单商品明细 `ShoppingCartPackageDetailBO`
struct OrderDetailPackageLineBO: Decodable {
    let packageName: String?
    let commodityName: String?
    let quantity: Int?
    let billingType: Int?
    let price: Double?
    /// 发货状态：1 待发货；2 已发货
    let shipmentStatus: Int?
    /// 预计发货/备货时间
    let presetDeliveryTime: String?

    private enum CodingKeys: String, CodingKey {
        case packageName, commodityName, quantity, billingType, price
        case shipmentStatus, presetDeliveryTime
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        packageName = try c.decodeIfPresent(String.self, forKey: .packageName)
        commodityName = try c.decodeIfPresent(String.self, forKey: .commodityName)
        quantity = Self.decodeFlexibleInt(c, key: .quantity)
        billingType = Self.decodeFlexibleInt(c, key: .billingType)
        price = Self.decodeFlexibleDouble(c, key: .price)
        shipmentStatus = Self.decodeFlexibleInt(c, key: .shipmentStatus)
        presetDeliveryTime = try c.decodeIfPresent(String.self, forKey: .presetDeliveryTime)
    }

    var displayName: String {
        let commodity = commodityName?.nilIfEmpty
        let package = packageName?.nilIfEmpty
        return commodity ?? package ?? "商品"
    }

    var qtyLabel: String {
        let qty = max(1, quantity ?? 1)
        return "\(qty)\(Self.billingUnit(billingType))"
    }

    var priceValue: Double { max(0, price ?? 0) }

    var shipmentStatusLabel: String {
        switch shipmentStatus {
        case 2: return "已发货"
        case 1: return "待发货"
        default: return "待发货"
        }
    }

    var isShipped: Bool { shipmentStatus == 2 }

    func logisticsSecondaryText(isPickup: Bool, orderLogisticsSummary: String?) -> String? {
        if isShipped {
            let summary = orderLogisticsSummary?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return summary.isEmpty ? nil : summary
        }
        let time = presetDeliveryTime?.nilIfEmpty ?? "--"
        if isPickup {
            return "预计 \(time) 完成备货，可自提"
        }
        return "商家备货中，预计发货时间 \(time)"
    }

    private static func billingUnit(_ type: Int?) -> String {
        switch type {
        case 1: return "天"
        case 2: return "月"
        case 3: return "次"
        case 4: return "件"
        default: return "份"
        }
    }

    private static func decodeFlexibleInt<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> Int? {
        if let v = try? container.decodeIfPresent(Int.self, forKey: key) { return v }
        if let v = try? container.decodeIfPresent(Double.self, forKey: key) { return Int(v) }
        if let s = try? container.decodeIfPresent(String.self, forKey: key) {
            return Int(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    private static func decodeFlexibleDouble<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> Double? {
        if let v = try? container.decodeIfPresent(Double.self, forKey: key) { return v }
        if let v = try? container.decodeIfPresent(Int.self, forKey: key) { return Double(v) }
        if let s = try? container.decodeIfPresent(String.self, forKey: key) {
            return Double(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}

/// 跳过无法解析的商品行元素
private struct FlexibleJSONValue: Decodable {
    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer() {
            if container.decodeNil() { return }
            if (try? container.decode(Bool.self)) != nil { return }
            if (try? container.decode(Int64.self)) != nil { return }
            if (try? container.decode(Double.self)) != nil { return }
            if (try? container.decode(String.self)) != nil { return }
        }
        _ = try? decoder.container(keyedBy: AnyCodingKey.self)
    }

    private struct AnyCodingKey: CodingKey {
        var stringValue: String
        var intValue: Int?
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { self.intValue = intValue; self.stringValue = "\(intValue)" }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
