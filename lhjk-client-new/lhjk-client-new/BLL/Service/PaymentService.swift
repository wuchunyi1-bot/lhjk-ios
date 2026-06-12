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
}
