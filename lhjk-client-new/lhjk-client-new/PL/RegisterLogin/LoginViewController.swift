import UIKit
import SnapKit

/// 注册/登录页面
/// 参考 funde-client: prototype/src/views/auth/LoginView.vue
///
/// 布局结构:
///   BrandHeaderView → Form (SMS / Password dual mode) → WeChat entry → Auth sheet
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

    /// 验证码输入框右侧的 "获取验证码" 按钮
    private lazy var codeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("获取验证码", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        btn.setTitleColor(.fdPrimary, for: .normal)
        btn.setTitleColor(.fdMuted, for: .disabled)
        btn.backgroundColor = .fdPrimarySoft
        btn.layer.cornerRadius = 12
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        btn.addTarget(self, action: #selector(sendCode), for: .touchUpInside)
        return btn
    }()

    /// 验证码行容器（输入框 + 按钮）
    private lazy var codeRowView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [codeFieldContainer, codeButton])
        stack.axis = .horizontal
        stack.alignment = .bottom
        stack.spacing = 10
        return stack
    }()

    /// 验证码输入框容器（用于和 codeButton 并排时 flex 分配）
    private let codeFieldContainer = UIView()

    // Password fields
    private lazy var usernameField = LoginFieldView(
        title: "账号",
        placeholder: "请输入账号",
        sfSymbol: "person.crop.circle"
    )

    private lazy var passwordField = LoginFieldView(
        title: "密码",
        placeholder: "请输入密码",
        sfSymbol: "lock",
        rightButton: .secureToggle
    )

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

    // Agreement hint
    private lazy var agreementLabel: UILabel = {
        let label = UILabel()
        label.text = "登录即代表同意《用户协议》与《隐私政策》"
        label.font = .systemFont(ofSize: 11)
        label.textColor = .fdMuted
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleAgreementTap(_:)))
        label.addGestureRecognizer(tap)
        return label
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

    /// 微信授权弹层背景
    private lazy var overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.alpha = 0
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissWechatSheet)))
        return view
    }()

    /// 微信授权弹层
    private let wechatSheetView = UIView()

    // MARK: - State

    private var loginMode: LoginMode = .sms
    private var countdown = 0
    private var countdownTimer: Timer?
    private var isLoggingIn = false

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
    }

    deinit {
        countdownTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
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

        // Form
        contentView.addSubview(formStack)

        // SMS fields
        smsFieldsContainer.addSubview(phoneField)
        codeFieldContainer.addSubview(codeField)
        smsFieldsContainer.addSubview(codeRowView)

        phoneField.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        codeField.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        codeRowView.snp.makeConstraints { make in
            make.top.equalTo(phoneField.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        codeButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }

        // Password fields
        passwordFieldsContainer.addSubview(usernameField)
        passwordFieldsContainer.addSubview(passwordField)

        usernameField.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        passwordField.snp.makeConstraints { make in
            make.top.equalTo(usernameField.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        formStack.addArrangedSubview(smsFieldsContainer)
        formStack.addArrangedSubview(passwordFieldsContainer)

        formStack.snp.makeConstraints { make in
            make.top.equalTo(brandHeader.snp.bottom).offset(48)
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
        }

        // Submit button
        contentView.addSubview(submitButton)
        submitButton.snp.makeConstraints { make in
            make.top.equalTo(formStack.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
            make.height.equalTo(52)
        }

        // Mode switch
        contentView.addSubview(modeSwitchButton)
        modeSwitchButton.snp.makeConstraints { make in
            make.top.equalTo(submitButton.snp.bottom).offset(12)
            make.trailing.equalTo(submitButton)
        }

        // Agreement
        contentView.addSubview(agreementLabel)
        agreementLabel.snp.makeConstraints { make in
            make.top.equalTo(modeSwitchButton.snp.bottom).offset(14)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
        }

        // WeChat entry
        contentView.addSubview(wechatButton)
        wechatButton.snp.makeConstraints { make in
            make.top.equalTo(agreementLabel.snp.bottom).offset(28)
            make.centerX.equalToSuperview()
            make.size.equalTo(52)
            make.bottom.equalToSuperview().offset(-32)
        }

        // WeChat sheet overlay
        setupWechatSheet()

        // Default mode
        updateModeUI(animated: false)
    }

    /// 底部微信授权弹层
    private func setupWechatSheet() {
        view.addSubview(overlayView)
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        wechatSheetView.backgroundColor = .white
        wechatSheetView.layer.cornerRadius = 24
        wechatSheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        // 默认藏在屏幕底部以下
        wechatSheetView.transform = CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height)
        view.addSubview(wechatSheetView)

        // Sheet content
        let iconBg = UIView()
        iconBg.backgroundColor = UIColor.fdWechatGreen.withAlphaComponent(0.12)
        iconBg.layer.cornerRadius = 18
        wechatSheetView.addSubview(iconBg)

        let icon = UIImageView(image: UIImage(systemName: "message.circle.fill")?
            .withTintColor(.fdWechatGreen, renderingMode: .alwaysOriginal)
            .applyingSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)))
        iconBg.addSubview(icon)

        let title = UILabel()
        title.text = "微信快捷登录"
        title.font = .systemFont(ofSize: 18, weight: .bold)
        title.textColor = .fdText
        title.textAlignment = .center
        wechatSheetView.addSubview(title)

        let desc = UILabel()
        desc.text = "将通过微信授权登录富德健康。继续即表示同意《用户协议》与《隐私政策》。"
        desc.font = .systemFont(ofSize: 13)
        desc.textColor = .fdSubtext
        desc.textAlignment = .center
        desc.numberOfLines = 0
        wechatSheetView.addSubview(desc)

        let authBtn = UIButton(type: .system)
        authBtn.setTitle("微信登录", for: .normal)
        authBtn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        authBtn.setTitleColor(.white, for: .normal)
        authBtn.backgroundColor = .fdWechatGreen
        authBtn.layer.cornerRadius = 14
        authBtn.addTarget(self, action: #selector(wechatLogin), for: .touchUpInside)
        wechatSheetView.addSubview(authBtn)

        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("取消", for: .normal)
        closeBtn.titleLabel?.font = .systemFont(ofSize: 14)
        closeBtn.setTitleColor(.fdSubtext, for: .normal)
        closeBtn.addTarget(self, action: #selector(dismissWechatSheet), for: .touchUpInside)
        wechatSheetView.addSubview(closeBtn)

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

        // 强制布局以获取 sheet 高度
        wechatSheetView.layoutIfNeeded()
        let sheetHeight = wechatSheetView.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        // Pin to bottom & set initial off-screen transform
        wechatSheetView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.snp.bottom)
        }
        // Re-apply transform after constraints
        wechatSheetView.transform = CGAffineTransform(translationX: 0, y: sheetHeight)
    }

    // MARK: - Mode Switching

    private func updateModeUI(animated: Bool) {
        let isSMS = loginMode == .sms

        let changes = {
            self.smsFieldsContainer.isHidden = !isSMS
            self.passwordFieldsContainer.isHidden = isSMS

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
        updateModeUI(animated: true)
    }

    // MARK: - Verification Code

    @objc private func sendCode() {
        let phone = phoneField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard validatePhone(phone) else { return }

        startCountdown()
        showToast("验证码已发送（演示：123456）")
    }

    private func validatePhone(_ phone: String) -> Bool {
        let pattern = "^1[3-9]\\d{9}$"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              regex.firstMatch(in: phone, range: NSRange(phone.startIndex..., in: phone)) != nil else {
            showToast("请输入正确的手机号")
            return false
        }
        return true
    }

    private func startCountdown() {
        countdown = 60
        updateCodeButtonState()
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.countdown -= 1
            if self.countdown <= 0 {
                self.countdownTimer?.invalidate()
                self.countdownTimer = nil
            }
            self.updateCodeButtonState()
        }
    }

    private func updateCodeButtonState() {
        if countdown > 0 {
            codeButton.isEnabled = false
            codeButton.backgroundColor = .fdBg2
            codeButton.setTitle("\(countdown)s 后重试", for: .disabled)
        } else {
            codeButton.isEnabled = true
            codeButton.backgroundColor = .fdPrimarySoft
            codeButton.setTitle("获取验证码", for: .normal)
        }
    }

    // MARK: - Submit

    @objc private func handleSubmit() {
        guard !isLoggingIn else { return }

        if loginMode == .sms {
            submitBySMS()
        } else {
            submitByPassword()
        }
    }

    private func submitBySMS() {
        let phone = phoneField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let code = codeField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        guard !phone.isEmpty else { showToast("请输入手机号"); return }
        guard !code.isEmpty else { showToast("请输入验证码"); return }

        setLoggingIn(true)
        // 演示：模拟登录延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.setLoggingIn(false)
            self?.completeLogin()
        }
    }

    private func submitByPassword() {
        let username = usernameField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let password = passwordField.textField.text ?? ""

        guard !username.isEmpty else { showToast("请输入账号"); return }
        guard !password.isEmpty else { showToast("请输入密码"); return }

        setLoggingIn(true)
        // 演示：模拟登录延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.setLoggingIn(false)
            self?.completeLogin()
        }
    }

    private func setLoggingIn(_ loggingIn: Bool) {
        isLoggingIn = loggingIn
        submitButton.isEnabled = !loggingIn
        submitButton.alpha = loggingIn ? 0.72 : 1.0

        if loggingIn {
            submitButton.setTitle("登录中…", for: .disabled)
        } else {
            let title = loginMode == .sms ? "登录 / 注册" : "密码登录"
            submitButton.setTitle(title, for: .normal)
        }
    }

    private func completeLogin() {
        dismiss(animated: true)
    }

    // MARK: - WeChat

    @objc private func showWechatSheet() {
        view.endEditing(true)

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.overlayView.alpha = 1
            self.wechatSheetView.transform = .identity
        }
    }

    @objc private func dismissWechatSheet() {
        let sheetHeight = wechatSheetView.bounds.height

        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            self.overlayView.alpha = 0
            self.wechatSheetView.transform = CGAffineTransform(translationX: 0, y: sheetHeight)
        }
    }

    @objc private func wechatLogin() {
        // 演示：模拟微信授权
        dismissWechatSheet()
        setLoggingIn(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.setLoggingIn(false)
            self?.completeLogin()
        }
    }

    // MARK: - Agreement

    @objc private func handleAgreementTap(_ gesture: UITapGestureRecognizer) {
        guard let label = gesture.view as? UILabel else { return }
        let point = gesture.location(in: label)

        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: .zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText ?? NSAttributedString(string: label.text ?? ""))

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        textContainer.size = label.bounds.size

        let boundingBox = layoutManager.usedRect(for: textContainer)
        let textOffset = CGPoint(
            x: (label.bounds.width - boundingBox.width) * 0.5 - boundingBox.minX,
            y: (label.bounds.height - boundingBox.height) * 0.5 - boundingBox.minY
        )
        let textPoint = CGPoint(x: point.x - textOffset.x, y: point.y - textOffset.y)
        let glyphIndex = layoutManager.glyphIndex(for: textPoint, in: textContainer)

        if glyphIndex != NSNotFound {
            let charRange = layoutManager.characterRange(forGlyphRange: NSRange(location: glyphIndex, length: 1), actualGlyphRange: nil)
            let text = (label.text ?? "") as NSString

            let userAgreementRange = text.range(of: "《用户协议》")
            let privacyPolicyRange = text.range(of: "《隐私政策》")

            if userAgreementRange.location != NSNotFound,
               NSIntersectionRange(charRange, userAgreementRange).length > 0 {
                showToast("打开《用户协议》")
            } else if privacyPolicyRange.location != NSNotFound,
                      NSIntersectionRange(charRange, privacyPolicyRange).length > 0 {
                showToast("打开《隐私政策》")
            }
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

    // MARK: - Toast

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}
