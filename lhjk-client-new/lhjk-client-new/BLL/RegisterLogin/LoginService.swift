import Foundation

/// 登录业务逻辑实现（V1.0 Mock 版本）
/// 参考 funde-client PRD 5.2 测试数据
///
/// V1.0 所有接口返回 mock 数据，V1.1 对接真实后端。
final class LoginService: LoginServiceProtocol {

    static let shared = LoginService()

    // MARK: - Mock Storage

    private var storedToken: String?
    private var storedRefreshToken: String?
    private var agreedPrivacyVersion: Int = 0

    // Mock registered users
    private var registeredUsers: Set<String> = ["15600000002", "15600000003"]

    private init() {}

    // MARK: - Privacy

    func getPrivacyVersion() async throws -> PrivacyVersionInfo {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        return PrivacyVersionInfo(
            latestPrivacyVersion: 2,
            userAgreementURL: "https://example.com/agreement",
            privacyPolicyURL: "https://example.com/privacy"
        )
    }

    func agreePrivacy(version: Int) async throws {
        try await Task.sleep(nanoseconds: 100_000_000)
        agreedPrivacyVersion = version
    }

    // MARK: - Local Phone

    func getLocalPhoneNumber() async throws -> String? {
        // V1.0 mock: simulate carrier return
        try await Task.sleep(nanoseconds: 300_000_000)
        // Return mock phone number (simulates successful carrier detection)
        return "15612348923"
    }

    // MARK: - SMS

    func sendVerificationCode(to phone: String, captchaToken: String) async throws -> SMSResponse {
        try await Task.sleep(nanoseconds: 400_000_000)

        // Mock error scenarios
        if phone == "15600000004" {
            throw LoginError.accountFrozen
        }
        if phone == "15600000005" {
            throw LoginError.accountCanceling
        }

        return SMSResponse(
            smsRequestId: "sms_\(UUID().uuidString.prefix(8))",
            expireSeconds: 300,
            resendAfter: 60
        )
    }

    // MARK: - Login

    func loginByPhone(_ phone: String, code: String, smsRequestId: String) async throws -> LoginResult {
        try await Task.sleep(nanoseconds: 500_000_000)

        // Test mock: fixed code "111111" always passes
        guard code == "111111" else {
            throw LoginError.invalidCode
        }

        let isNewUser = !registeredUsers.contains(phone)
        if isNewUser {
            registeredUsers.insert(phone)
        }

        return LoginResult(
            accessToken: "token_\(UUID().uuidString.prefix(12))",
            refreshToken: "refresh_\(UUID().uuidString.prefix(12))",
            isNewUser: isNewUser,
            redirectAllowed: nil
        )
    }

    func loginByPassword(_ phone: String, password: String) async throws -> LoginResult {
        try await Task.sleep(nanoseconds: 500_000_000)

        // Test mock: phone "15600000003" + password "Fdjk1234" → success
        guard phone == "15600000003" && password == "Fdjk1234" else {
            throw LoginError.invalidPassword
        }

        return LoginResult(
            accessToken: "token_\(UUID().uuidString.prefix(12))",
            refreshToken: "refresh_\(UUID().uuidString.prefix(12))",
            isNewUser: false,
            redirectAllowed: nil
        )
    }

    // MARK: - WeChat

    func wechatAuth(authCode: String) async throws -> WechatAuthResult {
        try await Task.sleep(nanoseconds: 500_000_000)

        // Test mock: based on openid mock
        if authCode == "mock_openid_bound" {
            return WechatAuthResult(bindStatus: .bound, wechatTempToken: nil, maskedPhone: "156****7890")
        } else {
            return WechatAuthResult(bindStatus: .unbound, wechatTempToken: "wxtoken_\(UUID().uuidString.prefix(8))", maskedPhone: nil)
        }
    }

    func wechatBindPhone(wechatToken: String, phone: String, code: String, confirmRebind: Bool) async throws -> LoginResult {
        try await Task.sleep(nanoseconds: 500_000_000)

        guard code == "111111" else {
            throw LoginError.invalidCode
        }

        // Phone already bound to other WeChat → conflict
        if phone == "15600000006" && !confirmRebind {
            throw LoginError.phoneBoundOtherWechat
        }

        return LoginResult(
            accessToken: "token_\(UUID().uuidString.prefix(12))",
            refreshToken: "refresh_\(UUID().uuidString.prefix(12))",
            isNewUser: false,
            redirectAllowed: nil
        )
    }

    // MARK: - Password Reset

    func resetPassword(phone: String, code: String, newPassword: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)

        guard code == "111111" else {
            throw LoginError.invalidCode
        }
        // Success — password updated in mock
    }

    // MARK: - Session

    func getSessionStatus() async throws -> SessionStatus {
        try await Task.sleep(nanoseconds: 200_000_000)

        guard storedToken != nil else {
            return SessionStatus(isValid: false, accountStatus: .normal, reason: "token_expired")
        }

        return SessionStatus(isValid: true, accountStatus: .normal, reason: nil)
    }

    func reportNotificationPermission(status: NotificationPermissionStatus) async throws {
        try await Task.sleep(nanoseconds: 100_000_000)
        // Mock: save success
    }

    // MARK: - Token Storage

    func saveToken(_ token: String, refreshToken: String) {
        storedToken = token
        storedRefreshToken = refreshToken
        // TODO: V1.1 — save to Keychain
    }

    func getToken() -> String? {
        return storedToken
    }

    func clearSession() {
        storedToken = nil
        storedRefreshToken = nil
    }
}

// MARK: - Login Errors

enum LoginError: Error, LocalizedError {
    case invalidPhone
    case invalidCode
    case codeExpired
    case tooManyAttempts
    case invalidPassword
    case passwordLocked(remainingMinutes: Int)
    case accountFrozen
    case accountCanceling
    case wechatAuthFailed
    case wechatSDKUnavailable
    case wechatNotInstalled
    case phoneBoundOtherWechat
    case wechatBoundOtherPhone
    case networkError
    case timeout
    case systemError

    var errorDescription: String? {
        switch self {
        case .invalidPhone:
            return "请输入正确的手机号"
        case .invalidCode:
            return "验证码错误，请重新输入"
        case .codeExpired:
            return "验证码已过期，请重新获取"
        case .tooManyAttempts:
            return "尝试次数过多，请重新获取验证码"
        case .invalidPassword:
            return "手机号或密码错误，请重试。如忘记密码，可点击下方\"忘记密码\"重置"
        case .passwordLocked(let minutes):
            return "尝试次数过多，请 \(minutes) 分钟后再试或使用验证码登录"
        case .accountFrozen:
            return "当前账号暂无法登录，请联系客服处理"
        case .accountCanceling:
            return "账号正在注销处理中，暂无法登录"
        case .wechatAuthFailed:
            return "微信授权失败，请稍后重试"
        case .wechatSDKUnavailable:
            return "当前设备未安装微信，请使用手机号登录"
        case .wechatNotInstalled:
            return "当前设备未安装微信，请使用手机号登录"
        case .phoneBoundOtherWechat:
            return "该手机号已绑定其他微信号，请更换手机号，或联系客服解绑后重试"
        case .wechatBoundOtherPhone:
            return "当前微信已绑定其他手机号，请联系客服处理"
        case .networkError:
            return "网络不稳定，请稍后重试"
        case .timeout:
            return "请求超时，请稍后重试"
        case .systemError:
            return "系统暂时不可用，请稍后再试"
        }
    }
}
