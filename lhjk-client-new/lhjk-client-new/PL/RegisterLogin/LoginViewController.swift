import UIKit
import SnapKit
import UserNotifications

/// 注册/登录页面
/// 参考 funde-client PRD 用户注册与登录_v1.0.md + LoginView.vue
///
/// 完整流程:
///   隐私弹窗 → 登录页 (验证码/密码/微信)
///   → 通知权限预引导 → /home 或 /onboarding
///
/// 分支流程: 忘记密码、登录过期、账号冻结/注销中
final class LoginViewController: BaseViewController {

    // MARK: - Mode

    private enum LoginMode {
        case sms
        case password
    }

    // MARK: - Constants

    private let horizontalPadding: CGFloat = 24

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.keyboardDismissMode = .onDrag
        return sv
    }()

    private let contentView = UIView()

    // Brand
    private let brandHeader = BrandHeaderView()

    // Privacy prompt (shown before login form)
    private var privacyPromptView: PrivacyPromptView?

    // SMS fields
    private lazy var phoneField = LoginFieldView(
        title: "手机号",
        placeholder: "请输入手机号",
        sfSymbol: "phone"
    )

    private lazy var codeField = LoginFieldView(
        title: "验证码",
        placeholder: "请输入验证码",
        sfSymbol: "shield"
    )

    /// 验证码倒计时按钮
    private lazy var codeButton: VerifyCodeButton = {
        let btn = VerifyCodeButton()
        btn.onRequestCode = { [weak self] in
            self?.handleRequestCode()
        }
        return btn
    }()

    /// 验证码行容器（输入框 + 按钮）
    private lazy var codeRowView: UIStackView = {
        let container = UIView()
        container.addSubview(codeField)
        codeField.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        let stack = UIStackView(arrangedSubviews: [container, codeButton])
        stack.axis = .horizontal
        stack.alignment = .bottom
        stack.spacing = 10
        return stack
    }()

    // Password fields
    private lazy var passwordPhoneField = LoginFieldView(
        title: "手机号",
        placeholder: "请输入手机号",
        sfSymbol: "phone"
    )

    private lazy var passwordField = LoginFieldView(
        title: "密码",
        placeholder: "请输入密码",
        sfSymbol: "lock",
        rightButton: .secureToggle
    )

    // Forgot password link
    private lazy var forgotPasswordButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("忘记密码", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 13)
        btn.setTitleColor(.fdPrimary, for: .normal)
        btn.addTarget(self, action: #selector(showForgotPassword), for: .touchUpInside)
        return btn
    }()

    // Form stack
    private let formStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        return stack
    }()

    // SMS field wrapper
    private let smsFieldsContainer = UIView()

    // Password field wrapper
    private let passwordFieldsContainer = UIView()

    /// SMS form inner stack (phone field + code row)
    private let smsInnerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        return stack
    }()

    /// Password form inner stack
    private let passwordInnerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        return stack
    }()

    // Agreement checkbox
    private let agreementCheckbox = AgreementCheckboxView()

    // Submit button
    private lazy var submitButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("登录 / 注册", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .fdPrimary
        btn.layer.cornerRadius = 18
        btn.layer.shadowColor = UIColor.fdPrimary.cgColor
        btn.layer.shadowOffset = CGSize(width: 0, height: 6)
        btn.layer.shadowRadius = 18
        btn.layer.shadowOpacity = 0.32
        btn.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
        return btn
    }()

    // Mode switch link
    private lazy var modeSwitchButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("使用账号密码登录", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 13)
        btn.setTitleColor(.fdPrimary, for: .normal)
        btn.addTarget(self, action: #selector(toggleMode), for: .touchUpInside)
        return btn
    }()

    // WeChat entry
    private lazy var wechatButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "message.circle.fill")?
            .withTintColor(.fdWechatGreen, renderingMode: .alwaysOriginal)
            .applyingSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)),
            for: .normal)
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 26
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 12
        btn.layer.shadowOpacity = 0.08
        btn.addTarget(self, action: #selector(showWechatSheet), for: .touchUpInside)
        return btn
    }()

    // Overlays
    private var overlayView: UIView?
    private var wechatSheetView: UIView?
    private var captchaVerifyView: CaptchaVerifyView?
    private var notificationGuideView: NotificationGuideView?
    private var phoneBindingView: PhoneBindingView?

    // MARK: - Services

    private let loginService = LoginService.shared

    // MARK: - State

    private var loginMode: LoginMode = .sms
    private var isLoggingIn = false
    private var smsRequestId: String?

    /// 是否需要展示隐私弹窗
    private var needsPrivacyConsent = true

    // MARK: - Session expired banner

    private var sessionExpiredBanner: UIView?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )

        // Check privacy consent first
        checkPrivacyConsent()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Privacy Consent

    private func checkPrivacyConsent() {
        // V1.0 mock: always need consent on first launch
        let localVersion = UserDefaults.standard.integer(forKey: "agreed_privacy_version")

        Task {
            do {
                let info = try await loginService.getPrivacyVersion()
                if info.latestPrivacyVersion > localVersion {
                    await MainActor.run { showPrivacyPrompt(version: info) }
                } else {
                    needsPrivacyConsent = false
                    await MainActor.run { setupUI() }
                }
            } catch {
                // Network error — still show privacy check based on local cache
                if localVersion == 0 {
                    await MainActor.run {
                        showPrivacyPrompt(version: PrivacyVersionInfo(
                            latestPrivacyVersion: 1,
                            userAgreementURL: "",
                            privacyPolicyURL: ""
                        ))
                    }
                } else {
                    needsPrivacyConsent = false
                }
            }
        }
    }

    private func showPrivacyPrompt(version: PrivacyVersionInfo) {
        let prompt = PrivacyPromptView()
        prompt.onAgree = { [weak self] in
            self?.handlePrivacyAgree(version: version.latestPrivacyVersion)
        }
        prompt.onDisagree = { [weak self] in
            // Already handled in PrivacyPromptView UI
        }
        prompt.onRetry = { [weak self] in
            // Return to consent view
        }
        prompt.onExitApp = {
            exit(0)
        }
        prompt.onUserAgreementTap = { [weak self] in
            self?.openURL(version.userAgreementURL, title: "用户协议")
        }
        prompt.onPrivacyPolicyTap = { [weak self] in
            self?.openURL(version.privacyPolicyURL, title: "隐私政策")
        }

        view.addSubview(prompt)
        prompt.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        privacyPromptView = prompt
    }

    private func handlePrivacyAgree(version: Int) {
        Task {
            try? await loginService.agreePrivacy(version: version)
            UserDefaults.standard.set(version, forKey: "agreed_privacy_version")
            await MainActor.run { [weak self] in
                self?.dismissPrivacyPrompt()
                self?.needsPrivacyConsent = false
                self?.setupUI()
            }
        }
    }

    private func dismissPrivacyPrompt() {
        UIView.animate(withDuration: 0.25) {
            self.privacyPromptView?.alpha = 0
        } completion: { _ in
            self.privacyPromptView?.removeFromSuperview()
            self.privacyPromptView = nil
        }
    }

    // MARK: - Setup UI

    override func setupUI() {
        view.backgroundColor = .fdBg

        // ScrollView
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }

        // Brand
        contentView.addSubview(brandHeader)
        brandHeader.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(36)
            make.centerX.equalToSuperview()
        }

        // SMS fields
        smsInnerStack.addArrangedSubview(phoneField)
        smsInnerStack.addArrangedSubview(codeRowView)

        smsFieldsContainer.addSubview(smsInnerStack)
        smsInnerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Password fields
        passwordInnerStack.addArrangedSubview(passwordPhoneField)
        passwordInnerStack.addArrangedSubview(passwordField)

        passwordFieldsContainer.addSubview(passwordInnerStack)
        passwordInnerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Form stack
        contentView.addSubview(formStack)
        formStack.addArrangedSubview(smsFieldsContainer)
        formStack.addArrangedSubview(passwordFieldsContainer)

        formStack.snp.makeConstraints { make in
            make.top.equalTo(brandHeader.snp.bottom).offset(48)
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
        }

        // Forgot password (password mode only)
        contentView.addSubview(forgotPasswordButton)
        forgotPasswordButton.snp.makeConstraints { make in
            make.top.equalTo(formStack.snp.bottom).offset(10)
            make.trailing.equalTo(formStack)
        }
        forgotPasswordButton.isHidden = true

        // Agreement checkbox
        contentView.addSubview(agreementCheckbox)
        agreementCheckbox.snp.makeConstraints { make in
            make.top.equalTo(forgotPasswordButton.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
        }
        agreementCheckbox.onUserAgreementTap = { [weak self] in
            self?.openURL("https://example.com/agreement", title: "用户协议")
        }
        agreementCheckbox.onPrivacyPolicyTap = { [weak self] in
            self?.openURL("https://example.com/privacy", title: "隐私政策")
        }

        // Submit button
        contentView.addSubview(submitButton)
        submitButton.snp.makeConstraints { make in
            make.top.equalTo(agreementCheckbox.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
            make.height.equalTo(52)
        }

        // Mode switch
        contentView.addSubview(modeSwitchButton)
        modeSwitchButton.snp.makeConstraints { make in
            make.top.equalTo(submitButton.snp.bottom).offset(12)
            make.trailing.equalTo(submitButton)
        }

        // WeChat entry — [DEFERRED] 暂不启用
        // contentView.addSubview(wechatButton)
        // wechatButton.snp.makeConstraints { make in
        //     make.top.equalTo(modeSwitchButton.snp.bottom).offset(28)
        //     make.centerX.equalToSuperview()
        //     make.size.equalTo(52)
        //     make.bottom.equalToSuperview().offset(-32)
        // }

        // Bottom anchor — mode switch button anchors to content bottom
        modeSwitchButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-32)
        }

        // WeChat sheet — [DEFERRED] 暂不启用
        // setupWechatSheet()

        // Default mode
        updateModeUI(animated: false)
    }

    // MARK: - WeChat Sheet

    private func setupWechatSheet() {
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        overlay.alpha = 0
        overlay.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissWechatSheet)))
        view.addSubview(overlay)
        overlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.overlayView = overlay

        let sheet = UIView()
        sheet.backgroundColor = .white
        sheet.layer.cornerRadius = 24
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(sheet)

        // Sheet content
        let iconBg = UIView()
        iconBg.backgroundColor = UIColor.fdWechatGreen.withAlphaComponent(0.12)
        iconBg.layer.cornerRadius = 18
        sheet.addSubview(iconBg)

        let icon = UIImageView(image: UIImage(systemName: "message.circle.fill")?
            .withTintColor(.fdWechatGreen, renderingMode: .alwaysOriginal)
            .applyingSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)))
        iconBg.addSubview(icon)

        let title = UILabel()
        title.text = "微信快捷登录"
        title.font = .systemFont(ofSize: 18, weight: .bold)
        title.textColor = .fdText
        title.textAlignment = .center
        sheet.addSubview(title)

        let desc = UILabel()
        desc.text = "将通过微信授权登录富德健康。继续即表示同意《用户协议》与《隐私政策》。"
        desc.font = .systemFont(ofSize: 13)
        desc.textColor = .fdSubtext
        desc.textAlignment = .center
        desc.numberOfLines = 0
        sheet.addSubview(desc)

        let authBtn = UIButton(type: .system)
        authBtn.setTitle("微信登录", for: .normal)
        authBtn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        authBtn.setTitleColor(.white, for: .normal)
        authBtn.backgroundColor = .fdWechatGreen
        authBtn.layer.cornerRadius = 14
        authBtn.addTarget(self, action: #selector(wechatLogin), for: .touchUpInside)
        sheet.addSubview(authBtn)

        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("取消", for: .normal)
        closeBtn.titleLabel?.font = .systemFont(ofSize: 14)
        closeBtn.setTitleColor(.fdSubtext, for: .normal)
        closeBtn.addTarget(self, action: #selector(dismissWechatSheet), for: .touchUpInside)
        sheet.addSubview(closeBtn)

        iconBg.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.centerX.equalToSuperview()
            make.size.equalTo(56)
        }
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        title.snp.makeConstraints { make in
            make.top.equalTo(iconBg.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }
        desc.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
        }
        authBtn.snp.makeConstraints { make in
            make.top.equalTo(desc.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
            make.height.equalTo(48)
        }
        closeBtn.snp.makeConstraints { make in
            make.top.equalTo(authBtn.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-28)
        }

        sheet.layoutIfNeeded()
        let sheetHeight = sheet.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        sheet.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.snp.bottom)
        }
        sheet.transform = CGAffineTransform(translationX: 0, y: sheetHeight)
        self.wechatSheetView = sheet
    }

    // MARK: - Mode Switching

    private func updateModeUI(animated: Bool) {
        let isSMS = loginMode == .sms

        let changes = {
            self.smsFieldsContainer.isHidden = !isSMS
            self.passwordFieldsContainer.isHidden = isSMS
            self.forgotPasswordButton.isHidden = isSMS

            let submitTitle = isSMS ? "登录 / 注册" : "密码登录"
            self.submitButton.setTitle(submitTitle, for: .normal)

            let modeTitle = isSMS ? "使用账号密码登录" : "返回验证码登录"
            self.modeSwitchButton.setTitle(modeTitle, for: .normal)
        }

        if animated {
            UIView.animate(withDuration: 0.25, animations: changes)
        } else {
            changes()
        }
    }

    @objc private func toggleMode() {
        loginMode = (loginMode == .sms) ? .password : .sms

        // Preserve phone number between modes
        if loginMode == .password {
            let currentPhone = getCurrentPhone()
            if !currentPhone.isEmpty {
                passwordPhoneField.textField.text = currentPhone
            }
        } else {
            let pwdPhone = passwordPhoneField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
            if !pwdPhone.isEmpty {
                phoneField.textField.text = pwdPhone
            }
        }

        updateModeUI(animated: true)
    }

    private func getCurrentPhone() -> String {
        return phoneField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
    }

    // MARK: - Verification Code Request

    private func handleRequestCode() {
        guard agreementCheckbox.isChecked else {
            showToast("请先阅读并同意用户协议与隐私政策")
            return
        }

        let phone = getCurrentPhone()
        guard !phone.isEmpty else {
            showToast("请输入手机号")
            return
        }
        guard validatePhone(phone) else { return }

        // Show captcha verification
        showCaptchaVerify { [weak self] token in
            self?.sendCode(phone: phone, captchaToken: token)
        }
    }

    private func showCaptchaVerify(completion: @escaping (String) -> Void) {
        let captcha = CaptchaVerifyView()
        captcha.onVerifySuccess = { [weak self] token in
            self?.dismissCaptcha()
            completion(token)
        }
        captcha.onDismiss = { [weak self] in
            self?.dismissCaptcha()
        }
        captcha.reset()

        view.addSubview(captcha)
        captcha.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        captcha.alpha = 0
        captchaVerifyView = captcha

        UIView.animate(withDuration: 0.25) {
            captcha.alpha = 1
        }
    }

    private func dismissCaptcha() {
        UIView.animate(withDuration: 0.25) {
            self.captchaVerifyView?.alpha = 0
        } completion: { _ in
            self.captchaVerifyView?.removeFromSuperview()
            self.captchaVerifyView = nil
        }
    }

    private func sendCode(phone: String, captchaToken: String) {
        Task {
            do {
                let response = try await loginService.sendVerificationCode(to: phone, captchaToken: captchaToken)
                smsRequestId = response.smsRequestId
                await MainActor.run {
                    codeButton.startCountdown()
                    showToast("验证码已发送")
                }
            } catch {
                await MainActor.run {
                    showToast(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Validation

    private func validatePhone(_ phone: String) -> Bool {
        let pattern = "^1[3-9]\\d{9}$"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              regex.firstMatch(in: phone, range: NSRange(phone.startIndex..., in: phone)) != nil else {
            showToast("请输入正确的手机号")
            return false
        }
        return true
    }

    // MARK: - Submit

    @objc private func handleSubmit() {
        guard !isLoggingIn else { return }

        // Check agreement
        guard agreementCheckbox.isChecked else {
            showToast("请先阅读并同意用户协议与隐私政策")
            return
        }

        if loginMode == .sms {
            submitBySMS()
        } else {
            submitByPassword()
        }
    }

    private func submitBySMS() {
        let phone = getCurrentPhone()
        let code = codeField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        guard !phone.isEmpty else { showToast("请输入手机号"); return }
        guard validatePhone(phone) else { return }
        guard !code.isEmpty else { showToast("请输入验证码"); return }
        guard code.count == 6 else { showToast("请输入 6 位验证码"); return }

        setLoggingIn(true)

        let requestId = smsRequestId ?? ""
        Task {
            do {
                let result = try await loginService.loginByPhone(phone, code: code, smsRequestId: requestId)
                await MainActor.run {
                    setLoggingIn(false)
                    loginService.saveToken(result.accessToken, refreshToken: result.refreshToken)
                    handleLoginSuccess(isNewUser: result.isNewUser)
                }
            } catch {
                await MainActor.run {
                    setLoggingIn(false)
                    showToast(error.localizedDescription)
                }
            }
        }
    }

    private func submitByPassword() {
        let phone = passwordPhoneField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let password = passwordField.textField.text ?? ""

        guard !phone.isEmpty else { showToast("请输入手机号"); return }
        guard validatePhone(phone) else { return }
        guard !password.isEmpty else { showToast("请输入密码"); return }
        guard password.count >= 6 else { showToast("密码至少 6 位"); return }

        setLoggingIn(true)

        Task {
            do {
                let result = try await loginService.loginByPassword(phone, password: password)
                await MainActor.run {
                    setLoggingIn(false)
                    loginService.saveToken(result.accessToken, refreshToken: result.refreshToken)
                    handleLoginSuccess(isNewUser: false)
                }
            } catch {
                await MainActor.run {
                    setLoggingIn(false)
                    showToast(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Login Success

    private func handleLoginSuccess(isNewUser: Bool) {
        // Show notification permission guide
        showNotificationGuide { [weak self] in
            self?.navigateAfterLogin()
        }
    }

    // MARK: - Notification Permission

    private func showNotificationGuide(completion: @escaping () -> Void) {
        let guide = NotificationGuideView()
        guide.onEnable = { [weak self] in
            self?.requestNotificationPermission { _ in
                self?.dismissNotificationGuide()
                completion()
            }
        }
        guide.onSkip = { [weak self] in
            self?.dismissNotificationGuide()
            completion()
        }

        view.addSubview(guide)
        guide.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        guide.alpha = 0
        notificationGuideView = guide

        UIView.animate(withDuration: 0.25) {
            guide.alpha = 1
        }
    }

    private func dismissNotificationGuide() {
        UIView.animate(withDuration: 0.25) {
            self.notificationGuideView?.alpha = 0
        } completion: { _ in
            self.notificationGuideView?.removeFromSuperview()
            self.notificationGuideView = nil
        }
    }

    private func requestNotificationPermission(completion: @escaping (NotificationPermissionStatus) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            let status: NotificationPermissionStatus = granted ? .allowed : .denied
            Task {
                try? await self.loginService.reportNotificationPermission(status: status)
            }
            DispatchQueue.main.async {
                if !granted {
                    self.showToast("已暂不接收通知，可在设置中重新开启")
                }
                completion(status)
            }
        }
    }

    // MARK: - Post-Login Navigation

    private func navigateAfterLogin() {
        // Check onboarding status → home or onboarding
        let onboarded = UserDefaults.standard.bool(forKey: "fd_onboarded")
        dismiss(animated: true) {
            if !onboarded {
                Router.shared.present("/onboarding")
            }
        }
    }

    // MARK: - Forgot Password

    @objc private func showForgotPassword() {
        let forgotVC = ForgotPasswordViewController()
        forgotVC.onResetSuccess = { [weak self] phone in
            self?.passwordPhoneField.textField.text = phone
            self?.loginMode = .password
            self?.updateModeUI(animated: false)
        }
        let nav = UINavigationController(rootViewController: forgotVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    // MARK: - WeChat

    @objc private func showWechatSheet() {
        view.endEditing(true)

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.overlayView?.alpha = 1
            self.wechatSheetView?.transform = .identity
        }
    }

    @objc private func dismissWechatSheet() {
        let sheetHeight = wechatSheetView?.bounds.height ?? 0

        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            self.overlayView?.alpha = 0
            self.wechatSheetView?.transform = CGAffineTransform(translationX: 0, y: sheetHeight)
        }
    }

    @objc private func wechatLogin() {
        dismissWechatSheet()

        setLoggingIn(true)
        let mockAuthCode = "mock_openid_bound"

        Task {
            do {
                let result = try await loginService.wechatAuth(authCode: mockAuthCode)

                await MainActor.run {
                    setLoggingIn(false)

                    switch result.bindStatus {
                    case .bound:
                        // Directly login
                        loginService.saveToken("token_wechat_\(UUID().uuidString.prefix(8))", refreshToken: "refresh_wechat")
                        handleLoginSuccess(isNewUser: false)

                    case .unbound:
                        // Show phone binding
                        guard let tempToken = result.wechatTempToken else { return }
                        showPhoneBinding(wechatToken: tempToken)
                    }
                }
            } catch {
                await MainActor.run {
                    setLoggingIn(false)
                    showToast(error.localizedDescription)
                }
            }
        }
    }

    private func showPhoneBinding(wechatToken: String) {
        let binding = PhoneBindingView(mode: .bind)
        binding.onSubmit = { [weak self] phone, code in
            self?.handleWechatBinding(wechatToken: wechatToken, phone: phone, code: code, confirmRebind: false)
        }
        binding.onDismiss = { [weak self] in
            self?.dismissPhoneBinding()
        }

        view.addSubview(binding)
        binding.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        binding.alpha = 0
        phoneBindingView = binding

        UIView.animate(withDuration: 0.25) {
            binding.alpha = 1
        }
    }

    private func handleWechatBinding(wechatToken: String, phone: String, code: String, confirmRebind: Bool) {
        setLoggingIn(true)

        Task {
            do {
                let result = try await loginService.wechatBindPhone(
                    wechatToken: wechatToken,
                    phone: phone,
                    code: code,
                    confirmRebind: confirmRebind
                )
                await MainActor.run {
                    setLoggingIn(false)
                    dismissPhoneBinding()
                    loginService.saveToken(result.accessToken, refreshToken: result.refreshToken)
                    handleLoginSuccess(isNewUser: false)
                }
            } catch LoginError.phoneBoundOtherWechat {
                await MainActor.run {
                    setLoggingIn(false)
                    // Show rebind confirmation
                    let masked = Self.maskPhoneNumber(phone)
                    showPhoneBindingRebind(wechatToken: wechatToken, maskedPhone: masked, phone: phone)
                }
            } catch {
                await MainActor.run {
                    setLoggingIn(false)
                    showToast(error.localizedDescription)
                }
            }
        }
    }

    private func showPhoneBindingRebind(wechatToken: String, maskedPhone: String, phone: String) {
        dismissPhoneBinding()

        let binding = PhoneBindingView(mode: .rebind(maskedPhone: maskedPhone))
        binding.onSubmit = { [weak self] _, code in
            self?.handleWechatBinding(wechatToken: wechatToken, phone: phone, code: code, confirmRebind: true)
        }
        binding.onDismiss = { [weak self] in
            self?.dismissPhoneBinding()
        }

        view.addSubview(binding)
        binding.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        binding.alpha = 0
        phoneBindingView = binding

        UIView.animate(withDuration: 0.25) {
            binding.alpha = 1
        }
    }

    private func dismissPhoneBinding() {
        UIView.animate(withDuration: 0.25) {
            self.phoneBindingView?.alpha = 0
        } completion: { _ in
            self.phoneBindingView?.removeFromSuperview()
            self.phoneBindingView = nil
        }
    }

    // MARK: - Session Expired Banner

    private func showSessionExpiredBanner() {
        let banner = UIView()
        banner.backgroundColor = .fdWarningSoft

        let label = UILabel()
        label.text = "为保护您的健康数据安全，登录状态已过期，请重新登录"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .fdWarning
        label.numberOfLines = 0
        label.textAlignment = .center
        banner.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16))
        }

        view.addSubview(banner)
        banner.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
        sessionExpiredBanner = banner

        // Adjust brand header top
        brandHeader.snp.remakeConstraints { make in
            make.top.equalTo(banner.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }
    }

    // MARK: - Loading State

    private func setLoggingIn(_ loggingIn: Bool) {
        isLoggingIn = loggingIn
        submitButton.isEnabled = !loggingIn
        submitButton.alpha = loggingIn ? 0.72 : 1.0

        if loggingIn {
            let title = loginMode == .sms ? "登录中…" : "登录中…"
            submitButton.setTitle(title, for: .disabled)
        } else {
            let title = loginMode == .sms ? "登录 / 注册" : "密码登录"
            submitButton.setTitle(title, for: .normal)
        }
    }

    // MARK: - Keyboard

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let kbFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let inset = kbFrame.height
        scrollView.contentInset.bottom = inset
        scrollView.verticalScrollIndicatorInsets.bottom = inset
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }

    // MARK: - URL Opening

    private func openURL(_ urlString: String, title: String) {
        guard !urlString.isEmpty, let url = URL(string: urlString) else {
            showToast("\(title)暂不可用")
            return
        }
        // Present WebView using existing WebViewController
        let webVC = WebViewController(urlString: url.absoluteString, title: title)
        present(UINavigationController(rootViewController: webVC), animated: true)
    }

    // MARK: - Utilities

    /// 手机号脱敏：保留前3后4
    static func maskPhoneNumber(_ phone: String) -> String {
        guard phone.count == 11 else { return phone }
        let start = phone.prefix(3)
        let end = phone.suffix(4)
        return "\(start)****\(end)"
    }

    // MARK: - Toast

    private var toastWindow: UIWindow?

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}
