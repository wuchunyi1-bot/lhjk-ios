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
///   登录页 (验证码/密码/微信) → 通知权限预引导 → /home 或 /onboarding
///
/// 分支流程: 忘记密码、登录过期、账号冻结/注销中
final class LoginViewController: BaseViewController {

    // MARK: - ViewModel

    private let viewModel = LoginViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Constants

    /// iPhone 5 / SE1（min 边 ≤ 320pt）走紧凑布局，其它机型保持原样
    private var usesCompactLoginLayout = false
    private var heroHeightConstraint: Constraint?

    private enum LoginLayoutMetrics {
        static let compactScreenThreshold: CGFloat = 320

        static func isCompactScreen(bounds: CGRect) -> Bool {
            guard bounds.width > 0, bounds.height > 0 else { return false }
            return min(bounds.width, bounds.height) <= compactScreenThreshold
        }

        static func horizontalPadding(compact: Bool) -> CGFloat { compact ? 20 : 24 }
        static func heroHeight(compact: Bool) -> CGFloat { compact ? 172 : 243 }
        static func brandTop(compact: Bool) -> CGFloat { compact ? 52 : 80 }
        static func fieldsTopOffset(compact: Bool) -> CGFloat { compact ? 16 : 251 }
        static func fieldStackSpacing(compact: Bool) -> CGFloat { compact ? 12 : 20 }
        static func forgotStackSpacing(compact: Bool) -> CGFloat { compact ? 12 : 16 }
        static func submitGapBelowFields(compact: Bool) -> CGFloat { compact ? 24 : 52 }
        static func submitHeight(compact: Bool) -> CGFloat { compact ? 48 : 51 }
        static func modeSwitchHeight(compact: Bool) -> CGFloat { compact ? 36 : 44 }
        static func wechatButtonSize(compact: Bool) -> CGFloat { compact ? 44 : 52 }
        static func footerGapBelowModeSwitch(compact: Bool) -> CGFloat { compact ? 6 : 8 }
        static func agreementGapBelowFooter(compact: Bool) -> CGFloat { compact ? 10 : 12 }
        static func contentBottomPadding(compact: Bool) -> CGFloat { compact ? 12 : 12 }
    }

    private var horizontalPadding: CGFloat {
        LoginLayoutMetrics.horizontalPadding(compact: usesCompactLoginLayout)
    }
    /// 双输入框区域底边到登录主按钮顶边的间距（密码模式内含「忘记密码」行）
    private var loginSubmitGapBelowFields: CGFloat {
        LoginLayoutMetrics.submitGapBelowFields(compact: usesCompactLoginLayout)
    }
    /// 登录主按钮底边到「使用账号密码登录」顶边的间距（定值，不随底部区域拉伸）
    private let loginModeSwitchGapBelowSubmit: CGFloat = 0
    private var didBuildLoginUI = false

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.keyboardDismissMode = .interactive
        sv.alwaysBounceVertical = false
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
        btn.titleLabel?.font = .fdLoginMeta
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
        l.font = .fdFont(ofSize: 17, weight: .semibold)
        l.textColor = .fdText
        return l
    }()

    private let forgotDescLabel: UILabel = {
        let l = UILabel()
        l.text = "请输入注册手机号并完成短信验证，验证通过后可重新设置登录密码。"
        l.font = .fdLoginMeta
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
        btn.addTarget(self, action: #selector(handleWechatLoginTap), for: .touchUpInside)
        return btn
    }()

    private let wechatLabel: UILabel = {
        let l = UILabel()
        l.text = "微信登录"
        l.font = .fdLoginMeta
        l.textColor = .fdLoginLabel
        l.textAlignment = .center
        l.isUserInteractionEnabled = true
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

    /// 资源本身已是 375×243 可视区（@2x 750×486），勿再套 Figma 内层 403×290 二次裁切
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

    private let loginFooterStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        return stack
    }()

    private var modeSwitchHeightConstraint: Constraint?

    // Overlays
    private var notificationGuideView: NotificationGuideView?
    private var notificationWaitingForSettingsReturn = false
    private var notificationForegroundObserver: NSObjectProtocol?
    private var phoneBindingView: PhoneBindingView?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)

        // 协议勾选在登录页完成，启动后不再弹出「隐私保护提示」
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
            .combineLatest(viewModel.$isVerifyingForgotCode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] resetting, verifying in
                let loggingIn = (self?.viewModel.isLoggingIn ?? false) || resetting || verifying
                self?.updateSubmitButton(isLoggingIn: loggingIn)
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

        // 微信未绑定手机号
        viewModel.presentWeChatBindPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.showPhoneBinding()
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
        case .notificationGuide:
            dismissPhoneBinding()
            showNotificationGuide()
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
        usesCompactLoginLayout = LoginLayoutMetrics.isCompactScreen(bounds: view.bounds)

        view.backgroundColor = .fdLoginBackground

        view.addSubview(heroContainer)
        heroContainer.clipsToBounds = true
        heroContainer.addSubview(heroImageView)
        heroContainer.addSubview(heroFadeView)
        heroContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            heroHeightConstraint = make.height.equalTo(
                LoginLayoutMetrics.heroHeight(compact: usesCompactLoginLayout)
            ).constraint
        }
        heroImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        heroFadeView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(usesCompactLoginLayout ? 64 : 89)
        }

        if submitGradientLayer.superlayer == nil {
            submitButton.layer.insertSublayer(submitGradientLayer, at: 0)
        }

        loginFooterStack.addArrangedSubview(wechatStack)
        loginFooterStack.addArrangedSubview(sessionExpiredLabel)
        loginFooterStack.setCustomSpacing(
            usesCompactLoginLayout ? 8 : 12,
            after: wechatStack
        )
        wechatButton.snp.makeConstraints {
            $0.size.equalTo(LoginLayoutMetrics.wechatButtonSize(compact: usesCompactLoginLayout))
        }
        wechatLabel.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handleWechatLoginTap))
        )

        if usesCompactLoginLayout {
            setupCompactLoginChrome()
        } else {
            setupStandardLoginChrome()
        }

        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissTap.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissTap)

        configureLoginFieldKeyboards()

        smsInnerStack.spacing = LoginLayoutMetrics.fieldStackSpacing(compact: usesCompactLoginLayout)
        passwordInnerStack.spacing = LoginLayoutMetrics.fieldStackSpacing(compact: usesCompactLoginLayout)
        forgotInnerStack.spacing = LoginLayoutMetrics.forgotStackSpacing(compact: usesCompactLoginLayout)
        resetInnerStack.spacing = LoginLayoutMetrics.forgotStackSpacing(compact: usesCompactLoginLayout)

        contentView.addSubview(brandHeader)
        brandHeader.applyCompactLayout(usesCompactLoginLayout)
        brandHeader.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(
                LoginLayoutMetrics.brandTop(compact: usesCompactLoginLayout)
            )
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
        resetTitle.font = .fdFont(ofSize: 17, weight: .semibold)
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

        contentView.addSubview(smsFieldsContainer)
        contentView.addSubview(passwordFieldsContainer)
        contentView.addSubview(forgotFieldsContainer)
        contentView.addSubview(resetFieldsContainer)

        let fieldsTopOffset = LoginLayoutMetrics.fieldsTopOffset(compact: usesCompactLoginLayout)
        if usesCompactLoginLayout {
            smsFieldsContainer.snp.makeConstraints { make in
                make.top.equalTo(brandHeader.snp.bottom).offset(fieldsTopOffset)
                make.leading.trailing.equalToSuperview().inset(horizontalPadding)
            }
            passwordFieldsContainer.snp.makeConstraints { make in
                make.top.equalTo(brandHeader.snp.bottom).offset(fieldsTopOffset)
                make.leading.trailing.equalToSuperview().inset(horizontalPadding)
            }
            forgotFieldsContainer.snp.makeConstraints { make in
                make.top.equalTo(brandHeader.snp.bottom).offset(fieldsTopOffset)
                make.leading.trailing.equalToSuperview().inset(horizontalPadding)
            }
            resetFieldsContainer.snp.makeConstraints { make in
                make.top.equalTo(brandHeader.snp.bottom).offset(fieldsTopOffset)
                make.leading.trailing.equalToSuperview().inset(horizontalPadding)
            }
        } else {
            smsFieldsContainer.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(fieldsTopOffset)
                make.leading.trailing.equalToSuperview().inset(horizontalPadding)
            }
            passwordFieldsContainer.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(fieldsTopOffset)
                make.leading.trailing.equalToSuperview().inset(horizontalPadding)
            }
            forgotFieldsContainer.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(fieldsTopOffset)
                make.leading.trailing.equalToSuperview().inset(horizontalPadding)
            }
            resetFieldsContainer.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(fieldsTopOffset)
                make.leading.trailing.equalToSuperview().inset(horizontalPadding)
            }
        }

        contentView.addSubview(forgotPasswordButton)
        forgotPasswordButton.snp.makeConstraints { make in
            make.top.equalTo(passwordFieldsContainer.snp.bottom).offset(4)
            make.trailing.equalTo(passwordFieldsContainer)
            make.height.equalTo(32)
        }
        forgotPasswordButton.isHidden = true

        applySessionExpiredIfNeeded()
        updateFormStepUI(animated: false)
    }

    private func setupStandardLoginChrome() {
        view.addSubview(agreementCheckbox)
        agreementCheckbox.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12)
        }
        wireAgreementCheckboxActions()

        view.addSubview(submitButton)
        view.addSubview(modeSwitchButton)
        modeSwitchButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            modeSwitchHeightConstraint = make.height.equalTo(
                LoginLayoutMetrics.modeSwitchHeight(compact: false)
            ).constraint
            make.top.equalTo(submitButton.snp.bottom).offset(loginModeSwitchGapBelowSubmit)
        }

        view.addSubview(loginFooterStack)
        loginFooterStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
            make.bottom.equalTo(agreementCheckbox.snp.top).offset(-12)
        }
        sessionExpiredLabel.snp.makeConstraints { make in
            make.width.equalTo(loginFooterStack.snp.width)
        }

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }
    }

    private func setupCompactLoginChrome() {
        scrollView.alwaysBounceVertical = true

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }

        contentView.addSubview(submitButton)
        contentView.addSubview(modeSwitchButton)
        contentView.addSubview(loginFooterStack)
        contentView.addSubview(agreementCheckbox)

        wireAgreementCheckboxActions()

        modeSwitchButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            modeSwitchHeightConstraint = make.height.equalTo(
                LoginLayoutMetrics.modeSwitchHeight(compact: true)
            ).constraint
            make.top.equalTo(submitButton.snp.bottom).offset(loginModeSwitchGapBelowSubmit)
        }

        loginFooterStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
            make.top.equalTo(modeSwitchButton.snp.bottom).offset(
                LoginLayoutMetrics.footerGapBelowModeSwitch(compact: true)
            )
        }
        sessionExpiredLabel.snp.makeConstraints { make in
            make.width.equalTo(loginFooterStack.snp.width)
        }

        agreementCheckbox.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
            make.top.equalTo(loginFooterStack.snp.bottom).offset(
                LoginLayoutMetrics.agreementGapBelowFooter(compact: true)
            )
        }
    }

    private func wireAgreementCheckboxActions() {
        agreementCheckbox.onUserAgreementTap = { [weak self] in
            self?.openURL("https://example.com/agreement", title: "用户协议")
        }
        agreementCheckbox.onPrivacyPolicyTap = { [weak self] in
            self?.openURL("https://example.com/privacy", title: "隐私政策")
        }
        agreementCheckbox.onConsentTap = { [weak self] in
            self?.openURL("https://example.com/consent", title: "健康管理服务知情同意书")
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        submitGradientLayer.frame = submitButton.bounds
        submitGradientLayer.cornerRadius = submitButton.layer.cornerRadius
    }

    /// 登录过期回跳时展示底部提示（路由参数 `expired=1` 或本地标记）
    private func applySessionExpiredIfNeeded() {
        let expired = UserDefaults.standard.bool(forKey: SessionExpiryCoordinator.sessionExpiredHintKey)
        sessionExpiredLabel.isHidden = !expired
        if expired {
            UserDefaults.standard.set(false, forKey: SessionExpiryCoordinator.sessionExpiredHintKey)
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

        let changes = {
            if self.usesCompactLoginLayout {
                self.applyCompactFormStepLayout()
            } else {
                self.applyStandardFormStepLayout()
            }
        }
        if animated {
            UIView.animate(withDuration: 0.25, animations: changes)
        } else {
            changes()
        }
    }

    private func applyStandardFormStepLayout() {
        let step = viewModel.formStep
        let isSMS = viewModel.loginMode == .sms
        let inLogin = step == .login

        smsFieldsContainer.isHidden = !(inLogin && isSMS)
        passwordFieldsContainer.isHidden = !(inLogin && !isSMS)
        forgotFieldsContainer.isHidden = step != .forgot
        resetFieldsContainer.isHidden = step != .resetPassword

        forgotPasswordButton.isHidden = !(inLogin && !isSMS)
        agreementCheckbox.isHidden = !inLogin
        loginFooterStack.isHidden = !inLogin
        modeSwitchButton.isHidden = !inLogin
        modeSwitchHeightConstraint?.update(offset: inLogin ? LoginLayoutMetrics.modeSwitchHeight(compact: false) : 0)

        scrollView.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.submitButton.snp.top)
        }

        let fieldsBottom: ConstraintItem
        switch step {
        case .login:
            fieldsBottom = isSMS
                ? smsFieldsContainer.snp.bottom
                : passwordFieldsContainer.snp.bottom
        case .forgot:
            fieldsBottom = forgotFieldsContainer.snp.bottom
        case .resetPassword:
            fieldsBottom = resetFieldsContainer.snp.bottom
        }

        contentView.snp.remakeConstraints { make in
            make.top.leading.trailing.width.equalToSuperview()
            if inLogin {
                if isSMS {
                    make.bottom.equalTo(self.smsFieldsContainer.snp.bottom)
                } else {
                    make.bottom.equalTo(self.forgotPasswordButton.snp.bottom)
                }
            } else {
                make.bottom.equalTo(fieldsBottom).offset(20)
            }
        }

        submitButton.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(self.horizontalPadding)
            make.height.equalTo(LoginLayoutMetrics.submitHeight(compact: false))
            switch step {
            case .login:
                make.top.equalTo(fieldsBottom).offset(self.loginSubmitGapBelowFields)
            case .forgot, .resetPassword:
                make.bottom.equalTo(self.view.safeAreaLayoutGuide).offset(-24)
            }
        }

        applyFormStepChrome(step: step, isSMS: isSMS)
    }

    private func applyCompactFormStepLayout() {
        let step = viewModel.formStep
        let isSMS = viewModel.loginMode == .sms
        let inLogin = step == .login

        smsFieldsContainer.isHidden = !(inLogin && isSMS)
        passwordFieldsContainer.isHidden = !(inLogin && !isSMS)
        forgotFieldsContainer.isHidden = step != .forgot
        resetFieldsContainer.isHidden = step != .resetPassword

        forgotPasswordButton.isHidden = !(inLogin && !isSMS)
        agreementCheckbox.isHidden = !inLogin
        loginFooterStack.isHidden = !inLogin
        modeSwitchButton.isHidden = !inLogin
        modeSwitchHeightConstraint?.update(offset: inLogin
            ? LoginLayoutMetrics.modeSwitchHeight(compact: true)
            : 0)

        scrollView.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide)
        }

        let fieldsBottom: ConstraintItem
        switch step {
        case .login:
            fieldsBottom = isSMS
                ? smsFieldsContainer.snp.bottom
                : passwordFieldsContainer.snp.bottom
        case .forgot:
            fieldsBottom = forgotFieldsContainer.snp.bottom
        case .resetPassword:
            fieldsBottom = resetFieldsContainer.snp.bottom
        }

        let submitTopAnchor: ConstraintItem
        if inLogin && !isSMS {
            submitTopAnchor = forgotPasswordButton.snp.bottom
        } else {
            submitTopAnchor = fieldsBottom
        }

        submitButton.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(self.horizontalPadding)
            make.height.equalTo(LoginLayoutMetrics.submitHeight(compact: true))
            make.top.equalTo(submitTopAnchor).offset(self.loginSubmitGapBelowFields)
        }

        if inLogin {
            modeSwitchButton.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.height.equalTo(LoginLayoutMetrics.modeSwitchHeight(compact: true))
                make.top.equalTo(self.submitButton.snp.bottom).offset(self.loginModeSwitchGapBelowSubmit)
            }

            loginFooterStack.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(self.horizontalPadding)
                make.top.equalTo(self.modeSwitchButton.snp.bottom).offset(
                    LoginLayoutMetrics.footerGapBelowModeSwitch(compact: true)
                )
            }

            agreementCheckbox.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(self.horizontalPadding)
                make.top.equalTo(self.loginFooterStack.snp.bottom).offset(
                    LoginLayoutMetrics.agreementGapBelowFooter(compact: true)
                )
            }

            contentView.snp.remakeConstraints { make in
                make.top.leading.trailing.width.equalToSuperview()
                make.bottom.equalTo(self.agreementCheckbox.snp.bottom).offset(
                    LoginLayoutMetrics.contentBottomPadding(compact: true)
                )
            }
        } else {
            modeSwitchButton.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(self.submitButton.snp.bottom)
                make.height.equalTo(0)
            }
            loginFooterStack.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(self.horizontalPadding)
                make.top.equalTo(self.modeSwitchButton.snp.bottom)
                make.height.equalTo(0)
            }
            agreementCheckbox.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(self.horizontalPadding)
                make.top.equalTo(self.loginFooterStack.snp.bottom)
                make.height.equalTo(0)
            }
            contentView.snp.remakeConstraints { make in
                make.top.leading.trailing.width.equalToSuperview()
                make.bottom.equalTo(self.submitButton.snp.bottom).offset(24)
            }
        }

        applyFormStepChrome(step: step, isSMS: isSMS)
    }

    private func applyFormStepChrome(step: LoginFormStep, isSMS: Bool) {
        switch step {
        case .login:
            submitButton.setTitle(isSMS ? "登录/注册" : "密码登录", for: .normal)
            modeSwitchButton.setTitle(
                isSMS ? "使用账号密码登录" : "返回验证码登录",
                for: .normal
            )
            wechatStack.isHidden = false
        case .forgot:
            submitButton.setTitle("下一步", for: .normal)
            wechatStack.isHidden = true
        case .resetPassword:
            submitButton.setTitle("确认重置", for: .normal)
            wechatStack.isHidden = true
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

        viewModel.requestVerificationCode(phone: phone, type: .login)
        codeButton.startCountdown()
    }

    private func handleForgotRequestCode() {
        let phone = forgotPhoneField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !phone.isEmpty else {
            showToast("请输入手机号"); return
        }
        guard viewModel.validatePhone(phone) == nil else {
            showToast("请输入正确的手机号"); return
        }
        viewModel.requestVerificationCode(phone: phone, type: .resetPassword)
        forgotCodeButton.startCountdown()
    }

    // MARK: - Submit

    @objc private func handleSubmit() {
        dismissKeyboard()
        guard !viewModel.isLoggingIn, !viewModel.isResettingPassword, !viewModel.isVerifyingForgotCode else { return }

        switch viewModel.formStep {
        case .forgot:
            let phone = forgotPhoneField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
            let code = forgotCodeField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
            viewModel.submitForgotCode(phone: phone, code: code)
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
            case .wechatLogin:
                self.viewModel.startWeChatLogin()
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
            case .forgot: title = "校验中…"
            default: title = "登录中…"
            }
            submitButton.setTitle(title, for: .disabled)
        } else {
            updateFormStepUI(animated: false)
        }
    }

    // MARK: - Notification Permission

    private func showNotificationGuide() {
        guard notificationGuideView == nil else { return }

        Task {
            let decision = await NotificationPromptService.shared.loginPromptDecision()
            await MainActor.run {
                switch decision {
                case .skipAlreadyAuthorized:
                    NotificationPromptService.shared.registerForRemoteNotificationsIfNeeded()
                    viewModel.completePostLoginFlow()
                case .skipCooldown:
                    viewModel.completePostLoginFlow()
                case .show:
                    presentNotificationGuide()
                }
            }
        }
    }

    private func presentNotificationGuide() {
        guard notificationGuideView == nil else { return }

        let guide = NotificationGuideView()
        guide.onEnable = { [weak self] in
            guard let self else { return }
            Task {
                let authorized = await NotificationPromptService.shared.requestSystemAuthorization()
                await MainActor.run {
                    if authorized {
                        self.finishNotificationGuide(action: .enable)
                    } else {
                        self.notificationWaitingForSettingsReturn = true
                        NotificationPromptService.shared.openSystemSettings()
                    }
                }
            }
        }
        guide.onSkip = { [weak self] in
            self?.finishNotificationGuide(action: .skip)
        }

        view.addSubview(guide)
        guide.snp.makeConstraints { $0.edges.equalToSuperview() }
        guide.alpha = 0
        notificationGuideView = guide
        installNotificationForegroundObserver()
        UIView.animate(withDuration: 0.25) { guide.alpha = 1 }
    }

    private func installNotificationForegroundObserver() {
        guard notificationForegroundObserver == nil else { return }
        notificationForegroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleNotificationGuideAppReturned()
        }
    }

    private func removeNotificationForegroundObserver() {
        if let observer = notificationForegroundObserver {
            NotificationCenter.default.removeObserver(observer)
            notificationForegroundObserver = nil
        }
    }

    private func handleNotificationGuideAppReturned() {
        guard notificationGuideView != nil else { return }
        if notificationWaitingForSettingsReturn {
            notificationWaitingForSettingsReturn = false
            finishNotificationGuide(action: .enable)
        }
    }

    private func finishNotificationGuide(action: NotificationPromptService.PromptAction) {
        removeNotificationForegroundObserver()
        notificationWaitingForSettingsReturn = false

        Task {
            let authorized = await NotificationPromptService.shared.isSystemNotificationAuthorized()
            await MainActor.run {
                viewModel.reportNotificationPromptClosed(
                    action: action,
                    systemAuthorized: authorized
                )
                if authorized {
                    NotificationPromptService.shared.registerForRemoteNotificationsIfNeeded()
                }
                dismissNotificationGuide {
                    self.viewModel.completePostLoginFlow()
                }
            }
        }
    }

    private func dismissNotificationGuide(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25) {
            self.notificationGuideView?.alpha = 0
        } completion: { _ in
            self.notificationGuideView?.removeFromSuperview()
            self.notificationGuideView = nil
            completion?()
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

    @objc private func handleWechatLoginTap() {
        view.endEditing(true)
        guard !viewModel.isLoggingIn else { return }
        guard agreementCheckbox.isChecked else {
            presentAgreementConsent(action: .wechatLogin)
            return
        }
        viewModel.startWeChatLogin()
    }

    private func showPhoneBinding() {
        let binding = PhoneBindingView(mode: .bind)
        binding.onRequestSMSCode = { [weak self] phone in
            guard let self else { return }
            try await self.viewModel.sendWeChatBindVerificationCode(phone: phone)
        }
        binding.onSubmit = { [weak self] phone, code in
            self?.viewModel.submitWeChatBind(phone: phone, smsCode: code)
        }
        binding.onDismiss = { [weak self] in
            self?.viewModel.clearPendingWeChatCode()
            self?.dismissPhoneBinding()
        }

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

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func configureLoginFieldKeyboards() {
        let phoneFields = [phoneField, passwordPhoneField, forgotPhoneField]
        for field in phoneFields {
            field.textField.keyboardType = .phonePad
            field.textField.textContentType = .telephoneNumber
            field.attachDoneToolbarIfNeeded()
        }

        let codeFields = [codeField, forgotCodeField]
        for field in codeFields {
            field.textField.keyboardType = .numberPad
            field.textField.textContentType = .oneTimeCode
            field.attachDoneToolbarIfNeeded()
        }

        passwordField.textField.keyboardType = .default
        passwordField.textField.isSecureTextEntry = true
        passwordField.textField.returnKeyType = .done
        confirmPasswordField.textField.keyboardType = .default
        confirmPasswordField.textField.isSecureTextEntry = true
        confirmPasswordField.textField.returnKeyType = .done
        resetPasswordField.textField.keyboardType = .default
        resetPasswordField.textField.isSecureTextEntry = true
        resetPasswordField.textField.returnKeyType = .next

        phoneField.onReturnKey = { [weak self] in
            self?.codeField.textField.becomeFirstResponder()
            return true
        }
        codeField.onReturnKey = { [weak self] in
            self?.dismissKeyboard()
            return true
        }
        passwordPhoneField.onReturnKey = { [weak self] in
            self?.passwordField.textField.becomeFirstResponder()
            return true
        }
        passwordField.onReturnKey = { [weak self] in
            self?.dismissKeyboard()
            return true
        }
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let kbFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        let kbInView = view.convert(kbFrame, from: nil)
        let overlap = max(0, view.bounds.maxY - kbInView.minY)
        let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        let curveRaw = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt) ?? 0
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.scrollView.contentInset.bottom = overlap
            self.scrollView.verticalScrollIndicatorInsets.bottom = overlap
        } completion: { _ in
            self.scrollFocusedFieldAboveKeyboard(keyboardOverlap: overlap)
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        UIView.animate(withDuration: duration) {
            self.scrollView.contentInset.bottom = 0
            self.scrollView.verticalScrollIndicatorInsets.bottom = 0
        }
    }

    /// 把当前输入框与登录按钮滚到键盘上方可见区
    private func scrollFocusedFieldAboveKeyboard(keyboardOverlap: CGFloat) {
        guard keyboardOverlap > 0 else { return }

        var targetMaxY: CGFloat = 0
        if let field = findFirstResponder(in: contentView) {
            targetMaxY = max(targetMaxY, field.convert(field.bounds, to: scrollView).maxY)
        }
        // 登录主流程时尽量露出主按钮，避免被键盘挡住
        if viewModel.formStep == .login, !submitButton.isHidden, submitButton.superview != nil {
            targetMaxY = max(targetMaxY, submitButton.convert(submitButton.bounds, to: scrollView).maxY)
        }
        guard targetMaxY > 0 else { return }

        let visibleHeight = scrollView.bounds.height - keyboardOverlap
        let padding: CGFloat = 24
        let needed = targetMaxY + padding
        if needed > scrollView.contentOffset.y + visibleHeight {
            let offsetY = needed - visibleHeight
            scrollView.setContentOffset(
                CGPoint(x: 0, y: max(0, offsetY)),
                animated: true
            )
        }
    }

    private func findFirstResponder(in view: UIView) -> UIView? {
        if view.isFirstResponder { return view }
        for sub in view.subviews {
            if let found = findFirstResponder(in: sub) { return found }
        }
        return nil
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
