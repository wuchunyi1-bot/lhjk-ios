import Foundation
import Combine

// MARK: - 支付服务 (BLL)

/// 统一支付协调服务 — 渠道选择、订单创建、回调分发
final class PaymentService {

    // MARK: - Singleton

    static let shared = PaymentService()

    // MARK: - Dependencies

    private var channels: [String: PaymentChannelProtocol] = [:]

    // MARK: - Initialization

    private init() {
        registerDefaultChannels()
    }

    // MARK: - Public Methods

    /// 获取可用支付渠道
    func availableChannels() -> [PaymentChannel] {
        // 检测各渠道可用性：
        // - 微信支付: 检查 WXApi.isWXAppInstalled()
        // - 支付宝: 始终可用（通过 H5 兜底）
        var available: [PaymentChannel] = [.alipay]

        // TODO: 检查微信是否安装
        // if WXApi.isWXAppInstalled() { available.append(.wechatPay) }
        available.append(.wechatPay)

        return available
    }

    /// 发起支付
    /// - Parameters:
    ///   - productId: 商品 ID
    ///   - productName: 商品名称
    ///   - amount: 金额（分）
    ///   - channel: 支付渠道
    /// - Returns: 支付结果 Publisher
    func pay(
        productId: String,
        productName: String,
        amount: Int,
        channel: PaymentChannel
    ) -> AnyPublisher<PaymentResult, PaymentError> {
        let order = PaymentOrder(
            productId: productId,
            productName: productName,
            amount: amount,
            channel: channel
        )

        guard let paymentChannel = channels[channel.rawValue] else {
            return Fail(error: PaymentError.channelNotAvailable)
                .eraseToAnyPublisher()
        }

        return paymentChannel.pay(order: order)
    }

    /// 商城待支付订单：先调 `POST /v1/orderPay/orderPay`，再调起渠道 SDK
    func payMallOrder(
        orderId: Int64,
        productName: String,
        amountYuan: Double,
        channel: PaymentChannel,
        amountVersion: Int? = nil,
        expectedPayableAmount: Double? = nil,
        description: String? = nil,
        orderService: OrderService = .shared
    ) async throws -> PaymentResult {
        let payType: OrderPayType = channel == .wechatPay ? .wechat : .alipay
        let contractedPayable = expectedPayableAmount ?? amountYuan
        let payData = try await orderService.orderPay(
            orderId: orderId,
            payType: payType,
            amountVersion: amountVersion,
            expectedPayableAmount: contractedPayable,
            description: description
        )

        let fen = max(0, Int((contractedPayable * 100).rounded()))
        let order = PaymentOrder(
            id: String(orderId),
            productId: String(orderId),
            productName: productName,
            amount: fen,
            channel: channel
        )

        switch channel {
        case .wechatPay:
            if let prepay = payData.wechatPayRequest {
                return try requireSuccess(
                    try await WechatPayChannel.shared.payAsync(order: order, prepay: prepay)
                )
            }
            // 0 元单或后端未返回调起参数：接口成功即视为下单完成（不以客户端伪造支付成功）
            if fen <= 0 {
                return .success(
                    orderId: order.id,
                    receipt: PaymentReceipt(
                        channel: channel.rawValue,
                        orderId: order.id,
                        transactionId: order.id,
                        rawData: "zero_pay",
                        timestamp: Date()
                    )
                )
            }
            throw PaymentError.paymentFailed(reason: "微信预支付参数不完整，请稍后重试或联系客服")
        case .alipay:
            if let orderString = payData.alipayOrderString {
                return try requireSuccess(
                    try await AlipayChannel.shared.payAsync(order: order, orderString: orderString)
                )
            }
            if fen <= 0 {
                return .success(
                    orderId: order.id,
                    receipt: PaymentReceipt(
                        channel: channel.rawValue,
                        orderId: order.id,
                        transactionId: order.id,
                        rawData: "zero_pay",
                        timestamp: Date()
                    )
                )
            }
            throw PaymentError.paymentFailed(reason: "支付宝支付参数不完整，请稍后重试或联系客服")
        }
    }

    /// 处理支付回调
    /// - Parameter url: 回调 URL
    func handlePaymentCallback(url: URL) -> Bool {
        for channel in channels.values {
            if channel.handleCallback(url: url) {
                return true
            }
        }
        return false
    }

    // MARK: - Private

    private func registerDefaultChannels() {
        channels[PaymentChannel.wechatPay.rawValue] = WechatPayChannel.shared
        channels[PaymentChannel.alipay.rawValue] = AlipayChannel.shared
    }

    private func requireSuccess(_ result: PaymentResult) throws -> PaymentResult {
        switch result {
        case .success:
            return result
        case .pending:
            throw PaymentError.paymentFailed(reason: "支付处理中，请稍后在订单中查看结果")
        case .cancelled:
            throw PaymentError.userCancelled
        case .failed(_, let error):
            throw error
        }
    }
}
