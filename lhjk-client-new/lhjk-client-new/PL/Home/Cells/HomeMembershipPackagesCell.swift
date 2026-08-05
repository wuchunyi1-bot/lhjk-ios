import UIKit
import SnapKit

/// 推荐健康套餐 — 对齐 Figma：白卡内「一主二副」
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
    var onMoreTapped: (() -> Void)?

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdSurface
        v.layer.cornerRadius = 16
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "推荐健康套餐"
        l.font = .fdFont(ofSize: 16, weight: .medium)
        l.textColor = .fdText
        return l
    }()

    private let moreButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("更多套餐 ›", for: .normal)
        b.titleLabel?.font = .fdFont(ofSize: 12, weight: .regular)
        b.setTitleColor(.fdSubtext, for: .normal)
        return b
    }()

    private let mainCard = FeaturedPackageView()
    private let subStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 9
        s.distribution = .fillEqually
        return s
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(moreButton)
        cardView.addSubview(mainCard)
        cardView.addSubview(subStack)

        cardView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(16).priority(750)
            $0.bottom.equalToSuperview()
        }
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(16)
        }
        moreButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(12)
        }
        mainCard.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.height.equalTo(86)
        }
        subStack.snp.makeConstraints {
            $0.top.equalTo(mainCard.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview().inset(16)
            $0.height.equalTo(98)
        }

        moreButton.addTarget(self, action: #selector(moreTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(packages: [Package]) {
        subStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard let first = packages.first else {
            mainCard.isHidden = true
            return
        }
        mainCard.isHidden = false
        mainCard.configure(name: first.name, intro: first.intro, price: first.priceText, badge: first.badge)
        mainCard.onTap = { [weak self] in self?.onPackageTapped?(first.id) }

        for pkg in packages.dropFirst().prefix(2) {
            let card = SubPackageView()
            card.configure(name: pkg.name, intro: pkg.intro, price: pkg.priceText, badge: pkg.badge)
            card.onTap = { [weak self] in self?.onPackageTapped?(pkg.id) }
            subStack.addArrangedSubview(card)
        }
    }

    @objc private func moreTap() { onMoreTapped?() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onPackageTapped = nil
        onMoreTapped = nil
        subStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
}

// MARK: - Featured

private final class FeaturedPackageView: UIControl {
    var onTap: (() -> Void)?

    private let priceSymbol = UILabel()
    private let priceLabel = UILabel()
    private let nameLabel = UILabel()
    private let introLabel = UILabel()
    private let ctaButton = UILabel()
    private let badgeView = UIView()
    private let badgeLabel = UILabel()
    private let divider = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 16
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.fdPrimary.withAlphaComponent(0.3).cgColor
        clipsToBounds = true
        backgroundColor = UIColor(hexString: "#FFF8F5")

        priceSymbol.text = "¥"
        priceSymbol.font = .fdFont(ofSize: 14, weight: .medium)
        priceSymbol.textColor = UIColor(hexString: "#F93838")

        priceLabel.font = .fdFont(ofSize: 24, weight: .medium)
        priceLabel.textColor = UIColor(hexString: "#F93838")

        nameLabel.font = .fdFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = .fdText

        introLabel.font = .fdFont(ofSize: 12, weight: .regular)
        introLabel.textColor = .fdSubtext

        ctaButton.text = "立即了解"
        ctaButton.font = .fdFont(ofSize: 12, weight: .medium)
        ctaButton.textColor = .white
        ctaButton.textAlignment = .center
        ctaButton.backgroundColor = .fdPrimary
        ctaButton.layer.cornerRadius = 14
        ctaButton.clipsToBounds = true

        badgeView.backgroundColor = UIColor(hexString: "#F93838")
        badgeView.layer.cornerRadius = 7
        badgeView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        badgeLabel.font = .fdFont(ofSize: 10, weight: .regular)
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center

        divider.backgroundColor = UIColor.fdPrimary.withAlphaComponent(0.15)

        [priceSymbol, priceLabel, nameLabel, introLabel, ctaButton, badgeView, divider].forEach(addSubview)
        badgeView.addSubview(badgeLabel)

        priceSymbol.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.top.equalToSuperview().offset(38)
        }
        priceLabel.snp.makeConstraints {
            $0.leading.equalTo(priceSymbol.snp.trailing).offset(2)
            $0.bottom.equalTo(priceSymbol).offset(4)
        }
        divider.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(78)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(0.5)
            $0.height.equalTo(48)
        }
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(divider.snp.trailing).offset(12)
            $0.top.equalToSuperview().offset(24)
            $0.trailing.lessThanOrEqualTo(ctaButton.snp.leading).offset(-8)
        }
        introLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(nameLabel.snp.bottom).offset(8)
            $0.trailing.lessThanOrEqualTo(ctaButton.snp.leading).offset(-8)
        }
        ctaButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(70)
            $0.height.equalTo(28)
        }
        badgeView.snp.makeConstraints {
            $0.top.trailing.equalToSuperview()
            $0.height.equalTo(20)
            $0.width.greaterThanOrEqualTo(36)
        }
        badgeLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 3, left: 6, bottom: 3, right: 6))
        }

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(name: String, intro: String, price: String, badge: String?) {
        nameLabel.text = name
        introLabel.text = intro
        let digits = price.replacingOccurrences(of: "¥", with: "").trimmingCharacters(in: .whitespaces)
        priceLabel.text = digits
        if let badge, !badge.isEmpty {
            badgeView.isHidden = false
            badgeLabel.text = badge
        } else {
            badgeView.isHidden = true
        }
    }

    @objc private func handleTap() { onTap?() }
}

// MARK: - Sub

private final class SubPackageView: UIControl {
    var onTap: (() -> Void)?

    private let priceSymbol = UILabel()
    private let priceLabel = UILabel()
    private let nameLabel = UILabel()
    private let introLabel = UILabel()
    private let badgeView = UIView()
    private let badgeLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(hexString: "#FFFAF7")
        layer.cornerRadius = 16
        clipsToBounds = true

        priceSymbol.text = "¥"
        priceSymbol.font = .fdFont(ofSize: 14, weight: .medium)
        priceSymbol.textColor = UIColor(hexString: "#F93838")
        priceLabel.font = .fdFont(ofSize: 20, weight: .medium)
        priceLabel.textColor = UIColor(hexString: "#F93838")
        nameLabel.font = .fdFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 1
        introLabel.font = .fdFont(ofSize: 12, weight: .regular)
        introLabel.textColor = .fdSubtext
        introLabel.numberOfLines = 1

        badgeView.backgroundColor = UIColor(hexString: "#F93838")
        badgeView.layer.cornerRadius = 7
        badgeView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        badgeLabel.font = .fdFont(ofSize: 10, weight: .regular)
        badgeLabel.textColor = .white

        [priceSymbol, priceLabel, nameLabel, introLabel, badgeView].forEach(addSubview)
        badgeView.addSubview(badgeLabel)

        priceSymbol.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.top.equalToSuperview().offset(19)
        }
        priceLabel.snp.makeConstraints {
            $0.leading.equalTo(priceSymbol.snp.trailing).offset(2)
            $0.bottom.equalTo(priceSymbol).offset(3)
        }
        nameLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.top.equalToSuperview().offset(48)
        }
        introLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.top.equalTo(nameLabel.snp.bottom).offset(8)
        }
        badgeView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(18)
            $0.trailing.equalToSuperview()
            $0.height.equalTo(18)
        }
        badgeLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 5, bottom: 2, right: 5))
        }

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(name: String, intro: String, price: String, badge: String?) {
        nameLabel.text = name
        introLabel.text = intro
        priceLabel.text = price.replacingOccurrences(of: "¥", with: "").trimmingCharacters(in: .whitespaces)
        if let badge, !badge.isEmpty {
            badgeView.isHidden = false
            badgeLabel.text = badge
        } else {
            badgeView.isHidden = true
        }
    }

    @objc private func handleTap() { onTap?() }
}
