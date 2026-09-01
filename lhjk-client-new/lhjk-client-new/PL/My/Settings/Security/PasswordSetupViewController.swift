import UIKit
import SnapKit

/// 登录密码设置页 — 验证码步对齐 Figma 4457:12721
final class PasswordSetupViewController: BaseViewController {

    private enum Font {
        static let field = UIFont.fdFont(ofSize: 15, weight: .regular)
        static let action = UIFont.fdFont(ofSize: 17, weight: .medium)
        static let verifyCode = UIFont.fdFont(ofSize: 15, weight: .regular)
    }

    // MARK: - Mode

    enum Mode {
        case loggedIn(phone: String)
        case standalone

        var isLoggedIn: Bool {
            if case .loggedIn = self { return true }
            return false
        }
    }

    var mode: Mode = .standalone

    // MARK: - Step

    private enum Step {
        case phone, code, resetPassword
    }

    private var step: Step = .phone {
        didSet { updateStepUI() }
    }

    // MARK: - State

    private var enteredPhone = ""
    private var showPassword = false
    private var showConfirmPassword = false
    private var hasSentCode = false
    private var bottomBarBottomConstraint: Constraint?

    // MARK: - Layout

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let bottomBar = UIView()

    private let legacyContainer = UIView()
    private let codeStepContainer = UIView()
    private let codeStepStack = UIStackView()

    private let passwordCodeCard = PasswordCodeFormCardView()

    private var stepTitleLabel: UILabel!
    private var stepDescLabel: UILabel!

    // Step 1
    private var phoneField: UITextField!
    private let phoneContainer = UIView()

    // Step 2 (Figma)
    private lazy var codeLoginField = LoginFieldView(
        title: "",
        placeholder: "请输入验证码",
        sfSymbol: "shield",
        iconAssetName: "login_code_icon",
        placeholderFont: Font.field,
        placeholderColor: UIColor(hexString: "#A4A4A6"),
        showsIdleBorder: true,
        showsTitle: false
    )

    private lazy var codeButton: VerifyCodeButton = {
        let btn = VerifyCodeButton(style: .inline)
        btn.titleLabel?.font = Font.verifyCode
        btn.onRequestCode = { [weak self] in
            self?.resendCodeTapped()
        }
        return btn
    }()

    // Step 3
    private var newPasswordField: UITextField!
    private var confirmPasswordField: UITextField!
    private var togglePasswordBtn: UIButton!
    private var toggleConfirmPasswordBtn: UIButton!
    private let passwordContainer = UIView()

    private let actionBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.titleLabel?.font = Font.action
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .fdPrimary
        btn.layer.cornerRadius = 25.5
        return btn
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: .fdNavBack,
            style: .plain,
            target: self,
            action: #selector(handleBack)
        )

        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissTap.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissTap)

        if case .loggedIn(let phone) = mode {
            enteredPhone = phone
            step = .code
        }

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
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        switch step {
        case .phone:
            phoneField.becomeFirstResponder()
        case .code:
            codeLoginField.textField.becomeFirstResponder()
        case .resetPassword:
            newPasswordField.becomeFirstResponder()
        }
    }

    override func setupUI() {
        view.backgroundColor = .fdBg

        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            bottomBarBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24).constraint
        }

        actionBtn.addTarget(self, action: #selector(actionBtnTapped), for: .touchUpInside)
        bottomBar.addSubview(actionBtn)
        actionBtn.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(51)
        }

        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomBar.snp.top)
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }

        let rootStack = UIStackView(arrangedSubviews: [codeStepContainer, legacyContainer])
        rootStack.axis = .vertical
        contentView.addSubview(rootStack)
        rootStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-12)
        }

        setupLegacySteps()
        setupCodeStep()
        updateStepUI()
    }

    // MARK: - Legacy steps (phone / password)

    private func setupLegacySteps() {
        stepTitleLabel = UILabel()
        stepTitleLabel.font = .fdMyH2
        stepTitleLabel.textColor = .fdText
        legacyContainer.addSubview(stepTitleLabel)
        stepTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        stepDescLabel = UILabel()
        stepDescLabel.font = .fdMyBody
        stepDescLabel.textColor = .fdSubtext
        stepDescLabel.numberOfLines = 0
        legacyContainer.addSubview(stepDescLabel)
        stepDescLabel.snp.makeConstraints { make in
            make.top.equalTo(stepTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        setupPhoneStep()
        setupPasswordStep()
    }

    private func setupPhoneStep() {
        legacyContainer.addSubview(phoneContainer)

        let fieldLabel = UILabel()
        fieldLabel.text = "手机号"
        fieldLabel.font = .fdFont(ofSize: 15, weight: .semibold)
        fieldLabel.textColor = .fdSubtext
        phoneContainer.addSubview(fieldLabel)
        fieldLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        phoneField = makeTextField(placeholder: "请输入手机号", keyboardType: .phonePad)
        phoneContainer.addSubview(phoneField)
        phoneField.snp.makeConstraints { make in
            make.top.equalTo(fieldLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(52)
        }

        phoneContainer.snp.makeConstraints { make in
            make.top.equalTo(stepDescLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    private func setupPasswordStep() {
        legacyContainer.addSubview(passwordContainer)

        let newPwdLabel = UILabel()
        newPwdLabel.text = "新密码"
        newPwdLabel.font = .fdFont(ofSize: 15, weight: .semibold)
        newPwdLabel.textColor = .fdSubtext
        passwordContainer.addSubview(newPwdLabel)
        newPwdLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        let newPwdShell = makePasswordShell()
        passwordContainer.addSubview(newPwdShell)
        newPwdShell.snp.makeConstraints { make in
            make.top.equalTo(newPwdLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(52)
        }

        let lockIcon1 = UIImageView(image: UIImage(systemName: "lock"))
        lockIcon1.tintColor = .fdMuted
        lockIcon1.contentMode = .scaleAspectFit
        newPwdShell.addSubview(lockIcon1)
        lockIcon1.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }

        newPasswordField = UITextField()
        newPasswordField.placeholder = "请设置新密码"
        newPasswordField.isSecureTextEntry = true
        newPasswordField.font = .fdFont(ofSize: 18)
        newPasswordField.textColor = .fdText
        newPwdShell.addSubview(newPasswordField)

        togglePasswordBtn = UIButton(type: .system)
        togglePasswordBtn.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        togglePasswordBtn.tintColor = .fdMuted
        togglePasswordBtn.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        newPwdShell.addSubview(togglePasswordBtn)
        togglePasswordBtn.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
        }

        newPasswordField.snp.makeConstraints { make in
            make.leading.equalTo(lockIcon1.snp.trailing).offset(10)
            make.trailing.equalTo(togglePasswordBtn.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }

        let confirmPwdLabel = UILabel()
        confirmPwdLabel.text = "确认新密码"
        confirmPwdLabel.font = .fdFont(ofSize: 15, weight: .semibold)
        confirmPwdLabel.textColor = .fdSubtext
        passwordContainer.addSubview(confirmPwdLabel)
        confirmPwdLabel.snp.makeConstraints { make in
            make.top.equalTo(newPwdShell.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview()
        }

        let confirmPwdShell = makePasswordShell()
        passwordContainer.addSubview(confirmPwdShell)
        confirmPwdShell.snp.makeConstraints { make in
            make.top.equalTo(confirmPwdLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(52)
        }

        let lockIcon2 = UIImageView(image: UIImage(systemName: "lock"))
        lockIcon2.tintColor = .fdMuted
        lockIcon2.contentMode = .scaleAspectFit
        confirmPwdShell.addSubview(lockIcon2)
        lockIcon2.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }

        confirmPasswordField = UITextField()
        confirmPasswordField.placeholder = "请再次输入新密码"
        confirmPasswordField.isSecureTextEntry = true
        confirmPasswordField.font = .fdFont(ofSize: 18)
        confirmPasswordField.textColor = .fdText
        confirmPwdShell.addSubview(confirmPasswordField)

        toggleConfirmPasswordBtn = UIButton(type: .system)
        toggleConfirmPasswordBtn.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        toggleConfirmPasswordBtn.tintColor = .fdMuted
        toggleConfirmPasswordBtn.addTarget(self, action: #selector(toggleConfirmPasswordVisibility), for: .touchUpInside)
        confirmPwdShell.addSubview(toggleConfirmPasswordBtn)
        toggleConfirmPasswordBtn.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
        }

        confirmPasswordField.snp.makeConstraints { make in
            make.leading.equalTo(lockIcon2.snp.trailing).offset(10)
            make.trailing.equalTo(toggleConfirmPasswordBtn.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }

        passwordContainer.snp.makeConstraints { make in
            make.top.equalTo(stepDescLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    // MARK: - Code step (Figma)

    private func setupCodeStep() {
        codeStepStack.axis = .vertical
        codeStepStack.spacing = 12
        codeStepContainer.addSubview(codeStepStack)
        codeStepStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }

        codeStepStack.addArrangedSubview(SecurityHintBannerView.passwordVerification())

        passwordCodeCard.setBodyView(codeLoginField)
        codeStepStack.addArrangedSubview(passwordCodeCard)

        codeLoginField.textField.keyboardType = .numberPad
        codeLoginField.trailingAccessoryView = codeButton
        codeLoginField.attachDoneToolbarIfNeeded()
    }

    // MARK: - Step UI

    private func updateStepUI() {
        codeStepContainer.isHidden = step != .code
        legacyContainer.isHidden = step == .code

        phoneContainer.isHidden = step != .phone
        passwordContainer.isHidden = step != .resetPassword

        switch step {
        case .phone:
            title = "手机验证"
            stepTitleLabel.text = "手机验证"
            stepDescLabel.text = "通过短信验证码确认身份后，可设置新的登录密码。"
            actionBtn.setTitle("获取验证码", for: .normal)
        case .code:
            title = "填写验证码"
            passwordCodeCard.updateDesc(phone: enteredPhone, hasSentCode: hasSentCode)
            actionBtn.setTitle("下一步", for: .normal)
        case .resetPassword:
            title = "设置新密码"
            stepTitleLabel.text = "设置新密码"
            stepDescLabel.text = "建议 6-20 位，可用数字和字母组合。请避免使用生日、手机号后 6 位等容易被猜到的密码。"
            actionBtn.setTitle("完成设置", for: .normal)
        }
    }

    // MARK: - Navigation

    @objc private func handleBack() {
        switch step {
        case .phone:
            navigationController?.popViewController(animated: true)
        case .code:
            if mode.isLoggedIn {
                navigationController?.popViewController(animated: true)
            } else {
                step = .phone
            }
        case .resetPassword:
            step = .code
        }
    }

    // MARK: - Actions

    @objc private func actionBtnTapped() {
        switch step {
        case .phone:
            handleSendCode()
        case .code:
            handleVerifyCode()
        case .resetPassword:
            handleSubmitPassword()
        }
    }

    private func sendCode(for phone: String) {
        hasSentCode = true
        passwordCodeCard.updateDesc(phone: phone, hasSentCode: true)
        codeButton.startCountdown()
        Task {
            do {
                _ = try await LoginService.shared.sendVerificationCode(to: phone, type: .resetPassword)
                await MainActor.run { showToast("验证码已发送") }
            } catch {
                await MainActor.run {
                    showToast("发送失败，请稍后重试")
                    codeButton.stopCountdown()
                    hasSentCode = false
                    passwordCodeCard.updateDesc(phone: phone, hasSentCode: false)
                }
            }
        }
    }

    private func handleSendCode() {
        let phone = phoneField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard validatePhone(phone) else {
            showToast("请输入正确的手机号")
            return
        }
        enteredPhone = phone
        step = .code
        sendCode(for: phone)
    }

    @objc private func resendCodeTapped() {
        guard validatePhone(enteredPhone) else {
            showToast("请输入正确的手机号")
            return
        }
        sendCode(for: enteredPhone)
    }

    private func handleVerifyCode() {
        let phone = enteredPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        let code = codeLoginField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let cleanCode = code.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
        guard validatePhone(phone) else {
            showToast("请输入正确的手机号")
            return
        }
        guard cleanCode.count == 6 else {
            showToast("请输入6位验证码")
            return
        }

        actionBtn.isEnabled = false
        actionBtn.alpha = 0.6

        Task {
            do {
                try await LoginService.shared.checkSmsCode(
                    mobile: phone,
                    checkCode: cleanCode,
                    type: .resetPassword
                )
                await MainActor.run {
                    actionBtn.isEnabled = true
                    actionBtn.alpha = 1.0
                    step = .resetPassword
                }
            } catch {
                await MainActor.run {
                    actionBtn.isEnabled = true
                    actionBtn.alpha = 1.0
                    showToast(error.localizedDescription)
                }
            }
        }
    }

    private func handleSubmitPassword() {
        let newPwd = newPasswordField.text ?? ""
        let confirmPwd = confirmPasswordField.text ?? ""
        let code = codeLoginField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        guard !newPwd.isEmpty else {
            showToast("请设置新密码")
            return
        }
        guard newPwd.count >= 6 else {
            showToast("新密码至少6位")
            return
        }
        guard newPwd.count <= 20 else {
            showToast("新密码不能超过20位")
            return
        }
        guard !confirmPwd.isEmpty else {
            showToast("请再次输入新密码")
            return
        }
        guard newPwd == confirmPwd else {
            showToast("两次输入的密码不一致，请重新输入")
            return
        }

        actionBtn.isEnabled = false
        actionBtn.alpha = 0.6

        Task {
            do {
                try await UserService.shared.resetPasswordByMobile(
                    mobile: enteredPhone, newPwd: newPwd, checkCode: code
                )
                await MainActor.run {
                    UserDefaults.standard.set(true, forKey: "fd_login_password_set")
                    showToast("密码设置成功")
                    Task { await UserManager.shared.refreshUserInfo() }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.actionBtn.isEnabled = true
                    self?.actionBtn.alpha = 1
                    self?.showToast(error.localizedDescription)
                }
            }
        }
    }

    @objc private func togglePasswordVisibility() {
        showPassword.toggle()
        newPasswordField.isSecureTextEntry = !showPassword
        togglePasswordBtn.setImage(UIImage(systemName: showPassword ? "eye" : "eye.slash"), for: .normal)
    }

    @objc private func toggleConfirmPasswordVisibility() {
        showConfirmPassword.toggle()
        confirmPasswordField.isSecureTextEntry = !showConfirmPassword
        toggleConfirmPasswordBtn.setImage(UIImage(systemName: showConfirmPassword ? "eye" : "eye.slash"), for: .normal)
    }

    // MARK: - Helpers

    private func makeTextField(placeholder: String, keyboardType: UIKeyboardType) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.keyboardType = keyboardType
        tf.font = .fdFont(ofSize: 18)
        tf.textColor = .fdText
        tf.layer.cornerRadius = 8
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.fdBorder.cgColor
        tf.backgroundColor = .fdSurface
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 52))
        tf.leftViewMode = .always
        if keyboardType == .phonePad || keyboardType == .numberPad {
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let done = UIBarButtonItem(title: "完成", style: .done, target: self, action: #selector(dismissKeyboard))
            done.tintColor = .fdPrimary
            toolbar.items = [flex, done]
            tf.inputAccessoryView = toolbar
        }
        return tf
    }

    private func makePasswordShell() -> UIView {
        let shell = UIView()
        shell.layer.cornerRadius = 8
        shell.layer.borderWidth = 1
        shell.layer.borderColor = UIColor.fdBorder.cgColor
        shell.backgroundColor = .fdSurface
        return shell
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func validatePhone(_ phone: String) -> Bool {
        phone.range(of: "^1[3-9]\\d{9}$", options: .regularExpression) != nil
    }

    private func showToast(_ message: String) {
        showToastAlert(message, duration: 1.5)
    }

    // MARK: - Keyboard

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let kbFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let kbInView = view.convert(kbFrame, from: nil)
        let overlap = max(0, view.bounds.maxY - kbInView.minY - view.safeAreaInsets.bottom)
        bottomBarBottomConstraint?.update(offset: -(24 + overlap))
        scrollView.contentInset.bottom = overlap
        scrollView.verticalScrollIndicatorInsets.bottom = overlap
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        bottomBarBottomConstraint?.update(offset: -24)
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
}
