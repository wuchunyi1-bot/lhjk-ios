import UIKit
import SnapKit

/// 优惠券票券卡 — 对齐 funde `.coupon-card`
final class CouponCardCell: UITableViewCell {
    static let reuseID = "CouponCardCell"

    var onUse: (() -> Void)?
    var onToggleRules: (() -> Void)?

    private let card = UIView()
    private let statusBadge = UILabel()
    private let amountLabel = UILabel()
    private let thresholdLabel = UILabel()
    private let nameLabel = UILabel()
    private let validityLabel = UILabel()
    private let rulesButton = UIButton(type: .system)
    private let rulesStack = UIStackView()
    private let useButton = UIButton(type: .system)
    private let dashLayer = CAShapeLayer()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .fdBg
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 96, y: 8))
        path.addLine(to: CGPoint(x: 96, y: max(8, card.bounds.height - 8)))
        dashLayer.path = path.cgPath
        dashLayer.frame = card.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onUse = nil
        onToggleRules = nil
        rulesStack.arrangedSubviews.forEach {
            rulesStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        rulesStack.isHidden = true
        rulesButton.isHidden = false
        card.alpha = 1
        card.backgroundColor = .fdSurface
        card.layer.borderColor = UIColor.fdPrimaryEdge.cgColor
    }

    func configure(_ item: VoucherCouponAsset, expanded: Bool) {
        amountLabel.text = item.benefitText
        thresholdLabel.text = item.thresholdText
        nameLabel.text = item.name
        validityLabel.text = item.effectiveEndAt.isEmpty
            ? "有效期至 —"
            : "有效期至 \(item.effectiveEndAt)"
        statusBadge.text = " \(item.status.displayLabel) "
        useButton.isHidden = item.status != .received

        switch item.status {
        case .received:
            statusBadge.backgroundColor = .fdPrimary
            card.alpha = 1
            card.backgroundColor = .fdSurface
            card.layer.borderColor = UIColor.fdPrimaryEdge.cgColor
        case .used:
            statusBadge.backgroundColor = .fdSuccess
            card.alpha = 1
            card.backgroundColor = .fdSurface
            card.layer.borderColor = UIColor.fdPrimaryEdge.cgColor
        case .expired:
            statusBadge.backgroundColor = .fdMuted
            card.alpha = 0.72
            card.backgroundColor = .fdBg2
            card.layer.borderColor = UIColor.fdBorder.cgColor
        }

        let hasRules = item.hasExpandableRules
        rulesButton.isHidden = !hasRules
        let chevron = expanded ? "chevron.up" : "chevron.down"
        rulesButton.setImage(UIImage(systemName: chevron), for: .normal)
        rulesButton.setTitle("使用规则 ", for: .normal)

        rulesStack.arrangedSubviews.forEach {
            rulesStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        rulesStack.isHidden = !expanded || !hasRules
        if expanded, hasRules {
            // 标题对齐 Apifox：rule 仅影响业务/套餐；机构与排除商品标题固定
            if !item.businessCategories.isEmpty {
                rulesStack.addArrangedSubview(
                    makeRuleLine("\(item.scopeRule.prefix)业务：\(item.businessCategories.joined(separator: "、"))")
                )
            }
            if !item.packageNames.isEmpty {
                rulesStack.addArrangedSubview(
                    makeRuleLine("\(item.scopeRule.prefix)套餐：\(item.packageNames.joined(separator: "、"))")
                )
            }
            if !item.institutionNames.isEmpty {
                rulesStack.addArrangedSubview(
                    makeRuleLine("适用机构：\(item.institutionNames.joined(separator: "、"))")
                )
            }
            if !item.excludedProductNames.isEmpty {
                rulesStack.addArrangedSubview(
                    makeRuleLine("不参与折扣的商品：\(item.excludedProductNames.joined(separator: "、"))")
                )
            }
            if let desc = item.ruleDescription, !desc.isEmpty {
                rulesStack.addArrangedSubview(makeRuleLine(desc))
            }
        }
        setNeedsLayout()
    }

    private func setupUI() {
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 14
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.fdPrimaryEdge.cgColor
        card.clipsToBounds = true
        contentView.addSubview(card)

        dashLayer.strokeColor = UIColor.fdPrimaryEdge.cgColor
        dashLayer.lineWidth = 1
        dashLayer.lineDashPattern = [4, 3]
        dashLayer.fillColor = nil
        card.layer.addSublayer(dashLayer)

        statusBadge.font = .fdMicroBold
        statusBadge.textColor = .white
        statusBadge.clipsToBounds = true
        statusBadge.layer.cornerRadius = 6
        statusBadge.layer.maskedCorners = [.layerMaxXMaxYCorner]

        amountLabel.font = .fdNumM
        amountLabel.textColor = .fdPrimary
        amountLabel.textAlignment = .center
        thresholdLabel.font = .fdMicroSemibold
        thresholdLabel.textColor = .fdPrimary
        thresholdLabel.textAlignment = .center
        thresholdLabel.adjustsFontSizeToFitWidth = true

        let left = UIStackView(arrangedSubviews: [amountLabel, thresholdLabel])
        left.axis = .vertical
        left.spacing = 4
        left.alignment = .center

        nameLabel.font = .fdBodyBold
        nameLabel.textColor = .fdText
        nameLabel.lineBreakMode = .byTruncatingTail
        validityLabel.font = .fdMicro
        validityLabel.textColor = .fdSubtext

        rulesButton.titleLabel?.font = .fdMicro
        rulesButton.setTitleColor(.fdSubtext, for: .normal)
        rulesButton.tintColor = .fdSubtext
        rulesButton.semanticContentAttribute = .forceRightToLeft
        rulesButton.contentHorizontalAlignment = .leading
        rulesButton.addTarget(self, action: #selector(toggleRules), for: .touchUpInside)

        rulesStack.axis = .vertical
        rulesStack.spacing = 4
        rulesStack.isHidden = true

        let body = UIStackView(arrangedSubviews: [nameLabel, validityLabel, rulesButton, rulesStack])
        body.axis = .vertical
        body.spacing = 2
        body.alignment = .leading
        body.setCustomSpacing(4, after: rulesButton)

        useButton.setTitle("去使用", for: .normal)
        useButton.titleLabel?.font = .fdCaptionSemibold
        useButton.setTitleColor(.white, for: .normal)
        useButton.backgroundColor = .fdPrimary
        useButton.layer.cornerRadius = 16
        useButton.addTarget(self, action: #selector(useTapped), for: .touchUpInside)

        card.addSubview(statusBadge)
        card.addSubview(left)
        card.addSubview(body)
        card.addSubview(useButton)

        card.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        statusBadge.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.height.equalTo(18)
        }
        left.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(22)
            make.width.equalTo(96)
            make.bottom.lessThanOrEqualToSuperview().inset(12)
        }
        body.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(108)
            make.trailing.equalToSuperview().inset(80)
            make.top.equalToSuperview().offset(14)
            make.bottom.equalToSuperview().inset(12)
        }
        useButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().inset(12)
            make.height.equalTo(32)
            make.width.greaterThanOrEqualTo(58)
        }
    }

    private func makeRuleLine(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .fdMicro
        l.textColor = .fdSubtext
        l.numberOfLines = 0
        return l
    }

    @objc private func useTapped() { onUse?() }
    @objc private func toggleRules() { onToggleRules?() }
}
