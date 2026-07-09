import Foundation
import Combine

/// 登录流程步骤
enum LoginFlowStep {
    case privacyCheck
    case privacyPrompt(PrivacyVersionInfo)
    case loginForm
    case captchaVerify(String)
    case notificationGuide
    case complete
}

/// 登录页 ViewModel — 状态管理、API 调用、表单验证、流程编排
///
/// ViewController 只负责 UI 布局、键盘、弹窗动画、Toast 展示。
final class LoginViewModel: ObservableObject {

    // MARK: - Published State

    @Published var loginMode: LoginMode = .sms
    @Published var isLoggingIn = false
    @Published var needsPrivacyConsent = true
    @Published var phoneNumber = ""
    @Published var flowStep: LoginFlowStep = .privacyCheck

    // MARK: - One-shot Publishers

    let toastPublisher = PassthroughSubject<String, Never>()
    let navigateToHomePublisher = PassthroughSubject<Void, Never>()
    let presentOnboardingPublisher = PassthroughSubject<Void, Never>()

    // MARK: - Dependencies

    private let loginService: LoginService
    private let userManager: UserManager
    private let rongCloudManager: RongCloudManager

    // MARK: - Private State

    private var smsRequestId: String?

    // MARK: - Init

    init(loginService: LoginService = AppContainer.shared.loginService,
         userManager: UserManager = AppContainer.shared.userManager,
         rongCloudManager: RongCloudManager = AppContainer.shared.rongCloudManager) {
        self.loginService = loginService
        self.userManager = userManager
        self.rongCloudManager = rongCloudManager
    }

    // MARK: - Mode Toggle

    func toggleMode() {
        loginMode = loginMode == .sms ? .password : .sms
    }

    // MARK: - Privacy

    func checkPrivacyConsent() {
        let localVersion = UserDefaults.standard.integer(forKey: "agreed_privacy_version")

        Task {
            do {
                let info = try await loginService.getPrivacyVersion()
                await MainActor.run {
                    if info.latestPrivacyVersion > localVersion {
                        flowStep = .privacyPrompt(info)
                    } else {
                        needsPrivacyConsent = false
                        flowStep = .loginForm
                    }
                }
            } catch {
                await MainActor.run {
                    if localVersion == 0 {
                        flowStep = .privacyPrompt(PrivacyVersionInfo(
                            latestPrivacyVersion: 1,
                            userAgreementURL: "",
                            privacyPolicyURL: ""
                        ))
                    } else {
                        needsPrivacyConsent = false
                        flowStep = .loginForm
                    }
                }
            }
        }
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

    func sendVerificationCode(phone: String) {
        phoneNumber = phone
        guard validatePhone(phone) == nil else {
            toastPublisher.send("请输入正确的手机号")
            return
        }
        // captcha 验证 → 由 VC 展示 UI，完成后调用 sendCodeAfterCaptcha
        flowStep = .captchaVerify(phone)
    }

    func sendCodeAfterCaptcha(phone: String, captchaToken: String) {
        Task {
            do {
                let response = try await loginService.sendVerificationCode(to: phone, type: .login)
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

    func wechatAuth(authCode: String) async throws -> WechatAuthResult {
        try await loginService.wechatAuth(authCode: authCode)
    }

    func wechatBindPhone(wechatToken: String, phone: String, code: String,
                         confirmRebind: Bool = false) async throws -> LoginResult {
        try await loginService.wechatBindPhone(
            wechatToken: wechatToken, phone: phone, code: code, confirmRebind: confirmRebind
        )
    }

    // MARK: - Post-Login Orchestration

    private func handleLoginSuccess(phone: String) async {
        // Token 已由 LoginService 根据服务端 expires_in 持久化
        await MainActor.run {
            UserDefaults.standard.set(phone, forKey: "current_user_mobile")
            isLoggingIn = false
            flowStep = .notificationGuide
        }

        // 连接 IM
        rongCloudManager.fetchTokenAndConnect()

        // 检查是否需要 onboarding
        let needOnboarding = await userManager.checkNeedOnboarding()

        await MainActor.run {
            navigateToHomePublisher.send()
            if needOnboarding {
                presentOnboardingPublisher.send()
            }
            flowStep = .complete
        }
    }

    // MARK: - Notification Permission

    func reportNotificationPermission(status: NotificationPermissionStatus) {
        Task {
            try? await loginService.reportNotificationPermission(status: status)
        }
    }

    // MARK: - Forgot Password

    func resetPassword(phone: String, code: String, newPassword: String) async throws {
        try await loginService.resetPassword(phone: phone, code: code, newPassword: newPassword)
    }

    // MARK: - Agreement Check

    func isAgreementChecked(_ checked: Bool) -> String? {
        checked ? nil : "请先阅读并同意用户协议与隐私政策"
    }
}
