import Foundation

// MARK: - Errors

enum AlipaySDKError: Error, LocalizedError, Equatable {
    case notConfigured
    case sdkNotLinked
    case sendFailed
    case userCancelled
    case processing
    case networkError
    case payFailed(code: String, message: String)
    case underlying(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "支付宝尚未配置 AppID / URL Scheme"
        case .sdkNotLinked:
            return "未集成支付宝 SDK，请启用 AlipaySDK-iOS 后重试"
        case .sendFailed:
            return "调起支付宝失败"
        case .userCancelled:
            return "已取消支付"
        case .processing:
            return "支付处理中，请稍后在订单中查看结果"
        case .networkError:
            return "网络连接出错，请稍后重试"
        case .payFailed(_, let message):
            return message.isEmpty ? "支付宝支付失败" : message
        case .underlying(let message):
            return message
        }
    }
}

// MARK: - Pay result

struct AlipayPayResult: Equatable {
    /// 同步返回状态码（9000 表示支付成功）
    let resultStatus: String
    let memo: String
    /// 签名结果串，服务端可据此二次校验
    let result: String
}
