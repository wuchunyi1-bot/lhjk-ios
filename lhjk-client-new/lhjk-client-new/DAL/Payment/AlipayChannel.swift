import Foundation
import Combine

// MARK: - 支付宝支付渠道 (DAL)

/// 支付宝支付渠道实现
final class AlipayChannel: PaymentChannelProtocol {

    // MARK: - PaymentChannelProtocol

    let channelId = "alipay"

    // MARK: - Singleton

    static let shared = AlipayChannel()

    // MARK: - Properties

    private var pendingOrder: PaymentOrder?

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    func pay(order: PaymentOrder) -> AnyPublisher<PaymentResult, PaymentError> {
        pendingOrder = order

        return Future<PaymentResult, PaymentError> { [weak self] promise in
            guard self != nil else {
                promise(.failure(.unknown))
                return
            }

            // TODO: 1. 向服务端请求签名字符串（orderString）
            // TODO: 2. 调起支付宝 SDK
            // TODO: 3. 在回调闭包中 promise(.success) 或 promise(.failure)

            promise(.failure(.paymentFailed(reason: "支付宝支付暂未实现")))
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
        // TODO: AlipaySDK.defaultService()?.processOrder(withPaymentResult: url, standbyCallback: ...)
        return false
    }
}
