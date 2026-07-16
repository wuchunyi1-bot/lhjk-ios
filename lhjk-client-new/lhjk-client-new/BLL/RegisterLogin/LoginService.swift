import Foundation

// MARK: - SMS 验证码类型

/// 短信验证码发送场景
enum SMSVerificationType {
    /// 1 — 注册或登录
    case login
    /// 2 — 忘记密码 / 设置密码
    case resetPassword
    /// 3 — 修改邮箱（预留）
    case changeEmail
    /// 4 — 修改手机号码
    case changePhone

    /// 传给后端的整数值
    var backendValue: String {
        switch self {
        case .login:         return "1"
        case .resetPassword: return "2"
        case .changeEmail:   return "3"
        case .changePhone:   return "4"
        }
    }
}

/// 登录业务逻辑实现
///
/// V1.0 → V1.1: `sendVerificationCode`、`loginByPhone`、`loginByPassword` 已对接真实 API，
/// 其余方法（微信、会话状态等）保持 mock。
final class LoginService: LoginServiceProtocol {

    static let shared = LoginService()

    // MARK: - OAuth 常量

    private let clientId = "funde-app"
    private let clientSecret = "funde-app"

    // MARK: - Private State

    private var agreedPrivacyVersion: Int = 0
    private var storedToken: String?
    private var storedRefreshToken: String?

    private init() {}

    // MARK: - Privacy (Mock — 暂无真实 API)

    func getPrivacyVersion() async throws -> PrivacyVersionInfo {
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

    // MARK: - SMS (Real API)

    func sendVerificationCode(to phone: String, type: SMSVerificationType) async throws -> SMSResponse {
        print("[LoginService] sendVerificationCode → mobile=\(phone) type=\(type.backendValue)")

        let params: [String: Any] = [
            "mobile": phone,
            "type": type.backendValue,
            "clientId": clientId
        ]

        let response: APIResponse<SMSResponse> = try await APIManager.shared
            .publicGetAsync(
                path: "/v1/mobileVerification/sendVerificationCode",
                parameters: params,
                responseType: APIResponse<SMSResponse>.self
            )

        guard response.isSuccess else {
            print("[LoginService] sendVerificationCode ✗ code=\(response.code) msg=\(String(describing: response.msg))")
            throw LoginError(from: response.code, msg: response.msg ?? "")
        }

        print("[LoginService] sendVerificationCode ✓ smsRequestId=\(response.data?.smsRequestId ?? "nil")")
        return response.data ?? SMSResponse(smsRequestId: nil, expireSeconds: nil, resendAfter: nil)
    }

    // MARK: - Login (Real API)

    func loginByPhone(_ phone: String, code: String) async throws -> LoginResult {
        print("[LoginService] loginByPhone → mobile=\(phone) code=\(code.prefix(2))****")

        let params: [String: Any] = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "grant_type": "sms",
            "mobile": phone,
            "code": code
        ]

        let response: APIResponse<OAuthTokenResponse> = try await APIManager.shared
            .publicPostFormURLEncodedAsync(
                path: "/auth/oauth2/token",
                parameters: params,
                responseType: APIResponse<OAuthTokenResponse>.self,
                useGatewayRoot: true
            )

        guard response.isSuccess, let token = response.data else {
            print("[LoginService] loginByPhone ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw LoginError(from: response.code, msg: response.msg ?? "")
        }

        print("[LoginService] loginByPhone ✓ accessToken=\(token.accessToken.prefix(12))… expiresIn=\(token.expiresIn)s")

        // 持久化 OAuthCredential
        let credential = OAuthCredential(
            accessToken: token.accessToken,
            refreshToken: token.refreshToken,
            expiration: Date().addingTimeInterval(TimeInterval(token.expiresIn))
        )
        APIManager.shared.setCredential(credential)

        // 兼容旧版存储
        storedToken = token.accessToken
        storedRefreshToken = token.refreshToken

        UserManager.shared.applyLoginUserInfo(token.userInfo)

        return LoginResult(
            accessToken: token.accessToken,
            refreshToken: token.refreshToken
        )
    }

    // MARK: - Password Login (Mock — 待后续 API 对接)

    func loginByPassword(_ phone: String, password: String) async throws -> LoginResult {
        print("[LoginService] loginByPassword → mobile=\(phone)")

        let params: [String: Any] = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "grant_type": "password",
            "username": phone,
            "password": password
        ]

        let response: APIResponse<OAuthTokenResponse> = try await APIManager.shared
            .publicPostFormURLEncodedAsync(
                path: "/auth/oauth2/token",
                parameters: params,
                responseType: APIResponse<OAuthTokenResponse>.self,
                useGatewayRoot: true
            )

        guard response.isSuccess, let token = response.data else {
            print("[LoginService] loginByPassword ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw LoginError(from: response.code, msg: response.msg ?? "")
        }

        print("[LoginService] loginByPassword ✓ accessToken=\(token.accessToken.prefix(12))… expiresIn=\(token.expiresIn)s")

        let credential = OAuthCredential(
            accessToken: token.accessToken,
            refreshToken: token.refreshToken,
            expiration: Date().addingTimeInterval(TimeInterval(token.expiresIn))
        )
        APIManager.shared.setCredential(credential)
        storedToken = token.accessToken
        storedRefreshToken = token.refreshToken

        UserManager.shared.applyLoginUserInfo(token.userInfo)

        return LoginResult(accessToken: token.accessToken, refreshToken: token.refreshToken)
    }

    // MARK: - WeChat (Mock — 待后续 API 对接)

    func wechatAuth(authCode: String) async throws -> WechatAuthResult {
        try await Task.sleep(nanoseconds: 500_000_000)
        if authCode == "mock_openid_bound" {
            return WechatAuthResult(bindStatus: .bound, wechatTempToken: nil, maskedPhone: "156****7890")
        } else {
            return WechatAuthResult(bindStatus: .unbound, wechatTempToken: "wxtoken_\(UUID().uuidString.prefix(8))", maskedPhone: nil)
        }
    }

    func wechatBindPhone(wechatToken: String, phone: String, code: String, confirmRebind: Bool) async throws -> LoginResult {
        try await Task.sleep(nanoseconds: 500_000_000)
        guard code == "111111" else { throw LoginError.invalidCode }
        if phone == "15600000006" && !confirmRebind { throw LoginError.phoneBoundOtherWechat }
        return LoginResult(
            accessToken: "token_\(UUID().uuidString.prefix(12))",
            refreshToken: "refresh_\(UUID().uuidString.prefix(12))"
        )
    }

    // MARK: - Password Reset (Real API)

    func resetPassword(phone: String, code: String, newPassword: String) async throws {
        try await UserService.shared.resetPasswordByMobile(mobile: phone, newPwd: newPassword, checkCode: code)
    }

    // MARK: - Session (Mock — 待后续 API 对接)

    func getSessionStatus() async throws -> SessionStatus {
        try await Task.sleep(nanoseconds: 200_000_000)
        guard storedToken != nil else {
            return SessionStatus(isValid: false, accountStatus: .normal, reason: "token_expired")
        }
        return SessionStatus(isValid: true, accountStatus: .normal, reason: nil)
    }

    func reportNotificationPermission(status: NotificationPermissionStatus) async throws {
        try await Task.sleep(nanoseconds: 100_000_000)
    }

    // MARK: - Token Storage

    /// 调用服务端退出登录接口（fire-and-forget，不处理返回结果）
    func logout() async {
        print("[LoginService] logout → calling DELETE /auth/oauth2/logout")
        do {
            let response: APIResponse<EmptyResponse> = try await APIManager.shared.deleteAsync(
                path: "/auth/oauth2/logout",
                parameters: nil,
                responseType: APIResponse<EmptyResponse>.self,
                useGatewayRoot: true
            )
            print("[LoginService] logout ✓ code=\(response.code) msg=\(response.msg ?? "nil")")
        } catch {
            print("[LoginService] logout ✗ error: \(error.localizedDescription)")
        }
    }

    func saveToken(_ token: String, refreshToken: String) {
        storedToken = token
        storedRefreshToken = refreshToken
    }

    func getToken() -> String? {
        storedToken
    }

    func clearSession() {
        storedToken = nil
        storedRefreshToken = nil
        APIManager.shared.clearCredential()
    }
}

// MARK: - LoginError → 从 API 响应映射

extension LoginError {
    /// 根据 API 返回的 `code` / `msg` 构造对应错误
    init(from code: String, msg: String) {
        print("[LoginService] Server error — code=\(code) msg=\(msg)")
        switch code {
        case "400":
            self = .invalidPhone
        case "401":
            self = .invalidCode
        case "403":
            if msg.contains("冻结") { self = .accountFrozen }
            else if msg.contains("注销") { self = .accountCanceling }
            else { self = .invalidCode }
        case "429":
            self = .tooManyAttempts
        case "408", "504":
            self = .timeout
        case "A0230":
            self = msg.contains("失效") || msg.contains("过期") ? .codeExpired : .invalidCode
        default:
            if msg.contains("网络") || msg.contains("连接") { self = .networkError }
            else if msg.contains("超时") { self = .timeout }
            else if msg.contains("失效") || msg.contains("过期") { self = .codeExpired }
            else { self = .serverMessage(msg) }
        }
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
    case serverMessage(String)

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
        case .serverMessage(let msg):
            return msg
        }
    }
}
