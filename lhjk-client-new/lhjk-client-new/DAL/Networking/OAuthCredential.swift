import Alamofire
import Foundation

// MARK: - OAuth Token Response

/// OAuth2 Token 接口响应（`POST /auth/oauth2/token`）
struct OAuthTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String?
    let scope: String?
}

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

    /// 是否需要刷新
    ///
    /// 后端当前未提供 refresh_token 刷新接口，始终返回 false。
    /// Token 过期后由服务端返回 401，业务层引导用户重新登录。
    var requiresRefresh: Bool { false }
}
