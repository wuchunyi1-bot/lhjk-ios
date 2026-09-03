import Foundation
import UIKit

#if canImport(AlipaySDK)
import AlipaySDK
private let alipaySDKLinked = true
#else
private let alipaySDKLinked = false
#endif

/// 支付宝 SDK 统一入口（APP 支付）
final class AlipaySDKManager {

    static let shared = AlipaySDKManager()

    private var payCompletion: ((Result<AlipayPayResult, AlipaySDKError>) -> Void)?

    private init() {}

    // MARK: - Capability

    var isSDKLinked: Bool { alipaySDKLinked }

    /// 启动时校验配置（支付宝 SDK 无需像微信一样 registerApp）
    func register() {
        guard AlipayConfig.isConfigured else {
            print("[AlipaySDK] register skipped — AppID / URL Scheme 未配置（见 AlipayConfig）")
            return
        }
        #if canImport(AlipaySDK)
        print("[AlipaySDK] ready appId=\(AlipayConfig.appId) scheme=\(AlipayConfig.urlScheme)")
        #else
        print("[AlipaySDK] register skipped — AlipaySDK 未链接（请 pod 集成 AlipaySDK-iOS）")
        #endif
    }

    // MARK: - URL callbacks

    @discardableResult
    func handleOpenURL(_ url: URL) -> Bool {
        #if canImport(AlipaySDK)
        guard url.scheme?.caseInsensitiveCompare(AlipayConfig.urlScheme) == .orderedSame else {
            return false
        }
        AlipaySDK.defaultService().processOrder(withPaymentResult: url) { [weak self] result in
            self?.finishPay(Self.parsePayResult(result))
        }
        return true
        #else
        return false
        #endif
    }

    // MARK: - Pay

    func pay(
        orderString: String,
        completion: @escaping (Result<AlipayPayResult, AlipaySDKError>) -> Void
    ) {
        guard ensureReady(completion: completion) else { return }

        let trimmed = orderString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion(.failure(.underlying("支付参数为空")))
            return
        }

        #if canImport(AlipaySDK)
        payCompletion = completion
        AlipaySDK.defaultService().payOrder(
            trimmed,
            fromScheme: AlipayConfig.urlScheme
        ) { [weak self] result in
            self?.finishPay(Self.parsePayResult(result))
        }
        #endif
    }

    func pay(orderString: String) async throws -> AlipayPayResult {
        try await withCheckedThrowingContinuation { continuation in
            pay(orderString: orderString) { result in
                continuation.resume(with: result)
            }
        }
    }

    // MARK: - Private

    private func ensureReady<T>(completion: (Result<T, AlipaySDKError>) -> Void) -> Bool {
        #if !canImport(AlipaySDK)
        completion(.failure(.sdkNotLinked))
        return false
        #else
        guard AlipayConfig.isConfigured else {
            completion(.failure(.notConfigured))
            return false
        }
        return true
        #endif
    }

    private func finishPay(_ result: Result<AlipayPayResult, AlipaySDKError>) {
        let completion = payCompletion
        payCompletion = nil
        completion?(result)
    }

    private static func parsePayResult(_ raw: [AnyHashable: Any]?) -> Result<AlipayPayResult, AlipaySDKError> {
        guard let dict = raw else {
            return .failure(.underlying("无支付结果"))
        }
        let status = (dict["resultStatus"] as? String) ?? ""
        let memo = (dict["memo"] as? String) ?? ""
        let resultStr = (dict["result"] as? String) ?? ""

        switch status {
        case "9000":
            return .success(
                AlipayPayResult(resultStatus: status, memo: memo, result: resultStr)
            )
        case "8000":
            return .failure(.processing)
        case "6001":
            return .failure(.userCancelled)
        case "6002":
            return .failure(.networkError)
        case "4000":
            return .failure(.payFailed(
                code: status,
                message: memo.isEmpty ? "订单支付失败" : memo
            ))
        default:
            return .failure(.payFailed(
                code: status,
                message: memo.isEmpty ? "支付失败" : memo
            ))
        }
    }
}
