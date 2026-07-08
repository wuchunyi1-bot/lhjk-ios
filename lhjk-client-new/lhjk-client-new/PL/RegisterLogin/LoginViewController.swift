import UIKit
import SnapKit
import UserNotifications
import Combine

/// 登录模式
enum LoginMode {
    case sms
    case password
}

/// 注册/登录页面
/// 参考 funde-client PRD 用户注册与登录_v1.0.md + LoginView.vue
///
/// 完整流程:
///   隐私弹窗 → 登录页 (验证码/密码/微信)
///   → 通知权限预引导 → /home 或 /onboarding
///
/// 分支流程: 忘记密码、登录过期、账号冻结/注销中
final class LoginViewController: BaseViewController {

    // MARK: - ViewModel

    private let viewModel = LoginViewModel()
    private var cancellables = Set<AnyCancellable>()

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
        title: "手机号", placeholder: "请输入手机号", sfSymbol: "phone"
    )

    private lazy var codeField = LoginFieldView(
        title: "验证码", placeholder: "请输入验证码", sfSymbol: "shield"
    )

    private lazy var codeButton: VerifyCodeButton = {
        let btn = VerifyCodeButton()
        btn.onRequestCode = { [weak self] in
            self?.handleRequestCode()
        }
        return btn
    }()

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
        title: "手机号", placeholder: "请输入手机号", sfSymbol: "phone"
    )

    private lazy var passwordField = LoginFieldView(
        title: "密码", placeholder: "请输入密码", sfSymbol: "lock",
        rightButton: .secureToggle
    )

    // Forgot password link
    private lazy var forgotPasswordButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("忘记密码", for: .normal)
        btn.titleLabel?.font = .fdCaption
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

    private let smsFieldsContainer = UIView()
    private let passwordFieldsContainer = UIView()

    private let smsInnerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        return stack
    }()

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
        btn.titleLabel?.font = .fdBodyBold
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
        btn.titleLabel?.font = .fdCaption
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

    // Session expired banner
    private var sessionExpiredBanner: UIView?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)

        viewModel.checkPrivacyConsent()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - ViewModel Binding

    override func bindViewModel() {
        // 流程步骤 → 展示/隐藏对应弹窗
        viewModel.$flowStep
            .receive(on: DispatchQueue.main)
            .sink { [weak self] step in
                self?.handleFlowStep(step)
            }
            .store(in: &cancellables)

        // 登录中状态 → 按钮禁用
        viewModel.$isLoggingIn
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loggingIn in
                self?.updateSubmitButton(isLoggingIn: loggingIn)
            }
            .store(in: &cancellables)

        // Toast
        viewModel.toastPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                self?.showToast(msg)
            }
            .store(in: &cancellables)

        // 导航到首页
        viewModel.navigateToHomePublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in
                Router.shared.setRoot("/")
            }
            .store(in: &cancellables)

        // 展示 Onboarding
        viewModel.presentOnboardingPublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    Router.shared.present("/onboarding")
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Flow Step Handler

    private func handleFlowStep(_ step: LoginFlowStep) {
        switch step {
        case .privacyCheck:
            break // loading state, nothing to show
        case .privacyPrompt(let info):
            showPrivacyPrompt(version: info)
        case .loginForm:
            dismissPrivacyPrompt()
            setupUI()
        case .captchaVerify:
            // CaptchaVerifyView is shown synchronously in handleRequestCode
            break
        case .notificationGuide:
            showNotificationGuide { [weak self] in
                // Guide dismissed, navigation handled by publishers
            }
        case .complete:
            break
        }
    }

    // MARK: - Privacy Prompt

    private func showPrivacyPrompt(version: PrivacyVersionInfo) {
        guard privacyPromptView == nil else { return }
        let prompt = PrivacyPromptView()
        prompt.onAgree = { [weak self] in
            self?.viewModel.agreePrivacy(version: version.latestPrivacyVersion)
        }
        prompt.onDisagree = { }
        prompt.onRetry = { }
        prompt.onExitApp = { exit(0) }
        prompt.onUserAgreementTap = { [weak self] in
            self?.openURL(version.userAgreementURL, title: "用户协议")
        }
        prompt.onPrivacyPolicyTap = { [weak self] in
            self?.openURL(version.privacyPolicyURL, title: "隐私政策")
        }

        view.addSubview(prompt)
        prompt.snp.makeConstraints { $0.edges.equalToSuperview() }
        privacyPromptView = prompt
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
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

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
        smsInnerStack.snp.makeConstraints { $0.edges.equalToSuperview() }

        // Password fields
        passwordInnerStack.addArrangedSubview(passwordPhoneField)
        passwordInnerStack.addArrangedSubview(passwordField)
        passwordFieldsContainer.addSubview(passwordInnerStack)
        passwordInnerStack.snp.makeConstraints { $0.edges.equalToSuperview() }

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
            make.bottom.equalToSuperview().offset(-32)
        }

        updateModeUI(animated: false)
    }

    // MARK: - Mode Switching

    private func updateModeUI(animated: Bool) {
        let isSMS = viewModel.loginMode == .sms

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
        viewModel.toggleMode()

        // Preserve phone number between modes
        if viewModel.loginMode == .password {
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
        phoneField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
    }

    // MARK: - Verification Code

    private func handleRequestCode() {
        guard agreementCheckbox.isChecked else {
            showToast("请先阅读并同意用户协议与隐私政策")
            return
        }
        let phone = getCurrentPhone()
        guard !phone.isEmpty else {
            showToast("请输入手机号"); return
        }
        guard viewModel.validatePhone(phone) == nil else {
            showToast("请输入正确的手机号"); return
        }

        showCaptchaVerify { [weak self] token in
            self?.viewModel.sendCodeAfterCaptcha(phone: phone, captchaToken: token)
            self?.codeButton.startCountdown()
        }
    }

    private func showCaptchaVerify(completion: @escaping (String) -> Void) {
        let captcha = CaptchaVerifyView()
        captcha.onVerifySuccess = { [weak self] token in
            self?.dismissCaptcha()
            completion(token)
        }
        captcha.onDismiss = { [weak self] in self?.dismissCaptcha() }
        captcha.reset()

        view.addSubview(captcha)
        captcha.snp.makeConstraints { $0.edges.equalToSuperview() }
        captcha.alpha = 0
        captchaVerifyView = captcha
        UIView.animate(withDuration: 0.25) { captcha.alpha = 1 }
    }

    private func dismissCaptcha() {
        UIView.animate(withDuration: 0.25) {
            self.captchaVerifyView?.alpha = 0
        } completion: { _ in
            self.captchaVerifyView?.removeFromSuperview()
            self.captchaVerifyView = nil
        }
    }

    // MARK: - Submit

    @objc private func handleSubmit() {
        guard !viewModel.isLoggingIn else { return }
        guard agreementCheckbox.isChecked else {
            showToast("请先阅读并同意用户协议与隐私政策")
            return
        }

        if viewModel.loginMode == .sms {
            let phone = getCurrentPhone()
            let code = codeField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
            _ = viewModel.loginBySMS(phone: phone, code: code)
        } else {
            let phone = passwordPhoneField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
            let password = passwordField.textField.text ?? ""
            _ = viewModel.loginByPassword(phone: phone, password: password)
        }
    }

    private func updateSubmitButton(isLoggingIn: Bool) {
        submitButton.isEnabled = !isLoggingIn
        submitButton.alpha = isLoggingIn ? 0.72 : 1.0

        if isLoggingIn {
            submitButton.setTitle("登录中…", for: .disabled)
        } else {
            let title = viewModel.loginMode == .sms ? "登录 / 注册" : "密码登录"
            submitButton.setTitle(title, for: .normal)
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
        guide.snp.makeConstraints { $0.edges.equalToSuperview() }
        guide.alpha = 0
        notificationGuideView = guide
        UIView.animate(withDuration: 0.25) { guide.alpha = 1 }
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
            DispatchQueue.main.async {
                if !granted { self.showToast("已暂不接收通知，可在设置中重新开启") }
                completion(status)
            }
        }
    }

    // MARK: - Forgot Password

    @objc private func showForgotPassword() {
        let forgotVC = ForgotPasswordViewController()
        forgotVC.onResetSuccess = { [weak self] phone in
            self?.passwordPhoneField.textField.text = phone
            self?.viewModel.loginMode = .password
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
        viewModel.isLoggingIn = true

        Task {
            do {
                let result = try await viewModel.wechatAuth(authCode: "mock_openid_bound")
                await MainActor.run {
                    viewModel.isLoggingIn = false
                    switch result.bindStatus {
                    case .bound:
                        // Directly navigate — this is a simplified mock flow
                        showNotificationGuide { [weak self] in
                            Router.shared.setRoot("/")
                        }
                    case .unbound:
                        guard let tempToken = result.wechatTempToken else { return }
                        showPhoneBinding(wechatToken: tempToken)
                    }
                }
            } catch {
                await MainActor.run {
                    viewModel.isLoggingIn = false
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
        binding.onDismiss = { [weak self] in self?.dismissPhoneBinding() }

        view.addSubview(binding)
        binding.snp.makeConstraints { $0.edges.equalToSuperview() }
        binding.alpha = 0
        phoneBindingView = binding
        UIView.animate(withDuration: 0.25) { binding.alpha = 1 }
    }

    private func handleWechatBinding(wechatToken: String, phone: String, code: String, confirmRebind: Bool) {
        viewModel.isLoggingIn = true
        Task {
            do {
                let result = try await viewModel.wechatBindPhone(
                    wechatToken: wechatToken, phone: phone, code: code, confirmRebind: confirmRebind
                )
                await MainActor.run {
                    viewModel.isLoggingIn = false
                    dismissPhoneBinding()
                    showNotificationGuide { [weak self] in
                        Router.shared.setRoot("/")
                    }
                }
            } catch LoginError.phoneBoundOtherWechat {
                await MainActor.run {
                    viewModel.isLoggingIn = false
                    showPhoneBindingRebind(wechatToken: wechatToken, maskedPhone: Self.maskPhoneNumber(phone), phone: phone)
                }
            } catch {
                await MainActor.run {
                    viewModel.isLoggingIn = false
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
        binding.onDismiss = { [weak self] in self?.dismissPhoneBinding() }

        view.addSubview(binding)
        binding.snp.makeConstraints { $0.edges.equalToSuperview() }
        binding.alpha = 0
        phoneBindingView = binding
        UIView.animate(withDuration: 0.25) { binding.alpha = 1 }
    }

    private func dismissPhoneBinding() {
        UIView.animate(withDuration: 0.25) {
            self.phoneBindingView?.alpha = 0
        } completion: { _ in
            self.phoneBindingView?.removeFromSuperview()
            self.phoneBindingView = nil
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
        let webVC = WebViewController(urlString: url.absoluteString, title: title)
        present(UINavigationController(rootViewController: webVC), animated: true)
    }

    // MARK: - Utilities

    static func maskPhoneNumber(_ phone: String) -> String {
        guard phone.count == 11 else { return phone }
        let start = phone.prefix(3)
        let end = phone.suffix(4)
        return "\(start)****\(end)"
    }

    // MARK: - Toast

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}
