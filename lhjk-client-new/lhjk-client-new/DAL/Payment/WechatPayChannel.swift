import Foundation
import Combine

// MARK: - 微信支付渠道 (DAL)

/// 微信支付渠道 — 调起与回调委托 `WeChatSDKManager`（同一 Open SDK）
final class WechatPayChannel: PaymentChannelProtocol {

    // MARK: - PaymentChannelProtocol

    let channelId = "wechat"

    // MARK: - Singleton

    static let shared = WechatPayChannel()

    // MARK: - Properties

    private var pendingOrder: PaymentOrder?
    private let wechat: WeChatSDKManager

    // MARK: - Initialization

    private init(wechat: WeChatSDKManager = .shared) {
        self.wechat = wechat
    }

    // MARK: - Public Methods

    /// 旧入口：缺少服务端预下单字段时无法调起；请改用 `pay(order:prepay:)`
    func pay(order: PaymentOrder) -> AnyPublisher<PaymentResult, PaymentError> {
        pendingOrder = order
        return Fail(error: .paymentFailed(reason: "缺少微信预支付参数，请使用 pay(order:prepay:)"))
            .eraseToAnyPublisher()
    }

    /// 使用服务端预下单结果调起微信支付
    func pay(order: PaymentOrder, prepay: WeChatPayRequest) -> AnyPublisher<PaymentResult, PaymentError> {
        pendingOrder = order

        return Future<PaymentResult, PaymentError> { [weak self] promise in
            guard let self else {
                promise(.failure(.unknown))
                return
            }

            guard self.wechat.isWeChatInstalled else {
                promise(.failure(.channelNotAvailable))
                return
            }

            self.wechat.pay(prepay) { result in
                switch result {
                case .success(let payResult):
                    let receipt = PaymentReceipt(
                        channel: self.channelId,
                        orderId: order.id,
                        transactionId: payResult.returnKey ?? order.id,
                        rawData: payResult.returnKey ?? "",
                        timestamp: Date()
                    )
                    // 客户端成功仅表示微信侧完成；最终到账须 BLL 服务端二次校验
                    promise(.success(.success(orderId: order.id, receipt: receipt)))
                case .failure(let error):
                    switch error {
                    case .userCancelled:
                        promise(.failure(.userCancelled))
                    case .notInstalled, .notSupported, .sdkNotLinked, .notConfigured:
                        promise(.failure(.channelNotAvailable))
                    case .payFailed(_, let message):
                        promise(.failure(.paymentFailed(reason: message)))
                    default:
                        promise(.failure(.paymentFailed(reason: error.localizedDescription)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// async 封装，供确认订单等 ViewModel 使用
    func payAsync(order: PaymentOrder, prepay: WeChatPayRequest) async throws -> PaymentResult {
        try await withCheckedThrowingContinuation { cont in
            var cancellable: AnyCancellable?
            cancellable = pay(order: order, prepay: prepay)
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
        wechat.handleOpenURL(url)
    }
}
