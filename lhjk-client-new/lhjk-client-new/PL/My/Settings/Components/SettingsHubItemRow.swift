import UIKit
import SnapKit

/// 设置分组卡片 — 对齐 Figma 3826:32419
final class SettingsSectionCard: UIView {

    struct Item {
        let title: String
        let subtitle: String
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

    private func setupCard(sectionTitle: String, iconImageName: String, items: [Item]) {
        backgroundColor = .white
        layer.cornerRadius = 16
        clipsToBounds = true

        iconView.image = UIImage(named: iconImageName)
        iconView.contentMode = .scaleAspectFit

        titleLabel.text = sectionTitle
        titleLabel.font = .fdFont(ofSize: 20, weight: .medium)
        titleLabel.textColor = UIColor(hexString: "#1F2942")

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
    private let arrowView = UIImageView()
    private let divider = UIView()

    var descText: String? {
        get { descLabel.text }
        set { descLabel.text = newValue }
    }

    init(
        title: String,
        desc: String,
        showDivider: Bool,
        action: @escaping () -> Void
    ) {
        super.init(frame: .zero)
        addAction(UIAction { _ in action() }, for: .touchUpInside)
        setupUI(title: title, desc: desc, showDivider: showDivider)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI(title: String, desc: String, showDivider: Bool) {
        titleLabel.text = title
        titleLabel.font = .fdFont(ofSize: 18, weight: .regular)
        titleLabel.textColor = UIColor(hexString: "#1F2942")
        titleLabel.isUserInteractionEnabled = false

        descLabel.text = desc
        descLabel.font = .fdFont(ofSize: 16, weight: .regular)
        descLabel.textColor = UIColor(hexString: "#8591AB")
        descLabel.numberOfLines = 2
        descLabel.isUserInteractionEnabled = false

        arrowView.image = UIImage(named: "settings_chevron")
        arrowView.contentMode = .scaleAspectFit
        arrowView.isUserInteractionEnabled = false

        divider.backgroundColor = UIColor(hexString: "#F0F2F5")
        divider.isHidden = !showDivider

        let textStack = UIStackView(arrangedSubviews: [titleLabel, descLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading
        textStack.isUserInteractionEnabled = false

        addSubview(textStack)
        addSubview(arrowView)
        addSubview(divider)

        arrowView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.size.equalTo(12)
        }

        textStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalTo(arrowView.snp.leading).offset(-8)
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

/// 退出登录行 — 对齐 Figma 3826:32432
final class SettingsLogoutRow: UIControl {

    private let titleLabel = UILabel()
    private let arrowView = UIImageView()

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
        titleLabel.font = .fdFont(ofSize: 18, weight: .regular)
        titleLabel.textColor = UIColor(hexString: "#1F2942")
        titleLabel.isUserInteractionEnabled = false

        arrowView.image = UIImage(named: "settings_chevron")
        arrowView.contentMode = .scaleAspectFit
        arrowView.isUserInteractionEnabled = false

        addSubview(titleLabel)
        addSubview(arrowView)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
        }

        arrowView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.size.equalTo(12)
        }

        snp.makeConstraints { make in
            make.height.equalTo(45)
        }
    }
}
