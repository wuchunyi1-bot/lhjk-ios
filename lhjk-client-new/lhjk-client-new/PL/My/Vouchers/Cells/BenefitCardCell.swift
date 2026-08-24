import UIKit
import SnapKit
import Kingfisher

/// 权益卡 / 转赠记录 — 对齐 Figma 3835:32584
final class BenefitCardCell: UITableViewCell {
    static let reuseID = "BenefitCardCell"

    var onPrimary: (() -> Void)?
    var onSecondary: (() -> Void)?

    private let card = UIView()
    private let bgGradientLayer = CAGradientLayer()

    // Left Cover
    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        return iv
    }()

    // Middle Info
    private let nameLabel = UILabel()
    private let amountLabel = UILabel()
    private let metaLabel = UILabel()
    private let warnLabel = UILabel()

    // Top-Right Corner Stamp
    private let stampImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    // Bottom Actions Bar
    private let actionsWrap = UIView()
    private let actionsBgGradientLayer = CAGradientLayer()
    private let actionsTopDivider = UIView()
    private let actionsCenterDivider = UIView()
    private let secondaryButton = UIButton(type: .custom)
    private let primaryButton = UIButton(type: .custom)

    private var contentBottomToActions: Constraint?
    private var contentBottomToCard: Constraint?
    private var actionsHeight: Constraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .white
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        bgGradientLayer.frame = card.bounds
        actionsBgGradientLayer.frame = actionsWrap.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onPrimary = nil
        onSecondary = nil
        setActionsVisible(false)
        warnLabel.isHidden = true
        card.alpha = 1
        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = nil
        stampImageView.image = nil
    }

    func configureCard(_ item: BenefitCard) {
        nameLabel.text = item.name
        setAmountText(item.amount, isActive: item.status == .available || item.status == .pendingReceive)
        applyStamp(imageName: item.status.stampImageName)
        applyCover(imageUrl: item.imageUrl, isActive: item.status == .available || item.status == .pendingReceive)

        switch item.status {
        case .available:
            var meta = "有效期至 \(item.validUntil)"
            if let giver = item.sourcePartyName?.trimmingCharacters(in: .whitespacesAndNewlines), !giver.isEmpty {
                meta += "\n赠送人：\(giver)"
            }
            metaLabel.text = meta
            metaLabel.textColor = UIColor(hexString: "#8C714F")
            nameLabel.textColor = UIColor(hexString: "#522B0F")
            warnLabel.isHidden = !item.isExpiringSoon
            warnLabel.text = "即将到期"
            applyCardStyle(isActive: true)
            showActions(gift: item.canGift, primary: "立即兑换")

        case .pendingReceive, .pendingBind:
            metaLabel.text = "有效期至 \(item.validUntil)"
            metaLabel.textColor = UIColor(hexString: "#8C714F")
            nameLabel.textColor = UIColor(hexString: "#522B0F")
            warnLabel.isHidden = true
            applyCardStyle(isActive: true)
            setActionsVisible(false)

        case .redeemed:
            let day = item.redeemedAt.map { String($0.replacingOccurrences(of: "T", with: " ").prefix(10)) } ?? "--"
            metaLabel.text = "兑换时间 \(day)"
            metaLabel.textColor = UIColor(hexString: "#8591AB")
            nameLabel.textColor = UIColor(hexString: "#8591AB")
            warnLabel.isHidden = true
            applyCardStyle(isActive: false)
            showActions(gift: false, primary: "查看订单")
            primaryButton.isEnabled = !(item.orderId?.isEmpty ?? true)

        case .expired:
            metaLabel.text = "到期时间 \(item.validUntil)"
            metaLabel.textColor = UIColor(hexString: "#8591AB")
            nameLabel.textColor = UIColor(hexString: "#8591AB")
            warnLabel.isHidden = true
            applyCardStyle(isActive: false)
            setActionsVisible(false)

        case .transferred:
            metaLabel.text = "有效期至 \(item.validUntil)"
            metaLabel.textColor = UIColor(hexString: "#8591AB")
            nameLabel.textColor = UIColor(hexString: "#8591AB")
            warnLabel.isHidden = true
            applyCardStyle(isActive: false)
            setActionsVisible(false)
        }
    }

    func configureTransfer(_ item: BenefitTransferRecord) {
        nameLabel.text = item.cardName
        let isActive = item.status == .waiting
        setAmountText(item.amount, isActive: isActive)
        applyStamp(imageName: item.status.stampImageName)
        applyCover(imageUrl: item.imageUrl, isActive: isActive)
        applyCardStyle(isActive: isActive)
        warnLabel.isHidden = true
        setActionsVisible(false)

        if item.status == .waiting {
            nameLabel.textColor = UIColor(hexString: "#522B0F")
            metaLabel.textColor = UIColor(hexString: "#8C714F")
            metaLabel.text = VoucherListQuery.waitingTransferMeta(sharedAt: item.sharedAt)
        } else {
            nameLabel.textColor = UIColor(hexString: "#8591AB")
            metaLabel.textColor = UIColor(hexString: "#8591AB")
            let name = (item.recipientName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let claimed = Self.formatDay(item.claimedAt)
            metaLabel.text = "已赠送给 \(name.isEmpty ? "—" : name)\n领取时间 \(claimed)"
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 0.5
        card.layer.borderColor = UIColor(hexString: "#FFECD2").cgColor
        card.clipsToBounds = true
        contentView.addSubview(card)

        card.layer.insertSublayer(bgGradientLayer, at: 0)

        // Labels
        nameLabel.font = .fdFont(ofSize: 18, weight: .medium)
        nameLabel.textColor = UIColor(hexString: "#522B0F")
        nameLabel.numberOfLines = 1

        amountLabel.font = .fdFont(ofSize: 16, weight: .medium)
        amountLabel.textColor = UIColor(hexString: "#522B0F")

        metaLabel.font = .fdFont(ofSize: 14, weight: .regular)
        metaLabel.textColor = UIColor(hexString: "#8C714F")
        metaLabel.numberOfLines = 2

        warnLabel.font = .fdFont(ofSize: 12, weight: .medium)
        warnLabel.textColor = .fdDanger
        warnLabel.isHidden = true

        let details = UIStackView(arrangedSubviews: [nameLabel, amountLabel, metaLabel, warnLabel])
        details.axis = .vertical
        details.spacing = 6
        details.alignment = .leading

        // Content Row: Cover + Details
        let contentRow = UIStackView(arrangedSubviews: [coverImageView, details])
        contentRow.axis = .horizontal
        contentRow.spacing = 10
        contentRow.alignment = .top

        // Actions Bar
        actionsWrap.clipsToBounds = true
        actionsBgGradientLayer.colors = [
            UIColor(hexString: "#FFF2E0").cgColor,
            UIColor(hexString: "#FFFAF3").cgColor
        ]
        actionsBgGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        actionsBgGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        actionsWrap.layer.insertSublayer(actionsBgGradientLayer, at: 0)

        actionsTopDivider.backgroundColor = UIColor(hexString: "#FFECD2")
        actionsCenterDivider.backgroundColor = UIColor(hexString: "#E5D0B5")

        secondaryButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .regular)
        secondaryButton.setTitleColor(UIColor(hexString: "#8C714F"), for: .normal)
        secondaryButton.addTarget(self, action: #selector(secondaryTapped), for: .touchUpInside)

        primaryButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        primaryButton.setTitleColor(UIColor(hexString: "#B86022"), for: .normal)
        primaryButton.addTarget(self, action: #selector(primaryTapped), for: .touchUpInside)

        let buttonsStack = UIStackView(arrangedSubviews: [secondaryButton, primaryButton])
        buttonsStack.axis = .horizontal
        buttonsStack.distribution = .fillEqually

        actionsWrap.addSubview(actionsTopDivider)
        actionsWrap.addSubview(actionsCenterDivider)
        actionsWrap.addSubview(buttonsStack)

        card.addSubview(contentRow)
        card.addSubview(stampImageView)
        card.addSubview(actionsWrap)

        // Constraints
        card.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-6).priority(999)
        }

        coverImageView.snp.makeConstraints { make in
            make.size.equalTo(82)
        }

        contentRow.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(12)
            make.trailing.equalToSuperview().inset(76)
            contentBottomToActions = make.bottom.equalTo(actionsWrap.snp.top).offset(-12).constraint
            contentBottomToCard = make.bottom.equalToSuperview().inset(12).constraint
        }
        contentBottomToActions?.deactivate()
        contentBottomToCard?.activate()

        stampImageView.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
            make.size.equalTo(84)
        }

        actionsWrap.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            actionsHeight = make.height.equalTo(0).constraint
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

        buttonsStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setAmountText(_ amount: Double, isActive: Bool) {
        let attr = NSMutableAttributedString(
            string: "面值 ｜ ¥ ",
            attributes: [
                .font: UIFont.fdFont(ofSize: 18, weight: .medium),
                .foregroundColor: isActive ? UIColor(hexString: "#522B0F") : UIColor(hexString: "#8591AB")
            ]
        )
        attr.append(NSAttributedString(
            string: Self.formatAmount(amount),
            attributes: [
                .font: UIFont.fdFont(ofSize: 20, weight: .medium),
                .foregroundColor: isActive ? UIColor(hexString: "#522B0F") : UIColor(hexString: "#8591AB")
            ]
        ))
        amountLabel.attributedText = attr
    }

    private func applyCardStyle(isActive: Bool) {
        if isActive {
            bgGradientLayer.isHidden = false
            bgGradientLayer.colors = [
                UIColor(hexString: "#FFF7EB").cgColor,
                UIColor(hexString: "#FFFAF3").cgColor
            ]
            card.layer.borderColor = UIColor(hexString: "#FFECD2").cgColor
            card.backgroundColor = .clear
        } else {
            bgGradientLayer.isHidden = true
            card.backgroundColor = UIColor(hexString: "#F8F9FA")
            card.layer.borderColor = UIColor(hexString: "#F0F2F5").cgColor
        }
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

    private func applyStamp(imageName: String?) {
        guard let imageName else {
            stampImageView.image = nil
            return
        }
        stampImageView.image = UIImage(named: imageName)
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
            primaryButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .regular)
            actionsCenterDivider.isHidden = true
        }
    }

    private func setActionsVisible(_ visible: Bool) {
        actionsWrap.isHidden = !visible
        if visible {
            actionsHeight?.update(offset: 40)
            contentBottomToCard?.deactivate()
            contentBottomToActions?.activate()
        } else {
            actionsHeight?.update(offset: 0)
            contentBottomToActions?.deactivate()
            contentBottomToCard?.activate()
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
