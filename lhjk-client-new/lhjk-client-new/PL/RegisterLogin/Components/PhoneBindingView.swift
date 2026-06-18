import UIKit
import SnapKit

/// 微信绑定手机号弹层
/// 参考 funde-client PRD 3.6: 微信授权成功后未绑定手机号时展示
///
/// 支持手机号验证码绑定，以及换绑冲突的二次确认。
final class PhoneBindingView: UIView {

    // MARK: - Mode

    enum Mode {
        case bind                  // 首次绑定
        case rebind(maskedPhone: String)  // 换绑二次确认
    }

    // MARK: - Callbacks

    var onSubmit: ((_ phone: String, _ code: String) -> Void)?
    var onDismiss: (() -> Void)?
    var onContactSupport: (() -> Void)?

    // MARK: - UI

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .fdH3
        label.textColor = .fdText
        label.textAlignment = .center
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .fdCaption
        label.textColor = .fdSubtext
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

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

    private lazy var submitButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.titleLabel?.font = .fdBodySemibold
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .fdPrimary
        btn.layer.cornerRadius = 14
        btn.addTarget(self, action: #selector(tapSubmit), for: .touchUpInside)
        return btn
    }()

    private lazy var cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("取消", for: .normal)
        btn.titleLabel?.font = .fdBody
        btn.setTitleColor(.fdSubtext, for: .normal)
        btn.addTarget(self, action: #selector(tapDismiss), for: .touchUpInside)
        return btn
    }()

    private lazy var contactSupportButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("联系客服解绑", for: .normal)
        btn.titleLabel?.font = .fdCaption
        btn.setTitleColor(.fdPrimary, for: .normal)
        btn.addTarget(self, action: #selector(tapContactSupport), for: .touchUpInside)
        return btn
    }()

    // MARK: - State

    private let mode: Mode
    private var isSubmitting = false

    // MARK: - Init

    init(mode: Mode = .bind) {
        self.mode = mode
        super.init(frame: .zero)
        setupUI()
        configureForMode()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.45)

        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(phoneField)
        containerView.addSubview(codeRowView)
        containerView.addSubview(submitButton)
        containerView.addSubview(cancelButton)

        containerView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        phoneField.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        codeRowView.snp.makeConstraints { make in
            make.top.equalTo(phoneField.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        codeButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }

        submitButton.snp.makeConstraints { make in
            make.top.equalTo(codeRowView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(48)
        }

        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(submitButton.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-24)
        }
    }

    private func configureForMode() {
        switch mode {
        case .bind:
            titleLabel.text = "请绑定手机号后继续使用"
            descriptionLabel.text = "微信授权成功，需绑定手机号以完成登录"
            submitButton.setTitle("绑定并登录", for: .normal)

        case .rebind(let maskedPhone):
            titleLabel.text = "该手机号已绑定其他微信号"
            descriptionLabel.text = "手机号 \(maskedPhone) 已绑定其他微信号。如需换绑至当前微信，请通过手机号验证码验证。"
            submitButton.setTitle("验证并换绑", for: .normal)

            // Show contact support option
            containerView.addSubview(contactSupportButton)
            contactSupportButton.snp.makeConstraints { make in
                make.top.equalTo(cancelButton.snp.bottom).offset(8)
                make.centerX.equalToSuperview()
            }
        }
    }

    // MARK: - Actions

    private func handleRequestCode() {
        let phone = phoneField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard validatePhone(phone) else { return }
        // Simulate sending code
        codeButton.startCountdown()
        showBriefToast("验证码已发送")
    }

    @objc private func tapSubmit() {
        guard !isSubmitting else { return }

        let phone = phoneField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let code = codeField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        guard !phone.isEmpty else { showBriefToast("请输入手机号"); return }
        guard validatePhone(phone) else { return }
        guard !code.isEmpty else { showBriefToast("请输入验证码"); return }

        isSubmitting = true
        submitButton.isEnabled = false
        submitButton.alpha = 0.72

        onSubmit?(phone, code)
    }

    @objc private func tapDismiss() {
        onDismiss?()
    }

    @objc private func tapContactSupport() {
        onContactSupport?()
    }

    // MARK: - Validation

    private func validatePhone(_ phone: String) -> Bool {
        let pattern = "^1[3-9]\\d{9}$"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              regex.firstMatch(in: phone, range: NSRange(phone.startIndex..., in: phone)) != nil else {
            showBriefToast("请输入正确的手机号")
            return false
        }
        return true
    }

    // MARK: - Helpers

    func resetSubmitState() {
        isSubmitting = false
        submitButton.isEnabled = true
        submitButton.alpha = 1.0
    }

    private func showBriefToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        // Find the topmost view controller to present the toast
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            topVC.present(alert, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                alert.dismiss(animated: true)
            }
        }
    }
}
