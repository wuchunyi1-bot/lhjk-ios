import Foundation
import Combine

/// 登录表单子步骤（页内忘记密码）
enum LoginFormStep {
    case login
    case forgot
    case resetPassword
}

/// 登录流程步骤
enum LoginFlowStep {
    case privacyCheck
    case privacyPrompt(PrivacyVersionInfo)
    case loginForm
    case notificationGuide
    case complete
}

/// 登录页 ViewModel — 状态管理、API 调用、表单验证、流程编排
///
/// ViewController 只负责 UI 布局、键盘、弹窗动画、Toast 展示。
final class LoginViewModel: ObservableObject {

    // MARK: - Published State

    @Published var loginMode: LoginMode = .sms
    @Published var formStep: LoginFormStep = .login
    @Published var isLoggingIn = false
    @Published var needsPrivacyConsent = false
    @Published var phoneNumber = ""
    @Published var flowStep: LoginFlowStep = .loginForm
    @Published var isResettingPassword = false
    @Published var isVerifyingForgotCode = false

    // MARK: - One-shot Publishers

    let toastPublisher = PassthroughSubject<String, Never>()
    let navigateToHomePublisher = PassthroughSubject<Void, Never>()
    let presentOnboardingPublisher = PassthroughSubject<Void, Never>()
    /// 微信登录需绑定手机号（携带待复用的微信 code）
    let presentWeChatBindPublisher = PassthroughSubject<String, Never>()

    // MARK: - Dependencies

    private let loginService: LoginService
    private let userManager: UserManager
    private let rongCloudManager: RongCloudManager
    private let wechatSDK: WeChatSDKManager

    /// 通知引导关闭后再跳转首页 / Onboarding
    private var pendingNeedOnboarding = false

    // MARK: - Private State

    private var smsRequestId: String?
    /// AU0001 后暂存的微信授权 code（取消绑定时清除）
    private(set) var pendingWeChatCode: String?

    // MARK: - Init

    init(loginService: LoginService = AppContainer.shared.loginService,
         userManager: UserManager = AppContainer.shared.userManager,
         rongCloudManager: RongCloudManager = AppContainer.shared.rongCloudManager,
         wechatSDK: WeChatSDKManager = .shared) {
        self.loginService = loginService
        self.userManager = userManager
        self.rongCloudManager = rongCloudManager
        self.wechatSDK = wechatSDK
    }

    // MARK: - Mode Toggle

    func toggleMode() {
        loginMode = loginMode == .sms ? .password : .sms
        formStep = .login
    }

    func startForgotPassword(prefillPhone: String) {
        phoneNumber = prefillPhone
        formStep = .forgot
    }

    func backToPasswordLogin() {
        formStep = .login
        loginMode = .password
    }

    func proceedToResetPassword() {
        formStep = .resetPassword
    }

    // MARK: - Privacy

    /// 启动后不再弹出「隐私保护提示」；协议在登录页勾选。
    func checkPrivacyConsent() {
        needsPrivacyConsent = false
        if case .loginForm = flowStep { return }
        flowStep = .loginForm
    }

    func agreePrivacy(version: Int) {
        Task {
            try? await loginService.agreePrivacy(version: version)
            UserDefaults.standard.set(version, forKey: "agreed_privacy_version")
            await MainActor.run {
                needsPrivacyConsent = false
                flowStep = .loginForm
            }
        }
    }

    // MARK: - Validation

    func validatePhone(_ phone: String) -> String? {
        let pattern = "^1[3-9]\\d{9}$"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              regex.firstMatch(in: phone, range: NSRange(phone.startIndex..., in: phone)) != nil else {
            return "请输入正确的手机号"
        }
        return nil
    }

    // MARK: - Send Code

    func requestVerificationCode(phone: String, type: SMSVerificationType = .login) {
        phoneNumber = phone
        guard validatePhone(phone) == nil else {
            toastPublisher.send("请输入正确的手机号")
            return
        }
        sendCodeAfterCaptcha(phone: phone, captchaToken: "", type: type)
    }

    func sendCodeAfterCaptcha(phone: String, captchaToken: String, type: SMSVerificationType = .login) {
        Task {
            do {
                let response = try await loginService.sendVerificationCode(to: phone, type: type)
                smsRequestId = response.smsRequestId
                await MainActor.run {
                    flowStep = .loginForm
                    toastPublisher.send("验证码已发送")
                }
            } catch {
                await MainActor.run {
                    flowStep = .loginForm
                    toastPublisher.send(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - SMS Login

    func loginBySMS(phone: String, code: String) -> Bool {
        guard validatePhone(phone) == nil else {
            toastPublisher.send("请输入正确的手机号")
            return false
        }
        guard !code.isEmpty else {
            toastPublisher.send("请输入验证码"); return false
        }
        guard code.count == 6 else {
            toastPublisher.send("请输入 6 位验证码"); return false
        }
        phoneNumber = phone
        isLoggingIn = true

        Task {
            do {
                try await loginService.loginByPhone(phone, code: code)
                await handleLoginSuccess(phone: phone)
            } catch {
                await MainActor.run {
                    isLoggingIn = false
                    toastPublisher.send(error.localizedDescription)
                }
            }
        }
        return true
    }

    // MARK: - Password Login

    func loginByPassword(phone: String, password: String) -> Bool {
        guard validatePhone(phone) == nil else {
            toastPublisher.send("请输入正确的手机号")
            return false
        }
        guard !password.isEmpty else {
            toastPublisher.send("请输入密码"); return false
        }
        guard password.count >= 6 else {
            toastPublisher.send("密码至少 6 位"); return false
        }
        phoneNumber = phone
        isLoggingIn = true

        Task {
            do {
                try await loginService.loginByPassword(phone, password: password)
                await handleLoginSuccess(phone: phone)
            } catch {
                await MainActor.run {
                    isLoggingIn = false
                    toastPublisher.send(error.localizedDescription)
                }
            }
        }
        return true
    }

    // MARK: - WeChat

    /// 拉起微信授权并登录；未绑定则通过 `presentWeChatBindPublisher` 通知 VC
    func startWeChatLogin() {
        guard !isLoggingIn else { return }
        isLoggingIn = true
        pendingWeChatCode = nil

        Task {
            do {
                let auth = try await requestWeChatAuthCode()
                let step = try await loginService.loginByWeChat(code: auth.code)
                switch step {
                case .loggedIn:
                    await handleLoginSuccess(phone: "")
                case .needBindMobile(let code):
                    await MainActor.run {
                        isLoggingIn = false
                        pendingWeChatCode = code
                        presentWeChatBindPublisher.send(code)
                    }
                }
            } catch let error as WeChatSDKError where error == .userCancelled {
                await MainActor.run { isLoggingIn = false }
            } catch {
                await MainActor.run {
                    isLoggingIn = false
                    let msg = mapWeChatError(error)
                    if !msg.isEmpty {
                        toastPublisher.send(msg)
                    }
                }
            }
        }
    }

    /// 绑定页发码（type=1）
    func sendWeChatBindVerificationCode(phone: String) async throws {
        _ = try await loginService.sendVerificationCode(to: phone, type: .login)
    }

    /// 提交绑定并登录
    func submitWeChatBind(phone: String, smsCode: String) {
        guard let wechatCode = pendingWeChatCode, !wechatCode.isEmpty else {
            toastPublisher.send(LoginError.wechatCodeExpired.errorDescription ?? "请重新微信登录")
            return
        }
        guard validatePhone(phone) == nil else {
            toastPublisher.send("请输入正确的手机号")
            return
        }
        guard !smsCode.isEmpty else {
            toastPublisher.send("请输入验证码")
            return
        }

        isLoggingIn = true
        Task {
            do {
                _ = try await loginService.loginByWeChatBinding(
                    code: wechatCode,
                    mobile: phone,
                    smsCode: smsCode
                )
                await MainActor.run { pendingWeChatCode = nil }
                await handleLoginSuccess(phone: phone)
            } catch {
                await MainActor.run {
                    isLoggingIn = false
                    toastPublisher.send(error.localizedDescription)
                }
            }
        }
    }

    func clearPendingWeChatCode() {
        pendingWeChatCode = nil
    }

    private func requestWeChatAuthCode() async throws -> WeChatAuthResult {
        try await withCheckedThrowingContinuation { continuation in
            wechatSDK.sendAuth { result in
                continuation.resume(with: result)
            }
        }
    }

    private func mapWeChatError(_ error: Error) -> String {
        if let sdk = error as? WeChatSDKError {
            switch sdk {
            case .notInstalled:
                return LoginError.wechatNotInstalled.errorDescription ?? sdk.localizedDescription
            case .sdkNotLinked, .notConfigured:
                return LoginError.wechatSDKUnavailable.errorDescription ?? sdk.localizedDescription
            case .userCancelled:
                return ""
            default:
                return LoginError.wechatAuthFailed.errorDescription ?? sdk.localizedDescription
            }
        }
        return error.localizedDescription
    }

    // MARK: - Post-Login Orchestration

    private func handleLoginSuccess(phone: String) async {
        // Token 已由 LoginService 根据服务端 expires_in 持久化
        await MainActor.run {
            UserDefaults.standard.set(phone, forKey: "current_user_mobile")
            isLoggingIn = false
        }

        // 连接 IM
        rongCloudManager.fetchTokenAndConnect()

        await DictionaryCacheService.shared.sync()

        // 串行：先拿 userId → 拉默认档案 → 按 archiveComplete 门禁
        _ = await userManager.refreshUserInfo()
        _ = await userManager.refreshDefaultArchive()
        _ = await userManager.refreshArchiveCompletion()
        let needOnboarding = userManager.checkNeedOnboarding()

        await MainActor.run {
            pendingNeedOnboarding = needOnboarding
            flowStep = .notificationGuide
        }
    }

    /// 用户处理完通知预引导后进入首页（避免 `setRoot` 把弹窗立刻顶掉）
    func completePostLoginFlow() {
        navigateToHomePublisher.send()
        if pendingNeedOnboarding {
            presentOnboardingPublisher.send()
        }
        pendingNeedOnboarding = false
        flowStep = .complete
    }

    // MARK: - Notification Permission

    func reportNotificationPromptClosed(
        action: NotificationPromptService.PromptAction,
        systemAuthorized: Bool
    ) {
        NotificationPromptService.shared.recordPromptClosed(
            action: action,
            systemAuthorized: systemAuthorized
        )
        let status: NotificationPermissionStatus = systemAuthorized ? .allowed : .denied
        Task {
            try? await loginService.reportNotificationPermission(
                status: status,
                promptAction: action,
                systemAuthorized: systemAuthorized
            )
        }
    }

    // MARK: - Forgot Password

    func submitForgotCode(phone: String, code: String) {
        guard validatePhone(phone) == nil else {
            toastPublisher.send("请输入正确的手机号")
            return
        }
        guard !code.isEmpty else {
            toastPublisher.send("请输入验证码"); return
        }
        guard code.count == 6 else {
            toastPublisher.send("请输入 6 位验证码"); return
        }

        print("[LoginViewModel] submitForgotCode → checking sms code")
        isVerifyingForgotCode = true
        Task {
            do {
                try await loginService.checkSmsCode(
                    mobile: phone,
                    checkCode: code,
                    type: .resetPassword
                )
                await MainActor.run {
                    isVerifyingForgotCode = false
                    phoneNumber = phone
                    proceedToResetPassword()
                }
            } catch {
                await MainActor.run {
                    isVerifyingForgotCode = false
                    toastPublisher.send(error.localizedDescription)
                }
            }
        }
    }

    func submitNewPassword(phone: String, code: String, newPassword: String, confirmPassword: String) {
        guard !newPassword.isEmpty else {
            toastPublisher.send("请设置新密码"); return
        }
        guard newPassword.count >= 6 else {
            toastPublisher.send("新密码至少 6 位"); return
        }
        guard newPassword.count <= 20 else {
            toastPublisher.send("新密码不能超过 20 位"); return
        }
        guard !confirmPassword.isEmpty else {
            toastPublisher.send("请再次输入新密码"); return
        }
        guard newPassword == confirmPassword else {
            toastPublisher.send("两次输入的密码不一致，请重新输入"); return
        }
        isResettingPassword = true
        Task {
            do {
                try await loginService.resetPassword(phone: phone, code: code, newPassword: newPassword)
                await MainActor.run {
                    isResettingPassword = false
                    phoneNumber = phone
                    loginMode = .password
                    formStep = .login
                    toastPublisher.send("密码已重置，请重新登录")
                }
            } catch {
                await MainActor.run {
                    isResettingPassword = false
                    toastPublisher.send(error.localizedDescription)
                }
            }
        }
    }

    func resetPassword(phone: String, code: String, newPassword: String) async throws {
        try await loginService.resetPassword(phone: phone, code: code, newPassword: newPassword)
    }

    // MARK: - Agreement Check

    func isAgreementChecked(_ checked: Bool) -> String? {
        checked ? nil : "请先阅读并同意用户协议、隐私政策与健康管理服务知情同意书"
    }
}
