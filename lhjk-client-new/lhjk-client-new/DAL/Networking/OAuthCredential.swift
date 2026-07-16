import Alamofire
import Foundation

// MARK: - Login UserInfo（登录 token 内嵌）

/// 登录接口返回的用户摘要 — onboarding 门禁主体（非信息详情接口）
struct LoginUserInfo: Codable {
    var chineseName: String?
    var sex: String?
    var birthday: String?
    /// 所属机构 ID
    var hospitalId: String?
    var id: String?
    var mobile: String?

    enum CodingKeys: String, CodingKey {
        case chineseName, sex, birthday, hospitalId, id, mobile
    }

    init(
        chineseName: String? = nil,
        sex: String? = nil,
        birthday: String? = nil,
        hospitalId: String? = nil,
        id: String? = nil,
        mobile: String? = nil
    ) {
        self.chineseName = chineseName
        self.sex = sex
        self.birthday = birthday
        self.hospitalId = hospitalId
        self.id = id
        self.mobile = mobile
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        chineseName = try c.decodeIfPresent(String.self, forKey: .chineseName)
        sex = try c.decodeIfPresent(String.self, forKey: .sex)
        birthday = try c.decodeIfPresent(String.self, forKey: .birthday)
        hospitalId = Self.decodeFlexibleString(c, key: .hospitalId)
        id = Self.decodeFlexibleString(c, key: .id)
        mobile = try c.decodeIfPresent(String.self, forKey: .mobile)
    }

    private static func decodeFlexibleString<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> String? {
        if let s = try? container.decodeIfPresent(String.self, forKey: key) {
            return s
        }
        if let i = try? container.decodeIfPresent(Int64.self, forKey: key) {
            return String(i)
        }
        if let i = try? container.decodeIfPresent(Int.self, forKey: key) {
            return String(i)
        }
        return nil
    }

    /// 任一必填门禁字段为空则视为未完善
    var needsOnboarding: Bool {
        isBlank(chineseName) || isBlank(sex) || isBlank(birthday) || isBlank(hospitalId)
    }

    private func isBlank(_ value: String?) -> Bool {
        (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - OAuth Token Response

/// OAuth2 Token 接口响应（`POST /auth/oauth2/token`）
struct OAuthTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String?
    let scope: String?
    /// 登录用户摘要（门禁用）；后端可能未返回
    let userInfo: LoginUserInfo?
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
