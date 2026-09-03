import UIKit
import SnapKit

// MARK: - Design tokens
//
// 标杆来源：设置主页 `SettingsHubItemRow`（账号与安全 / 安全中心 / 手机号、密码与账号管理）
// | 层级     | 示例                     | 字号 | 字重   | 颜色     |
// | 分组标题 | 账号与安全               | 20pt | medium | #1F2942 |
// | 行标题   | 安全中心                 | 18pt | regular| #1F2942 |
// | 行副标题 | 手机号、密码与账号管理   | 16pt | regular| #8591AB |

enum SettingsStyle {
    static let cardRadius: CGFloat = 16
    static let horizontalInset: CGFloat = 16
    static let cardPadding: CGFloat = 12
    static let cardSpacing: CGFloat = 12
    static let sectionIconSize: CGFloat = 16
    static let chevronSize: CGFloat = 12
    static let permissionRowHeight: CGFloat = 45
    static let tipRadius: CGFloat = 12

    static let titleColor = UIColor(hexString: "#1F2942")
    static let subtitleColor = UIColor(hexString: "#8591AB")

    static let sectionTitleFont = UIFont.fdFont(ofSize: 20, weight: .medium)
    static let rowTitleFont = UIFont.fdFont(ofSize: 18, weight: .regular)
    static let rowSubtitleFont = UIFont.fdFont(ofSize: 16, weight: .regular)
    static let rowValueFont = rowSubtitleFont
    static let tipFont = rowSubtitleFont
    static let footerFont = rowSubtitleFont

    static let valueColor = subtitleColor
}

enum SettingsIcons {
    static func chevron() -> UIImage? {
        UIImage(named: "order_confirm_arrow_right")
    }

    static func note(size: CGFloat = 14) -> UIImage? {
        guard let image = UIImage(named: "address_note") else { return nil }
        let target = CGSize(width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }

    static func close(size: CGFloat = 12) -> UIImage? {
        guard let image = UIImage(named: "address_close") else { return nil }
        let target = CGSize(width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

enum SettingsDivider {
    static func make() -> UIView {
        let line = UIView()
        line.backgroundColor = .fdBorder
        line.snp.makeConstraints { $0.height.equalTo(1.0 / UIScreen.main.scale) }
        return line
    }
}

// MARK: - Tip banner

final class SettingsTipBannerView: UIView {

    var onClose: (() -> Void)?

    init(message: String) {
        super.init(frame: .zero)
        setupUI(message: message)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI(message: String) {
        backgroundColor = .fdPrimarySoft
        layer.cornerRadius = SettingsStyle.tipRadius
        clipsToBounds = true

        let iconView = UIImageView(image: SettingsIcons.note())
        iconView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = message
        label.font = SettingsStyle.tipFont
        label.textColor = .fdPrimary
        label.numberOfLines = 0

        let closeButton = UIButton(type: .custom)
        closeButton.setImage(SettingsIcons.close(), for: .normal)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        addSubview(iconView)
        addSubview(label)
        addSubview(closeButton)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.equalToSuperview().offset(8)
            make.size.equalTo(14)
        }

        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
            make.size.equalTo(28)
        }

        label.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(6)
            make.trailing.equalTo(closeButton.snp.leading).offset(-4)
            make.top.bottom.equalToSuperview().inset(8)
        }
    }

    @objc private func closeTapped() {
        onClose?()
    }
}

// MARK: - Section card

/// 子设置页分组白卡（隐私 / 协议等），与设置主页 `SettingsSectionCard` 区分
final class SettingsDetailSectionCard: UIView {

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let headerDivider = SettingsDivider.make()
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

    func setHeaderAccessory(_ view: UIView?) {
        subviews.filter { $0.tag == 9_001 }.forEach { $0.removeFromSuperview() }
        guard let view else { return }
        view.tag = 9_001
        addSubview(view)
        view.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(SettingsStyle.cardPadding)
            make.top.equalTo(headerDivider.snp.bottom).offset(12)
        }
        bodyStack.snp.remakeConstraints { make in
            make.top.equalTo(view.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(SettingsStyle.cardPadding)
            make.bottom.equalToSuperview().offset(-SettingsStyle.cardPadding)
        }
    }

    private func setupCard(sectionTitle: String, iconImageName: String) {
        backgroundColor = .fdSurface
        layer.cornerRadius = SettingsStyle.cardRadius
        clipsToBounds = true

        iconView.image = UIImage(named: iconImageName)
        iconView.contentMode = .scaleAspectFit

        titleLabel.text = sectionTitle
        titleLabel.font = SettingsStyle.sectionTitleFont
        titleLabel.textColor = SettingsStyle.titleColor

        bodyStack.axis = .vertical
        bodyStack.spacing = 0

        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(headerDivider)
        addSubview(bodyStack)

        iconView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(SettingsStyle.cardPadding)
            make.size.equalTo(SettingsStyle.sectionIconSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(4)
            make.centerY.equalTo(iconView)
            make.trailing.lessThanOrEqualToSuperview().offset(-SettingsStyle.cardPadding)
        }

        headerDivider.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(9)
            make.leading.trailing.equalToSuperview().inset(SettingsStyle.cardPadding)
        }

        bodyStack.snp.makeConstraints { make in
            make.top.equalTo(headerDivider.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(SettingsStyle.cardPadding)
            make.bottom.equalToSuperview().offset(-SettingsStyle.cardPadding)
        }
    }
}

// MARK: - Permission row

final class SettingsPermissionRow: UIControl {

    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    private let chevronView = UIImageView()
    private let divider = SettingsDivider.make()

    var statusText: String? {
        get { statusLabel.text }
        set { statusLabel.text = newValue }
    }

    init(title: String, status: String, showDivider: Bool, action: @escaping () -> Void) {
        super.init(frame: .zero)
        addAction(UIAction { _ in action() }, for: .touchUpInside)
        setupUI(title: title, status: status, showDivider: showDivider)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI(title: String, status: String, showDivider: Bool) {
        titleLabel.text = title
        titleLabel.font = SettingsStyle.rowTitleFont
        titleLabel.textColor = SettingsStyle.titleColor
        titleLabel.isUserInteractionEnabled = false

        statusLabel.text = status
        statusLabel.font = SettingsStyle.rowValueFont
        statusLabel.textColor = SettingsStyle.valueColor
        statusLabel.textAlignment = .right
        statusLabel.isUserInteractionEnabled = false

        chevronView.image = SettingsIcons.chevron()
        chevronView.contentMode = .scaleAspectFit
        chevronView.isUserInteractionEnabled = false

        divider.isHidden = !showDivider

        addSubview(titleLabel)
        addSubview(statusLabel)
        addSubview(chevronView)
        addSubview(divider)

        chevronView.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(SettingsStyle.chevronSize)
        }

        statusLabel.snp.makeConstraints { make in
            make.trailing.equalTo(chevronView.snp.leading).offset(-2)
            make.centerY.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(statusLabel.snp.leading).offset(-8)
        }

        divider.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }

        snp.makeConstraints { make in
            make.height.equalTo(SettingsStyle.permissionRowHeight)
        }
    }
}

// MARK: - Document row

final class SettingsDocumentRow: UIControl {

    init(title: String, subtitle: String, showDivider: Bool, action: @escaping () -> Void) {
        super.init(frame: .zero)
        addAction(UIAction { _ in action() }, for: .touchUpInside)
        setupUI(title: title, subtitle: subtitle, showDivider: showDivider)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI(title: String, subtitle: String, showDivider: Bool) {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = SettingsStyle.rowTitleFont
        titleLabel.textColor = SettingsStyle.titleColor
        titleLabel.numberOfLines = 0
        titleLabel.isUserInteractionEnabled = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = SettingsStyle.rowSubtitleFont
        subtitleLabel.textColor = SettingsStyle.valueColor
        subtitleLabel.numberOfLines = 2
        subtitleLabel.isUserInteractionEnabled = false

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.isUserInteractionEnabled = false

        let chevronView = UIImageView(image: SettingsIcons.chevron())
        chevronView.contentMode = .scaleAspectFit
        chevronView.isUserInteractionEnabled = false

        let divider = SettingsDivider.make()
        divider.isHidden = !showDivider

        addSubview(textStack)
        addSubview(chevronView)
        addSubview(divider)

        chevronView.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(SettingsStyle.chevronSize)
        }

        textStack.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.lessThanOrEqualTo(chevronView.snp.leading).offset(-8)
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }

        divider.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}

// MARK: - Info row

final class SettingsInfoRow: UIControl {

    init(
        title: String,
        value: String,
        showChevron: Bool,
        showDivider: Bool,
        action: (() -> Void)? = nil
    ) {
        super.init(frame: .zero)
        if let action {
            addAction(UIAction { _ in action() }, for: .touchUpInside)
        } else {
            isUserInteractionEnabled = false
        }
        setupUI(title: title, value: value, showChevron: showChevron, showDivider: showDivider)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI(title: String, value: String, showChevron: Bool, showDivider: Bool) {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = SettingsStyle.rowTitleFont
        titleLabel.textColor = SettingsStyle.titleColor
        titleLabel.isUserInteractionEnabled = false

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = SettingsStyle.rowValueFont
        valueLabel.textColor = SettingsStyle.valueColor
        valueLabel.textAlignment = .right
        valueLabel.isUserInteractionEnabled = false
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let sideStack = UIStackView()
        sideStack.axis = .horizontal
        sideStack.spacing = 2
        sideStack.alignment = .center
        sideStack.isUserInteractionEnabled = false
        sideStack.addArrangedSubview(valueLabel)

        if showChevron {
            let chevronView = UIImageView(image: SettingsIcons.chevron())
            chevronView.contentMode = .scaleAspectFit
            chevronView.snp.makeConstraints { $0.size.equalTo(SettingsStyle.chevronSize) }
            sideStack.addArrangedSubview(chevronView)
        }

        let divider = SettingsDivider.make()
        divider.isHidden = !showDivider

        addSubview(titleLabel)
        addSubview(sideStack)
        addSubview(divider)

        sideStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(sideStack.snp.leading).offset(-8)
        }

        divider.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }

        snp.makeConstraints { make in
            make.height.equalTo(SettingsStyle.permissionRowHeight)
        }
    }
}
