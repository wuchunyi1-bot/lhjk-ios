import Foundation

// MARK: - Login Data Types

/// 登录方式
enum LoginType: String {
    case sms = "sms"
    case password = "password"
    case wechat = "wechat"
}

/// 隐私协议版本信息
struct PrivacyVersionInfo {
    let latestPrivacyVersion: Int
    let userAgreementURL: String
    let privacyPolicyURL: String
}

/// 短信发送响应（所有字段 optional，兼容后端差异）
struct SMSResponse: Decodable {
    let smsRequestId: String?
    let expireSeconds: Int?
    let resendAfter: Int?
}

/// 登录结果（BLL 层概念，由 `LoginService` 从 `OAuthTokenResponse` 转换）
struct LoginResult {
    let accessToken: String
    let refreshToken: String
}

/// 微信 App 登录中间结果（对接 `WE_CHAT_APP_LOGIN`）
enum WeChatLoginStep {
    /// 已获 Token，可进入登录成功编排
    case loggedIn(LoginResult)
    /// 业务码 AU0001：需绑定手机号，复用同一微信 `code`
    case needBindMobile(wechatCode: String)
}

/// 会话状态
struct SessionStatus {
    let isValid: Bool
    let accountStatus: AccountStatus
    let reason: String?
}

/// 账号状态
enum AccountStatus {
    case normal
    case frozen
    case canceling
}

/// 通知权限状态
enum NotificationPermissionStatus: String {
    case allowed
    case denied
    case notDetermined = "not_determined"
    case unavailable
}
