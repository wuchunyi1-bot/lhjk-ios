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
        /// 相对票券左上角的偏移（正值向右下，略压住圆角呈包裹感）
        static let ribbonTopOffset: CGFloat = -5
        static let ribbonLeadingOffset: CGFloat = -4

        static var aspectRatio: CGFloat { cardHeight / cardWidth }
        static var leftSectionRatio: CGFloat { leftSectionWidth / cardWidth }
        static var rightSectionRatio: CGFloat { rightSectionWidth / cardWidth }
        static var middleLeadingRatio: CGFloat { middleLeading / cardWidth }
        static var leftToMiddleGapRatio: CGFloat { (middleLeading - leftSectionWidth) / cardWidth }
        static var middleToRightGapRatio: CGFloat { middleToRightGap / cardWidth }
        static var middleTopRatio: CGFloat { middleTop / cardHeight }
        static var ribbonWidthRatio: CGFloat { ribbonWidth / cardWidth }
        static var ribbonHeightRatio: CGFloat { ribbonHeight / cardWidth }

        static let contentVerticalInset: CGFloat = 12
        static let contentHorizontalInset: CGFloat = 32
        /// 「使用规则」标题与虚线分隔、规则文案之间的间距
        static let rulesDividerTopSpacing: CGFloat = 8
        static let rulesDividerHeight: CGFloat = 1
        static let rulesDividerBottomSpacing: CGFloat = 8
        static let rulesBottomInset: CGFloat = 12
        static let rulesLineSpacing: CGFloat = 4

        /// Figma 3888:36154 — 待使用展开规则：首行 #FF7A50 Medium，其余 rgba(255,122,80,0.8)
        static let rulesActiveSecondaryAlpha: CGFloat = 0.8

        static var rulesExpandedVerticalPadding: CGFloat {
            rulesDividerTopSpacing + rulesDividerHeight + rulesDividerBottomSpacing
        }

        /// 票券底图九宫格保护区（pt，设计稿 343×99）— 作用于「先等比栅格化」后的位图，再仅纵向拉伸中间
        static let bgCapTop: CGFloat = 20
        static let bgCapLeft: CGFloat = 111
        static let bgCapBottom: CGFloat = 20
        static let bgCapRight: CGFloat = 46
    }

    /// 列表行高（与内部约束一致，避免 automaticDimension 与比例高度冲突）
    static func rowHeight(
        for tableWidth: CGFloat,
        item: VoucherCouponAsset,
        expanded: Bool
    ) -> CGFloat {
        let base = collapsedRowHeight(for: tableWidth)
        guard expanded, item.hasExpandableRules else { return base }
        let cardWidth = contentCardWidth(for: tableWidth)
        return base + Design.rulesExpandedVerticalPadding + rulesContentHeight(for: item, cardWidth: cardWidth) + Design.rulesBottomInset
    }

    static func collapsedRowHeight(for tableWidth: CGFloat) -> CGFloat {
        Design.contentVerticalInset + ticketHeight(for: tableWidth)
    }

    private static func contentCardWidth(for tableWidth: CGFloat) -> CGFloat {
        max(0, tableWidth - Design.contentHorizontalInset)
    }

    private static func ticketHeight(for tableWidth: CGFloat) -> CGFloat {
        contentCardWidth(for: tableWidth) * Design.aspectRatio
    }

    private static func rulesContentHeight(for item: VoucherCouponAsset, cardWidth: CGFloat) -> CGFloat {
        let rulesWidth = cardWidth * (1 - Design.middleLeadingRatio - Design.middleToRightGapRatio - Design.rightSectionRatio)
        let font = UIFont.fdFont(ofSize: 13, weight: .regular)
        let lines = ruleLines(for: item)
        guard !lines.isEmpty else { return 0 }

        var total: CGFloat = 0
        for text in lines {
            let height = (text as NSString).boundingRect(
                with: CGSize(width: rulesWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil
            ).height
            total += ceil(height)
        }
        total += CGFloat(max(0, lines.count - 1)) * Design.rulesLineSpacing
        return total
    }

    private static func ruleLines(for item: VoucherCouponAsset) -> [String] {
        var lines: [String] = []
        if !item.businessCategories.isEmpty {
            lines.append("\(item.scopeRule.prefix)业务：\(item.businessCategories.joined(separator: "、"))")
        }
        if !item.packageNames.isEmpty {
            lines.append("\(item.scopeRule.prefix)套餐：\(item.packageNames.joined(separator: "、"))")
        }
        if !item.institutionNames.isEmpty {
            lines.append("适用机构：\(item.institutionNames.joined(separator: "、"))")
        }
        if !item.excludedProductNames.isEmpty {
            lines.append("不参与折扣的商品：\(item.excludedProductNames.joined(separator: "、"))")
        }
        if let desc = item.ruleDescription, !desc.isEmpty {
            lines.append(desc)
        }
        return lines
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
    private let rulesDividerView = HorizontalDashedLineView()
    private let rulesStack = UIStackView()

    private let actionButton = UIButton(type: .custom)
    private let actionLabel = UILabel()

    private var ticketHeightConstraint: Constraint?
    private var ticketBottomConstraint: Constraint?
    private var rulesStackTopConstraint: Constraint?
    private var rulesStackCollapsedHeightConstraint: Constraint?
    private var rulesDividerTopConstraint: Constraint?
    private var rulesDividerHeightConstraint: Constraint?
    private var middleTopConstraint: Constraint?
    private var ribbonTopConstraint: Constraint?
    private var ribbonLeadingConstraint: Constraint?
    private var lastRibbonLayoutWidth: CGFloat = 0
    private var lastTicketBgLayoutWidth: CGFloat = 0
    private var displayedRibbonName: String?
    private var ticketBackgroundName: String?
    private var ticketBgVerticallyStretched = false
    private var rulesContentIsActive = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .white
        contentView.clipsToBounds = false
        clipsToBounds = false
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onUse = nil
        onToggleRules = nil
        displayedRibbonName = nil
        lastRibbonLayoutWidth = 0
        lastTicketBgLayoutWidth = 0
        ticketBgVerticallyStretched = false
        rulesStack.arrangedSubviews.forEach {
            rulesStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        rulesStack.isHidden = true
        rulesButton.isHidden = false
        rulesDividerView.isHidden = true
        rulesDividerTopConstraint?.deactivate()
        rulesDividerHeightConstraint?.update(offset: 0)
        rulesStackTopConstraint?.deactivate()
        rulesStackCollapsedHeightConstraint?.activate()
        ticketHeightConstraint?.activate()
        ticketBottomConstraint?.deactivate()
    }

    func configure(_ item: VoucherCouponAsset, expanded: Bool) {
        let isActive = item.status == .received
        let hasRules = item.hasExpandableRules

        switch item.status {
        case .received:
            setRibbonImage(named: "coupon_ribbon_active")
        case .used:
            setRibbonImage(named: "coupon_ribbon_used")
        case .expired:
            setRibbonImage(named: "coupon_ribbon_expired")
        }

        setAmountAndThreshold(item, isActive: isActive)

        nameLabel.text = item.name
        nameLabel.textColor = isActive ? UIColor(hexString: "#1F2942") : UIColor(hexString: "#8591AB")

        validityLabel.text = item.effectiveEndAt.isEmpty
            ? "有效期至 —"
            : "有效期至 \(item.effectiveEndAt)"

        configureAction(for: item.status)

        applyTicketBackground(isActive: isActive, verticallyStretched: expanded && hasRules)

        rulesButton.isHidden = !hasRules
        updateRulesChevron(expanded: expanded)

        rulesStack.arrangedSubviews.forEach {
            rulesStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        if expanded, hasRules {
            rulesContentIsActive = isActive
            updateRulesDividerStyle(isActive: isActive)
            rulesDividerView.isHidden = false
            rulesDividerTopConstraint?.activate()
            rulesDividerHeightConstraint?.update(offset: Design.rulesDividerHeight)
            rulesStack.isHidden = false
            rulesStackTopConstraint?.activate()
            rulesStackCollapsedHeightConstraint?.deactivate()
            ticketHeightConstraint?.deactivate()
            ticketBottomConstraint?.activate()
            appendRules(for: item)
        } else {
            rulesContentIsActive = false
            rulesDividerView.isHidden = true
            rulesDividerTopConstraint?.deactivate()
            rulesDividerHeightConstraint?.update(offset: 0)
            rulesStack.isHidden = true
            rulesStackTopConstraint?.deactivate()
            rulesStackCollapsedHeightConstraint?.activate()
            ticketBottomConstraint?.deactivate()
            ticketHeightConstraint?.activate()
        }
        setNeedsLayout()
    }

    private func applyTicketBackground(isActive: Bool, verticallyStretched: Bool) {
        let name = isActive ? "coupon_card_bg_active" : "coupon_card_bg_inactive"
        ticketBackgroundName = name
        ticketBgVerticallyStretched = verticallyStretched

        guard UIImage(named: name) != nil else {
            ticketBgImageView.image = nil
            return
        }

        if verticallyStretched {
            ticketBgImageView.contentMode = .scaleToFill
            lastTicketBgLayoutWidth = 0
            updateStretchedTicketBackgroundIfNeeded()
        } else {
            ticketBgImageView.image = UIImage(named: name)
            ticketBgImageView.contentMode = .scaleAspectFill
            lastTicketBgLayoutWidth = 0
        }
    }

    /// 展开态底图：先按收起态尺寸等比栅格化，再仅纵向九宫格拉伸（cap 与栅格图同比例）
    private func updateStretchedTicketBackgroundIfNeeded() {
        guard ticketBgVerticallyStretched,
              let name = ticketBackgroundName,
              let sourceImage = UIImage(named: name) else { return }

        let ticketWidth = ticketView.bounds.width
        guard ticketWidth > 0 else { return }
        guard abs(ticketWidth - lastTicketBgLayoutWidth) > 0.5 else { return }
        lastTicketBgLayoutWidth = ticketWidth

        let scale = ticketWidth / Design.cardWidth
        let collapsedHeight = ticketWidth * Design.aspectRatio
        let scaledSize = CGSize(width: ticketWidth, height: collapsedHeight)

        let format = UIGraphicsImageRendererFormat()
        format.scale = sourceImage.scale
        let renderer = UIGraphicsImageRenderer(size: scaledSize, format: format)
        let horizontallyScaledImage = renderer.image { _ in
            sourceImage.draw(in: CGRect(origin: .zero, size: scaledSize))
        }

        let caps = UIEdgeInsets(
            top: Design.bgCapTop * scale,
            left: Design.bgCapLeft * scale,
            bottom: Design.bgCapBottom * scale,
            right: Design.bgCapRight * scale
        )
        ticketBgImageView.image = horizontallyScaledImage.resizableImage(withCapInsets: caps, resizingMode: .stretch)
        ticketBgImageView.contentMode = .scaleToFill
    }

    private func setupUI() {
        card.layer.cornerRadius = 16
        card.clipsToBounds = false
        contentView.addSubview(card)

        card.addSubview(ticketView)
        ticketView.clipsToBounds = true
        ticketView.addSubview(ticketBgImageView)
        card.addSubview(ribbonImageView)
        ribbonImageView.layer.zPosition = 10
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
        rulesChevron.contentMode = .scaleAspectFit
        rulesChevron.setContentHuggingPriority(.required, for: .horizontal)
        rulesChevron.setContentCompressionResistancePriority(.required, for: .horizontal)

        let rulesHeader = UIStackView(arrangedSubviews: [rulesTitle, rulesChevron])
        rulesHeader.axis = .horizontal
        rulesHeader.spacing = 4
        rulesHeader.alignment = .center
        rulesHeader.isUserInteractionEnabled = false
        rulesChevron.snp.makeConstraints { $0.size.equalTo(14) }

        rulesButton.addSubview(rulesHeader)
        rulesHeader.snp.makeConstraints { $0.edges.equalToSuperview() }
        rulesButton.contentHorizontalAlignment = .leading
        rulesButton.addTarget(self, action: #selector(toggleRules), for: .touchUpInside)

        let middleStack = UIStackView(arrangedSubviews: [nameLabel, validityLabel, rulesButton])
        middleStack.axis = .vertical
        middleStack.spacing = 6
        middleStack.alignment = .leading
        ticketView.addSubview(middleStack)
        rulesButton.snp.makeConstraints { $0.height.equalTo(20) }

        rulesStack.axis = .vertical
        rulesStack.spacing = Design.rulesLineSpacing
        rulesStack.alignment = .leading
        rulesStack.isHidden = true
        ticketView.addSubview(rulesDividerView)
        ticketView.addSubview(rulesStack)

        actionLabel.numberOfLines = 0
        actionLabel.textAlignment = .center
        actionLabel.isUserInteractionEnabled = false
        actionButton.addSubview(actionLabel)
        actionButton.addTarget(self, action: #selector(useTapped), for: .touchUpInside)

        card.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-6)
        }

        ticketView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            ticketHeightConstraint = make.height.equalTo(Design.cardHeight).constraint
            ticketBottomConstraint = make.bottom.equalToSuperview().constraint
        }
        ticketBottomConstraint?.deactivate()

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
            ribbonTopConstraint = make.top.equalTo(ticketView.snp.top).constraint
            ribbonLeadingConstraint = make.leading.equalTo(ticketView.snp.leading).constraint
            make.width.equalTo(ticketView.snp.width).multipliedBy(Design.ribbonWidthRatio)
            make.height.equalTo(ticketView.snp.width).multipliedBy(Design.ribbonHeightRatio)
        }

        middleStack.snp.makeConstraints { make in
            make.leading.equalTo(leftMiddleGapGuide.snp.trailing)
            make.trailing.equalTo(rightGapGuide.snp.leading)
            middleTopConstraint = make.top.equalToSuperview().constraint
            make.bottom.lessThanOrEqualToSuperview()
        }

        rulesDividerView.isHidden = true
        rulesDividerView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(middleStack)
            rulesDividerTopConstraint = make.top.equalTo(middleStack.snp.bottom)
                .offset(Design.rulesDividerTopSpacing).constraint
            rulesDividerHeightConstraint = make.height.equalTo(0).constraint
        }
        rulesDividerTopConstraint?.deactivate()

        rulesStack.snp.makeConstraints { make in
            make.leading.equalTo(middleStack)
            make.trailing.equalTo(rightGapGuide.snp.leading)
            make.bottom.equalToSuperview().inset(Design.rulesBottomInset)
            rulesStackTopConstraint = make.top.equalTo(rulesDividerView.snp.bottom)
                .offset(Design.rulesDividerBottomSpacing).constraint
            rulesStackCollapsedHeightConstraint = make.height.equalTo(0).constraint
        }
        rulesStackTopConstraint?.deactivate()
    }

    private func updateTicketHeightIfNeeded() {
        guard rulesStack.isHidden, card.bounds.width > 0 else { return }
        let cardWidth = card.bounds.width
        ticketHeightConstraint?.update(offset: cardWidth * Design.aspectRatio)
    }

    private func setRibbonImage(named name: String) {
        guard displayedRibbonName != name else { return }
        displayedRibbonName = name
        ribbonImageView.image = UIImage(named: name)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateTicketHeightIfNeeded()
        updateStretchedTicketBackgroundIfNeeded()

        let ticketWidth = ticketView.bounds.width
        guard ticketWidth > 0 else { return }
        let scale = ticketWidth / Design.cardWidth
        middleTopConstraint?.update(offset: Design.middleTop * scale)
        guard abs(ticketWidth - lastRibbonLayoutWidth) > 0.5 else { return }
        lastRibbonLayoutWidth = ticketWidth
        ribbonTopConstraint?.update(offset: Design.ribbonTopOffset * scale)
        ribbonLeadingConstraint?.update(offset: Design.ribbonLeadingOffset * scale)
    }

    private func updateRulesChevron(expanded: Bool) {
        let color = UIColor(hexString: "#8591AB")
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        let symbolName = expanded ? "chevron.up" : "chevron.down"
        rulesChevron.image = UIImage(systemName: symbolName, withConfiguration: config)?
            .withTintColor(color, renderingMode: .alwaysOriginal)
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

    private func updateRulesDividerStyle(isActive: Bool) {
        if isActive {
            rulesDividerView.strokeColor = UIColor.fdPrimary.withAlphaComponent(Design.rulesActiveSecondaryAlpha)
        } else {
            rulesDividerView.strokeColor = UIColor(hexString: "#8591AB").withAlphaComponent(0.4)
        }
        rulesDividerView.setNeedsLayout()
    }

    private func appendRules(for item: VoucherCouponAsset) {
        var isFirstLine = true

        func addLine(_ text: String) {
            rulesStack.addArrangedSubview(makeRuleLine(text, isFirst: isFirstLine))
            isFirstLine = false
        }

        if !item.businessCategories.isEmpty {
            addLine("\(item.scopeRule.prefix)业务：\(item.businessCategories.joined(separator: "、"))")
        }
        if !item.packageNames.isEmpty {
            addLine("\(item.scopeRule.prefix)套餐：\(item.packageNames.joined(separator: "、"))")
        }
        if !item.institutionNames.isEmpty {
            addLine("适用机构：\(item.institutionNames.joined(separator: "、"))")
        }
        if !item.excludedProductNames.isEmpty {
            addLine("不参与折扣的商品：\(item.excludedProductNames.joined(separator: "、"))")
        }
        if let desc = item.ruleDescription, !desc.isEmpty {
            addLine(desc)
        }
    }

    private func makeRuleLine(_ text: String, isFirst: Bool) -> UILabel {
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0

        if rulesContentIsActive {
            label.font = .fdFont(ofSize: 13, weight: isFirst ? .medium : .regular)
            label.textColor = isFirst
                ? .fdPrimary
                : UIColor.fdPrimary.withAlphaComponent(Design.rulesActiveSecondaryAlpha)
        } else {
            label.font = .fdFont(ofSize: 13, weight: .regular)
            label.textColor = UIColor(hexString: "#8591AB")
        }
        return label
    }

    @objc private func useTapped() {
        onUse?()
    }

    @objc private func toggleRules() {
        onToggleRules?()
    }
}

// MARK: - 使用规则与正文之间的虚线分隔

private final class HorizontalDashedLineView: UIView {
    private let shapeLayer = CAShapeLayer()

    var strokeColor: UIColor = UIColor(hexString: "#8591AB").withAlphaComponent(0.4)

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        shapeLayer.fillColor = nil
        shapeLayer.lineWidth = 1
        shapeLayer.lineDashPattern = [3, 3]
        layer.addSublayer(shapeLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.frame = bounds
        shapeLayer.strokeColor = strokeColor.cgColor
        let path = UIBezierPath()
        let y = bounds.height / 2
        path.move(to: CGPoint(x: 0, y: y))
        path.addLine(to: CGPoint(x: bounds.width, y: y))
        shapeLayer.path = path.cgPath
    }
}
