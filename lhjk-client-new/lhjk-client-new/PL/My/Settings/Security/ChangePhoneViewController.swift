import UIKit
import SnapKit

/// 修改手机号 — 对齐 Figma 4457:12463
final class ChangePhoneViewController: BaseViewController {

    private enum Font {
        static let field = UIFont.fdFont(ofSize: 15, weight: .regular)
        static let submit = UIFont.fdFont(ofSize: 17, weight: .medium)
        static let agreement = UIFont.fdFont(ofSize: 15, weight: .regular)
        static let verifyCode = UIFont.fdFont(ofSize: 15, weight: .regular)
    }

    // MARK: - State

    private var currentPhone: String = ""
    private var isConsentChecked = false
    private var bottomBarBottomConstraint: Constraint?

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    private let bottomBar = UIView()

    private let formCard = ChangePhoneFormCardView()
    private lazy var agreementView = AgreementCheckboxView(textFont: Font.agreement)
    private let consentErrorBorder = UIView()

    private lazy var phoneField = LoginFieldView(
        title: "手机号",
        placeholder: "请输入手机号",
        sfSymbol: "phone",
        iconAssetName: "login_phone_icon",
        titleFont: Font.field,
        titleColor: UIColor(hexString: "#535D72"),
        placeholderFont: Font.field,
        placeholderColor: UIColor(hexString: "#A4A4A6"),
        showsIdleBorder: true
    )

    private lazy var codeField = LoginFieldView(
        title: "验证码",
        placeholder: "请输入验证码",
        sfSymbol: "shield",
        iconAssetName: "login_code_icon",
        titleFont: Font.field,
        titleColor: UIColor(hexString: "#535D72"),
        placeholderFont: Font.field,
        placeholderColor: UIColor(hexString: "#A4A4A6"),
        showsIdleBorder: true
    )

    private lazy var codeButton: VerifyCodeButton = {
        let btn = VerifyCodeButton(style: .inline)
        btn.titleLabel?.font = Font.verifyCode
        btn.onRequestCode = { [weak self] in
            self?.sendCodeTapped()
        }
        return btn
    }()

    private let submitBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("确认更换", for: .normal)
        btn.titleLabel?.font = Font.submit
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .fdPrimary
        btn.layer.cornerRadius = 25.5
        return btn
    }()

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        currentPhone = resolveCurrentPhone()
        formCard.currentPhoneValueLabel.text = maskPhone(currentPhone)
    }

    override func viewDidLoad() {
        currentPhone = resolveCurrentPhone()
        super.viewDidLoad()
        configureKeyboardDismiss()
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

    override func setupUI() {
        title = "修改手机号"
        view.backgroundColor = .fdBg

        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            bottomBarBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24).constraint
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

        stackView.axis = .vertical
        stackView.spacing = 12
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-12)
        }

        stackView.addArrangedSubview(ChangePhoneHintBannerView())

        formCard.currentPhoneValueLabel.text = maskPhone(currentPhone)
        formCard.setFormFields([phoneField, codeField])
        stackView.addArrangedSubview(formCard)

        codeField.textField.keyboardType = .numberPad
        phoneField.textField.keyboardType = .phonePad
        codeField.trailingAccessoryView = codeButton
        phoneField.attachDoneToolbarIfNeeded()
        codeField.attachDoneToolbarIfNeeded()

        setupBottomBar()
        wireAgreementCallbacks()
    }

    // MARK: - Bottom bar

    private func setupBottomBar() {
        submitBtn.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        bottomBar.addSubview(submitBtn)
        bottomBar.addSubview(consentErrorBorder)

        submitBtn.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(51)
        }

        setupAgreementSection()
        consentErrorBorder.snp.makeConstraints { make in
            make.top.equalTo(submitBtn.snp.bottom).offset(20)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func setupAgreementSection() {
        consentErrorBorder.layer.cornerRadius = 8
        consentErrorBorder.layer.borderWidth = 1
        consentErrorBorder.layer.borderColor = UIColor.clear.cgColor
        consentErrorBorder.backgroundColor = .clear

        consentErrorBorder.addSubview(agreementView)
        agreementView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func wireAgreementCallbacks() {
        agreementView.onUserAgreementTap = { [weak self] in
            self?.showProtocolSheet(
                title: "用户协议",
                content: "（用户协议占位文本）\n\n欢迎使用富德健康服务！\n\n（实际内容以正式版本为准）"
            )
        }
        agreementView.onPrivacyPolicyTap = { [weak self] in
            self?.showProtocolSheet(
                title: "隐私政策",
                content: "（隐私政策占位文本）\n\n富德健康高度重视您的个人信息保护。\n\n（实际内容以正式版本为准）"
            )
        }
        agreementView.onConsentTap = { [weak self] in
            self?.showProtocolSheet(
                title: "健康管理服务知情同意书",
                content: "（健康管理服务知情同意书占位文本）\n\n尊敬的客户：\n\n欢迎您使用富德健康管理服务。\n\n（实际内容以正式版本为准）"
            )
        }
    }

    // MARK: - Actions

    private func sendCodeTapped() {
        let phone = phoneField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard validatePhone(phone) else {
            showToast("请输入正确的手机号")
            return
        }
        codeButton.startCountdown()
        Task {
            do {
                _ = try await LoginService.shared.sendVerificationCode(to: phone, type: .changePhone)
                await MainActor.run {
                    showToast("验证码已发送")
                }
            } catch {
                await MainActor.run {
                    showToast("发送失败，请稍后重试")
                    codeButton.stopCountdown()
                }
            }
        }
    }

    @objc private func submitTapped() {
        let phone = phoneField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let code = codeField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        guard validatePhone(phone) else {
            showToast("请输入正确的手机号")
            return
        }
        guard code.count == 6 else {
            showToast("请输入6位验证码")
            return
        }

        isConsentChecked = agreementView.isChecked
        guard isConsentChecked else {
            triggerConsentError()
            return
        }

        let oldPhone = currentPhone
        submitBtn.isEnabled = false
        submitBtn.alpha = 0.6

        Task {
            do {
                try await UserService.shared.changeMobile(oldMobile: oldPhone, newMobile: phone, checkCode: code)
                await MainActor.run {
                    UserDefaults.standard.set(phone, forKey: "current_user_mobile")
                    showToast("手机号已更换")
                    Task { await UserManager.shared.refreshUserInfo() }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.submitBtn.isEnabled = true
                    self?.submitBtn.alpha = 1
                    self?.showToast(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Helpers

    private func resolveCurrentPhone() -> String {
        let fromUser = UserManager.shared.currentUser?.mobile?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !fromUser.isEmpty { return fromUser }
        return UserDefaults.standard.string(forKey: "current_user_mobile")?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func validatePhone(_ phone: String) -> Bool {
        phone.range(of: "^1[3-9]\\d{9}$", options: .regularExpression) != nil
    }

    private func maskPhone(_ phone: String) -> String {
        let digits = phone.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
        guard digits.count == 11 else { return phone.isEmpty ? "—" : phone }
        return "\(digits.prefix(3))****\(digits.suffix(4))"
    }

    private func triggerConsentError() {
        showToast("请先阅读并同意用户协议、隐私政策与健康管理服务知情同意书")
        consentErrorBorder.layer.borderColor = UIColor(hexString: "#D93025").withAlphaComponent(0.45).cgColor
        consentErrorBorder.backgroundColor = UIColor(hexString: "#D93025").withAlphaComponent(0.06)

        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.values = [0, -5, 5, -5, 0]
        anim.duration = 0.38
        consentErrorBorder.layer.add(anim, forKey: "shake")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            self?.hideConsentError()
        }
    }

    private func hideConsentError() {
        consentErrorBorder.layer.borderColor = UIColor.clear.cgColor
        consentErrorBorder.backgroundColor = .clear
    }

    private func showProtocolSheet(title: String, content: String) {
        let alert = UIAlertController(title: title, message: content, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "关闭", style: .default))
        present(alert, animated: true)
    }

    private func showToast(_ message: String) {
        showToastAlert(message, duration: 1.5)
    }

    // MARK: - Keyboard

    private func configureKeyboardDismiss() {
        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissTap.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissTap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

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
