import Foundation

// MARK: - 订单状态

/// 商城订单状态枚举，对应后端 status 字段（1-9）
/// 注意：与 DAL/Payment/PaymentOrder.swift 的 `OrderStatus`（支付状态）区分
enum AppOrderStatus: Int {
    case pendingPayment = 1   // 待付款
    case pendingShip = 2      // 待发货
    case pendingReceive = 3   // 待收货
    case inProgress = 4       // 使用中
    case completed = 5        // 已完成
    case refund = 6           // 退款/售后
    case overdue = 7          // 已逾期
    case cancelled = 8        // 已取消
    case refundReview = 9     // 退款审核中

    /// 状态显示文本
    var label: String {
        switch self {
        case .pendingPayment: return "待付款"
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

// MARK: - 订单模型

/// 订单模型，对应后端 `AppOrderListBO`
struct MOrder {
    let id: Int64?
    let orderName: String?
    let status: Int?
    let payable: Double?
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
        guard let price = price else { return "¥0" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: price)) ?? String(format: "%.2f", price)
        return "¥\(formatted)"
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
        case id, orderName, status, payable, price, createTime
        case hospitalName, doctorName, packageDescription
        case packageType, packageImageUrl, beginTime, endTime, serviceTime
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                  = Self.decodeFlexibleInt64(c, key: .id)
        orderName           = try c.decodeIfPresent(String.self, forKey: .orderName)
        status              = try c.decodeIfPresent(Int.self, forKey: .status)
        payable             = try c.decodeIfPresent(Double.self, forKey: .payable)
        price               = try c.decodeIfPresent(Double.self, forKey: .price)
        createTime          = try c.decodeIfPresent(String.self, forKey: .createTime)
        hospitalName        = try c.decodeIfPresent(String.self, forKey: .hospitalName)
        doctorName          = try c.decodeIfPresent(String.self, forKey: .doctorName)
        packageDescription  = try c.decodeIfPresent(String.self, forKey: .packageDescription)
        packageType         = try c.decodeIfPresent(Int.self, forKey: .packageType)
        packageImageUrl     = try c.decodeIfPresent(String.self, forKey: .packageImageUrl)
        beginTime           = try c.decodeIfPresent(String.self, forKey: .beginTime)
        endTime             = try c.decodeIfPresent(String.self, forKey: .endTime)
        serviceTime         = try c.decodeIfPresent(String.self, forKey: .serviceTime)
    }

    private static func decodeFlexibleInt64<K: CodingKey>(_ container: KeyedDecodingContainer<K>, key: K) -> Int64? {
        if let v = try? container.decodeIfPresent(Int64.self, forKey: key) { return v }
        if let s = try? container.decodeIfPresent(String.self, forKey: key) { return Int64(s) }
        return nil
    }
}

// MARK: - 订单分页数据

/// 分页订单列表数据，对应 `GET /mobile/v1/order/getAppOrderList` 的 `data` 字段
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
    }
}
