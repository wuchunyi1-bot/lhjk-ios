import Foundation

// MARK: - 订单状态

/// 商城订单状态枚举，对应后端 status 字段（1-9）
/// 注意：与 DAL/Payment/PaymentOrder.swift 的 `OrderStatus`（支付状态）区分
enum AppOrderStatus: Int {
    case pendingPayment = 1   // 待支付
    case pendingShip = 2      // 待发货
    case pendingReceive = 3   // 待收货
    case inProgress = 4       // 使用中
    case completed = 5        // 已完成
    case refund = 6           // 退款/售后
    case overdue = 7          // 已逾期
    case cancelled = 8        // 已取消
    case refundReview = 9     // 退款审核中

    /// 状态显示文本（对齐 funde 列表文案）
    var label: String {
        switch self {
        case .pendingPayment: return "待支付"
        case .pendingShip:    return "待发货"
        case .pendingReceive: return "待收货"
        case .inProgress:     return "使用中"
        case .completed:      return "已完成"
        case .refund:         return "退款/售后"
        case .overdue:        return "已逾期"
        case .cancelled:      return "已取消"
        case .refundReview:   return "退款审核中"
        }
    }

    /// 状态角标背景色 hex
    var tagBgHex: String {
        switch self {
        case .pendingPayment, .refundReview: return "#FFF8E8"
        case .pendingShip, .pendingReceive:  return "#FFF3EE"
        case .inProgress:                     return "#EEF6FF"
        case .completed:                      return "#F0FAF4"
        case .refund:                         return "#FFF0F0"
        case .overdue, .cancelled:            return "#F0F0F0"
        }
    }

    /// 状态角标文字色 hex
    var tagTextHex: String {
        switch self {
        case .pendingPayment, .refundReview: return "#B47300"
        case .pendingShip, .pendingReceive:  return "#FF7A50"
        case .inProgress:                     return "#3D6FB8"
        case .completed:                      return "#52B96A"
        case .refund:                         return "#D6602B"
        case .overdue, .cancelled:            return "#999999"
        }
    }
}

// MARK: - 套餐类型

/// 订单关联套餐类型（`packageType`）
enum AppPackageType: Int {
    case lease = 1       // 租赁套餐
    case sale = 2        // 售卖套餐
    case virtual = 3     // 虚拟套餐
    case experience = 4  // 体验套餐

    /// 仅租赁套餐支持续费
    var supportsRenewal: Bool { self == .lease }

    /// 售卖（电商零售）、体验套餐可申请普通退款/售后
    var supportsAfterSale: Bool {
        self == .sale || self == .experience
    }

    static func supportsRenewal(packageType: Int?) -> Bool {
        guard let packageType, let type = AppPackageType(rawValue: packageType) else { return false }
        return type.supportsRenewal
    }

    static func supportsAfterSale(packageType: Int?) -> Bool {
        guard let packageType, let type = AppPackageType(rawValue: packageType) else { return false }
        return type.supportsAfterSale
    }
}

// MARK: - 续费资格
// Apifox `AppOrderListBO.renewed` / `AppOrderDetailBO.renewed`：1 允许续租，0 不允许

enum AppOrderRenewalRules {
    /// 已逾期可续费窗口：第 0～5 天（含）；天数由列表/详情 `endTime` 推算（接口无 overdueDays）
    static let overdueRenewalMaxDays = 5

    /// `renewed == 1` 允许续租；`0` / 缺失均不允许
    static func isRenewalAllowed(renewed: Int?) -> Bool {
        renewed == 1
    }

    static func canShowRenew(
        packageType: Int?,
        status: AppOrderStatus?,
        renewed: Int?,
        endTime: String?
    ) -> Bool {
        guard AppPackageType.supportsRenewal(packageType: packageType) else { return false }
        guard isRenewalAllowed(renewed: renewed) else { return false }
        guard let status else { return false }

        switch status {
        case .inProgress:
            return true
        case .overdue:
            guard let days = overdueDaysComputed(from: endTime) else { return false }
            return days >= 0 && days <= overdueRenewalMaxDays
        default:
            return false
        }
    }

    /// 用服务结束日推算逾期天数（日历日）；无法解析返回 nil
    static func overdueDaysComputed(from endTime: String?) -> Int? {
        guard let end = parseFlexibleDate(endTime) else { return nil }
        let calendar = Calendar.current
        let startOfEnd = calendar.startOfDay(for: end)
        let startOfToday = calendar.startOfDay(for: Date())
        let components = calendar.dateComponents([.day], from: startOfEnd, to: startOfToday)
        return components.day
    }

    private static func parseFlexibleDate(_ raw: String?) -> Date? {
        guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        let formats = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd",
            "yyyy/MM/dd HH:mm:ss",
            "yyyy/MM/dd",
            "yyyy-M-d H:m:s",
            "yyyy-M-d",
        ]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: trimmed) { return date }
        }
        if let iso = ISO8601DateFormatter().date(from: trimmed) { return iso }
        return nil
    }
}

// MARK: - 去退货资格
// 列表：`canReturnGoods` + `refundId`（getAppOrderList）
// 提交：POST /v1/orderClearing/submitReturnGoods

enum AppOrderReturnGoodsRules {
    /// 列表权威：status=6 + canReturnGoods + 有效 refundId
    static func canShow(
        status: AppOrderStatus?,
        canReturnGoods: Bool?,
        refundId: Int64?
    ) -> Bool {
        guard status == .refund else { return false }
        guard canReturnGoods == true else { return false }
        guard let refundId, refundId > 0 else { return false }
        return true
    }

    /// 详情兼容：优先 `canReturnGoods`；缺失时仅用 status=6 + refundId
    static func canShowForDetail(
        status: AppOrderStatus?,
        canReturnGoods: Bool?,
        refundId: Int64?
    ) -> Bool {
        guard status == .refund else { return false }
        guard let refundId, refundId > 0 else { return false }
        if let canReturnGoods {
            return canReturnGoods
        }
        return true
    }
}

/// `POST /v1/orderClearing/submitReturnGoods` 请求体
/// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/493050735e0.md
struct ReturnGoodsSubmitDTO {
    /// 退款单 ID（必填，禁止 mock）
    let refundId: Int64
    /// 1 自行送回 / 2 快递送回
    let returnMethod: Int
    let logisticsName: String?
    let logisticsId: String?
    let sender: String?
    let senderPhone: String?

    func apiParameters() -> [String: Any] {
        var body: [String: Any] = [
            "refundId": refundId,
            "returnMethod": returnMethod,
        ]
        if let logisticsName, !logisticsName.isEmpty {
            body["logisticsName"] = String(logisticsName.prefix(10))
        }
        if let logisticsId, !logisticsId.isEmpty {
            body["logisticsId"] = String(logisticsId.prefix(80))
        }
        if let sender, !sender.isEmpty {
            body["sender"] = String(sender.prefix(10))
        }
        if let senderPhone, !senderPhone.isEmpty {
            body["senderPhone"] = String(senderPhone.prefix(11))
        }
        return body
    }

    static func selfDelivery(refundId: Int64) -> ReturnGoodsSubmitDTO {
        ReturnGoodsSubmitDTO(
            refundId: refundId,
            returnMethod: 1,
            logisticsName: nil,
            logisticsId: nil,
            sender: nil,
            senderPhone: nil
        )
    }

    static func express(
        refundId: Int64,
        logisticsName: String,
        logisticsId: String
    ) -> ReturnGoodsSubmitDTO {
        ReturnGoodsSubmitDTO(
            refundId: refundId,
            returnMethod: 2,
            logisticsName: logisticsName,
            logisticsId: logisticsId,
            sender: nil,
            senderPhone: nil
        )
    }
}

// MARK: - 订单模型

/// 订单模型，对应后端 `AppOrderListBO`
/// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330738e0.md
struct MOrder {
    let id: Int64?
    let parentId: Int64?
    let orderName: String?
    let status: Int?
    /// 套包金额（不含优惠券、权益卡和运费）；列表卡片金额不使用该字段
    let payable: Double?
    /// 订单应付金额（套包金额加运费并扣除优惠券、权益卡）
    let settlementAmount: Double?
    /// 订单实付金额
    let price: Double?
    let createTime: String?
    let hospitalName: String?
    let doctorName: String?
    let packageDescription: String?
    let packageType: Int?
    let packageImageUrl: String?
    let beginTime: String?
    let endTime: String?
    let serviceTime: String?
    let packageId: String?
    let hospitalId: String?
    /// 列表文档未声明；若后端额外下发则解码，供续费跳转
    let categoryServiceId: String?
    /// 1 允许续租，0 不允许（`AppOrderListBO.renewed`）
    let renewed: Int?
    /// 是否可去退货（`AppOrderListBO.canReturnGoods`）
    let canReturnGoods: Bool?
    /// 退款单 ID（提交退货用，非订单 id）
    let refundId: Int64?
    /// 拒绝退款原因（如果有）
    let refuseReasons: String?

    /// 订单状态枚举
    var orderStatus: AppOrderStatus? {
        guard let status = status else { return nil }
        return AppOrderStatus(rawValue: status)
    }

    /// 状态显示文本
    var statusLabel: String {
        orderStatus?.label ?? "未知"
    }

    /// 格式化的价格文本
    var priceText: String {
        displayAmountText
    }

    /// 列表金额：`price`（实付）不为 null 则展示实付，否则展示 `settlementAmount`（应付）
    var displayAmountText: String {
        let amount = price ?? settlementAmount ?? 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
        return "¥\(formatted)"
    }

    /// 续费跳转用 packageId
    var resolvedPackageId: String? {
        guard let raw = packageId?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        return raw
    }

    /// 是否展示「续费订单」
    var canShowRenewAction: Bool {
        AppOrderRenewalRules.canShowRenew(
            packageType: packageType,
            status: orderStatus,
            renewed: renewed,
            endTime: endTime
        )
    }

    /// 列表侧：有有效退款单则视为已发生退款相关流程
    var hasRefundHistory: Bool {
        if let refundId, refundId > 0 { return true }
        return false
    }

    /// 是否展示「去退货」：status=6 + canReturnGoods + 有效 refundId
    var canShowReturnGoodsAction: Bool {
        AppOrderReturnGoodsRules.canShow(
            status: orderStatus,
            canReturnGoods: canReturnGoods,
            refundId: refundId
        )
    }

    /// 是否展示「退款/售后」
    var canShowAfterSaleAction: Bool {
        guard AppPackageType.supportsAfterSale(packageType: packageType) else { return false }
        return !hasRefundHistory
    }

    /// 拒绝退款/通知栏文案（如果有）
    var noticeText: String? {
        guard let reasons = refuseReasons?.trimmingCharacters(in: .whitespacesAndNewlines), !reasons.isEmpty else {
            return nil
        }
        if reasons.hasPrefix("拒绝退款") || reasons.hasPrefix("退款未通过") {
            return reasons
        }
        return "拒绝退款：\(reasons)"
    }

    /// 日期范围文本
    var dateRangeText: String? {
        let start = beginTime ?? createTime
        let end = endTime
        if let s = start, let e = end {
            return "\(s) — \(e)"
        } else if let s = start {
            return s
        }
        return nil
    }
}

// MARK: - MOrder Decodable

extension MOrder: Decodable {

    enum CodingKeys: String, CodingKey {
        case id, parentId, orderName, status, payable, settlementAmount, price, createTime
        case hospitalName, doctorName, packageDescription
        case packageType, packageImageUrl, beginTime, endTime, serviceTime
        case packageId, hospitalId, categoryServiceId, renewed
        case canReturnGoods, refundId, refuseReasons
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                  = Self.decodeFlexibleInt64(c, key: .id)
        parentId            = Self.decodeFlexibleInt64(c, key: .parentId)
        orderName           = try c.decodeIfPresent(String.self, forKey: .orderName)
        status              = HospitalPackageInt.decodeIfPresent(c, key: .status)
        payable             = Self.decodeFlexibleDouble(c, key: .payable)
        settlementAmount    = Self.decodeFlexibleDouble(c, key: .settlementAmount)
        price               = Self.decodeFlexibleDouble(c, key: .price)
        createTime          = try c.decodeIfPresent(String.self, forKey: .createTime)
        hospitalName        = try c.decodeIfPresent(String.self, forKey: .hospitalName)
        doctorName          = try c.decodeIfPresent(String.self, forKey: .doctorName)
        packageDescription  = try c.decodeIfPresent(String.self, forKey: .packageDescription)
        packageType         = HospitalPackageInt.decodeIfPresent(c, key: .packageType)
        packageImageUrl     = try c.decodeIfPresent(String.self, forKey: .packageImageUrl)
        beginTime           = try c.decodeIfPresent(String.self, forKey: .beginTime)
        endTime             = try c.decodeIfPresent(String.self, forKey: .endTime)
        serviceTime         = try c.decodeIfPresent(String.self, forKey: .serviceTime)
        packageId           = HospitalPackageID.decodeOptional(c, key: .packageId)
        hospitalId          = HospitalPackageID.decodeOptional(c, key: .hospitalId)
        categoryServiceId   = HospitalPackageID.decodeOptional(c, key: .categoryServiceId)
        renewed             = HospitalPackageInt.decodeIfPresent(c, key: .renewed)
        canReturnGoods      = Self.decodeFlexibleBool(c, key: .canReturnGoods)
        refundId            = Self.decodeFlexibleInt64(c, key: .refundId)
        refuseReasons       = try c.decodeIfPresent(String.self, forKey: .refuseReasons)
    }

    private static func decodeFlexibleInt64<K: CodingKey>(_ container: KeyedDecodingContainer<K>, key: K) -> Int64? {
        if let v = try? container.decodeIfPresent(Int64.self, forKey: key) { return v }
        if let s = try? container.decodeIfPresent(String.self, forKey: key) { return Int64(s) }
        return nil
    }

    private static func decodeFlexibleDouble<K: CodingKey>(_ container: KeyedDecodingContainer<K>, key: K) -> Double? {
        if let v = try? container.decodeIfPresent(Double.self, forKey: key) { return v }
        if let v = try? container.decodeIfPresent(Int.self, forKey: key) { return Double(v) }
        if let s = try? container.decodeIfPresent(String.self, forKey: key) {
            return Double(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    private static func decodeFlexibleBool<K: CodingKey>(_ container: KeyedDecodingContainer<K>, key: K) -> Bool? {
        if let v = try? container.decodeIfPresent(Bool.self, forKey: key) { return v }
        if let i = try? container.decodeIfPresent(Int.self, forKey: key) { return i != 0 }
        if let s = try? container.decodeIfPresent(String.self, forKey: key) {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if t == "true" || t == "1" { return true }
            if t == "false" || t == "0" { return false }
        }
        return nil
    }
}

// MARK: - 订单分页数据

/// 分页订单列表数据，对应 `GET /v1/order/getAppOrderList` 的 `data` 字段
/// Apifox 标准分页字段为中文 key，同时兼容英文别名
struct PaginatedOrderData: Decodable {
    let totalRecords: Int?
    let pageSize: Int?
    let totalPages: Int?
    let currentPage: Int?
    let records: [MOrder]?

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

    init(
        totalRecords: Int? = nil,
        pageSize: Int? = nil,
        totalPages: Int? = nil,
        currentPage: Int? = nil,
        records: [MOrder]? = nil
    ) {
        self.totalRecords = totalRecords
        self.pageSize = pageSize
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.records = records
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalRecords = (try? c.decodeIfPresent(Int.self, forKey: .totalRecords))
            ?? (try? c.decodeIfPresent(Int.self, forKey: .totalRecordsCN))
        pageSize = (try? c.decodeIfPresent(Int.self, forKey: .pageSize))
            ?? (try? c.decodeIfPresent(Int.self, forKey: .pageSizeCN))
        totalPages = (try? c.decodeIfPresent(Int.self, forKey: .totalPages))
            ?? (try? c.decodeIfPresent(Int.self, forKey: .totalPagesCN))
        currentPage = (try? c.decodeIfPresent(Int.self, forKey: .currentPage))
            ?? (try? c.decodeIfPresent(Int.self, forKey: .currentPageCN))
        records = (try? c.decodeIfPresent([MOrder].self, forKey: .records))
            ?? (try? c.decodeIfPresent([MOrder].self, forKey: .recordsCN))
    }
}

// MARK: - 取消 / 更新订单状态
// Apifox: POST /v1/order/insertOrEdit
// https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330734e0.md

/// `insertOrEdit` 请求体（`MOrder` 子集，仅传业务所需字段）
/// Apifox schema：`id` / `hospitalId` 为 int64；客户端按线上兼容以字符串编码
struct OrderInsertOrEditRequest: Encodable {
    let id: Int64
    let hospitalId: String?
    let status: Int
    let remark: String?
    let shipmentTime: String?
    let description: String?
    let serialNumber: Int?

    init(
        id: Int64,
        hospitalId: String?,
        status: Int,
        remark: String? = nil,
        shipmentTime: String? = nil,
        description: String? = nil,
        serialNumber: Int? = nil
    ) {
        self.id = id
        self.hospitalId = hospitalId
        self.status = status
        self.remark = remark
        self.shipmentTime = shipmentTime
        self.description = description
        self.serialNumber = serialNumber
    }

    /// 转为 API JSON 参数字典（`id` / `hospitalId` 为字符串）
    func apiParameters() -> [String: Any] {
        var body: [String: Any] = [
            "id": String(id),
            "status": status,
        ]
        if let hospitalId = hospitalId?.trimmingCharacters(in: .whitespacesAndNewlines), !hospitalId.isEmpty {
            body["hospitalId"] = hospitalId
        }
        if let remark = remark?.trimmingCharacters(in: .whitespacesAndNewlines), !remark.isEmpty {
            body["remark"] = remark
        }
        if let shipmentTime = shipmentTime?.trimmingCharacters(in: .whitespacesAndNewlines), !shipmentTime.isEmpty {
            body["shipmentTime"] = shipmentTime
        }
        if let description = description?.trimmingCharacters(in: .whitespacesAndNewlines), !description.isEmpty {
            body["description"] = description
        }
        if let serialNumber = serialNumber {
            body["serialNumber"] = serialNumber
        }
        return body
    }

    /// 待支付取消 → status=8
    static func cancelOrder(orderId: Int64, hospitalId: String, remark: String? = nil) -> OrderInsertOrEditRequest {
        OrderInsertOrEditRequest(
            id: orderId,
            hospitalId: hospitalId,
            status: AppOrderStatus.cancelled.rawValue,
            remark: remark.map { String($0.prefix(300)) }
        )
    }

    /// 确认发货 → status=3（待收货）
    static func confirmShipment(
        orderId: Int64,
        hospitalId: String,
        shipmentTime: String
    ) -> OrderInsertOrEditRequest {
        OrderInsertOrEditRequest(
            id: orderId,
            hospitalId: hospitalId,
            status: AppOrderStatus.pendingReceive.rawValue,
            shipmentTime: shipmentTime
        )
    }

    /// 确认收货 → status=4（使用中）
    static func confirmReceipt(orderId: Int64, hospitalId: String) -> OrderInsertOrEditRequest {
        OrderInsertOrEditRequest(
            id: orderId,
            hospitalId: hospitalId,
            status: AppOrderStatus.inProgress.rawValue
        )
    }

    /// 退款/售后、待发货取消、结算 → status=9 + remark
    static func submitRefundApplication(
        orderId: Int64,
        hospitalId: String,
        remark: String
    ) -> OrderInsertOrEditRequest {
        OrderInsertOrEditRequest(
            id: orderId,
            hospitalId: hospitalId,
            status: AppOrderStatus.refundReview.rawValue,
            remark: String(remark.prefix(300))
        )
    }

    /// 结算订单 → status=9 + remark
    static func settleOrder(
        orderId: Int64,
        hospitalId: String,
        remark: String
    ) -> OrderInsertOrEditRequest {
        submitRefundApplication(orderId: orderId, hospitalId: hospitalId, remark: remark)
    }

    /// 购物车去结算 → status=1（待支付）
    static func checkoutFromCart(orderId: Int64, hospitalId: String? = nil) -> OrderInsertOrEditRequest {
        OrderInsertOrEditRequest(
            id: orderId,
            hospitalId: hospitalId,
            status: AppOrderStatus.pendingPayment.rawValue
        )
    }

    // MARK: - 兼容旧工厂方法

    static func cancelPendingPayment(orderId: Int64, hospitalId: String, remark: String? = nil) -> OrderInsertOrEditRequest {
        cancelOrder(orderId: orderId, hospitalId: hospitalId, remark: remark)
    }

    static func submitPendingShipRefund(
        orderId: Int64,
        hospitalId: String,
        remark: String
    ) -> OrderInsertOrEditRequest {
        submitRefundApplication(orderId: orderId, hospitalId: hospitalId, remark: remark)
    }
}

/// insertOrEdit 时间格式
enum OrderInsertOrEditFormats {
    /// 确认发货时间：`yyyy-M-d H:m:s`（不补零）
    static func shipmentTime(from date: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        guard let year = c.year, let month = c.month, let day = c.day,
              let hour = c.hour, let minute = c.minute, let second = c.second else {
            return ""
        }
        return "\(year)-\(month)-\(day) \(hour):\(minute):\(second)"
    }
}

/// 取消订单套餐预览（退款申请弹层）
struct OrderCancelPackagePreview {
    let name: String
    let subtitle: String?
    let imageURL: String?
    let amountText: String
}

extension OrderCancelPackagePreview {
    static func from(order: MOrder) -> OrderCancelPackagePreview {
        OrderCancelPackagePreview(
            name: order.orderName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfNonempty ?? "套餐",
            subtitle: order.packageDescription?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfNonempty,
            imageURL: order.packageImageUrl,
            amountText: order.displayAmountText
        )
    }

    static func from(detail: AppOrderDetailBO) -> OrderCancelPackagePreview {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        let amount = detail.paidAmount
        let amountText = "¥\(formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount))"
        return OrderCancelPackagePreview(
            name: detail.orderName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfNonempty ?? "套餐",
            subtitle: detail.packageDescription?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfNonempty,
            imageURL: detail.packageImageUrl,
            amountText: amountText
        )
    }
}

extension Notification.Name {
    /// 订单列表需要全量刷新（取消、支付等成功后发送）
    static let orderListNeedsRefresh = Notification.Name("lhjk.order.listNeedsRefresh")
}

// MARK: - 订单支付 `POST /v1/orderPay/orderPay`

/// 支付渠道类型（对齐订单 `paymentType`：1 微信 / 2 支付宝）
enum OrderPayType: String {
    case wechat = "1"
    case alipay = "2"
}

/// `orderPay` 返回 `data`（Apifox schema 为空；微信走预下单字段，支付宝走 `aliBody`）
struct OrderPayResultVO: Decodable, Equatable {
    let partnerId: String?
    let prepayId: String?
    let nonceStr: String?
    let timeStamp: String?
    let packageValue: String?
    let sign: String?
    let appId: String?
    /// 支付宝 `orderStr`，后端字段为 `aliBody`
    let orderString: String?

    static let empty = OrderPayResultVO(
        partnerId: nil,
        prepayId: nil,
        nonceStr: nil,
        timeStamp: nil,
        packageValue: nil,
        sign: nil,
        appId: nil,
        orderString: nil
    )

    init(
        partnerId: String?,
        prepayId: String?,
        nonceStr: String?,
        timeStamp: String?,
        packageValue: String?,
        sign: String?,
        appId: String?,
        orderString: String?
    ) {
        self.partnerId = partnerId
        self.prepayId = prepayId
        self.nonceStr = nonceStr
        self.timeStamp = timeStamp
        self.packageValue = packageValue
        self.sign = sign
        self.appId = appId
        self.orderString = orderString
    }

    var wechatPayRequest: WeChatPayRequest? {
        let partner = Self.nonEmpty(partnerId)
        let prepay = Self.nonEmpty(prepayId)
        let nonce = Self.nonEmpty(nonceStr)
        let stamp = Self.nonEmpty(timeStamp)
        let signValue = Self.nonEmpty(sign)
        guard let partner, let prepay, let nonce, let stamp, let signValue else { return nil }
        let pkg = Self.nonEmpty(packageValue) ?? "Sign=WXPay"
        return WeChatPayRequest(
            partnerId: partner,
            prepayId: prepay,
            nonceStr: nonce,
            timeStamp: stamp,
            package: pkg,
            sign: signValue
        )
    }

    /// 支付宝 SDK `payOrder` 所需的签名串（`aliBody`）
    var alipayOrderString: String? { Self.nonEmpty(orderString) }

    init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(),
           let raw = try? single.decode(String.self),
           let data = raw.data(using: .utf8),
           let nested = try? JSONDecoder().decode(OrderPayPayload.self, from: data) {
            self.init(payload: nested)
            return
        }

        let c = try decoder.container(keyedBy: DynamicKey.self)
        var payload = OrderPayPayload(from: c)

        if payload.partnerId == nil, payload.prepayId == nil {
            for nestKey in ["wxPay", "wechat", "weChat", "appPay", "payInfo", "payParam", "wxPayInfo"] {
                guard let nested = try? c.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(nestKey)) else {
                    continue
                }
                let child = OrderPayPayload(from: nested)
                if child.prepayId != nil {
                    payload = child
                    break
                }
            }
        }

        if payload.orderString == nil {
            for nestKey in ["aliPay", "alipay", "ali", "aliPayInfo"] {
                guard let nested = try? c.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(nestKey)) else {
                    continue
                }
                let child = OrderPayPayload(from: nested)
                if let aliBody = child.orderString {
                    payload.orderString = aliBody
                    break
                }
            }
        }
        self.init(payload: payload)
    }

    private init(payload: OrderPayPayload) {
        self.init(
            partnerId: payload.partnerId,
            prepayId: payload.prepayId,
            nonceStr: payload.nonceStr,
            timeStamp: payload.timeStamp,
            packageValue: payload.packageValue,
            sign: payload.sign,
            appId: payload.appId,
            orderString: payload.orderString
        )
    }

    private static func nonEmpty(_ value: String?) -> String? {
        let t = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return t.isEmpty ? nil : t
    }

    private struct DynamicKey: CodingKey {
        var stringValue: String
        init(_ string: String) { stringValue = string }
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { nil }
    }

    private struct OrderPayPayload: Decodable {
        var partnerId: String?
        var prepayId: String?
        var nonceStr: String?
        var timeStamp: String?
        var packageValue: String?
        var sign: String?
        var appId: String?
        var orderString: String?

        init(from c: KeyedDecodingContainer<DynamicKey>) {
            partnerId = Self.pick(c, ["partnerId", "partnerid", "partner_id", "mchId", "mch_id", "mchid"])
            prepayId = Self.pick(c, ["prepayId", "prepayid", "prepay_id"])
            nonceStr = Self.pick(c, ["nonceStr", "noncestr", "nonce_str"])
            timeStamp = Self.pick(c, ["timeStamp", "timestamp", "time_stamp"])
            packageValue = Self.pick(c, ["package", "packageValue", "package_value"])
            sign = Self.pick(c, ["sign", "paySign", "pay_sign"])
            appId = Self.pick(c, ["appId", "appid", "app_id"])
            orderString = Self.pick(c, [
                "aliBody",
                "ali_body",
                "alibody",
                "orderString",
                "orderInfo",
                "alipayOrderString",
                "body",
            ])
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: DynamicKey.self)
            self.init(from: c)
        }

        private static func pick(_ c: KeyedDecodingContainer<DynamicKey>, _ keys: [String]) -> String? {
            for key in keys {
                if let s = try? c.decodeIfPresent(String.self, forKey: DynamicKey(key)) {
                    let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !t.isEmpty { return t }
                }
                if let i = try? c.decodeIfPresent(Int64.self, forKey: DynamicKey(key)) {
                    return String(i)
                }
                if let i = try? c.decodeIfPresent(Int.self, forKey: DynamicKey(key)) {
                    return String(i)
                }
            }
            return nil
        }
    }
}

// MARK: - insertOrEdit 机构 id

enum OrderInsertOrEditContext {
    static func resolvedHospitalId(from order: MOrder) -> String? {
        order.hospitalId?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfNonempty
    }

    static func resolvedHospitalId(from detail: AppOrderDetailBO) -> String? {
        detail.hospitalId?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfNonempty
    }
}

private extension String {
    var nilIfNonempty: String? {
        isEmpty ? nil : self
    }
}
