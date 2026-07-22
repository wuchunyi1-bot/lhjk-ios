import Foundation

// MARK: - 订单结算 DTO
// Apifox: GET /v1/order/getOrderSettlement
// https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/490169537e0.md

/// 移动端套餐结算信息 `ShoppingCartPackageDetailMobileBO`
struct OrderSettlementBO: Decodable {
    let packageName: String?
    let img: String?
    let totalPrice: Double?
    let details: [OrderSettlementDetailBO]?
    let address: MAddress?
    let appOrderDetailBO: OrderSettlementAppOrderBO?
    let categoryServiceId: String?
    let couponTakeId: String?
    let amount: Double?
    let discountRatio: Double?
    let commodityPrice: Double?
    let expressAmount: Double?
    let description: String?
    let wechat: Bool?
    let alipay: Bool?
    let fundeChannelFlag: Bool?
    /// 1 支持快递发货；0 医院自提
    let orderExpress: Int?

    private enum CodingKeys: String, CodingKey {
        case packageName, img, totalPrice, details, address, appOrderDetailBO
        case categoryServiceId, couponTakeId, amount, discountRatio
        case commodityPrice, expressAmount, description
        case wechat, alipay, fundeChannelFlag, orderExpress
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        packageName = try c.decodeIfPresent(String.self, forKey: .packageName)
        img = try c.decodeIfPresent(String.self, forKey: .img)
        totalPrice = Self.decodeFlexibleDouble(c, key: .totalPrice)
        details = try c.decodeIfPresent([OrderSettlementDetailBO].self, forKey: .details)
        address = try c.decodeIfPresent(MAddress.self, forKey: .address)
        appOrderDetailBO = try c.decodeIfPresent(OrderSettlementAppOrderBO.self, forKey: .appOrderDetailBO)
        categoryServiceId = HospitalPackageID.decodeOptional(c, key: .categoryServiceId)
        couponTakeId = HospitalPackageID.decodeOptional(c, key: .couponTakeId)
        amount = Self.decodeFlexibleDouble(c, key: .amount)
        discountRatio = Self.decodeFlexibleDouble(c, key: .discountRatio)
        commodityPrice = Self.decodeFlexibleDouble(c, key: .commodityPrice)
        expressAmount = Self.decodeFlexibleDouble(c, key: .expressAmount)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        wechat = try c.decodeIfPresent(Bool.self, forKey: .wechat)
        alipay = try c.decodeIfPresent(Bool.self, forKey: .alipay)
        fundeChannelFlag = try c.decodeIfPresent(Bool.self, forKey: .fundeChannelFlag)
        orderExpress = HospitalPackageInt.decodeIfPresent(c, key: .orderExpress)
    }

    /// 是否支持快递发货
    var supportsExpress: Bool { orderExpress == 1 }

    /// 套餐金额（商品金额，元，取整）
    /// 优先 `commodityPrice`；缺省时用 `totalPrice` 减运费、再退到订单应付减运费
    var packageAmountYuan: Int {
        if let v = commodityPrice { return max(0, Int(v.rounded())) }
        if let total = totalPrice {
            return max(0, Int((total - (expressAmount ?? 0)).rounded()))
        }
        if let payable = appOrderDetailBO?.payable {
            return max(0, Int((payable - (expressAmount ?? 0)).rounded()))
        }
        return 0
    }

    /// 运费（元，取整）
    var expressAmountYuan: Int {
        max(0, Int((expressAmount ?? 0).rounded()))
    }

    /// 应付金额（元，取整）
    /// 优先 `totalPrice`；缺省时退到 `appOrderDetailBO.payable`；再退到 套餐金额 + 运费
    var payableAmountYuan: Int {
        if let v = totalPrice { return max(0, Int(v.rounded())) }
        if let v = appOrderDetailBO?.payable { return max(0, Int(v.rounded())) }
        return max(0, packageAmountYuan + expressAmountYuan)
    }

    var resolvedHospitalId: String? {
        if let id = appOrderDetailBO?.hospitalId?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty {
            return id
        }
        return nil
    }

    var resolvedHospitalName: String? {
        let name = appOrderDetailBO?.hospitalName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? nil : name
    }

    var resolvedPackageId: String {
        if let id = appOrderDetailBO?.packageId?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty {
            return id
        }
        if let fromDetail = details?.compactMap({ $0.packageId }).first,
           !fromDetail.isEmpty {
            return fromDetail
        }
        return ""
    }

    var resolvedSubtitle: String {
        appOrderDetailBO?.packageDescription?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private static func decodeFlexibleDouble<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> Double? {
        if let v = try? container.decodeIfPresent(Double.self, forKey: key) { return v }
        if let v = try? container.decodeIfPresent(Int.self, forKey: key) { return Double(v) }
        if let v = try? container.decodeIfPresent(Int64.self, forKey: key) { return Double(v) }
        if let s = try? container.decodeIfPresent(String.self, forKey: key) {
            return Double(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}

/// 结算内嵌订单摘要（取 hospitalId 等）
struct OrderSettlementAppOrderBO: Decodable {
    let id: String?
    let packageId: String?
    let hospitalId: String?
    let hospitalName: String?
    let packageDescription: String?
    /// 订单应付金额
    let payable: Double?
    /// 订单实付金额
    let price: Double?
    /// 取货方式 1 快递 0 自提
    let typeOrder: Int?
    /// 收件人 / 提货人
    let receiver: String?
    /// 收件人 / 提货人电话
    let phone: String?
    /// 收货 / 提货地址
    let address: String?

    private enum CodingKeys: String, CodingKey {
        case id, packageId, hospitalId, hospitalName, packageDescription
        case payable, price, typeOrder, receiver, phone, address
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = HospitalPackageID.decodeOptional(c, key: .id)
        packageId = HospitalPackageID.decodeOptional(c, key: .packageId)
        hospitalId = HospitalPackageID.decodeOptional(c, key: .hospitalId)
        hospitalName = try c.decodeIfPresent(String.self, forKey: .hospitalName)
        packageDescription = try c.decodeIfPresent(String.self, forKey: .packageDescription)
        payable = Self.decodeFlexibleDouble(c, key: .payable)
        price = Self.decodeFlexibleDouble(c, key: .price)
        typeOrder = HospitalPackageInt.decodeIfPresent(c, key: .typeOrder)
        receiver = try c.decodeIfPresent(String.self, forKey: .receiver)
        phone = try c.decodeIfPresent(String.self, forKey: .phone)
        address = try c.decodeIfPresent(String.self, forKey: .address)
    }

    /// 是否已带配送地址信息
    var hasDeliveryAddress: Bool {
        let r = receiver?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let p = phone?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let a = address?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !r.isEmpty || !p.isEmpty || !a.isEmpty
    }

    private static func decodeFlexibleDouble<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> Double? {
        if let v = try? container.decodeIfPresent(Double.self, forKey: key) { return v }
        if let v = try? container.decodeIfPresent(Int.self, forKey: key) { return Double(v) }
        if let v = try? container.decodeIfPresent(Int64.self, forKey: key) { return Double(v) }
        if let s = try? container.decodeIfPresent(String.self, forKey: key) {
            return Double(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}

/// 结算明细行 `ShoppingCartPackageDetailBO`
struct OrderSettlementDetailBO: Decodable {
    let id: String?
    let packageId: String?
    let packageName: String?
    let quantity: Int?
    let billingType: Int?
    let price: Double?
    let commodityName: String?
    let serialNumber: Int?
    let orderId: String?
    let categoryServiceId: String?

    private enum CodingKeys: String, CodingKey {
        case id, packageId, packageName, quantity, billingType, price
        case commodityName, serialNumber, orderId, categoryServiceId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = HospitalPackageID.decodeOptional(c, key: .id)
        packageId = HospitalPackageID.decodeOptional(c, key: .packageId)
        packageName = try c.decodeIfPresent(String.self, forKey: .packageName)
        quantity = HospitalPackageInt.decodeIfPresent(c, key: .quantity)
        billingType = HospitalPackageInt.decodeIfPresent(c, key: .billingType)
        if let v = try? c.decodeIfPresent(Double.self, forKey: .price) {
            price = v
        } else if let i = try? c.decodeIfPresent(Int.self, forKey: .price) {
            price = Double(i)
        } else if let s = try? c.decodeIfPresent(String.self, forKey: .price) {
            price = Double(s.trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
            price = nil
        }
        commodityName = try c.decodeIfPresent(String.self, forKey: .commodityName)
        serialNumber = HospitalPackageInt.decodeIfPresent(c, key: .serialNumber)
        orderId = HospitalPackageID.decodeOptional(c, key: .orderId)
        categoryServiceId = HospitalPackageID.decodeOptional(c, key: .categoryServiceId)
    }

    func toDraftItem() -> PackageOrderDraftItem {
        let name = nonEmpty(commodityName) ?? nonEmpty(packageName) ?? "商品"
        let qty = max(1, quantity ?? 1)
        return PackageOrderDraftItem(
            name: name,
            qty: "\(qty)",
            unit: Self.billingUnit(billingType),
            price: max(0, Int((price ?? 0).rounded()))
        )
    }

    /// `billingType`: 1 天, 2 月, 3 次, 4 件
    private static func billingUnit(_ type: Int?) -> String {
        switch type {
        case 1: return "天"
        case 2: return "月"
        case 3: return "次"
        case 4: return "件"
        default: return "份"
        }
    }

    private func nonEmpty(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}
