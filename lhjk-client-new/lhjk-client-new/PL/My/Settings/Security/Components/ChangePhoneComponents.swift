import UIKit
import SnapKit

// MARK: - Design tokens (Figma 4457:12463)

private enum ChangePhoneStyle {
    static let cardRadius: CGFloat = 16
    static let tertiaryText = UIColor(hexString: "#A6ACB8")
    static let fieldLabelColor = UIColor(hexString: "#535D72")
    static let placeholderColor = UIColor(hexString: "#A4A4A6")
}

// MARK: - Hint banner

/// 顶部提示条 — 对齐 Figma 安全中心表单页
final class SecurityHintBannerView: UIView {

    private let message: String
    private let gradientLayer = CAGradientLayer()

    init(message: String) {
        self.message = message
        super.init(frame: .zero)
        setupUI()
    }

    convenience init() {
        self.init(message: "更换后将使用新手机号登录富德健康,并用于接收服务与安全提醒")
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    private func setupUI() {
        layer.cornerRadius = ChangePhoneStyle.cardRadius
        clipsToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.cgColor

        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor(hexString: "#FDF6F4").cgColor,
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        let iconView = UIImageView(image: UIImage(named: "change_phone_hint_bell"))
        iconView.contentMode = .scaleAspectFit
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)

        let label = UILabel()
        label.text = message
        label.font = SettingsStyle.rowSubtitleFont
        label.textColor = SettingsStyle.subtitleColor
        label.numberOfLines = 2

        addSubview(iconView)
        addSubview(label)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(15)
            make.centerY.equalTo(label)
            make.size.equalTo(14)
        }

        label.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(4)
            make.trailing.equalToSuperview().offset(-12)
            make.top.bottom.equalToSuperview().inset(11)
        }

        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(42)
        }
    }
}

/// 修改手机号页顶部提示条
typealias ChangePhoneHintBannerView = SecurityHintBannerView

extension SecurityHintBannerView {
    static func changePhone() -> SecurityHintBannerView {
        SecurityHintBannerView(
            message: "更换后将使用新手机号登录富德健康,并用于接收服务与安全提醒"
        )
    }

    static func passwordVerification() -> SecurityHintBannerView {
        SecurityHintBannerView(
            message: "通过短信验证码确认身份后，可设置新的登录密码"
        )
    }
}

// MARK: - Form card

/// 表单白卡片 — 对齐 Figma 4457:12679
final class ChangePhoneFormCardView: UIView {

    private let gradientLayer = CAGradientLayer()

    let currentPhoneTitleLabel = UILabel()
    let currentPhoneValueLabel = UILabel()
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

    func setFormFields(_ views: [UIView]) {
        bodyStack.arrangedSubviews.forEach { view in
            bodyStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        views.forEach { bodyStack.addArrangedSubview($0) }
    }

    private func setupUI() {
        layer.cornerRadius = ChangePhoneStyle.cardRadius
        clipsToBounds = true

        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor.white.withAlphaComponent(0).cgColor,
        ]
        gradientLayer.locations = [0.72, 1]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        currentPhoneTitleLabel.text = "当前绑定手机号"
        currentPhoneTitleLabel.font = SettingsStyle.rowSubtitleFont
        currentPhoneTitleLabel.textColor = SettingsStyle.subtitleColor

        currentPhoneValueLabel.font = .fdFont(ofSize: 25, weight: .medium)
        currentPhoneValueLabel.textColor = UIColor(hexString: "#1F2942")
        currentPhoneValueLabel.adjustsFontSizeToFitWidth = true
        currentPhoneValueLabel.minimumScaleFactor = 0.8

        let currentStack = UIStackView(arrangedSubviews: [currentPhoneTitleLabel, currentPhoneValueLabel])
        currentStack.axis = .vertical
        currentStack.spacing = 4
        currentStack.alignment = .leading

        bodyStack.axis = .vertical
        bodyStack.spacing = 22

        addSubview(currentStack)
        addSubview(bodyStack)

        currentStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }

        bodyStack.snp.makeConstraints { make in
            make.top.equalTo(currentStack.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-24)
        }
    }
}

// MARK: - Password code form card

/// 填写验证码表单卡片 — 对齐 Figma 4457:12732
final class PasswordCodeFormCardView: UIView {

    private let gradientLayer = CAGradientLayer()
    let descLabel = UILabel()
    private let bodyContainer = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    func setBodyView(_ view: UIView) {
        bodyContainer.subviews.forEach { $0.removeFromSuperview() }
        bodyContainer.addSubview(view)
        view.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    func updateDesc(phone: String, hasSentCode: Bool) {
        let masked = maskPhone(phone)
        let prefix = hasSentCode ? "验证码已发送至 " : "验证码将发送至 "
        let suffix = hasSentCode ? "" : "，请点击右侧按钮获取"
        let full = "\(prefix)\(masked)\(suffix)"
        let attributed = NSMutableAttributedString(
            string: full,
            attributes: [
                .font: SettingsStyle.rowSubtitleFont,
                .foregroundColor: SettingsStyle.subtitleColor,
            ]
        )
        if let range = full.range(of: masked) {
            attributed.addAttributes(
                [.foregroundColor: SettingsStyle.titleColor],
                range: NSRange(range, in: full)
            )
        }
        descLabel.attributedText = attributed
    }

    private func maskPhone(_ phone: String) -> String {
        let digits = phone.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
        guard digits.count == 11 else { return phone.isEmpty ? "—" : phone }
        return "\(digits.prefix(3))****\(digits.suffix(4))"
    }

    private func setupUI() {
        layer.cornerRadius = ChangePhoneStyle.cardRadius
        clipsToBounds = true

        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor.white.withAlphaComponent(0).cgColor,
        ]
        gradientLayer.locations = [0.72, 1]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        descLabel.numberOfLines = 0

        addSubview(descLabel)
        addSubview(bodyContainer)

        descLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }

        bodyContainer.snp.makeConstraints { make in
            make.top.equalTo(descLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-24)
        }
    }
}
