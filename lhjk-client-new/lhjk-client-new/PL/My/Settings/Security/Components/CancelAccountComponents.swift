import UIKit
import SnapKit

// MARK: - Design tokens (Figma 4457:12851)

private enum CancelAccountStyle {
    static let cardRadius: CGFloat = 16
    static let sectionSpacing: CGFloat = 12
    static let titleDescSpacing: CGFloat = 4
    static let cardHorizontalInset: CGFloat = 12
    static let cardVerticalInset: CGFloat = 16
    static let warningFontSize: CGFloat = 16
    static let sectionTitleFontSize: CGFloat = 18
    static let sectionDescFontSize: CGFloat = 16
    static let warningBannerMinHeight: CGFloat = 46
}

// MARK: - Warning banner

/// 顶部警示条 — 对齐 Figma 4457:12915
final class CancelAccountWarningBannerView: UIView {

    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    private func setupUI() {
        layer.cornerRadius = CancelAccountStyle.cardRadius
        clipsToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.cgColor

        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor(hexString: "#FDF6F4").cgColor,
        ]
        gradientLayer.locations = [0.214, 1]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        let iconView = UIImageView(image: UIImage(named: "change_phone_hint_bell"))
        iconView.contentMode = .scaleAspectFit
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)

        let label = UILabel()
        label.text = "注销后，您将放弃以下资产和权益："
        label.font = .fdFont(ofSize: CancelAccountStyle.warningFontSize, weight: .medium)
        label.textColor = .fdPrimary
        label.numberOfLines = 1

        addSubview(iconView)
        addSubview(label)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
            make.size.equalTo(14)
        }

        label.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(4)
            make.trailing.equalToSuperview().offset(-12)
            make.top.bottom.equalToSuperview().inset(11)
        }

        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(CancelAccountStyle.warningBannerMinHeight)
        }
    }
}

// MARK: - Impact list card

/// 权益说明白卡片 — 对齐 Figma 4457:12891
final class CancelAccountImpactListView: UIView {

    private let gradientLayer = CAGradientLayer()
    private let stackView = UIStackView()

    init(items: [(title: String, desc: String)]) {
        super.init(frame: .zero)
        setupUI(items: items)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    private func setupUI(items: [(title: String, desc: String)]) {
        layer.cornerRadius = CancelAccountStyle.cardRadius
        clipsToBounds = true

        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor.white.withAlphaComponent(0).cgColor,
        ]
        gradientLayer.locations = [0.684, 1]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        stackView.axis = .vertical
        stackView.spacing = CancelAccountStyle.sectionSpacing
        addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(
                    top: CancelAccountStyle.cardVerticalInset,
                    left: CancelAccountStyle.cardHorizontalInset,
                    bottom: CancelAccountStyle.cardVerticalInset,
                    right: CancelAccountStyle.cardHorizontalInset
                )
            )
        }

        for (index, item) in items.enumerated() {
            stackView.addArrangedSubview(makeSection(title: item.title, desc: item.desc))
            if index < items.count - 1 {
                stackView.addArrangedSubview(makeDivider())
            }
        }
    }

    private func makeSection(title: String, desc: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .fdFont(ofSize: CancelAccountStyle.sectionTitleFontSize, weight: .regular)
        titleLabel.textColor = SettingsStyle.titleColor
        titleLabel.numberOfLines = 0

        let descLabel = UILabel()
        descLabel.text = desc
        descLabel.font = SettingsStyle.rowSubtitleFont
        descLabel.textColor = SettingsStyle.subtitleColor
        descLabel.numberOfLines = 0

        let section = UIStackView(arrangedSubviews: [titleLabel, descLabel])
        section.axis = .vertical
        section.spacing = CancelAccountStyle.titleDescSpacing
        section.alignment = .fill
        return section
    }

    private func makeDivider() -> UIView {
        let line = UIView()
        line.backgroundColor = .fdBorder
        line.snp.makeConstraints { $0.height.equalTo(1.0 / UIScreen.main.scale) }
        return line
    }
}
