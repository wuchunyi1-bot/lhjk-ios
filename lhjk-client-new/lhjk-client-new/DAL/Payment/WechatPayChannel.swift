import Foundation
import Combine

// MARK: - 微信支付渠道 (DAL)

/// 微信支付渠道实现
final class WechatPayChannel: PaymentChannelProtocol {

    // MARK: - PaymentChannelProtocol

    let channelId = "wechat"

    // MARK: - Singleton

    static let shared = WechatPayChannel()

    // MARK: - Properties

    private var pendingOrder: PaymentOrder?

    // MARK: - Initialization

    private init() {
        // TODO: 注册微信 SDK
        // WXApi.registerApp("wx_app_id", universalLink: "https://...")
    }

    // MARK: - Public Methods

    func pay(order: PaymentOrder) -> AnyPublisher<PaymentResult, PaymentError> {
        pendingOrder = order

        return Future<PaymentResult, PaymentError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }

            // TODO: 1. 向服务端请求预支付信息（prepay_id）
            // TODO: 2. 构建 PayReq，调起微信支付
            // TODO: 3. 在 WXApiDelegate 回调中 promise(.success) 或 promise(.failure)

            promise(.failure(.paymentFailed(reason: "微信支付暂未实现")))
        }
        .eraseToAnyPublisher()
    }

    func verify(receipt: PaymentReceipt) -> AnyPublisher<Bool, PaymentError> {
        // TODO: 将支付凭证发送至服务端验证
        return Just(true)
            .setFailureType(to: PaymentError.self)
            .eraseToAnyPublisher()
    }

    func handleCallback(url: URL) -> Bool {
        // TODO: WXApi.handleOpen(url, delegate: self)
        return false
    }
}
