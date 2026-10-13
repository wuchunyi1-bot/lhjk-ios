import UIKit
import SnapKit

/// 设置分组卡片 — 对齐 Figma 3826:32419
final class SettingsSectionCard: UIView {

    struct Item {
        let title: String
        let subtitle: String
        /// 箭头左侧状态，如「未开启」
        var trailing: String? = nil
        var action: (() -> Void)?
    }

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let headerDivider = UIView()
    private let itemsStack = UIStackView()

    init(sectionTitle: String, iconImageName: String, items: [Item]) {
        super.init(frame: .zero)
        setupCard(sectionTitle: sectionTitle, iconImageName: iconImageName, items: items)
    }

    required init?(coder: NSCoder) { fatalError() }

    func updateSubtitle(at index: Int, text: String) {
        guard index >= 0, index < itemsStack.arrangedSubviews.count else { return }
        (itemsStack.arrangedSubviews[index] as? SettingsHubItemRow)?.descText = text
    }

    func updateTrailing(at index: Int, text: String) {
        guard index >= 0, index < itemsStack.arrangedSubviews.count else { return }
        (itemsStack.arrangedSubviews[index] as? SettingsHubItemRow)?.trailingText = text
    }

    private func setupCard(sectionTitle: String, iconImageName: String, items: [Item]) {
        backgroundColor = .white
        layer.cornerRadius = 16
        clipsToBounds = true

        iconView.image = UIImage(named: iconImageName)
        iconView.contentMode = .scaleAspectFit

        titleLabel.text = sectionTitle
        titleLabel.font = SettingsStyle.sectionTitleFont
        titleLabel.textColor = SettingsStyle.titleColor

        headerDivider.backgroundColor = UIColor(hexString: "#F0F2F5")

        itemsStack.axis = .vertical
        itemsStack.spacing = 0

        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(headerDivider)
        addSubview(itemsStack)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.equalToSuperview().offset(19)
            make.size.equalTo(18)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(34)
            make.centerY.equalTo(iconView)
            make.trailing.lessThanOrEqualToSuperview().offset(-12)
        }

        headerDivider.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(52)
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(0.5)
        }

        itemsStack.snp.makeConstraints { make in
            make.top.equalTo(headerDivider.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        for (index, item) in items.enumerated() {
            let row = SettingsHubItemRow(
                title: item.title,
                desc: item.subtitle,
                trailing: item.trailing,
                showDivider: index < items.count - 1,
                action: item.action ?? {}
            )
            itemsStack.addArrangedSubview(row)
        }
    }
}

/// 设置列表行 — 对齐 Figma 3826:32421
final class SettingsHubItemRow: UIControl {

    private let titleLabel = UILabel()
    private let descLabel = UILabel()
    private let trailingLabel = UILabel()
    private let arrowView = UIImageView()
    private let divider = UIView()

    var descText: String? {
        get { descLabel.text }
        set { descLabel.text = newValue }
    }

    var trailingText: String? {
        get { trailingLabel.text }
        set { trailingLabel.text = newValue }
    }

    init(
        title: String,
        desc: String,
        trailing: String? = nil,
        showDivider: Bool,
        action: @escaping () -> Void
    ) {
        super.init(frame: .zero)
        addAction(UIAction { _ in action() }, for: .touchUpInside)
        setupUI(title: title, desc: desc, trailing: trailing, showDivider: showDivider)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI(title: String, desc: String, trailing: String?, showDivider: Bool) {
        titleLabel.text = title
        titleLabel.font = SettingsStyle.rowTitleFont
        titleLabel.textColor = SettingsStyle.titleColor
        titleLabel.isUserInteractionEnabled = false

        descLabel.text = desc
        descLabel.font = SettingsStyle.rowSubtitleFont
        descLabel.textColor = SettingsStyle.subtitleColor
        descLabel.numberOfLines = 2
        descLabel.isUserInteractionEnabled = false

        trailingLabel.text = trailing
        trailingLabel.font = SettingsStyle.rowValueFont
        trailingLabel.textColor = SettingsStyle.subtitleColor
        trailingLabel.isHidden = trailing == nil
        trailingLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        trailingLabel.isUserInteractionEnabled = false

        arrowView.image = UIImage(named: "order_confirm_arrow_right")
        arrowView.contentMode = .scaleAspectFit
        arrowView.isUserInteractionEnabled = false

        divider.backgroundColor = UIColor(hexString: "#F0F2F5")
        divider.isHidden = !showDivider

        let textStack = UIStackView(arrangedSubviews: [titleLabel, descLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading
        textStack.isUserInteractionEnabled = false

        let sideStack = UIStackView(arrangedSubviews: trailing == nil ? [arrowView] : [trailingLabel, arrowView])
        sideStack.axis = .horizontal
        sideStack.spacing = 4
        sideStack.alignment = .center
        sideStack.isUserInteractionEnabled = false

        addSubview(textStack)
        addSubview(sideStack)
        addSubview(divider)

        arrowView.snp.makeConstraints { make in
            make.size.equalTo(12)
        }

        sideStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }

        textStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalTo(sideStack.snp.leading).offset(-8)
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }

        divider.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }

        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(57)
        }
    }
}

/// 退出登录行 — 居中、无箭头；字号与上方列表行标题一致（18pt）
final class SettingsLogoutRow: UIControl {

    private let titleLabel = UILabel()

    init(action: @escaping () -> Void) {
        super.init(frame: .zero)
        addAction(UIAction { _ in action() }, for: .touchUpInside)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 12
        clipsToBounds = true

        titleLabel.text = "退出登录"
        titleLabel.font = SettingsStyle.rowTitleFont
        titleLabel.textColor = SettingsStyle.titleColor
        titleLabel.textAlignment = .center
        titleLabel.isUserInteractionEnabled = false

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(12)
        }

        snp.makeConstraints { make in
            make.height.equalTo(45)
        }
    }
}
