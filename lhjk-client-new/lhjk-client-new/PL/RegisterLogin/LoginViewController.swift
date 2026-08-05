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
    private var didBuildLoginUI = false

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
        sfSymbol: "phone",
        iconAssetName: "login_phone_icon"
    )

    private lazy var codeField = LoginFieldView(
        title: "验证码",
        placeholder: "请输入验证码",
        sfSymbol: "shield",
        iconAssetName: "login_code_icon"
    )

    private lazy var codeButton: VerifyCodeButton = {
        let btn = VerifyCodeButton()
        btn.onRequestCode = { [weak self] in
            self?.handleRequestCode()
        }
        return btn
    }()

    // Password fields
    private lazy var passwordPhoneField = LoginFieldView(
        title: "手机号",
        placeholder: "请输入手机号",
        sfSymbol: "phone",
        iconAssetName: "login_phone_icon"
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

    private let smsFieldsContainer = UIView()
    private let passwordFieldsContainer = UIView()
    private let forgotFieldsContainer = UIView()
    private let resetFieldsContainer = UIView()

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

    private let forgotInnerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        return stack
    }()

    private let resetInnerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        return stack
    }()

    // Forgot / reset fields
    private lazy var forgotHeadBackButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(.fdNavBack, for: .normal)
        btn.tintColor = .fdText
        btn.addTarget(self, action: #selector(backFromForgotFlow), for: .touchUpInside)
        return btn
    }()

    private let forgotTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "找回密码"
        l.font = .fdBodySemibold
        l.textColor = .fdText
        return l
    }()

    private let forgotDescLabel: UILabel = {
        let l = UILabel()
        l.text = "请输入注册手机号并完成短信验证，验证通过后可重新设置登录密码。"
        l.font = .fdCaption
        l.textColor = .fdSubtext
        l.numberOfLines = 0
        return l
    }()

    private lazy var forgotPhoneField = LoginFieldView(
        title: "手机号",
        placeholder: "请输入手机号",
        sfSymbol: "phone",
        iconAssetName: "login_phone_icon"
    )

    private lazy var forgotCodeField = LoginFieldView(
        title: "验证码",
        placeholder: "请输入验证码",
        sfSymbol: "shield",
        iconAssetName: "login_code_icon"
    )

    private lazy var forgotCodeButton: VerifyCodeButton = {
        let btn = VerifyCodeButton()
        btn.onRequestCode = { [weak self] in self?.handleForgotRequestCode() }
        return btn
    }()

    private lazy var resetPasswordField = LoginFieldView(
        title: "新密码", placeholder: "请设置新密码（6-20 位）", sfSymbol: "lock",
        rightButton: .secureToggle
    )

    private lazy var confirmPasswordField = LoginFieldView(
        title: "确认新密码", placeholder: "请再次输入新密码", sfSymbol: "lock",
        rightButton: .secureToggle
    )

    private var pendingConsentAction: AgreementConsentSheet.PendingAction?

    // Agreement checkbox
    private let agreementCheckbox = AgreementCheckboxView()

    // Submit button（渐变胶囊，在 layoutSubviews 更新图层）
    private lazy var submitButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("登录/注册", for: .normal)
        btn.titleLabel?.font = .fdLoginButton
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 25.5
        btn.layer.borderWidth = 0.5
        btn.layer.borderColor = UIColor.fdLoginButtonEnd.cgColor
        btn.clipsToBounds = true
        btn.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
        return btn
    }()

    private let submitGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.fdLoginButtonStart.cgColor,
            UIColor.fdLoginButtonEnd.cgColor,
        ]
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        return layer
    }()

    // Mode switch link
    private lazy var modeSwitchButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("使用账号密码登录", for: .normal)
        btn.titleLabel?.font = .fdLoginInput
        btn.setTitleColor(.fdPrimary, for: .normal)
        btn.addTarget(self, action: #selector(toggleMode), for: .touchUpInside)
        return btn
    }()

    // WeChat entry
    private lazy var wechatButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "login_wechat"), for: .normal)
        btn.imageView?.contentMode = .scaleAspectFit
        btn.backgroundColor = .fdSurface
        btn.layer.cornerRadius = 26
        btn.addTarget(self, action: #selector(showWechatSheet), for: .touchUpInside)
        return btn
    }()

    private let wechatLabel: UILabel = {
        let l = UILabel()
        l.text = "微信登录"
        l.font = .fdLoginMeta
        l.textColor = .fdLoginLabel
        l.textAlignment = .center
        return l
    }()

    private lazy var wechatStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [wechatButton, wechatLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        return stack
    }()

    // Hero — Figma 3021:586
    private let heroContainer = UIView()

    private let heroImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "login_hero_bg"))
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let heroFadeView = LoginHeroFadeView()

    // Session expired hint（仅登录过期回跳时展示）
    private let sessionExpiredLabel: UILabel = {
        let l = UILabel()
        l.text = "当前登录状态已失效，请重新登录后继续操作"
        l.font = .fdLoginMeta
        l.textColor = .fdMuted
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden = true
        return l
    }()

    // Overlays
    private var overlayView: UIView?
    private var wechatSheetView: UIView?
    private var captchaVerifyView: CaptchaVerifyView?
    private var notificationGuideView: NotificationGuideView?
    private var phoneBindingView: PhoneBindingView?

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
                if msg == "密码已重置，请重新登录" {
                    self?.passwordPhoneField.textField.text = self?.viewModel.phoneNumber
                    self?.updateFormStepUI(animated: true)
                }
            }
            .store(in: &cancellables)

        viewModel.$formStep
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateFormStepUI(animated: true)
            }
            .store(in: &cancellables)

        viewModel.$isResettingPassword
            .receive(on: DispatchQueue.main)
            .sink { [weak self] resetting in
                self?.updateSubmitButton(isLoggingIn: resetting || (self?.viewModel.isLoggingIn ?? false))
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
        prompt.onConsentTap = { [weak self] in
            self?.openURL("https://example.com/consent", title: "健康管理服务知情同意书")
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
        // Base.viewDidLoad 会先调一次；等 flow 进入 loginForm 再建树，并保证只建一次
        guard !didBuildLoginUI else { return }
        guard case .loginForm = viewModel.flowStep else { return }
        didBuildLoginUI = true

        view.backgroundColor = .fdLoginBackground

        view.addSubview(heroContainer)
        heroContainer.clipsToBounds = true
        heroContainer.addSubview(heroImageView)
        heroContainer.addSubview(heroFadeView)
        heroContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(243)
        }
        heroImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview().offset(2)
            make.width.equalTo(403)
            make.height.equalTo(290)
        }
        heroFadeView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(89)
        }

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
            make.height.greaterThanOrEqualTo(830)
        }

        contentView.addSubview(brandHeader)
        brandHeader.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(80)
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
        }

        // SMS：验证码按钮内嵌输入壳
        codeField.trailingAccessoryView = codeButton
        smsInnerStack.addArrangedSubview(phoneField)
        smsInnerStack.addArrangedSubview(codeField)
        smsFieldsContainer.addSubview(smsInnerStack)
        smsInnerStack.snp.makeConstraints { $0.edges.equalToSuperview() }

        passwordInnerStack.addArrangedSubview(passwordPhoneField)
        passwordInnerStack.addArrangedSubview(passwordField)
        passwordFieldsContainer.addSubview(passwordInnerStack)
        passwordInnerStack.snp.makeConstraints { $0.edges.equalToSuperview() }

        let forgotHead = UIStackView(arrangedSubviews: [forgotHeadBackButton, forgotTitleLabel])
        forgotHead.axis = .horizontal
        forgotHead.spacing = 8
        forgotHead.alignment = .center
        forgotHeadBackButton.snp.makeConstraints { $0.size.equalTo(28) }

        forgotCodeField.trailingAccessoryView = forgotCodeButton

        forgotInnerStack.addArrangedSubview(forgotHead)
        forgotInnerStack.addArrangedSubview(forgotDescLabel)
        forgotInnerStack.addArrangedSubview(forgotPhoneField)
        forgotInnerStack.addArrangedSubview(forgotCodeField)
        forgotFieldsContainer.addSubview(forgotInnerStack)
        forgotInnerStack.snp.makeConstraints { $0.edges.equalToSuperview() }

        let resetHeadBack = UIButton(type: .system)
        resetHeadBack.setImage(.fdNavBack, for: .normal)
        resetHeadBack.tintColor = .fdText
        resetHeadBack.addTarget(self, action: #selector(backToForgotStep), for: .touchUpInside)
        resetHeadBack.snp.makeConstraints { $0.size.equalTo(28) }
        let resetTitle = UILabel()
        resetTitle.text = "设置新密码"
        resetTitle.font = .fdBodySemibold
        resetTitle.textColor = .fdText
        let resetHead = UIStackView(arrangedSubviews: [resetHeadBack, resetTitle])
        resetHead.axis = .horizontal
        resetHead.spacing = 8
        resetHead.alignment = .center
        resetInnerStack.addArrangedSubview(resetHead)
        resetInnerStack.addArrangedSubview(resetPasswordField)
        resetInnerStack.addArrangedSubview(confirmPasswordField)
        resetFieldsContainer.addSubview(resetInnerStack)
        resetInnerStack.snp.makeConstraints { $0.edges.equalToSuperview() }

        // 四个流程表单独立占位，避免用普通 UIView 作为 UIStackView arrangedSubview
        // 时无法向 stack 传递 intrinsic height。
        contentView.addSubview(smsFieldsContainer)
        smsFieldsContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(251)
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
        }

        contentView.addSubview(passwordFieldsContainer)
        passwordFieldsContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(251)
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
        }

        contentView.addSubview(forgotFieldsContainer)
        forgotFieldsContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(251)
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
        }

        contentView.addSubview(resetFieldsContainer)
        resetFieldsContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(251)
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
        }

        contentView.addSubview(forgotPasswordButton)
        forgotPasswordButton.snp.makeConstraints { make in
            make.top.equalTo(passwordFieldsContainer.snp.bottom)
            make.trailing.equalTo(passwordFieldsContainer)
            make.height.equalTo(28)
        }
        forgotPasswordButton.isHidden = true

        if submitGradientLayer.superlayer == nil {
            submitButton.layer.insertSublayer(submitGradientLayer, at: 0)
        }
        contentView.addSubview(submitButton)
        submitButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(448)
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
            make.height.equalTo(51)
        }

        contentView.addSubview(modeSwitchButton)
        modeSwitchButton.snp.makeConstraints { make in
            make.top.equalTo(submitButton.snp.bottom)
            make.centerX.equalToSuperview()
            make.height.equalTo(44)
        }

        wechatButton.snp.makeConstraints { $0.size.equalTo(52) }
        contentView.addSubview(wechatStack)
        wechatStack.snp.makeConstraints { make in
            make.top.equalTo(modeSwitchButton.snp.bottom).offset(49)
            make.centerX.equalToSuperview()
        }

        contentView.addSubview(sessionExpiredLabel)
        sessionExpiredLabel.snp.makeConstraints { make in
            make.top.equalTo(wechatStack.snp.bottom).offset(27)
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
        }

        contentView.addSubview(agreementCheckbox)
        agreementCheckbox.snp.makeConstraints { make in
            make.top.equalTo(sessionExpiredLabel.snp.bottom).offset(14)
            make.centerX.equalToSuperview()
            make.width.equalTo(263)
            make.height.equalTo(36)
            make.bottom.lessThanOrEqualToSuperview().offset(-34)
        }
        agreementCheckbox.onUserAgreementTap = { [weak self] in
            self?.openURL("https://example.com/agreement", title: "用户协议")
        }
        agreementCheckbox.onPrivacyPolicyTap = { [weak self] in
            self?.openURL("https://example.com/privacy", title: "隐私政策")
        }
        agreementCheckbox.onConsentTap = { [weak self] in
            self?.openURL("https://example.com/consent", title: "健康管理服务知情同意书")
        }

        applySessionExpiredIfNeeded()
        updateFormStepUI(animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        submitGradientLayer.frame = submitButton.bounds
        submitGradientLayer.cornerRadius = submitButton.layer.cornerRadius
    }

    /// 登录过期回跳时展示底部提示（路由参数 `expired=1` 或本地标记）
    private func applySessionExpiredIfNeeded() {
        let expired = UserDefaults.standard.bool(forKey: "fd_session_expired_hint")
        sessionExpiredLabel.isHidden = !expired
        if expired {
            UserDefaults.standard.set(false, forKey: "fd_session_expired_hint")
        }
    }

    // MARK: - Mode / Form Step

    private func updateModeUI(animated: Bool) {
        updateFormStepUI(animated: animated)
    }

    private func updateFormStepUI(animated: Bool) {
        // BaseViewController 在 UI 构建前就会收到 @Published 的初始值。
        // 此时 submitButton 尚未加入 contentView，不能创建跨层级约束。
        guard didBuildLoginUI, submitButton.superview != nil else { return }

        let step = viewModel.formStep
        let isSMS = viewModel.loginMode == .sms
        let changes = {
            let inLogin = step == .login
            self.smsFieldsContainer.isHidden = !(inLogin && isSMS)
            self.passwordFieldsContainer.isHidden = !(inLogin && !isSMS)
            self.forgotFieldsContainer.isHidden = step != .forgot
            self.resetFieldsContainer.isHidden = step != .resetPassword

            self.forgotPasswordButton.isHidden = !(inLogin && !isSMS)
            self.agreementCheckbox.isHidden = !inLogin
            self.modeSwitchButton.isHidden = !inLogin

            self.submitButton.snp.remakeConstraints { make in
                switch step {
                case .login:
                    make.top.equalToSuperview().offset(448)
                case .forgot:
                    make.top.equalTo(self.forgotFieldsContainer.snp.bottom).offset(20)
                case .resetPassword:
                    make.top.equalTo(self.resetFieldsContainer.snp.bottom).offset(20)
                }
                make.leading.trailing.equalToSuperview().inset(self.horizontalPadding)
                make.height.equalTo(51)
            }

            switch step {
            case .login:
                self.submitButton.setTitle(isSMS ? "登录/注册" : "密码登录", for: .normal)
                self.modeSwitchButton.setTitle(
                    isSMS ? "使用账号密码登录" : "返回验证码登录",
                    for: .normal
                )
                self.wechatStack.isHidden = false
            case .forgot:
                self.submitButton.setTitle("下一步", for: .normal)
                self.wechatStack.isHidden = true
            case .resetPassword:
                self.submitButton.setTitle("确认重置", for: .normal)
                self.wechatStack.isHidden = true
            }
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
        let phone = getCurrentPhone()
        guard !phone.isEmpty else {
            showToast("请输入手机号"); return
        }
        guard viewModel.validatePhone(phone) == nil else {
            showToast("请输入正确的手机号"); return
        }

        showCaptchaVerify { [weak self] token in
            self?.viewModel.sendCodeAfterCaptcha(phone: phone, captchaToken: token, type: .login)
            self?.codeButton.startCountdown()
        }
    }

    private func handleForgotRequestCode() {
        let phone = forgotPhoneField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !phone.isEmpty else {
            showToast("请输入手机号"); return
        }
        guard viewModel.validatePhone(phone) == nil else {
            showToast("请输入正确的手机号"); return
        }
        showCaptchaVerify { [weak self] token in
            self?.viewModel.sendCodeAfterCaptcha(phone: phone, captchaToken: token, type: .resetPassword)
            self?.forgotCodeButton.startCountdown()
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
        guard !viewModel.isLoggingIn, !viewModel.isResettingPassword else { return }

        switch viewModel.formStep {
        case .forgot:
            let phone = forgotPhoneField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
            let code = forgotCodeField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
            _ = viewModel.submitForgotCode(phone: phone, code: code)
        case .resetPassword:
            let phone = forgotPhoneField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
            let code = forgotCodeField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
            let pwd = resetPasswordField.textField.text ?? ""
            let confirm = confirmPasswordField.textField.text ?? ""
            viewModel.submitNewPassword(phone: phone, code: code, newPassword: pwd, confirmPassword: confirm)
        case .login:
            guard agreementCheckbox.isChecked else {
                presentAgreementConsent(
                    action: viewModel.loginMode == .sms ? .smsLogin : .passwordLogin
                )
                return
            }
            performLoginSubmit()
        }
    }

    private func performLoginSubmit() {
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

    private func presentAgreementConsent(action: AgreementConsentSheet.PendingAction) {
        pendingConsentAction = action
        let sheet = AgreementConsentSheet()
        sheet.onOpenUserAgreement = { [weak self] in
            self?.openURL("https://example.com/agreement", title: "用户协议")
        }
        sheet.onOpenPrivacyPolicy = { [weak self] in
            self?.openURL("https://example.com/privacy", title: "隐私政策")
        }
        sheet.onOpenConsent = { [weak self] in
            self?.openURL("https://example.com/consent", title: "健康管理服务知情同意书")
        }
        sheet.onLater = { [weak self] in
            self?.pendingConsentAction = nil
        }
        sheet.onAgreeAndContinue = { [weak self] in
            guard let self else { return }
            self.agreementCheckbox.isChecked = true
            let pending = self.pendingConsentAction
            self.pendingConsentAction = nil
            switch pending {
            case .smsLogin:
                self.viewModel.loginMode = .sms
                self.performLoginSubmit()
            case .passwordLogin:
                self.viewModel.loginMode = .password
                self.performLoginSubmit()
            case .none:
                break
            }
        }
        present(sheet, animated: true)
        showToast("请先阅读并同意用户协议、隐私政策与健康管理服务知情同意书")
    }

    private func updateSubmitButton(isLoggingIn: Bool) {
        submitButton.isEnabled = !isLoggingIn
        submitButton.alpha = isLoggingIn ? 0.72 : 1.0

        if isLoggingIn {
            let title: String
            switch viewModel.formStep {
            case .resetPassword: title = "提交中…"
            default: title = "登录中…"
            }
            submitButton.setTitle(title, for: .disabled)
        } else {
            updateFormStepUI(animated: false)
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
        let phone = passwordPhoneField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        forgotPhoneField.textField.text = phone
        forgotCodeField.textField.text = ""
        resetPasswordField.textField.text = ""
        confirmPasswordField.textField.text = ""
        viewModel.startForgotPassword(prefillPhone: phone)
    }

    @objc private func backFromForgotFlow() {
        viewModel.backToPasswordLogin()
    }

    @objc private func backToForgotStep() {
        viewModel.formStep = .forgot
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

/// Figma 3021:588 — 头图下沿由透明渐变到登录页底色。
private final class LoginHeroFadeView: UIView {

    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        gradientLayer.colors = [
            UIColor.fdLoginBackground.withAlphaComponent(0).cgColor,
            UIColor.fdLoginBackground.cgColor,
        ]
        gradientLayer.locations = [0.05, 0.95]
        layer.addSublayer(gradientLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
