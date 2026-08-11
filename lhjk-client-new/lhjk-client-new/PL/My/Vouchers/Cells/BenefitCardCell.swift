import UIKit
import SnapKit
import Kingfisher

/// 权益卡 / 转赠记录 — 对齐 funde `.benefit-card`
final class BenefitCardCell: UITableViewCell {
    static let reuseID = "BenefitCardCell"

    var onPrimary: (() -> Void)?
    var onSecondary: (() -> Void)?

    private let card = UIView()
    private let cover = UIView()
    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 10
        iv.isHidden = true
        return iv
    }()
    private let coverIcon = UIImageView(image: UIImage(systemName: "gift.fill"))
    private let coverTitle: UILabel = {
        let l = UILabel()
        l.text = "权益卡"
        l.font = .fdMicroSemibold
        l.textColor = .fdPrimary
        return l
    }()
    private let nameLabel = UILabel()
    private let amountLabel = UILabel()
    private let metaLabel = UILabel()
    private let warnLabel = UILabel()
    private let sealLabel = UILabel()
    private let actionsWrap = UIView()
    private let actionsDivider = UIView()
    private let secondaryButton = UIButton(type: .system)
    private let primaryButton = UIButton(type: .system)

    /// 有操作栏时：content → actions；无操作栏时：content → card.bottom
    private var contentBottomToActions: Constraint?
    private var contentBottomToCard: Constraint?
    private var actionsHeight: Constraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .fdBg
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onPrimary = nil
        onSecondary = nil
        setActionsVisible(false)
        warnLabel.isHidden = true
        card.alpha = 1
        card.backgroundColor = .fdSurface
        metaLabel.numberOfLines = 2
        metaLabel.font = .fdCaption
        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = nil
        coverImageView.isHidden = true
        coverIcon.isHidden = false
        coverTitle.isHidden = false
    }

    func configureCard(_ item: BenefitCard) {
        nameLabel.text = item.name
        amountLabel.text = "面值：¥\(Self.formatAmount(item.amount))"
        applySeal(text: item.status.rawValue, tint: item.status.sealTint, bg: item.status.sealBackground)
        applyCover(imageUrl: item.imageUrl)

        switch item.status {
        case .available:
            var meta = "有效期至 \(item.validUntil)"
            if let giver = item.sourcePartyName?.trimmingCharacters(in: .whitespacesAndNewlines), !giver.isEmpty {
                meta += "\n赠送人：\(giver)"
            }
            metaLabel.text = meta
            warnLabel.isHidden = !item.isExpiringSoon
            warnLabel.text = "即将到期"
            card.backgroundColor = .fdSurface
            card.alpha = 1
            showActions(gift: item.canGift, primary: "立即兑换")
        case .redeemed:
            let day = item.redeemedAt.map { String($0.replacingOccurrences(of: "T", with: " ").prefix(10)) } ?? "--"
            metaLabel.text = "兑换时间 \(day)"
            warnLabel.isHidden = true
            card.backgroundColor = .fdSurface2
            card.alpha = 1
            showActions(gift: false, primary: "查看订单")
            primaryButton.isEnabled = !(item.orderId?.isEmpty ?? true)
        case .expired:
            metaLabel.text = "到期时间 \(item.validUntil)"
            warnLabel.isHidden = true
            card.backgroundColor = .fdBg2
            card.alpha = 0.72
            setActionsVisible(false)
        case .pendingBind:
            metaLabel.text = item.validUntil
            setActionsVisible(false)
        }
    }

    func configureTransfer(_ item: BenefitTransferRecord) {
        nameLabel.text = item.cardName
        amountLabel.text = "面值：¥\(Self.formatAmount(item.amount))"
        applySeal(text: item.status.rawValue, tint: item.status.sealTint, bg: item.status.sealBackground)
        applyCover(imageUrl: item.imageUrl)
        card.backgroundColor = .fdInfoSoft
        card.alpha = 1
        warnLabel.isHidden = true
        setActionsVisible(false)

        if item.status == .waiting {
            metaLabel.font = .fdCaption
            metaLabel.text = VoucherListQuery.waitingTransferMeta(sharedAt: item.sharedAt)
        } else {
            metaLabel.font = .fdCaption
            let name = (item.recipientName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let claimed = Self.formatDay(item.claimedAt)
            metaLabel.text = "已赠送给 \(name.isEmpty ? "—" : name)\n领取时间 \(claimed)"
        }
    }

    // MARK: - UI

    private func setupUI() {
        card.layer.cornerRadius = 14
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.fdBorder.cgColor
        contentView.addSubview(card)

        cover.backgroundColor = .fdSurface
        cover.layer.cornerRadius = 10
        cover.layer.borderWidth = 1
        cover.layer.borderColor = UIColor.fdPrimaryEdge.cgColor
        coverIcon.tintColor = .fdPrimary
        coverIcon.contentMode = .scaleAspectFit
        cover.addSubview(coverIcon)
        cover.addSubview(coverTitle)
        cover.addSubview(coverImageView)

        nameLabel.font = .fdBodyBold
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 1
        amountLabel.font = .fdNumM
        amountLabel.textColor = .fdPrimary
        metaLabel.font = .fdCaption
        metaLabel.textColor = .fdSubtext
        metaLabel.numberOfLines = 2
        warnLabel.font = .fdMicro
        warnLabel.textColor = .fdDanger

        sealLabel.font = .fdMicroSemibold
        sealLabel.textAlignment = .center
        sealLabel.numberOfLines = 2
        sealLabel.layer.cornerRadius = 28
        sealLabel.layer.borderWidth = 2
        sealLabel.clipsToBounds = true
        sealLabel.transform = CGAffineTransform(rotationAngle: -0.16)

        let details = UIStackView(arrangedSubviews: [nameLabel, amountLabel, metaLabel, warnLabel])
        details.axis = .vertical
        details.spacing = 4
        details.alignment = .fill
        details.setCustomSpacing(2, after: metaLabel)

        // 顶部对齐，避免 UIStackView centerY 与固定 cover 高度在临时 cell 高度下冲突
        let contentRow = UIStackView(arrangedSubviews: [cover, details])
        contentRow.axis = .horizontal
        contentRow.spacing = 12
        contentRow.alignment = .top

        actionsDivider.backgroundColor = .fdBorder
        secondaryButton.titleLabel?.font = .fdCaptionSemibold
        secondaryButton.setTitleColor(.fdPrimary, for: .normal)
        secondaryButton.addTarget(self, action: #selector(secondaryTapped), for: .touchUpInside)
        primaryButton.titleLabel?.font = .fdBodySemibold
        primaryButton.setTitleColor(.fdPrimary, for: .normal)
        primaryButton.addTarget(self, action: #selector(primaryTapped), for: .touchUpInside)

        let actions = UIStackView(arrangedSubviews: [secondaryButton, primaryButton])
        actions.axis = .horizontal
        actions.distribution = .fillEqually
        actionsWrap.addSubview(actionsDivider)
        actionsWrap.addSubview(actions)

        card.addSubview(contentRow)
        card.addSubview(sealLabel)
        card.addSubview(actionsWrap)

        // bottom 降优先级，避免与 UITableView 临时 Encapsulated-Layout-Height 硬刚
        card.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-6).priority(999)
        }
        cover.snp.makeConstraints { make in
            make.width.height.equalTo(64)
        }
        coverIcon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(12)
            make.size.equalTo(22)
        }
        coverTitle.snp.makeConstraints { make in
            make.top.equalTo(coverIcon.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }
        coverImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentRow.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(14)
            make.trailing.equalToSuperview().inset(72)
            contentBottomToActions = make.bottom.equalTo(actionsWrap.snp.top).offset(-12).constraint
            contentBottomToCard = make.bottom.equalToSuperview().inset(14).constraint
        }
        contentBottomToActions?.deactivate()
        contentBottomToCard?.activate()

        sealLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().inset(12)
            make.size.equalTo(56)
        }
        actionsWrap.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            actionsHeight = make.height.equalTo(0).constraint
        }
        actionsDivider.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }
        actions.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        actionsWrap.isHidden = true
    }

    private func showActions(gift: Bool, primary: String) {
        setActionsVisible(true)
        secondaryButton.isHidden = !gift
        secondaryButton.setTitle("赠送好友", for: .normal)
        primaryButton.setTitle(primary, for: .normal)
        primaryButton.isEnabled = true
        primaryButton.isHidden = false
    }

    private func setActionsVisible(_ visible: Bool) {
        actionsWrap.isHidden = !visible
        actionsHeight?.update(offset: visible ? 48 : 0)
        if visible {
            contentBottomToCard?.deactivate()
            contentBottomToActions?.activate()
        } else {
            contentBottomToActions?.deactivate()
            contentBottomToCard?.activate()
        }
    }

    private func applyCover(imageUrl: String?) {
        coverImageView.kf.cancelDownloadTask()
        if let urlStr = imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
           !urlStr.isEmpty,
           let url = URL(string: urlStr) {
            coverImageView.isHidden = false
            coverIcon.isHidden = true
            coverTitle.isHidden = true
            coverImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        } else {
            coverImageView.isHidden = true
            coverImageView.image = nil
            coverIcon.isHidden = false
            coverTitle.isHidden = false
        }
    }

    private func applySeal(text: String, tint: UIColor, bg: UIColor) {
        sealLabel.text = text
        sealLabel.textColor = tint
        sealLabel.backgroundColor = bg
        sealLabel.layer.borderColor = tint.cgColor
    }

    @objc private func primaryTapped() { onPrimary?() }
    @objc private func secondaryTapped() { onSecondary?() }

    private static func formatAmount(_ value: Double) -> String {
        value == floor(value) ? "\(Int(value))" : String(format: "%.2f", value)
    }

    private static func formatDay(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "--" }
        return String(value.replacingOccurrences(of: "T", with: " ").prefix(10))
    }
}
