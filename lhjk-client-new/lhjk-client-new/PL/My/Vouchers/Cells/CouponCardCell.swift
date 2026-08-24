import UIKit
import SnapKit

/// 优惠券票券卡 — 对齐 Figma 3838:32984（343×99 基准等比缩放）
final class CouponCardCell: UITableViewCell {
    static let reuseID = "CouponCardCell"

    var onUse: (() -> Void)?
    var onToggleRules: (() -> Void)?

    /// Figma 375 设计稿下卡片 343×99
    private enum Design {
        static let cardWidth: CGFloat = 343
        static let cardHeight: CGFloat = 99
        static let leftSectionWidth: CGFloat = 98
        static let rightSectionWidth: CGFloat = 46   // 343 - 297
        static let middleLeading: CGFloat = 111
        static let middleToRightGap: CGFloat = 8
        static let middleTop: CGFloat = 16
        static let ribbonWidth: CGFloat = 47
        static let ribbonHeight: CGFloat = 41
        static let ribbonOutsideOffset: CGFloat = -6

        static var aspectRatio: CGFloat { cardHeight / cardWidth }
        static var leftSectionRatio: CGFloat { leftSectionWidth / cardWidth }
        static var rightSectionRatio: CGFloat { rightSectionWidth / cardWidth }
        static var middleLeadingRatio: CGFloat { middleLeading / cardWidth }
        static var leftToMiddleGapRatio: CGFloat { (middleLeading - leftSectionWidth) / cardWidth }
        static var middleToRightGapRatio: CGFloat { middleToRightGap / cardWidth }
        static var middleTopRatio: CGFloat { middleTop / cardHeight }
        static var ribbonWidthRatio: CGFloat { ribbonWidth / cardWidth }
        static var ribbonHeightRatio: CGFloat { ribbonHeight / cardWidth }
    }

    private let card = UIView()

    private let ticketView = UIView()
    private let ticketBgImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let ribbonImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let leftSectionGuide = UILayoutGuide()
    private let leftMiddleGapGuide = UILayoutGuide()
    private let rightGapGuide = UILayoutGuide()
    private let rightSectionGuide = UILayoutGuide()

    private let amountLabel = UILabel()
    private let thresholdLabel = UILabel()

    private let nameLabel = UILabel()
    private let validityLabel = UILabel()
    private let rulesButton = UIButton(type: .custom)
    private let rulesChevron = UIImageView()
    private let rulesStack = UIStackView()

    private let actionButton = UIButton(type: .custom)
    private let actionLabel = UILabel()

    private var ticketBottomToRules: Constraint?
    private var ticketBottomToCard: Constraint?
    private var middleTopConstraint: Constraint?
    private var ribbonTopConstraint: Constraint?
    private var ribbonLeadingConstraint: Constraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .white
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

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
    }

    func configure(_ item: VoucherCouponAsset, expanded: Bool) {
        let isActive = item.status == .received

        ticketBgImageView.image = UIImage(named: isActive ? "coupon_card_bg_active" : "coupon_card_bg_inactive")

        switch item.status {
        case .received:
            ribbonImageView.image = UIImage(named: "coupon_ribbon_active")
        case .used:
            ribbonImageView.image = UIImage(named: "coupon_ribbon_used")
        case .expired:
            ribbonImageView.image = UIImage(named: "coupon_ribbon_expired")
        }

        setAmountAndThreshold(item, isActive: isActive)

        nameLabel.text = item.name
        nameLabel.textColor = isActive ? UIColor(hexString: "#1F2942") : UIColor(hexString: "#8591AB")

        validityLabel.text = item.effectiveEndAt.isEmpty
            ? "有效期至 —"
            : "有效期至 \(item.effectiveEndAt)"

        configureAction(for: item.status)

        let hasRules = item.hasExpandableRules
        rulesButton.isHidden = !hasRules
        let chevronName = expanded ? "chevron.up" : "chevron.down"
        rulesChevron.image = UIImage(systemName: chevronName)?.withRenderingMode(.alwaysTemplate)

        rulesStack.arrangedSubviews.forEach {
            rulesStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        if expanded, hasRules {
            rulesStack.isHidden = false
            ticketBottomToCard?.deactivate()
            ticketBottomToRules?.activate()
            appendRules(for: item)
        } else {
            rulesStack.isHidden = true
            ticketBottomToRules?.deactivate()
            ticketBottomToCard?.activate()
        }
    }

    private func setupUI() {
        card.layer.cornerRadius = 16
        card.clipsToBounds = true
        contentView.addSubview(card)

        card.addSubview(ticketView)
        ticketView.clipsToBounds = true
        ticketView.addSubview(ticketBgImageView)
        ticketView.addSubview(ribbonImageView)
        ticketView.addSubview(actionButton)

        ticketView.addLayoutGuide(leftSectionGuide)
        ticketView.addLayoutGuide(leftMiddleGapGuide)
        ticketView.addLayoutGuide(rightGapGuide)
        ticketView.addLayoutGuide(rightSectionGuide)

        amountLabel.textAlignment = .center
        amountLabel.numberOfLines = 1
        thresholdLabel.font = .fdFont(ofSize: 14, weight: .medium)
        thresholdLabel.textAlignment = .center
        thresholdLabel.adjustsFontSizeToFitWidth = true
        thresholdLabel.minimumScaleFactor = 0.8

        let leftStack = UIStackView(arrangedSubviews: [amountLabel, thresholdLabel])
        leftStack.axis = .vertical
        leftStack.spacing = 4
        leftStack.alignment = .center
        ticketView.addSubview(leftStack)

        nameLabel.font = .fdFont(ofSize: 18, weight: .medium)
        nameLabel.textColor = UIColor(hexString: "#1F2942")
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.numberOfLines = 1

        validityLabel.font = .fdFont(ofSize: 14, weight: .regular)
        validityLabel.textColor = UIColor(hexString: "#8591AB")

        let rulesTitle = UILabel()
        rulesTitle.text = "使用规则"
        rulesTitle.font = .fdFont(ofSize: 14, weight: .regular)
        rulesTitle.textColor = UIColor(hexString: "#8591AB")
        rulesChevron.tintColor = UIColor(hexString: "#8591AB")
        rulesChevron.contentMode = .scaleAspectFit

        let rulesHeader = UIStackView(arrangedSubviews: [rulesTitle, rulesChevron])
        rulesHeader.axis = .horizontal
        rulesHeader.spacing = 2
        rulesHeader.alignment = .center
        rulesHeader.isUserInteractionEnabled = false
        rulesChevron.snp.makeConstraints { $0.size.equalTo(12) }

        rulesButton.addSubview(rulesHeader)
        rulesHeader.snp.makeConstraints { $0.edges.equalToSuperview() }
        rulesButton.addTarget(self, action: #selector(toggleRules), for: .touchUpInside)

        let middleStack = UIStackView(arrangedSubviews: [nameLabel, validityLabel, rulesButton])
        middleStack.axis = .vertical
        middleStack.spacing = 6
        middleStack.alignment = .leading
        ticketView.addSubview(middleStack)

        rulesStack.axis = .vertical
        rulesStack.spacing = 4
        rulesStack.alignment = .leading
        rulesStack.isHidden = true
        card.addSubview(rulesStack)

        actionLabel.numberOfLines = 0
        actionLabel.textAlignment = .center
        actionLabel.isUserInteractionEnabled = false
        actionButton.addSubview(actionLabel)
        actionButton.addTarget(self, action: #selector(useTapped), for: .touchUpInside)

        card.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        ticketView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(ticketView.snp.width).multipliedBy(Design.aspectRatio)
            ticketBottomToCard = make.bottom.equalToSuperview().constraint
            ticketBottomToRules = make.bottom.equalTo(rulesStack.snp.top).offset(-10).constraint
        }
        ticketBottomToRules?.deactivate()

        ticketBgImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        rightSectionGuide.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(Design.rightSectionRatio)
        }

        rightGapGuide.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.trailing.equalTo(rightSectionGuide.snp.leading)
            make.width.equalToSuperview().multipliedBy(Design.middleToRightGapRatio)
        }

        leftSectionGuide.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(Design.leftSectionRatio)
        }

        leftMiddleGapGuide.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalTo(leftSectionGuide.snp.trailing)
            make.width.equalToSuperview().multipliedBy(Design.leftToMiddleGapRatio)
        }

        actionButton.snp.makeConstraints { make in
            make.edges.equalTo(rightSectionGuide)
        }

        actionLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
        }

        leftStack.snp.makeConstraints { make in
            make.center.equalTo(leftSectionGuide)
            make.leading.greaterThanOrEqualTo(leftSectionGuide.snp.leading).offset(2)
            make.trailing.lessThanOrEqualTo(leftSectionGuide.snp.trailing).offset(-2)
        }

        ribbonImageView.snp.makeConstraints { make in
            ribbonTopConstraint = make.top.equalToSuperview().constraint
            ribbonLeadingConstraint = make.leading.equalToSuperview().constraint
            make.width.equalToSuperview().multipliedBy(Design.ribbonWidthRatio)
            make.height.equalTo(ticketView.snp.width).multipliedBy(Design.ribbonHeightRatio)
        }

        middleStack.snp.makeConstraints { make in
            make.leading.equalTo(leftMiddleGapGuide.snp.trailing)
            make.trailing.equalTo(rightGapGuide.snp.leading)
            middleTopConstraint = make.top.equalToSuperview().constraint
            make.bottom.lessThanOrEqualToSuperview()
        }

        rulesStack.snp.makeConstraints { make in
            make.leading.equalTo(middleStack)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(12)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let ticketWidth = ticketView.bounds.width
        middleTopConstraint?.update(offset: ticketView.bounds.height * Design.middleTopRatio)
        let ribbonOffset = ticketWidth * Design.ribbonOutsideOffset / Design.cardWidth
        ribbonTopConstraint?.update(offset: ribbonOffset)
        ribbonLeadingConstraint?.update(offset: ribbonOffset)
    }

    private func configureAction(for status: VoucherCouponStatus) {
        switch status {
        case .received:
            setVerticalActionText("去使用", color: UIColor(hexString: "#FF7A50"), weight: .medium)
            actionButton.isUserInteractionEnabled = true
        case .used:
            setVerticalActionText("已使用", color: UIColor(hexString: "#8591AB"), weight: .regular)
            actionButton.isUserInteractionEnabled = false
        case .expired:
            setVerticalActionText("已过期", color: UIColor(hexString: "#8591AB"), weight: .regular)
            actionButton.isUserInteractionEnabled = false
        }
    }

    private func setVerticalActionText(_ text: String, color: UIColor, weight: UIFont.Weight) {
        let font = UIFont.fdFont(ofSize: 18, weight: weight)
        let attr = NSMutableAttributedString()
        for (index, char) in text.enumerated() {
            if index > 0 {
                attr.append(NSAttributedString(string: "\n"))
            }
            attr.append(NSAttributedString(
                string: String(char),
                attributes: [.font: font, .foregroundColor: color]
            ))
        }
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 1
        style.alignment = .center
        attr.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: attr.length))
        actionLabel.attributedText = attr
    }

    private func setAmountAndThreshold(_ item: VoucherCouponAsset, isActive: Bool) {
        let color = isActive ? UIColor(hexString: "#F93838") : UIColor(hexString: "#8591AB")
        thresholdLabel.textColor = color
        thresholdLabel.text = item.thresholdText

        let text = item.benefitText
        if text.hasPrefix("¥") {
            let num = text.trimmingCharacters(in: CharacterSet(charactersIn: "¥ ")).trimmingCharacters(in: .whitespaces)
            let attr = NSMutableAttributedString(
                string: "¥ ",
                attributes: [.font: UIFont.fdFont(ofSize: 20, weight: .medium), .foregroundColor: color]
            )
            attr.append(NSAttributedString(
                string: num,
                attributes: [.font: UIFont.fdFont(ofSize: 26, weight: .bold), .foregroundColor: color]
            ))
            amountLabel.attributedText = attr
        } else if text.hasSuffix("折") {
            let num = text.replacingOccurrences(of: "折", with: "").trimmingCharacters(in: .whitespaces)
            let attr = NSMutableAttributedString(
                string: num,
                attributes: [.font: UIFont.fdFont(ofSize: 26, weight: .bold), .foregroundColor: color]
            )
            attr.append(NSAttributedString(
                string: " 折",
                attributes: [.font: UIFont.fdFont(ofSize: 20, weight: .medium), .foregroundColor: color]
            ))
            amountLabel.attributedText = attr
        } else {
            amountLabel.attributedText = NSAttributedString(
                string: text,
                attributes: [.font: UIFont.fdFont(ofSize: 26, weight: .bold), .foregroundColor: color]
            )
        }
    }

    private func appendRules(for item: VoucherCouponAsset) {
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

    private func makeRuleLine(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .fdFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(hexString: "#8591AB")
        label.numberOfLines = 0
        return label
    }

    @objc private func useTapped() {
        onUse?()
    }

    @objc private func toggleRules() {
        onToggleRules?()
    }
}
