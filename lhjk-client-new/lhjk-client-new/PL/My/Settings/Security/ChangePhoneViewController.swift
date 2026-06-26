import UIKit
import SnapKit

/// 手机号修改页
/// PRD: 02_用户_我的设置_v1.0 §5.3
/// 原型: funde-client prototype/src/views/me/ChangePhoneView.vue
///
/// 布局:
///   当前手机号（脱敏、只读）
///   新手机号输入框（11 位）
///   验证码输入框 + 发送按钮（60s 倒计时）
///   协议勾选（用户协议 / 隐私政策 / 健康管理服务知情同意书）
///   确认更换按钮
final class ChangePhoneViewController: BaseViewController {

    // MARK: - State

    private var currentPhone: String = ""
    private var countdown = 0
    private var timer: Timer?
    private var isConsentChecked = false

    // MARK: - UI

    private let scrollView = UIScrollView()

    private var currentPhoneLabel: UILabel!
    private var newPhoneField: UITextField!
    private var codeField: UITextField!
    private var sendCodeBtn: UIButton!
    private var consentCheckbox: UIButton!
    private var consentErrorBorder: UIView!
    private var submitBtn: UIButton!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        currentPhone = UserDefaults.standard.string(forKey: "current_user_mobile") ?? ""
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        newPhoneField.becomeFirstResponder()
    }

    override func setupUI() {
        title = "更换手机号"
        view.backgroundColor = .fdBg

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let contentView = UIView()
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        // MARK: 说明文字
        let descLabel = UILabel()
        descLabel.text = "更换后，可使用新手机号登录富德健康。"
        descLabel.font = .fdBody
        descLabel.textColor = .fdSubtext
        descLabel.numberOfLines = 0
        contentView.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        // MARK: 当前手机号
        let currentTitleLabel = UILabel()
        currentTitleLabel.text = "当前手机号"
        currentTitleLabel.font = .fdCaption
        currentTitleLabel.textColor = .fdMuted
        contentView.addSubview(currentTitleLabel)
        currentTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(descLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        currentPhoneLabel = UILabel()
        currentPhoneLabel.text = maskPhone(currentPhone)
        currentPhoneLabel.font = .fdFont(ofSize: 32, weight: .bold)
        currentPhoneLabel.textColor = .fdText
        contentView.addSubview(currentPhoneLabel)
        currentPhoneLabel.snp.makeConstraints { make in
            make.top.equalTo(currentTitleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        // MARK: 新手机号输入
        let newPhoneTitleLabel = UILabel()
        newPhoneTitleLabel.text = "新手机号"
        newPhoneTitleLabel.font = .fdFont(ofSize: 14, weight: .semibold)
        newPhoneTitleLabel.textColor = .fdSubtext
        contentView.addSubview(newPhoneTitleLabel)
        newPhoneTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(currentPhoneLabel.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        newPhoneField = UITextField()
        newPhoneField.placeholder = "请输入新手机号"
        newPhoneField.keyboardType = .phonePad
        newPhoneField.font = .fdFont(ofSize: 16)
        newPhoneField.textColor = .fdText
        newPhoneField.layer.cornerRadius = 8
        newPhoneField.layer.borderWidth = 1
        newPhoneField.layer.borderColor = UIColor.fdBorder.cgColor
        newPhoneField.backgroundColor = .fdSurface
        newPhoneField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 52))
        newPhoneField.leftViewMode = .always
        contentView.addSubview(newPhoneField)
        newPhoneField.snp.makeConstraints { make in
            make.top.equalTo(newPhoneTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(52)
        }

        // MARK: 验证码输入 + 发送按钮
        let codeTitleLabel = UILabel()
        codeTitleLabel.text = "验证码"
        codeTitleLabel.font = .fdFont(ofSize: 14, weight: .semibold)
        codeTitleLabel.textColor = .fdSubtext
        contentView.addSubview(codeTitleLabel)
        codeTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(newPhoneField.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        let codeRow = UIView()
        contentView.addSubview(codeRow)
        codeRow.snp.makeConstraints { make in
            make.top.equalTo(codeTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(52)
        }

        codeField = UITextField()
        codeField.placeholder = "请输入验证码"
        codeField.keyboardType = .numberPad
        codeField.font = .fdFont(ofSize: 16)
        codeField.textColor = .fdText
        codeField.layer.cornerRadius = 8
        codeField.layer.borderWidth = 1
        codeField.layer.borderColor = UIColor.fdBorder.cgColor
        codeField.backgroundColor = .fdSurface
        codeField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 52))
        codeField.leftViewMode = .always
        codeRow.addSubview(codeField)

        sendCodeBtn = UIButton(type: .system)
        sendCodeBtn.setTitle("发送验证码", for: .normal)
        sendCodeBtn.titleLabel?.font = .fdFont(ofSize: 13, weight: .bold)
        sendCodeBtn.setTitleColor(.fdPrimary, for: .normal)
        sendCodeBtn.setTitleColor(.fdMuted, for: .disabled)
        sendCodeBtn.layer.cornerRadius = 8
        sendCodeBtn.layer.borderWidth = 1
        sendCodeBtn.layer.borderColor = UIColor.fdBorder.cgColor
        sendCodeBtn.backgroundColor = .fdSurface
        sendCodeBtn.addTarget(self, action: #selector(sendCodeTapped), for: .touchUpInside)
        codeRow.addSubview(sendCodeBtn)

        codeField.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        sendCodeBtn.snp.makeConstraints { make in
            make.leading.equalTo(codeField.snp.trailing).offset(10)
            make.trailing.top.bottom.equalToSuperview()
            make.width.equalTo(110)
        }

        // MARK: 协议勾选
        consentErrorBorder = UIView()
        consentErrorBorder.layer.cornerRadius = 8
        consentErrorBorder.layer.borderWidth = 1
        consentErrorBorder.layer.borderColor = UIColor.clear.cgColor
        consentErrorBorder.backgroundColor = .clear
        contentView.addSubview(consentErrorBorder)
        consentErrorBorder.snp.makeConstraints { make in
            make.top.equalTo(codeRow.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(14)
        }

        let consentRow = UIView()
        consentErrorBorder.addSubview(consentRow)
        consentRow.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        consentCheckbox = UIButton(type: .custom)
        consentCheckbox.setImage(UIImage(systemName: "square"), for: .normal)
        consentCheckbox.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
        consentCheckbox.tintColor = .fdPrimary
        consentCheckbox.addTarget(self, action: #selector(consentToggled), for: .touchUpInside)
        consentRow.addSubview(consentCheckbox)
        consentCheckbox.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.size.equalTo(22)
        }

        let consentText = UILabel()
        consentText.numberOfLines = 0
        consentText.font = .fdFont(ofSize: 12)
        consentText.textColor = .fdSubtext
        let fullText = "我已阅读并同意《用户协议》《隐私政策》与《健康管理服务知情同意书》"
        let attrStr = NSMutableAttributedString(string: fullText, attributes: [
            .font: UIFont.fdFont(ofSize: 12),
            .foregroundColor: UIColor.fdSubtext
        ])
        // Underline protocol links
        for keyword in ["《用户协议》", "《隐私政策》", "《健康管理服务知情同意书》"] {
            if let range = fullText.range(of: keyword) {
                attrStr.addAttributes([
                    .foregroundColor: UIColor.fdPrimary,
                    .font: UIFont.fdFont(ofSize: 12, weight: .semibold)
                ], range: NSRange(range, in: fullText))
            }
        }
        consentText.attributedText = attrStr
        consentText.isUserInteractionEnabled = true
        consentText.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(consentTextTapped(_:))))
        consentRow.addSubview(consentText)
        consentText.snp.makeConstraints { make in
            make.leading.equalTo(consentCheckbox.snp.trailing).offset(8)
            make.trailing.top.bottom.equalToSuperview()
        }

        // MARK: 确认更换按钮
        submitBtn = UIButton(type: .system)
        submitBtn.setTitle("确认更换", for: .normal)
        submitBtn.titleLabel?.font = .fdBodyBold
        submitBtn.setTitleColor(.white, for: .normal)
        submitBtn.backgroundColor = .fdPrimary
        submitBtn.layer.cornerRadius = 27
        submitBtn.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        contentView.addSubview(submitBtn)
        submitBtn.snp.makeConstraints { make in
            make.top.equalTo(consentErrorBorder.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(54)
            make.bottom.equalToSuperview().offset(-32)
        }
    }

    // MARK: - Actions

    @objc private func sendCodeTapped() {
        guard validatePhone(newPhoneField.text ?? "") else {
            showToast("请输入正确的手机号")
            return
        }
        startCountdown()
        let phone = newPhoneField.text ?? ""
        Task {
            do {
                _ = try await LoginService.shared.sendVerificationCode(to: phone, type: .changePhone)
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

    @objc private func consentToggled() {
        isConsentChecked.toggle()
        consentCheckbox.isSelected = isConsentChecked
        hideConsentError()
    }

    @objc private func consentTextTapped(_ gesture: UITapGestureRecognizer) {
        guard let text = (gesture.view as? UILabel)?.text else { return }
        let point = gesture.location(in: gesture.view)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: .zero)
        let textStorage = NSTextStorage(attributedString: NSAttributedString(string: text, attributes: [
            .font: UIFont.fdFont(ofSize: 12)
        ]))
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textContainer.lineFragmentPadding = 0
        textContainer.size = gesture.view?.bounds.size ?? .zero

        let charIndex = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        let protocols: [(String, String, String)] = [
            ("《用户协议》", "用户协议", "（用户协议占位文本）\n\n欢迎使用富德健康服务！\n\n一、服务条款\n1.1 本协议是您与富德健康之间关于使用富德健康服务所订立的协议。\n\n（实际内容以正式版本为准）"),
            ("《隐私政策》", "隐私政策", "（隐私政策占位文本）\n\n富德健康高度重视您的个人信息保护。\n\n一、信息收集\n1.1 我们收集您的手机号码用于账号注册与登录。\n\n（实际内容以正式版本为准）"),
            ("《健康管理服务知情同意书》", "健康管理服务知情同意书", "（健康管理服务知情同意书占位文本）\n\n尊敬的客户：\n\n欢迎您使用富德健康管理服务。\n\n（实际内容以正式版本为准）"),
        ]

        for (keyword, title, content) in protocols {
            if let range = text.range(of: keyword), NSRange(range, in: text).contains(charIndex) {
                showProtocolSheet(title: title, content: content)
                return
            }
        }
    }

    @objc private func submitTapped() {
        let phone = newPhoneField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let code = codeField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        guard validatePhone(phone) else {
            showToast("请输入正确的手机号")
            return
        }
        guard code.count == 6 else {
            showToast("请输入6位验证码")
            return
        }
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
        sendCodeBtn.isEnabled = false
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
        sendCodeBtn.isEnabled = true
        UIView.performWithoutAnimation {
            sendCodeBtn.setTitle("重新获取", for: .normal)
            sendCodeBtn.layoutIfNeeded()
        }
    }

    private func updateCountdownUI() {
        UIView.performWithoutAnimation {
            sendCodeBtn.setTitle("\(countdown)秒后重发", for: .normal)
            sendCodeBtn.layoutIfNeeded()
        }
    }

    private func triggerConsentError() {
        showToast("请先阅读并同意用户协议、隐私政策与健康管理服务知情同意书")
        consentErrorBorder.layer.borderColor = UIColor(hexString: "#D93025").withAlphaComponent(0.45).cgColor
        consentErrorBorder.backgroundColor = UIColor(hexString: "#D93025").withAlphaComponent(0.06)
        // Shake animation
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
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { alert.dismiss(animated: true) }
    }
}
