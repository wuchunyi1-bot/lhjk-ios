import UIKit
import SnapKit

/// 忘记密码页面
/// 参考 funde-client PRD 3.5: 通过手机号、拼图验证、短信验证码和新密码完成密码重置
///
/// 流程: 手机号 → 拼图验证 → 发送验证码 → 输入验证码 → 设置新密码 → 提交重置
/// 重置成功后返回密码登录页并预填手机号。
final class ForgotPasswordViewController: BaseViewController {

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

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "重置密码"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .fdText
        label.textAlignment = .center
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "请输入手机号，通过验证码设置新密码"
        label.font = .systemFont(ofSize: 13)
        label.textColor = .fdSubtext
        label.textAlignment = .center
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
            self?.requestCode()
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

    private lazy var newPasswordField = LoginFieldView(
        title: "新密码",
        placeholder: "请设置新密码（至少 6 位）",
        sfSymbol: "lock",
        rightButton: .secureToggle
    )

    private lazy var submitButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("重置密码", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .fdPrimary
        btn.layer.cornerRadius = 18
        btn.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
        return btn
    }()

    // MARK: - State

    private var isSubmitting = false
    private var captchaToken: String?

    /// 重置成功后回传手机号
    var onResetSuccess: ((String) -> Void)?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "忘记密码"
    }

    // MARK: - Setup

    override func setupUI() {
        view.backgroundColor = .fdBg

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }

        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(phoneField)
        contentView.addSubview(codeRowView)
        contentView.addSubview(newPasswordField)
        contentView.addSubview(submitButton)

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(40)
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
        }

        phoneField.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
        }

        codeRowView.snp.makeConstraints { make in
            make.top.equalTo(phoneField.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
        }

        codeButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }

        newPasswordField.snp.makeConstraints { make in
            make.top.equalTo(codeRowView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
        }

        submitButton.snp.makeConstraints { make in
            make.top.equalTo(newPasswordField.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
            make.height.equalTo(52)
            make.bottom.equalToSuperview().offset(-32)
        }
    }

    // MARK: - Request Code

    private func requestCode() {
        let phone = phoneField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard validatePhone(phone) else { return }

        // Show captcha first (mock in V1.0)
        showCaptchaVerify { [weak self] token in
            guard let self = self else { return }
            self.captchaToken = token
            self.codeButton.startCountdown()
            self.showToast("验证码已发送")
        }
    }

    private func showCaptchaVerify(completion: @escaping (String) -> Void) {
        // V1.0: mock captcha, skip UI and directly callback
        let mockToken = "captcha_reset_\(UUID().uuidString.prefix(8))"
        completion(mockToken)
    }

    // MARK: - Submit

    @objc private func handleSubmit() {
        guard !isSubmitting else { return }

        let phone = phoneField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let code = codeField.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let newPassword = newPasswordField.textField.text ?? ""

        guard !phone.isEmpty else { showToast("请输入手机号"); return }
        guard validatePhone(phone) else { return }
        guard !code.isEmpty else { showToast("请输入验证码"); return }
        guard !newPassword.isEmpty else { showToast("请设置新密码"); return }
        guard newPassword.count >= 6 else { showToast("新密码至少 6 位"); return }

        isSubmitting = true
        submitButton.isEnabled = false
        submitButton.alpha = 0.72

        // V1.0 mock: simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self = self else { return }
            self.isSubmitting = false
            self.submitButton.isEnabled = true
            self.submitButton.alpha = 1.0

            self.showToast("密码已重置，请重新登录") {
                self.onResetSuccess?(phone)
                self.navigationController?.popViewController(animated: true)
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

    // MARK: - Toast

    private func showToast(_ message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true) {
                completion?()
            }
        }
    }
}
