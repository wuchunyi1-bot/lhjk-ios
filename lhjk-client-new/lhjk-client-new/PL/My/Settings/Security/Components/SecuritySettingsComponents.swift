import UIKit
import SnapKit

// MARK: - Design tokens — 对齐设置主页标杆（SettingsStyle）

private enum SecurityStyle {
    static let cardRadius: CGFloat = 16
    static let tipRadius: CGFloat = 12
    static let rowHeight: CGFloat = 45
    static let cardInset: CGFloat = 12
    static let headerIconSize: CGFloat = 16
    static let shieldSize: CGFloat = 44
    static let chevronSize: CGFloat = 12

    static let titleColor = SettingsStyle.titleColor
    static let valueColor = SettingsStyle.subtitleColor
    static let descColor = SettingsStyle.subtitleColor
    static let warnColor = UIColor(hexString: "#F93838")
    static let dividerColor = UIColor(hexString: "#F0F2F5")
}

// MARK: - Section card

/// 安全中心分组白卡片 — 对齐 Figma 4449:12225 / 4449:12320 / 4449:12381
final class SecuritySectionCard: UIView {

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let bodyStack = UIStackView()

    init(sectionTitle: String, iconImageName: String) {
        super.init(frame: .zero)
        setupCard(sectionTitle: sectionTitle, iconImageName: iconImageName)
    }

    required init?(coder: NSCoder) { fatalError() }

    func setBodyViews(_ views: [UIView]) {
        bodyStack.arrangedSubviews.forEach { view in
            bodyStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        views.forEach { bodyStack.addArrangedSubview($0) }
    }

    private func setupCard(sectionTitle: String, iconImageName: String) {
        backgroundColor = .white
        layer.cornerRadius = SecurityStyle.cardRadius
        clipsToBounds = true

        iconView.image = UIImage(named: iconImageName)
        iconView.contentMode = .scaleAspectFit

        titleLabel.text = sectionTitle
        titleLabel.font = SettingsStyle.sectionTitleFont
        titleLabel.textColor = SecurityStyle.titleColor

        bodyStack.axis = .vertical
        bodyStack.spacing = 0

        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(bodyStack)

        iconView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(SecurityStyle.cardInset)
            make.size.equalTo(SecurityStyle.headerIconSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(4)
            make.centerY.equalTo(iconView)
            make.trailing.lessThanOrEqualToSuperview().offset(-SecurityStyle.cardInset)
        }

        bodyStack.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(13)
            make.leading.trailing.equalToSuperview().inset(SecurityStyle.cardInset)
            make.bottom.equalToSuperview().offset(-SecurityStyle.cardInset)
        }
    }
}

// MARK: - Account status tip

/// 账号状态提示条 — 对齐 Figma 4449:12239
final class SecurityAccountStatusTipView: UIView {

    private let shieldView = UIImageView()
    private let titleLabel = UILabel()
    private let descLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .fdBg
        layer.cornerRadius = SecurityStyle.tipRadius
        clipsToBounds = true

        shieldView.image = UIImage(named: "security_status_shield")
        shieldView.contentMode = .scaleAspectFit

        titleLabel.text = "账号安全状态良好"
        titleLabel.font = SettingsStyle.rowTitleFont
        titleLabel.textColor = SecurityStyle.titleColor

        descLabel.text = "已绑定手机号，建议定期更新登录密码，保护账号与健康数据安全"
        descLabel.font = SettingsStyle.rowSubtitleFont
        descLabel.textColor = SecurityStyle.descColor
        descLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLabel, descLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.alignment = .leading

        addSubview(shieldView)
        addSubview(textStack)

        shieldView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(SecurityStyle.shieldSize)
        }

        textStack.snp.makeConstraints { make in
            make.leading.equalTo(shieldView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-12)
            make.top.bottom.equalToSuperview().inset(12)
        }
    }
}

// MARK: - Settings row

/// 安全中心列表行 — 对齐 Figma 4449:12330
final class SecuritySettingsRow: UIControl {

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let chevronView = UIImageView()
    private let divider = UIView()

    var valueText: String? {
        get { valueLabel.text }
        set { valueLabel.text = newValue }
    }

    var valueWarn: Bool = false {
        didSet { valueLabel.textColor = valueWarn ? SecurityStyle.warnColor : SecurityStyle.valueColor }
    }

    init(
        title: String,
        value: String,
        valueWarn: Bool = false,
        showDivider: Bool,
        action: @escaping () -> Void
    ) {
        super.init(frame: .zero)
        addAction(UIAction { _ in action() }, for: .touchUpInside)
        setupUI(title: title, value: value, valueWarn: valueWarn, showDivider: showDivider)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI(title: String, value: String, valueWarn: Bool, showDivider: Bool) {
        titleLabel.text = title
        titleLabel.font = SettingsStyle.rowTitleFont
        titleLabel.textColor = SecurityStyle.titleColor
        titleLabel.isUserInteractionEnabled = false

        valueLabel.text = value
        valueLabel.font = SettingsStyle.rowValueFont
        valueLabel.textColor = valueWarn ? SecurityStyle.warnColor : SecurityStyle.valueColor
        valueLabel.textAlignment = .right
        valueLabel.isUserInteractionEnabled = false
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        chevronView.image = UIImage(named: "settings_chevron")
        chevronView.contentMode = .scaleAspectFit
        chevronView.isUserInteractionEnabled = false

        divider.backgroundColor = SecurityStyle.dividerColor
        divider.isHidden = !showDivider

        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(chevronView)
        addSubview(divider)

        chevronView.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(SecurityStyle.chevronSize)
        }

        valueLabel.snp.makeConstraints { make in
            make.trailing.equalTo(chevronView.snp.leading).offset(-4)
            make.centerY.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(valueLabel.snp.leading).offset(-8)
        }

        divider.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }

        snp.makeConstraints { make in
            make.height.equalTo(SecurityStyle.rowHeight)
        }
    }
}
