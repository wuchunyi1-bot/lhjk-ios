import Foundation
import Combine

// MARK: - 支付渠道协议

/// 统一支付渠道协议
protocol PaymentChannelProtocol {
    /// 渠道标识
    var channelId: String { get }

    /// 发起支付
    /// - Parameter order: 订单信息
    /// - Returns: 支付结果 Publisher
    func pay(order: PaymentOrder) -> AnyPublisher<PaymentResult, PaymentError>

    /// 验证支付结果
    /// - Parameter receipt: 支付凭证
    /// - Returns: 验证结果 Publisher
    func verify(receipt: PaymentReceipt) -> AnyPublisher<Bool, PaymentError>

    /// 处理支付回调（URL Scheme / Universal Link）
    /// - Parameter url: 回调 URL
    func handleCallback(url: URL) -> Bool
}

// MARK: - 支付结果

enum PaymentResult {
    case success(orderId: String, receipt: PaymentReceipt)
    case pending(orderId: String)
    case cancelled(orderId: String)
    case failed(orderId: String, error: PaymentError)
}

// MARK: - 支付凭证

struct PaymentReceipt {
    let channel: String
    let orderId: String
    let transactionId: String
    let rawData: String
    let timestamp: Date
}

// MARK: - 支付错误

enum PaymentError: Error, LocalizedError {
    case channelNotAvailable
    case orderCreationFailed
    case paymentFailed(reason: String)
    case verificationFailed
    case userCancelled
    case unknown

    var errorDescription: String? {
        switch self {
        case .channelNotAvailable: return "该支付方式不可用"
        case .orderCreationFailed: return "订单创建失败"
        case .paymentFailed(let reason): return reason
        case .verificationFailed: return "支付验证失败"
        case .userCancelled: return "用户取消支付"
        case .unknown: return "未知支付错误"
        }
    }
}
