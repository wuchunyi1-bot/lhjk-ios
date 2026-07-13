import UIKit
import SnapKit

/// 会员卡视图 — 对齐 MeView.vue membership-card 多状态
final class MeMembershipCardView: UIView {

    var onCardTap: (() -> Void)?
    var onPrimaryTap: (() -> Void)?
    var onUpgradeTap: (() -> Void)?
    var onBenefitsTap: (() -> Void)?

    private let brandLabel = UILabel()
    private let typeLabel = UILabel()
    private let benefitLabel = UILabel()
    private let dateLabel = UILabel()
    private let actionsStack = UIStackView()
    private let iconWrap = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 18
        clipsToBounds = true
        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cardTapped)))

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(hexString: "#FF9A6B").cgColor,
            UIColor(hexString: "#FF7A50").cgColor,
            UIColor(hexString: "#F05A3A").cgColor,
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = bounds
        gradient.name = "bg"
        layer.insertSublayer(gradient, at: 0)

        iconWrap.backgroundColor = UIColor.white.withAlphaComponent(0.24)
        iconWrap.layer.cornerRadius = 14
        let icon = UIImageView(image: UIImage(systemName: "crown.fill"))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        iconWrap.addSubview(icon)
        icon.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(14) }

        brandLabel.text = "健康大会员"
        brandLabel.font = .fdBodySemibold
        brandLabel.textColor = .white

        typeLabel.font = .fdMicroSemibold
        typeLabel.textColor = UIColor.white.withAlphaComponent(0.96)
        typeLabel.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        typeLabel.layer.cornerRadius = 999
        typeLabel.clipsToBounds = true
        typeLabel.textAlignment = .center

        benefitLabel.font = .fdCaption
        benefitLabel.textColor = UIColor.white.withAlphaComponent(0.88)
        benefitLabel.numberOfLines = 2

        dateLabel.font = .fdCaption
        dateLabel.textColor = UIColor.white.withAlphaComponent(0.78)

        actionsStack.axis = .horizontal
        actionsStack.spacing = 8
        actionsStack.alignment = .center
        actionsStack.distribution = .fill

        let brandRow = UIStackView(arrangedSubviews: [iconWrap, brandLabel, UIView(), typeLabel])
        brandRow.axis = .horizontal
        brandRow.spacing = 8
        brandRow.alignment = .center

        let content = UIStackView(arrangedSubviews: [benefitLabel, dateLabel])
        content.axis = .vertical
        content.spacing = 3

        let root = UIStackView(arrangedSubviews: [brandRow, content, actionsStack])
        root.axis = .vertical
        root.spacing = 8
        addSubview(root)

        iconWrap.snp.makeConstraints { $0.size.equalTo(28) }
        root.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)) }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(92) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.sublayers?.first(where: { $0.name == "bg" })?.frame = bounds
    }

    func configure(with vm: MyViewModel) {
        let type = vm.membershipTypeText
        typeLabel.isHidden = type.isEmpty
        if !type.isEmpty {
            typeLabel.text = "  \(type)  "
        }

        benefitLabel.text = vm.membershipBenefitText
        let date = vm.membershipDateText
        dateLabel.isHidden = date.isEmpty
        dateLabel.text = date

        actionsStack.arrangedSubviews.forEach {
            actionsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        actionsStack.addArrangedSubview(UIView()) // spacer

        if let primary = vm.membershipPrimaryActionTitle {
            actionsStack.addArrangedSubview(makeButton(title: primary, style: .primary, action: #selector(primaryTapped)))
        }
        if let upgrade = vm.membershipUpgradeTitle {
            actionsStack.addArrangedSubview(makeButton(title: upgrade, style: .soft, action: #selector(upgradeTapped)))
        }
        if vm.showsMembershipBenefitsButton {
            actionsStack.addArrangedSubview(makeButton(title: "我的权益", style: .soft, action: #selector(benefitsTapped)))
        }
    }

    private enum Style { case primary, soft }

    private func makeButton(title: String, style: Style, action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .fdMicroSemibold
        b.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        b.layer.cornerRadius = 14
        b.clipsToBounds = true
        b.snp.makeConstraints { $0.height.equalTo(28) }
        switch style {
        case .primary:
            b.backgroundColor = UIColor.white.withAlphaComponent(0.95)
            b.setTitleColor(.fdPrimary, for: .normal)
        case .soft:
            b.backgroundColor = UIColor.white.withAlphaComponent(0.2)
            b.setTitleColor(.white, for: .normal)
        }
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }

    @objc private func cardTapped() { onCardTap?() }
    @objc private func primaryTapped() { onPrimaryTap?() }
    @objc private func upgradeTapped() { onUpgradeTap?() }
    @objc private func benefitsTapped() { onBenefitsTap?() }
}
