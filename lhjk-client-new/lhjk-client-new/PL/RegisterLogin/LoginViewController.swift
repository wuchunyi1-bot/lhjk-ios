import UIKit
import SnapKit

/// 注册/登陆页面
final class LoginViewController: BaseViewController {

    // MARK: - UI

    private let phoneTextField = UITextField()
    private let codeTextField = UITextField()
    private let loginButton = UIButton(type: .system)

    // MARK: - Lifecycle

    override func setupUI() {
        title = "登录"
        view.backgroundColor = .systemBackground

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        view.addSubview(stack)

        stack.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(-60)
            make.leading.trailing.equalToSuperview().inset(40)
        }

        // 标题
        let titleLabel = UILabel()
        titleLabel.text = "欢迎登录"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        stack.addArrangedSubview(titleLabel)

        // 手机号输入框
        phoneTextField.placeholder = "请输入手机号"
        phoneTextField.borderStyle = .roundedRect
        phoneTextField.keyboardType = .phonePad
        phoneTextField.font = .systemFont(ofSize: 16)
        phoneTextField.clearButtonMode = .whileEditing
        stack.addArrangedSubview(phoneTextField)

        // 验证码输入框
        codeTextField.placeholder = "请输入验证码"
        codeTextField.borderStyle = .roundedRect
        codeTextField.keyboardType = .numberPad
        codeTextField.font = .systemFont(ofSize: 16)
        codeTextField.clearButtonMode = .whileEditing
        codeTextField.isSecureTextEntry = true
        stack.addArrangedSubview(codeTextField)

        // 登录按钮
        loginButton.setTitle("登录", for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.backgroundColor = .systemBlue
        loginButton.layer.cornerRadius = 10
        loginButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 0, bottom: 14, right: 0)
        loginButton.addAction(UIAction { [weak self] _ in
            self?.handleLogin()
        }, for: .touchUpInside)
        stack.addArrangedSubview(loginButton)

        // 提示
        let hintLabel = UILabel()
        hintLabel.text = "验证码：123456"
        hintLabel.font = .systemFont(ofSize: 13)
        hintLabel.textColor = .secondaryLabel
        hintLabel.textAlignment = .center
        stack.addArrangedSubview(hintLabel)

        stack.setCustomSpacing(30, after: titleLabel)
    }

    // MARK: - Actions

    private func handleLogin() {
        let phone = phoneTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let code = codeTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        guard !phone.isEmpty else {
            showAlert(message: "请输入手机号")
            return
        }

        guard code == "123456" else {
            showAlert(message: "验证码错误")
            return
        }

        dismiss(animated: true)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
