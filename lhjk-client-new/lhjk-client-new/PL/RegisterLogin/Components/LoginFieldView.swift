import UIKit
import SnapKit

/// 登录输入框 — Figma 3021:575 / 3021:578
final class LoginFieldView: UIView {

    enum RightButton {
        case none
        case secureToggle
        case custom(sfSymbol: String, action: () -> Void)
    }

    /// Figma 输入框左侧图标 1x 尺寸（pt）
    private static let iconSize: CGFloat = 18

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .fdLoginInput
        label.textColor = .fdLoginLabel
        return label
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    let textField: UITextField = {
        let tf = UITextField()
        tf.font = .fdLoginInput
        tf.textColor = .fdText
        tf.borderStyle = .none
        return tf
    }()

    private let shellView: UIView = {
        let view = UIView()
        view.backgroundColor = .fdSurface
        view.layer.cornerRadius = 12
        return view
    }()

    private var rightButton: UIButton?
    private var rightButtonConfig: RightButton = .none
    private var trailingAccessory: UIView?
    private var isSecureVisible = false

    /// 内嵌于输入壳右侧的配件（如「获取验证码」文字按钮）。
    var trailingAccessoryView: UIView? {
        get { trailingAccessory }
        set { setTrailingAccessory(newValue) }
    }

    init(
        title: String,
        placeholder: String,
        sfSymbol: String,
        iconAssetName: String? = nil,
        rightButton: RightButton = .none
    ) {
        super.init(frame: .zero)
        rightButtonConfig = rightButton

        titleLabel.text = title
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .font: UIFont.fdLoginInput,
                .foregroundColor: UIColor.fdLoginLabel.withAlphaComponent(0.5),
            ]
        )

        if let iconAssetName {
            iconImageView.image = UIImage(named: iconAssetName)
        } else {
            iconImageView.image = UIImage(systemName: sfSymbol)?.withRenderingMode(.alwaysTemplate)
            iconImageView.tintColor = .fdPrimary
        }

        setupUI()
        configureRightButton()
        textField.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(titleLabel)
        addSubview(shellView)
        shellView.addSubview(iconImageView)
        shellView.addSubview(textField)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }

        shellView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(9)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(48)
            make.bottom.equalToSuperview()
        }

        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(Self.iconSize)
        }

        textField.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-14)
        }
    }

    private func configureRightButton() {
        switch rightButtonConfig {
        case .none:
            break

        case .secureToggle:
            textField.isSecureTextEntry = true
            textField.textContentType = .password
            let btn = makeRightButton(sfSymbol: "eye.slash", action: #selector(toggleSecure))
            btn.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            shellView.addSubview(btn)
            btn.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-4)
                make.centerY.equalToSuperview()
                make.size.equalTo(44)
            }
            remakeTextFieldTrailing(equalTo: btn.snp.leading, offset: -4)

        case .custom(let sfSymbol, let action):
            let btn = makeRightButton(sfSymbol: sfSymbol, action: #selector(customAction))
            btn.addAction(UIAction { _ in action() }, for: .touchUpInside)
            shellView.addSubview(btn)
            btn.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-14)
                make.centerY.equalToSuperview()
                make.size.equalTo(24)
            }
            remakeTextFieldTrailing(equalTo: btn.snp.leading, offset: -8)
        }
    }

    private func setTrailingAccessory(_ view: UIView?) {
        trailingAccessory?.removeFromSuperview()
        trailingAccessory = view

        guard let view else {
            textField.snp.remakeConstraints { make in
                make.leading.equalTo(iconImageView.snp.trailing).offset(12)
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview().offset(-14)
            }
            return
        }

        shellView.addSubview(view)
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }
        remakeTextFieldTrailing(equalTo: view.snp.leading, offset: -8)
    }

    private func remakeTextFieldTrailing(
        equalTo anchor: ConstraintRelatableTarget,
        offset: CGFloat
    ) {
        textField.snp.remakeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(anchor).offset(offset)
        }
    }

    private func makeRightButton(sfSymbol: String, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: sfSymbol), for: .normal)
        btn.tintColor = .fdSubtext
        btn.addTarget(self, action: action, for: .touchUpInside)
        rightButton = btn
        return btn
    }

    @objc private func toggleSecure() {
        isSecureVisible.toggle()
        let wasEditing = textField.isFirstResponder
        if wasEditing { textField.resignFirstResponder() }

        textField.isSecureTextEntry = !isSecureVisible
        let current = textField.text
        textField.text = nil
        textField.text = current
        rightButton?.setImage(
            UIImage(systemName: isSecureVisible ? "eye" : "eye.slash"),
            for: .normal
        )

        if wasEditing { textField.becomeFirstResponder() }
    }

    @objc private func customAction() {}

    private func setFocused(_ focused: Bool) {
        UIView.animate(withDuration: 0.15) {
            self.shellView.layer.borderWidth = focused ? 1 : 0
            self.shellView.layer.borderColor = UIColor.fdPrimary.cgColor
        }
    }
}

extension LoginFieldView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        setFocused(true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        setFocused(false)
    }
}
