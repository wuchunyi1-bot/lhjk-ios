import Foundation
import Combine

// MARK: - 支付宝支付渠道 (DAL)

/// 支付宝支付渠道 — 调起与回调委托 `AlipaySDKManager`
final class AlipayChannel: PaymentChannelProtocol {

    // MARK: - PaymentChannelProtocol

    let channelId = "alipay"

    // MARK: - Singleton

    static let shared = AlipayChannel()

    // MARK: - Properties

    private var pendingOrder: PaymentOrder?
    private let alipay: AlipaySDKManager

    // MARK: - Initialization

    private init(alipay: AlipaySDKManager = .shared) {
        self.alipay = alipay
    }

    // MARK: - Public Methods

    /// 旧入口：缺少服务端 orderString 时无法调起；请改用 `pay(order:orderString:)`
    func pay(order: PaymentOrder) -> AnyPublisher<PaymentResult, PaymentError> {
        pendingOrder = order
        return Fail(error: .paymentFailed(reason: "缺少支付宝 orderString，请使用 pay(order:orderString:)"))
            .eraseToAnyPublisher()
    }

    /// 使用服务端 `orderPay` 返回的签名字符串调起支付宝
    func pay(order: PaymentOrder, orderString: String) -> AnyPublisher<PaymentResult, PaymentError> {
        pendingOrder = order

        return Future<PaymentResult, PaymentError> { [weak self] promise in
            guard let self else {
                promise(.failure(.unknown))
                return
            }

            self.alipay.pay(orderString: orderString) { result in
                switch result {
                case .success(let payResult):
                    let receipt = PaymentReceipt(
                        channel: self.channelId,
                        orderId: order.id,
                        transactionId: payResult.result,
                        rawData: payResult.result,
                        timestamp: Date()
                    )
                    promise(.success(.success(orderId: order.id, receipt: receipt)))
                case .failure(let error):
                    switch error {
                    case .userCancelled:
                        promise(.failure(.userCancelled))
                    case .notConfigured, .sdkNotLinked:
                        promise(.failure(.channelNotAvailable))
                    case .processing:
                        promise(.success(.pending(orderId: order.id)))
                    case .networkError, .sendFailed:
                        promise(.failure(.paymentFailed(reason: error.localizedDescription)))
                    case .payFailed(_, let message):
                        promise(.failure(.paymentFailed(reason: message)))
                    case .underlying(let message):
                        promise(.failure(.paymentFailed(reason: message)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func payAsync(order: PaymentOrder, orderString: String) async throws -> PaymentResult {
        try await withCheckedThrowingContinuation { cont in
            var cancellable: AnyCancellable?
            cancellable = pay(order: order, orderString: orderString)
                .sink(
                    receiveCompletion: { completion in
                        defer { cancellable = nil }
                        if case .failure(let error) = completion {
                            cont.resume(throwing: error)
                        }
                    },
                    receiveValue: { value in
                        cont.resume(returning: value)
                    }
                )
        }
    }

    func verify(receipt: PaymentReceipt) -> AnyPublisher<Bool, PaymentError> {
        // 真实校验在 BLL → 服务端；此处不信任本地结果
        return Just(false)
            .setFailureType(to: PaymentError.self)
            .eraseToAnyPublisher()
    }

    func handleCallback(url: URL) -> Bool {
        alipay.handleOpenURL(url)
    }
}
