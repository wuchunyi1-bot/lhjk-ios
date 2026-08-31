import UIKit
import SnapKit
import Kingfisher

/// 权益卡 / 转赠记录 — 对齐 Figma 3835:32594（343pt 基准等比缩放 + 状态背景切图）
final class BenefitCardCell: UITableViewCell {
    static let reuseID = "BenefitCardCell"

    private enum Design {
        static let cardWidth: CGFloat = 343
        static let horizontalInset: CGFloat = 32
        static let cellVerticalInset: CGFloat = 12

        static let contentInset: CGFloat = 10
        static let contentTrailingInset: CGFloat = 76
        static let contentToActionsSpacing: CGFloat = 8
        static let coverSize: CGFloat = 82
        static let coverCornerRadius: CGFloat = 12
        static let contentSpacing: CGFloat = 10
        static let actionsHeight: CGFloat = 40

        /// Figma 3835:32622+ — 标题 16 / 面值 16+18 / 赠送人+有效期 12
        static let nameFontSize: CGFloat = 16
        static let amountPrefixFontSize: CGFloat = 16
        static let amountValueFontSize: CGFloat = 18
        static let sublineFontSize: CGFloat = 12
        static let warnFontSize: CGFloat = 12
        static let actionFontSize: CGFloat = 16

        static let nameToAmountSpacing: CGFloat = 3
        static let amountToSublineSpacing: CGFloat = 4
        /// 无赠送人时，日期与面值间距略大，视觉更舒展
        static let amountToMetaWithoutGiverSpacing: CGFloat = 12
        static let sublineSpacing: CGFloat = 4

        static let activeTitleColor = UIColor(hexString: "#522B0F")
        static let inactiveTitleColor = UIColor(hexString: "#535353")
        static let activeSublineColor = UIColor(hexString: "#8C714F")
        static let inactiveSublineColor = UIColor(hexString: "#757575")

        static var fallbackAspectRatio: CGFloat { 147 / cardWidth }
    }

    var onPrimary: (() -> Void)?
    var onSecondary: (() -> Void)?

    private let card = UIView()
    private let bgImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let nameLabel = UILabel()
    private let amountLabel = UILabel()
    private let giverLabel = UILabel()
    private let metaLabel = UILabel()
    private let warnLabel = UILabel()

    private let actionsWrap = UIView()
    private let actionsTopDivider = UIView()
    private let actionsCenterDivider = UIView()
    private let secondaryButton = UIButton(type: .custom)
    private let primaryButton = UIButton(type: .custom)

    private var cardHeightConstraint: Constraint?
    private var contentBottomToActions: Constraint?
    private var actionsHeightConstraint: Constraint?

    private var coverSizeConstraint: Constraint?
    private var contentLeadingConstraint: Constraint?
    private var contentTrailingConstraint: Constraint?
    private var contentTopConstraint: Constraint?
    private var contentBottomInsetConstraint: Constraint?

    private var lastLayoutScale: CGFloat = 0
    private var backgroundImageName: String?
    private var lastAmount: Double = 0
    private var lastAmountIsActive = false
    private var detailsStack: UIStackView!
    private var contentRowStack: UIStackView!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .white
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    static func rowHeight(for tableWidth: CGFloat, card: BenefitCard) -> CGFloat {
        Design.cellVerticalInset + cardHeight(for: tableWidth, imageName: card.status.cardBackgroundImageName)
    }

    static func rowHeight(for tableWidth: CGFloat, transfer: BenefitTransferRecord) -> CGFloat {
        Design.cellVerticalInset + cardHeight(for: tableWidth, imageName: transfer.status.cardBackgroundImageName)
    }

    private static func cardHeight(for tableWidth: CGFloat, imageName: String) -> CGFloat {
        let width = max(0, tableWidth - Design.horizontalInset)
        guard let image = UIImage(named: imageName), image.size.width > 0 else {
            return width * Design.fallbackAspectRatio
        }
        return width * image.size.height / image.size.width
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onPrimary = nil
        onSecondary = nil
        setActionsVisible(false)
        warnLabel.isHidden = true
        giverLabel.isHidden = true
        giverLabel.text = nil
        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = nil
        backgroundImageName = nil
        lastLayoutScale = 0
    }

    func configureCard(_ item: BenefitCard) {
        backgroundImageName = item.status.cardBackgroundImageName
        applyBackgroundImage(item.status.cardBackgroundImageName)

        nameLabel.text = item.name
        setAmountText(item.amount, isActive: item.status == .available || item.status == .pendingReceive)
        applyCover(imageUrl: item.imageUrl, isActive: item.status == .available || item.status == .pendingReceive)

        switch item.status {
        case .available:
            applyGiver(name: item.sourcePartyName, textColor: Design.activeSublineColor)
            metaLabel.text = "有效期至 \(item.validUntil)"
            metaLabel.textColor = Design.activeSublineColor
            metaLabel.numberOfLines = 1
            nameLabel.textColor = Design.activeTitleColor
            warnLabel.isHidden = !item.isExpiringSoon
            warnLabel.text = "即将到期"
            showActions(gift: item.canGift, primary: "立即兑换")

        case .pendingReceive, .pendingBind:
            applyGiver(name: item.sourcePartyName, textColor: Design.activeSublineColor)
            metaLabel.text = "有效期至 \(item.validUntil)"
            metaLabel.textColor = Design.activeSublineColor
            metaLabel.numberOfLines = 1
            nameLabel.textColor = Design.activeTitleColor
            warnLabel.isHidden = true
            setActionsVisible(false)

        case .redeemed:
            applyGiver(name: nil, textColor: Design.inactiveSublineColor)
            let day = item.redeemedAt.map { String($0.replacingOccurrences(of: "T", with: " ").prefix(10)) } ?? "--"
            metaLabel.text = "兑换时间 \(day)"
            metaLabel.textColor = Design.inactiveSublineColor
            metaLabel.numberOfLines = 1
            nameLabel.textColor = Design.inactiveTitleColor
            warnLabel.isHidden = true
            showActions(gift: false, primary: "查看订单")
            primaryButton.isEnabled = !(item.orderId?.isEmpty ?? true)

        case .expired:
            applyGiver(name: item.sourcePartyName, textColor: Design.inactiveSublineColor)
            metaLabel.text = "到期时间 \(item.validUntil)"
            metaLabel.textColor = Design.inactiveSublineColor
            metaLabel.numberOfLines = 1
            nameLabel.textColor = Design.inactiveTitleColor
            warnLabel.isHidden = true
            setActionsVisible(false)

        case .transferred:
            applyGiver(name: item.sourcePartyName, textColor: Design.inactiveSublineColor)
            metaLabel.text = "有效期至 \(item.validUntil)"
            metaLabel.textColor = Design.inactiveSublineColor
            metaLabel.numberOfLines = 1
            nameLabel.textColor = Design.inactiveTitleColor
            warnLabel.isHidden = true
            setActionsVisible(false)
        }

        applyDetailsSpacing(scale: currentScale())
        setNeedsLayout()
    }

    func configureTransfer(_ item: BenefitTransferRecord) {
        backgroundImageName = item.status.cardBackgroundImageName
        applyBackgroundImage(item.status.cardBackgroundImageName)

        nameLabel.text = item.cardName
        let isActive = item.status == .waiting
        setAmountText(item.amount, isActive: isActive)
        applyCover(imageUrl: item.imageUrl, isActive: isActive)
        warnLabel.isHidden = true
        giverLabel.isHidden = true
        giverLabel.text = nil
        setActionsVisible(false)

        if item.status == .waiting {
            nameLabel.textColor = Design.activeTitleColor
            metaLabel.textColor = Design.activeSublineColor
            metaLabel.numberOfLines = 2
            metaLabel.text = VoucherListQuery.waitingTransferMeta(sharedAt: item.sharedAt)
        } else {
            nameLabel.textColor = Design.inactiveTitleColor
            metaLabel.textColor = Design.inactiveSublineColor
            metaLabel.numberOfLines = 2
            let name = (item.recipientName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let claimed = Self.formatDay(item.claimedAt)
            metaLabel.text = "已赠送给 \(name.isEmpty ? "—" : name)\n领取时间 \(claimed)"
        }

        applyDetailsSpacing(scale: currentScale())
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCardHeightIfNeeded()
        applyProportionalLayoutIfNeeded()
    }

    // MARK: - UI Setup

    private func setupUI() {
        card.layer.cornerRadius = 16
        card.clipsToBounds = true
        contentView.addSubview(card)

        card.addSubview(bgImageView)
        bgImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        nameLabel.numberOfLines = 1
        giverLabel.numberOfLines = 1
        giverLabel.isHidden = true
        metaLabel.numberOfLines = 1
        metaLabel.lineBreakMode = .byTruncatingTail
        warnLabel.textColor = .fdDanger
        warnLabel.isHidden = true

        let details = UIStackView(arrangedSubviews: [nameLabel, amountLabel, giverLabel, metaLabel, warnLabel])
        details.axis = .vertical
        details.spacing = 0
        details.alignment = .leading
        detailsStack = details

        contentRowStack = UIStackView(arrangedSubviews: [coverImageView, details])
        contentRowStack.axis = .horizontal
        contentRowStack.spacing = Design.contentSpacing
        contentRowStack.alignment = .top

        actionsWrap.backgroundColor = .clear
        actionsTopDivider.backgroundColor = UIColor(hexString: "#FFECD2")
        actionsCenterDivider.backgroundColor = UIColor(hexString: "#E5D0B5")

        secondaryButton.addTarget(self, action: #selector(secondaryTapped), for: .touchUpInside)
        primaryButton.addTarget(self, action: #selector(primaryTapped), for: .touchUpInside)

        let buttonsStack = UIStackView(arrangedSubviews: [secondaryButton, primaryButton])
        buttonsStack.axis = .horizontal
        buttonsStack.distribution = .fillEqually

        actionsWrap.addSubview(actionsTopDivider)
        actionsWrap.addSubview(actionsCenterDivider)
        actionsWrap.addSubview(buttonsStack)

        card.addSubview(contentRowStack)
        card.addSubview(actionsWrap)

        card.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-6).priority(999)
            cardHeightConstraint = make.height.equalTo(Design.cardWidth * Design.fallbackAspectRatio).constraint
        }

        coverImageView.snp.makeConstraints { make in
            coverSizeConstraint = make.size.equalTo(Design.coverSize).constraint
        }

        contentRowStack.snp.makeConstraints { make in
            contentTopConstraint = make.top.equalToSuperview().inset(Design.contentInset).constraint
            contentLeadingConstraint = make.leading.equalToSuperview().inset(Design.contentInset).constraint
            contentTrailingConstraint = make.trailing.equalToSuperview().inset(Design.contentTrailingInset).constraint
            contentBottomInsetConstraint = make.bottom.equalToSuperview().inset(Design.contentInset).constraint
            contentBottomToActions = make.bottom.equalTo(actionsWrap.snp.top)
                .offset(-Design.contentToActionsSpacing).constraint
        }
        contentBottomToActions?.deactivate()

        actionsWrap.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            actionsHeightConstraint = make.height.equalTo(0).constraint
        }

        actionsTopDivider.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        actionsCenterDivider.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(0.5)
            make.height.equalTo(18)
        }

        buttonsStack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func updateCardHeightIfNeeded() {
        guard let name = backgroundImageName else { return }
        let tableWidth = contentView.bounds.width
        guard tableWidth > 0 else { return }
        cardHeightConstraint?.update(offset: Self.cardHeight(for: tableWidth, imageName: name))
    }

    private func applyProportionalLayoutIfNeeded() {
        let width = card.bounds.width
        guard width > 0 else { return }
        let scale = width / Design.cardWidth
        guard abs(scale - lastLayoutScale) > 0.01 else { return }
        lastLayoutScale = scale

        card.layer.cornerRadius = 16 * scale
        coverImageView.layer.cornerRadius = Design.coverCornerRadius * scale
        coverSizeConstraint?.update(offset: Design.coverSize * scale)

        contentTopConstraint?.update(inset: Design.contentInset * scale)
        contentLeadingConstraint?.update(inset: Design.contentInset * scale)
        contentTrailingConstraint?.update(inset: Design.contentTrailingInset * scale)
        contentBottomInsetConstraint?.update(inset: Design.contentInset * scale)
        contentBottomToActions?.update(offset: -Design.contentToActionsSpacing * scale)

        applyDetailsSpacing(scale: scale)

        contentRowStack.spacing = Design.contentSpacing * scale

        nameLabel.font = .fdFont(ofSize: Design.nameFontSize * scale, weight: .medium)
        giverLabel.font = .fdFont(ofSize: Design.sublineFontSize * scale, weight: .regular)
        metaLabel.font = .fdFont(ofSize: Design.sublineFontSize * scale, weight: .regular)
        warnLabel.font = .fdFont(ofSize: Design.warnFontSize * scale, weight: .medium)

        secondaryButton.titleLabel?.font = .fdFont(ofSize: Design.actionFontSize * scale, weight: .regular)
        primaryButton.titleLabel?.font = .fdFont(ofSize: Design.actionFontSize * scale, weight: .medium)

        if actionsWrap.isHidden == false {
            actionsHeightConstraint?.update(offset: Design.actionsHeight * scale)
        }

        actionsCenterDivider.snp.updateConstraints { make in
            make.height.equalTo(18 * scale)
        }

        refreshAmountTypography(scale: scale)
    }

    private func applyDetailsSpacing(scale: CGFloat) {
        detailsStack.setCustomSpacing(Design.nameToAmountSpacing * scale, after: nameLabel)
        let amountToNextSpacing = giverLabel.isHidden
            ? Design.amountToMetaWithoutGiverSpacing * scale
            : Design.amountToSublineSpacing * scale
        detailsStack.setCustomSpacing(amountToNextSpacing, after: amountLabel)
        if !giverLabel.isHidden {
            detailsStack.setCustomSpacing(Design.sublineSpacing * scale, after: giverLabel)
        }
        if !warnLabel.isHidden {
            detailsStack.setCustomSpacing(Design.sublineSpacing * scale, after: metaLabel)
        }
    }

    private func applyGiver(name: String?, textColor: UIColor) {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else {
            giverLabel.isHidden = true
            giverLabel.text = nil
            return
        }
        giverLabel.isHidden = false
        giverLabel.text = "赠送人：\(trimmed)"
        giverLabel.textColor = textColor
    }

    private func applyBackgroundImage(_ name: String) {
        bgImageView.image = UIImage(named: name)
        card.backgroundColor = .clear
        card.layer.borderWidth = 0
    }

    private func setAmountText(_ amount: Double, isActive: Bool) {
        lastAmount = amount
        lastAmountIsActive = isActive
        refreshAmountTypography(amount: amount, isActive: isActive, scale: currentScale())
    }

    private func currentScale() -> CGFloat {
        if lastLayoutScale > 0 { return lastLayoutScale }
        let width = card.bounds.width
        return width > 0 ? width / Design.cardWidth : 1
    }

    private func refreshAmountTypography(amount: Double? = nil, isActive: Bool? = nil, scale: CGFloat) {
        let value = amount ?? lastAmount
        let active = isActive ?? lastAmountIsActive
        let color = active ? Design.activeTitleColor : Design.inactiveTitleColor
        let prefixFont = UIFont.fdFont(ofSize: Design.amountPrefixFontSize * scale, weight: .medium)
        let valueFont = UIFont.fdFont(ofSize: Design.amountValueFontSize * scale, weight: .medium)

        let attr = NSMutableAttributedString(
            string: "面值 ｜ ¥ ",
            attributes: [.font: prefixFont, .foregroundColor: color]
        )
        attr.append(NSAttributedString(
            string: Self.formatAmount(value),
            attributes: [.font: valueFont, .foregroundColor: color]
        ))
        amountLabel.attributedText = attr
    }

    private func applyCover(imageUrl: String?, isActive: Bool) {
        let fallbackName = isActive ? "benefit_card_cover_active" : "benefit_card_cover_inactive"
        let fallback = UIImage(named: fallbackName)

        guard let raw = imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty,
              let url = URL(string: raw) else {
            coverImageView.image = fallback
            return
        }
        coverImageView.kf.setImage(with: url, placeholder: fallback)
    }

    private func showActions(gift: Bool, primary: String) {
        setActionsVisible(true)
        primaryButton.setTitle(primary, for: .normal)

        if gift {
            secondaryButton.isHidden = false
            secondaryButton.setTitle("赠送好友", for: .normal)
            secondaryButton.setTitleColor(UIColor(hexString: "#8C714F"), for: .normal)
            primaryButton.setTitleColor(UIColor(hexString: "#B86022"), for: .normal)
            actionsCenterDivider.isHidden = false
        } else {
            secondaryButton.isHidden = true
            primaryButton.setTitleColor(UIColor(hexString: "#535D72"), for: .normal)
            actionsCenterDivider.isHidden = true
        }
    }

    private func setActionsVisible(_ visible: Bool) {
        actionsWrap.isHidden = !visible
        if visible {
            actionsHeightConstraint?.update(offset: Design.actionsHeight * currentScale())
            contentBottomInsetConstraint?.deactivate()
            contentBottomToActions?.activate()
        } else {
            actionsHeightConstraint?.update(offset: 0)
            contentBottomToActions?.deactivate()
            contentBottomInsetConstraint?.activate()
        }
    }

    @objc private func primaryTapped() {
        onPrimary?()
    }

    @objc private func secondaryTapped() {
        onSecondary?()
    }

    private static func formatAmount(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(val))
        }
        return String(format: "%.2f", val)
    }

    private static func formatDay(_ iso: String?) -> String {
        guard let iso, !iso.isEmpty else { return "—" }
        return String(iso.replacingOccurrences(of: "T", with: " ").prefix(10))
    }
}
