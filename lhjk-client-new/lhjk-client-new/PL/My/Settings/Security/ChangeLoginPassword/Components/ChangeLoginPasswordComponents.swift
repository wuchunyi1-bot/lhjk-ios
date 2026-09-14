import UIKit
import SnapKit

// MARK: - Figma 4828:11644 / 4828:11665

enum ChangeLoginPasswordStyle {
    static let cardRadius: CGFloat = 16
    static let fieldRadius: CGFloat = 12
    static let cardInset: CGFloat = 16
    static let screenInset: CGFloat = 16
    static let buttonInset: CGFloat = 24
    static let buttonHeight: CGFloat = 51
    static let fieldHeight: CGFloat = 48
    static let phoneBoxHeight: CGFloat = 76
    static let iconSize: CGFloat = 18
    static let eyeSize: CGFloat = 16
    static let headerToBody: CGFloat = 24
    static let phoneToCode: CGFloat = 18
    static let labelToField: CGFloat = 10
    static let passwordGroupSpacing: CGFloat = 22

    static let titleColor = SettingsStyle.titleColor
    static let subtitleColor = SettingsStyle.subtitleColor
    static let fieldLabelColor = UIColor(hexString: "#535D72")
    static let placeholderColor = UIColor(hexString: "#A4A4A6")
    static let fieldBorderColor = UIColor(red: 113 / 255, green: 120 / 255, blue: 133 / 255, alpha: 0.3)

    static let titleFont = UIFont.fdFont(ofSize: 18, weight: .medium)
    static let subtitleFont = UIFont.fdFont(ofSize: 12, weight: .regular)
    static let phoneFont = UIFont.fdFont(ofSize: 18, weight: .medium)
    static let captionFont = UIFont.fdFont(ofSize: 14, weight: .regular)
    static let fieldFont = UIFont.fdFont(ofSize: 14, weight: .regular)
    static let buttonFont = UIFont.fdFont(ofSize: 16, weight: .medium)
}

/// 白色渐变表单卡片
final class ChangeLoginPasswordCardView: UIView {

    private let gradientLayer = CAGradientLayer()
    let bodyStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    func setBodyViews(_ views: [UIView]) {
        bodyStack.arrangedSubviews.forEach {
            bodyStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        views.forEach { bodyStack.addArrangedSubview($0) }
    }

    private func setupUI() {
        backgroundColor = .clear
        layer.cornerRadius = ChangeLoginPasswordStyle.cardRadius
        clipsToBounds = true

        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor.white.withAlphaComponent(0).cgColor,
        ]
        gradientLayer.locations = [0.72, 1]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        bodyStack.axis = .vertical
        bodyStack.alignment = .fill
        addSubview(bodyStack)
        bodyStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(ChangeLoginPasswordStyle.cardInset)
            make.bottom.equalToSuperview().offset(-24)
        }
    }
}

/// 标题 + 说明
final class ChangeLoginPasswordHeaderView: UIView {

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    init(title: String, subtitle: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.font = ChangeLoginPasswordStyle.titleFont
        titleLabel.textColor = ChangeLoginPasswordStyle.titleColor
        titleLabel.numberOfLines = 0

        subtitleLabel.text = subtitle
        subtitleLabel.font = ChangeLoginPasswordStyle.subtitleFont
        subtitleLabel.textColor = ChangeLoginPasswordStyle.subtitleColor
        subtitleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 4
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }
}

/// 当前注册手机号展示框（只读）
final class ChangeLoginPasswordPhoneBoxView: UIView {

    private let phoneLabel = UILabel()
    private let captionLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = ChangeLoginPasswordStyle.fieldRadius
        layer.borderWidth = 0.5
        layer.borderColor = ChangeLoginPasswordStyle.fieldBorderColor.cgColor
        clipsToBounds = true

        phoneLabel.font = ChangeLoginPasswordStyle.phoneFont
        phoneLabel.textColor = ChangeLoginPasswordStyle.titleColor
        phoneLabel.lineBreakMode = .byTruncatingTail

        captionLabel.text = "当前注册手机号"
        captionLabel.font = ChangeLoginPasswordStyle.captionFont
        captionLabel.textColor = ChangeLoginPasswordStyle.subtitleColor

        let stack = UIStackView(arrangedSubviews: [phoneLabel, captionLabel])
        stack.axis = .vertical
        stack.spacing = 4
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
        snp.makeConstraints { $0.height.equalTo(ChangeLoginPasswordStyle.phoneBoxHeight) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func setPhone(_ masked: String) {
        phoneLabel.text = masked
    }
}

/// 带标签的输入框：验证码（左图标）/ 密码（右眼睛）
final class ChangeLoginPasswordFieldView: UIView, UITextFieldDelegate {

    let textField = UITextField()
    private let titleLabel = UILabel()
    private let shellView = UIView()
    private let iconView = UIImageView()
    private var eyeButton: UIButton?
    private var isSecureVisible = false
    private let showsIcon: Bool
    private let usesSecureToggle: Bool

    init(
        title: String,
        placeholder: String,
        iconAssetName: String? = nil,
        usesSecureToggle: Bool = false
    ) {
        self.showsIcon = iconAssetName != nil
        self.usesSecureToggle = usesSecureToggle
        super.init(frame: .zero)

        titleLabel.text = title
        titleLabel.font = ChangeLoginPasswordStyle.fieldFont
        titleLabel.textColor = ChangeLoginPasswordStyle.fieldLabelColor

        shellView.backgroundColor = .white
        shellView.layer.cornerRadius = ChangeLoginPasswordStyle.fieldRadius
        shellView.layer.borderWidth = 0.5
        shellView.layer.borderColor = ChangeLoginPasswordStyle.fieldBorderColor.cgColor
        shellView.clipsToBounds = true

        if let iconAssetName {
            iconView.image = UIImage(named: iconAssetName)
            iconView.contentMode = .scaleAspectFit
        }

        textField.font = ChangeLoginPasswordStyle.fieldFont
        textField.textColor = ChangeLoginPasswordStyle.titleColor
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .font: ChangeLoginPasswordStyle.fieldFont,
                .foregroundColor: ChangeLoginPasswordStyle.placeholderColor,
            ]
        )
        textField.borderStyle = .none
        textField.returnKeyType = .done
        textField.delegate = self
        if usesSecureToggle {
            textField.isSecureTextEntry = true
            textField.textContentType = .newPassword
        }

        addSubview(titleLabel)
        addSubview(shellView)
        if showsIcon {
            shellView.addSubview(iconView)
        }
        shellView.addSubview(textField)

        titleLabel.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }
        shellView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(ChangeLoginPasswordStyle.labelToField)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(ChangeLoginPasswordStyle.fieldHeight)
        }

        if showsIcon {
            iconView.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(14)
                make.centerY.equalToSuperview()
                make.size.equalTo(ChangeLoginPasswordStyle.iconSize)
            }
            textField.snp.makeConstraints { make in
                make.leading.equalTo(iconView.snp.trailing).offset(12)
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview().offset(-12)
            }
        } else {
            textField.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(16)
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview().offset(-16)
            }
        }

        if usesSecureToggle {
            let btn = UIButton(type: .custom)
            btn.setImage(Self.eyeIcon(visible: false), for: .normal)
            btn.addTarget(self, action: #selector(toggleSecure), for: .touchUpInside)
            shellView.addSubview(btn)
            btn.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-12)
                make.centerY.equalToSuperview()
                make.size.equalTo(44)
            }
            btn.imageView?.contentMode = .scaleAspectFit
            eyeButton = btn
            textField.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(16)
                make.centerY.equalToSuperview()
                make.trailing.equalTo(btn.snp.leading).offset(-8)
            }
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func setTrailingAccessory(_ view: UIView?) {
        guard let view else { return }
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        shellView.addSubview(view)
        view.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }
        if showsIcon {
            textField.snp.remakeConstraints { make in
                make.leading.equalTo(iconView.snp.trailing).offset(12)
                make.centerY.equalToSuperview()
                make.trailing.equalTo(view.snp.leading).offset(-8)
            }
        } else {
            textField.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(16)
                make.centerY.equalToSuperview()
                make.trailing.equalTo(view.snp.leading).offset(-8)
            }
        }
    }

    func attachDoneToolbarIfNeeded() {
        switch textField.keyboardType {
        case .phonePad, .numberPad, .decimalPad, .asciiCapableNumberPad:
            break
        default:
            return
        }
        guard textField.inputAccessoryView == nil else { return }
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "完成", style: .done, target: self, action: #selector(endEditingFromToolbar))
        done.tintColor = .fdPrimary
        toolbar.items = [flex, done]
        textField.inputAccessoryView = toolbar
    }

    @objc private func endEditingFromToolbar() {
        textField.resignFirstResponder()
    }

    @objc private func toggleSecure() {
        isSecureVisible.toggle()
        let wasEditing = textField.isFirstResponder
        if wasEditing { textField.resignFirstResponder() }
        textField.isSecureTextEntry = !isSecureVisible
        let current = textField.text
        textField.text = nil
        textField.text = current
        eyeButton?.setImage(Self.eyeIcon(visible: isSecureVisible), for: .normal)
        if wasEditing { textField.becomeFirstResponder() }
    }

    private static func eyeIcon(visible: Bool) -> UIImage? {
        let name = visible ? "login_password_eye_on" : "login_password_eye_off"
        return UIImage(named: name)?.withRenderingMode(.alwaysOriginal)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        shellView.layer.borderColor = UIColor.fdPrimary.cgColor
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        shellView.layer.borderColor = ChangeLoginPasswordStyle.fieldBorderColor.cgColor
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

final class ChangeLoginPasswordActionButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel?.font = ChangeLoginPasswordStyle.buttonFont
        setTitleColor(.white, for: .normal)
        backgroundColor = .fdPrimary
        layer.cornerRadius = ChangeLoginPasswordStyle.buttonHeight / 2
        clipsToBounds = true
        snp.makeConstraints { $0.height.equalTo(ChangeLoginPasswordStyle.buttonHeight) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func setBusy(_ busy: Bool) {
        isEnabled = !busy
        alpha = busy ? 0.6 : 1
    }
}
