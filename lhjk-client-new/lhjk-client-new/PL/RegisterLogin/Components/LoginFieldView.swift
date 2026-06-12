import UIKit
import SnapKit

/// 登录输入框组件 — label + icon + textField + 可选右侧按钮
/// 参考 funde-client: login-field / login-field__shell / login-field__icon / login-field__input / login-field__toggle
final class LoginFieldView: UIView {

    // MARK: - Types

    enum RightButton {
        case none
        /// 密码显隐切换 (eye / eye.slash)
        case secureToggle
        /// 自定义 icon
        case custom(sfSymbol: String, action: () -> Void)
    }

    // MARK: - UI

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .fdSubtext
        return label
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = .fdSubtext
        iv.contentMode = .scaleAspectFit
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.setContentCompressionResistancePriority(.required, for: .horizontal)
        return iv
    }()

    let textField: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 15)
        tf.textColor = .fdText
        tf.borderStyle = .none
        return tf
    }()

    /// 输入框容器（白色背景 + 边框 + 圆角）
    private let shellView: UIView = {
        let view = UIView()
        view.backgroundColor = .fdSurface
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.fdBorder.cgColor
        view.layer.cornerRadius = 12
        return view
    }()

    /// 右侧按钮（可选：密码显隐等）
    private var rightButton: UIButton?
    private var rightButtonConfig: RightButton = .none

    /// 密码当前是否可见
    private var isSecureVisible = false

    // MARK: - Init

    init(title: String, placeholder: String, sfSymbol: String, rightButton: RightButton = .none) {
        super.init(frame: .zero)
        self.rightButtonConfig = rightButton

        titleLabel.text = title
        textField.placeholder = placeholder
        iconImageView.image = UIImage(systemName: sfSymbol)?.withRenderingMode(.alwaysTemplate)

        setupUI()
        configureRightButton()
        textField.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(titleLabel)
        addSubview(shellView)
        shellView.addSubview(iconImageView)
        shellView.addSubview(textField)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }

        shellView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(48)
            make.bottom.equalToSuperview()
        }

        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }

        // textField 的 trailing 取决于是否有右侧按钮，先做基础约束
        textField.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
        }
    }

    private func configureRightButton() {
        switch rightButtonConfig {
        case .none:
            textField.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-14)
            }

        case .secureToggle:
            isSecureVisible = false
            let btn = makeRightButton(sfSymbol: "eye.slash", action: #selector(toggleSecure))
            shellView.addSubview(btn)
            btn.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-14)
                make.centerY.equalToSuperview()
                make.size.equalTo(24)
            }
            textField.snp.makeConstraints { make in
                make.trailing.equalTo(btn.snp.leading).offset(-8)
            }

        case .custom(let sfSymbol, let action):
            let btn = makeRightButton(sfSymbol: sfSymbol, action: #selector(customAction))
            shellView.addSubview(btn)
            btn.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-14)
                make.centerY.equalToSuperview()
                make.size.equalTo(24)
            }
            rightButton?.addAction(UIAction { _ in action() }, for: .touchUpInside)
            textField.snp.makeConstraints { make in
                make.trailing.equalTo(btn.snp.leading).offset(-8)
            }
        }
    }

    private func makeRightButton(sfSymbol: String, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: sfSymbol), for: .normal)
        btn.tintColor = .fdSubtext
        btn.addTarget(self, action: action, for: .touchUpInside)
        self.rightButton = btn
        return btn
    }

    // MARK: - Actions

    @objc private func toggleSecure() {
        isSecureVisible.toggle()
        textField.isSecureTextEntry = !isSecureVisible
        let icon = isSecureVisible ? "eye" : "eye.slash"
        rightButton?.setImage(UIImage(systemName: icon), for: .normal)
    }

    @objc private func customAction() {
        // handled via UIAction
    }

    // MARK: - Focus Styling

    private func setFocused(_ focused: Bool) {
        let borderColor = focused ? UIColor.fdPrimary : UIColor.fdBorder
        let shadowOpacity: Float = focused ? 1.0 : 0.0

        UIView.animate(withDuration: 0.15) {
            self.shellView.layer.borderColor = borderColor.cgColor
            self.shellView.layer.shadowColor = UIColor.fdPrimary.cgColor
            self.shellView.layer.shadowOffset = .zero
            self.shellView.layer.shadowRadius = 3
            self.shellView.layer.shadowOpacity = shadowOpacity
        }
    }
}

// MARK: - UITextFieldDelegate

extension LoginFieldView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        setFocused(true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        setFocused(false)
    }
}
