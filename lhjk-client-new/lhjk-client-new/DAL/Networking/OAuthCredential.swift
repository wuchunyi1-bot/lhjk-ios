import Alamofire
import Foundation

// MARK: - OAuth Credential

/// Token 凭证模型，遵循 Alamofire 的 AuthenticationCredential 协议
///
/// `AuthenticationInterceptor` 通过 `requiresRefresh` 判断 Token 是否过期，
/// 过期时自动调用 `Authenticator.refresh(_:for:completion:)` 刷新。
struct OAuthCredential: AuthenticationCredential {

    /// 访问令牌
    let accessToken: String

    /// 刷新令牌
    let refreshToken: String

    /// 令牌过期时间
    let expiration: Date

    // MARK: - AuthenticationCredential

    /// 是否需要刷新：当前时间距过期不足 5 分钟时即视为需刷新，留出缓冲窗口
    var requiresRefresh: Bool {
        Date() > expiration.addingTimeInterval(-5 * 60)
    }
}
