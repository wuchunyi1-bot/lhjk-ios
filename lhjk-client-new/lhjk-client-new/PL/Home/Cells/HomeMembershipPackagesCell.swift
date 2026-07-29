import UIKit
import SnapKit

/// 首页会员健康服务 — 一主二副白卡，对齐 HomeView.vue membership-section
final class HomeMembershipPackagesCell: UITableViewCell {

    static let reuseID = "HomeMembershipPackagesCell"

    struct Package {
        let id: String
        let name: String
        let intro: String
        let priceText: String
        let badge: String?
    }

    var onPackageTapped: ((String) -> Void)?

    private let mainCard = MembershipPackageCardView(style: .main)
    private let subStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 8
        s.distribution = .fillEqually
        return s
    }()

    private var packages: [Package] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .fdBg
        selectionStyle = .none
        contentView.addSubview(mainCard)
        contentView.addSubview(subStack)
        mainCard.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        subStack.snp.makeConstraints {
            $0.top.equalTo(mainCard.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(packages: [Package]) {
        self.packages = packages
        subStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard let first = packages.first else {
            mainCard.isHidden = true
            return
        }
        mainCard.isHidden = false
        mainCard.configure(name: first.name, intro: first.intro, price: first.priceText, badge: first.badge)
        mainCard.onTap = { [weak self] in self?.onPackageTapped?(first.id) }

        for pkg in packages.dropFirst().prefix(2) {
            let card = MembershipPackageCardView(style: .sub)
            card.configure(name: pkg.name, intro: pkg.intro, price: pkg.priceText, badge: pkg.badge)
            card.onTap = { [weak self] in self?.onPackageTapped?(pkg.id) }
            subStack.addArrangedSubview(card)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onPackageTapped = nil
        subStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
}

// MARK: - Card

private final class MembershipPackageCardView: UIControl {

    enum Style { case main, sub }

    var onTap: (() -> Void)?

    private let style: Style
    private let nameLabel = UILabel()
    private let introLabel = UILabel()
    private let priceLabel = UILabel()
    private let unitLabel = UILabel()
    private let badgeLabel = UILabel()

    init(style: Style) {
        self.style = style
        super.init(frame: .zero)
        backgroundColor = .fdSurface
        layer.cornerRadius = 12
        addFundeShadow()
        clipsToBounds = false

        nameLabel.font = style == .main ? .fdBodySemibold : .fdCaptionSemibold
        nameLabel.textColor = .fdText
        nameLabel.lineBreakMode = .byTruncatingTail

        introLabel.font = .fdMicro
        introLabel.textColor = .fdSubtext
        introLabel.lineBreakMode = .byTruncatingTail

        priceLabel.font = .fdFont(ofSize: style == .main ? 18 : 16, weight: .bold)
        priceLabel.textColor = .fdPrimary

        unitLabel.text = "元起"
        unitLabel.font = .fdMicro
        unitLabel.textColor = .fdSubtext

        badgeLabel.font = .fdMicroSemibold
        badgeLabel.textColor = .fdPrimary
        badgeLabel.backgroundColor = .fdPrimarySoft
        badgeLabel.layer.cornerRadius = 999
        badgeLabel.clipsToBounds = true
        badgeLabel.textAlignment = .center

        let footer = UIStackView(arrangedSubviews: [priceLabel, unitLabel])
        footer.axis = .horizontal
        footer.spacing = 4
        footer.alignment = .center

        addSubview(nameLabel)
        addSubview(introLabel)
        addSubview(footer)
        addSubview(badgeLabel)

        let pad: CGFloat = style == .main ? 16 : 12
        nameLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(pad)
            $0.trailing.equalToSuperview().inset(56)
        }
        introLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(pad)
        }
        footer.snp.makeConstraints {
            $0.top.equalTo(introLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().inset(pad)
            $0.bottom.equalToSuperview().inset(pad)
        }
        badgeLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(pad)
            $0.trailing.equalToSuperview().inset(style == .main ? 16 : 8)
            $0.height.equalTo(20)
        }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(88) }

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(name: String, intro: String, price: String, badge: String?) {
        nameLabel.text = name
        introLabel.text = intro
        priceLabel.text = price
        if let badge, !badge.isEmpty {
            badgeLabel.isHidden = false
            badgeLabel.text = "  \(badge)  "
        } else {
            badgeLabel.isHidden = true
        }
    }

    @objc private func handleTap() { onTap?() }
}
