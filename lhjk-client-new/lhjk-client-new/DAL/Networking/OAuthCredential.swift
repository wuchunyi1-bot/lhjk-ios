import Alamofire
import Foundation

// MARK: - OAuth Token Response

/// OAuth2 Token 接口响应（`POST /auth/oauth2/token`）
///
/// 仅取凭证字段；后端若仍下发 `userInfo` 则忽略（onboarding 改由档案 `archiveComplete` 判定）。
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
    /// 本地过期时间前 60 秒即触发 Alamofire 自动 `refresh`（`POST /auth/oauth2/token`，`grant_type=refresh_token`）。
    /// 服务端也可能在本地未过期时返回业务码 `A0230`，由 `SessionExpiryCoordinator` 再尝试一次刷新。
    var requiresRefresh: Bool {
        Date().addingTimeInterval(60) >= expiration
    }
}
