import Foundation

/// 统一 API 错误类型
enum APIError: Error, LocalizedError {
    /// 网络不可达
    case networkUnreachable
    /// 请求超时
    case timeout
    /// 服务端错误（HTTP 5xx）
    case serverError(statusCode: Int, message: String?)
    /// 业务错误（HTTP 2xx 但含业务错误码）
    case businessError(code: Int, message: String?)
    /// 未授权（HTTP 401）
    case unauthorized
    /// JSON 解析错误
    case decodingError(Error)
    /// 未知错误
    case unknown(Error?)

    var errorDescription: String? {
        switch self {
        case .networkUnreachable:
            return "网络连接不可用，请检查网络设置"
        case .timeout:
            return "请求超时，请稍后重试"
        case .serverError(let statusCode, let message):
            return message ?? "服务器错误 (\(statusCode))"
        case .businessError(_, let message):
            return message ?? "操作失败，请稍后重试"
        case .unauthorized:
            return "登录已过期，请重新登录"
        case .decodingError(let error):
            return "数据解析错误: \(error.localizedDescription)"
        case .unknown(let error):
            return error?.localizedDescription ?? "未知错误"
        }
    }
}
