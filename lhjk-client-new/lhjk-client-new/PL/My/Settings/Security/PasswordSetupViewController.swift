import UIKit
import SnapKit

/// 登录密码设置页
/// PRD: 02_用户_我的设置_v1.0 §5.4
/// 原型: funde-client prototype/src/views/me/settings/SecuritySettingsView.vue
///
/// 两种模式:
///   `.loggedIn(phone:)` — 登录态，手机号只读，Step 2(验证码) → Step 3(密码)
///   `.standalone` — 未登录态，Step 1(手机号) → Step 2(验证码) → Step 3(密码)
///
/// 统一使用 `UserService.resetPasswordByMobile` 提交
final class PasswordSetupViewController: BaseViewController {

    // MARK: - Mode

    enum Mode {
        /// 登录态：手机号预填、只读，跳过 Step 1
        case loggedIn(phone: String)
        /// 未登录态：用户手动输入手机号
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
    private var countdown = 0
    private var timer: Timer?
    private var showPassword = false

    // MARK: - UI Elements

    private var stepTitleLabel: UILabel!
    private var stepDescLabel: UILabel!

    // Step 1 (仅 standalone)
    private var phoneField: UITextField!

    // Step 2
    private var codeField: UITextField!
    private var codeResendBtn: UIButton!
    private var codeDescLabel: UILabel!

    // Step 3
    private var newPasswordField: UITextField!
    private var confirmPasswordField: UITextField!
    private var togglePasswordBtn: UIButton!

    // Common
    private var actionBtn: UIButton!

    // Containers
    private let phoneContainer = UIView()
    private let codeContainer = UIView()
    private let passwordContainer = UIView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(handleBack)
        )

        // 登录态：跳过 Step 1，直接发验证码
        if case .loggedIn(let phone) = mode {
            enteredPhone = phone
            step = .code
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if mode.isLoggedIn {
            // 登录态直接发验证码
            sendCode(for: enteredPhone)
        } else if step == .phone {
            phoneField.becomeFirstResponder()
        }
    }

    override func setupUI() {
        title = ""
        view.backgroundColor = .fdBg

        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let contentView = UIView()
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        // Step title
        stepTitleLabel = UILabel()
        stepTitleLabel.font = .fdH2
        stepTitleLabel.textColor = .fdText
        contentView.addSubview(stepTitleLabel)
        stepTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        stepDescLabel = UILabel()
        stepDescLabel.font = .fdBody
        stepDescLabel.textColor = .fdSubtext
        stepDescLabel.numberOfLines = 0
        contentView.addSubview(stepDescLabel)
        stepDescLabel.snp.makeConstraints { make in
            make.top.equalTo(stepTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        // MARK: - Step 1: Phone (仅 standalone)
        setupPhoneStep(contentView)

        // MARK: - Step 2: Code
        setupCodeStep(contentView)

        // MARK: - Step 3: Password
        setupPasswordStep(contentView)

        // MARK: - Action Button
        actionBtn = UIButton(type: .system)
        actionBtn.titleLabel?.font = .fdBodyBold
        actionBtn.setTitleColor(.white, for: .normal)
        actionBtn.backgroundColor = .fdPrimary
        actionBtn.layer.cornerRadius = 27
        actionBtn.addTarget(self, action: #selector(actionBtnTapped), for: .touchUpInside)
        contentView.addSubview(actionBtn)
        actionBtn.snp.makeConstraints { make in
            make.top.equalTo(passwordContainer.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(54)
            make.bottom.equalToSuperview().offset(-32)
        }

        updateStepUI()
    }

    // MARK: - Step 1 Setup (仅 standalone)

    private func setupPhoneStep(_ parent: UIView) {
        parent.addSubview(phoneContainer)

        let fieldLabel = UILabel()
        fieldLabel.text = "手机号"
        fieldLabel.font = .fdFont(ofSize: 13, weight: .semibold)
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
        }
    }

    // MARK: - Step 2 Setup

    private func setupCodeStep(_ parent: UIView) {
        parent.addSubview(codeContainer)

        codeDescLabel = UILabel()
        codeDescLabel.font = .fdFont(ofSize: 13)
        codeDescLabel.textColor = .fdSubtext
        codeContainer.addSubview(codeDescLabel)
        codeDescLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        let fieldLabel = UILabel()
        fieldLabel.text = "验证码"
        fieldLabel.font = .fdFont(ofSize: 13, weight: .semibold)
        fieldLabel.textColor = .fdSubtext
        codeContainer.addSubview(fieldLabel)
        fieldLabel.snp.makeConstraints { make in
            make.top.equalTo(codeDescLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
        }

        let codeRow = UIView()
        codeContainer.addSubview(codeRow)
        codeRow.snp.makeConstraints { make in
            make.top.equalTo(fieldLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(52)
        }

        codeField = makeTextField(placeholder: "请输入验证码", keyboardType: .numberPad)
        codeRow.addSubview(codeField)

        codeResendBtn = UIButton(type: .system)
        codeResendBtn.setTitle("重新获取", for: .normal)
        codeResendBtn.titleLabel?.font = .fdFont(ofSize: 13, weight: .bold)
        codeResendBtn.setTitleColor(.fdPrimary, for: .normal)
        codeResendBtn.setTitleColor(.fdMuted, for: .disabled)
        codeResendBtn.layer.cornerRadius = 8
        codeResendBtn.layer.borderWidth = 1
        codeResendBtn.layer.borderColor = UIColor.fdBorder.cgColor
        codeResendBtn.backgroundColor = .fdSurface
        codeResendBtn.addTarget(self, action: #selector(resendCodeTapped), for: .touchUpInside)
        codeRow.addSubview(codeResendBtn)

        codeField.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        codeResendBtn.snp.makeConstraints { make in
            make.leading.equalTo(codeField.snp.trailing).offset(10)
            make.trailing.top.bottom.equalToSuperview()
            make.width.equalTo(110)
        }

        codeContainer.snp.makeConstraints { make in
            make.top.equalTo(stepDescLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }
    }

    // MARK: - Step 3 Setup

    private func setupPasswordStep(_ parent: UIView) {
        parent.addSubview(passwordContainer)

        let newPwdLabel = UILabel()
        newPwdLabel.text = "新密码"
        newPwdLabel.font = .fdFont(ofSize: 13, weight: .semibold)
        newPwdLabel.textColor = .fdSubtext
        passwordContainer.addSubview(newPwdLabel)
        newPwdLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        let newPwdShell = UIView()
        newPwdShell.layer.cornerRadius = 8
        newPwdShell.layer.borderWidth = 1
        newPwdShell.layer.borderColor = UIColor.fdBorder.cgColor
        newPwdShell.backgroundColor = .fdSurface
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
        newPasswordField.font = .fdFont(ofSize: 16)
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
        confirmPwdLabel.font = .fdFont(ofSize: 13, weight: .semibold)
        confirmPwdLabel.textColor = .fdSubtext
        passwordContainer.addSubview(confirmPwdLabel)
        confirmPwdLabel.snp.makeConstraints { make in
            make.top.equalTo(newPwdShell.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview()
        }

        let confirmPwdShell = UIView()
        confirmPwdShell.layer.cornerRadius = 8
        confirmPwdShell.layer.borderWidth = 1
        confirmPwdShell.layer.borderColor = UIColor.fdBorder.cgColor
        confirmPwdShell.backgroundColor = .fdSurface
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
        confirmPasswordField.font = .fdFont(ofSize: 16)
        confirmPasswordField.textColor = .fdText
        confirmPwdShell.addSubview(confirmPasswordField)
        confirmPasswordField.snp.makeConstraints { make in
            make.leading.equalTo(lockIcon2.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
        }

        passwordContainer.snp.makeConstraints { make in
            make.top.equalTo(stepDescLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }
    }

    // MARK: - Step UI Update

    private func updateStepUI() {
        phoneContainer.isHidden = step != .phone
        codeContainer.isHidden = step != .code
        passwordContainer.isHidden = step != .resetPassword

        switch step {
        case .phone:
            title = "手机验证"
            stepTitleLabel.text = "手机验证"
            stepDescLabel.text = "通过短信验证码确认身份后，可设置新的登录密码。"
            actionBtn.setTitle("获取验证码", for: .normal)
            actionBtn.isHidden = false
        case .code:
            title = "填写验证码"
            stepTitleLabel.text = "填写验证码"
            codeDescLabel.text = "验证码已发送至 \(maskPhone(enteredPhone))"
            actionBtn.setTitle("下一步", for: .normal)
            actionBtn.isHidden = false
        case .resetPassword:
            title = "设置新密码"
            stepTitleLabel.text = "设置新密码"
            stepDescLabel.text = "建议 6-20 位，可用数字和字母组合。请避免使用生日、手机号后 6 位等容易被猜到的密码。"
            actionBtn.setTitle("完成设置", for: .normal)
            actionBtn.isHidden = false
        }
    }

    // MARK: - Navigation

    @objc private func handleBack() {
        switch step {
        case .phone:
            navigationController?.popViewController(animated: true)
        case .code:
            if mode.isLoggedIn {
                // 登录态没有 Step 1，直接返回
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

    // MARK: - Send Code

    private func sendCode(for phone: String) {
        startCountdown()
        Task {
            do {
                _ = try await LoginService.shared.sendVerificationCode(to: phone, type: .resetPassword)
                await MainActor.run {
                    showToast("验证码已发送")
                }
            } catch {
                await MainActor.run {
                    showToast("发送失败，请稍后重试")
                    stopCountdown()
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
        sendCode(for: phone)
        step = .code
    }

    private func handleVerifyCode() {
        let code = codeField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let cleanCode = code.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
        guard cleanCode.count == 6 else {
            showToast("请输入6位验证码")
            return
        }
        step = .resetPassword
    }

    private func handleSubmitPassword() {
        let newPwd = newPasswordField.text ?? ""
        let confirmPwd = confirmPasswordField.text ?? ""
        let code = codeField.text?.trimmingCharacters(in: .whitespaces) ?? ""

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

    @objc private func resendCodeTapped() {
        stopCountdown()
        sendCode(for: enteredPhone)
    }

    @objc private func togglePasswordVisibility() {
        showPassword.toggle()
        newPasswordField.isSecureTextEntry = !showPassword
        confirmPasswordField.isSecureTextEntry = !showPassword
        let imageName = showPassword ? "eye" : "eye.slash"
        togglePasswordBtn.setImage(UIImage(systemName: imageName), for: .normal)
    }

    // MARK: - Helpers

    private func makeTextField(placeholder: String, keyboardType: UIKeyboardType) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.keyboardType = keyboardType
        tf.font = .fdFont(ofSize: 16)
        tf.textColor = .fdText
        tf.layer.cornerRadius = 8
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.fdBorder.cgColor
        tf.backgroundColor = .fdSurface
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 52))
        tf.leftViewMode = .always
        return tf
    }

    private func validatePhone(_ phone: String) -> Bool {
        let pattern = "^1[3-9]\\d{9}$"
        return phone.range(of: pattern, options: .regularExpression) != nil
    }

    private func maskPhone(_ phone: String) -> String {
        let digits = phone.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
        guard digits.count == 11 else { return phone }
        return "\(digits.prefix(3))****\(digits.suffix(4))"
    }

    private func startCountdown() {
        countdown = 60
        codeResendBtn.isEnabled = false
        updateCountdownUI()
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            countdown -= 1
            if countdown <= 0 {
                self.stopCountdown()
            } else {
                self.updateCountdownUI()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopCountdown() {
        timer?.invalidate()
        timer = nil
        countdown = 0
        codeResendBtn.isEnabled = true
        UIView.performWithoutAnimation {
            codeResendBtn.setTitle("重新获取", for: .normal)
            codeResendBtn.layoutIfNeeded()
        }
    }

    private func updateCountdownUI() {
        UIView.performWithoutAnimation {
            codeResendBtn.setTitle("\(countdown)秒后重发", for: .normal)
            codeResendBtn.layoutIfNeeded()
        }
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { alert.dismiss(animated: true) }
    }
}
