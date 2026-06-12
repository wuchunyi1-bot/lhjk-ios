import Foundation

// MARK: - 支付渠道类型

enum PaymentChannel: String, Codable {
    case wechatPay
    case alipay

    var displayName: String {
        switch self {
        case .wechatPay: return "微信支付"
        case .alipay: return "支付宝"
        }
    }
}

// MARK: - 订单状态

enum OrderStatus: String, Codable {
    case created
    case pending
    case paid
    case cancelled
    case refunded
}

// MARK: - 订单模型

/// 支付订单模型
struct PaymentOrder: Identifiable {
    /// 订单 ID
    let id: String
    /// 商品 ID
    let productId: String
    /// 商品名称
    let productName: String
    /// 金额（单位：分）
    let amount: Int
    /// 支付渠道
    let channel: PaymentChannel
    /// 订单状态
    var status: OrderStatus
    /// 创建时间
    let createdAt: Date
    /// 支付时间
    var paidAt: Date?

    init(
        id: String = UUID().uuidString,
        productId: String,
        productName: String,
        amount: Int,
        channel: PaymentChannel,
        status: OrderStatus = .created,
        createdAt: Date = Date(),
        paidAt: Date? = nil
    ) {
        self.id = id
        self.productId = productId
        self.productName = productName
        self.amount = amount
        self.channel = channel
        self.status = status
        self.createdAt = createdAt
        self.paidAt = paidAt
    }
}
