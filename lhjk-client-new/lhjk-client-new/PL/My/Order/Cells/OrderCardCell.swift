import UIKit
import SnapKit
import Kingfisher

/// 订单列表卡片 — 对齐 funde-client `OrderListCard.vue`
final class OrderCardCell: UITableViewCell {

    static let reuseIdentifier = "OrderCardCell"

    var onAction: ((OrderListCardAction) -> Void)?

    // MARK: - UI

    private let cardView = UIView()

    private let institutionIcon = UIImageView(image: UIImage(systemName: "building.2"))
    private let institutionLabel = UILabel()
    private let statusContainer = UIView()
    private let statusLabel = UILabel()

    private let coverView = UIView()
    private let coverImageView = UIImageView()
    private let coverPlaceholder = UILabel()

    private let nameLabel = UILabel()
    private let introLabel = UILabel()
    private let priceLabel = UILabel()

    private let actionsStack = UIStackView()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupCard()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupCard() {
        cardView.backgroundColor = .fdSurface
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 1)
        cardView.layer.shadowRadius = 6
        cardView.layer.shadowOpacity = 0.03
        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
            // 低于 required，避免 TableView 临时 44pt 高度时与内容约束冲突
            make.bottom.equalToSuperview().offset(-6).priority(UILayoutPriority(999))
        }

        institutionIcon.tintColor = .fdMuted
        institutionIcon.contentMode = .scaleAspectFit

        institutionLabel.font = .fdCaptionSemibold
        institutionLabel.textColor = .fdText
        institutionLabel.lineBreakMode = .byTruncatingTail

        statusContainer.layer.cornerRadius = 999
        statusLabel.font = .fdMicroSemibold
        statusContainer.addSubview(statusLabel)
        statusLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8))
        }

        let institutionRow = UIStackView(arrangedSubviews: [institutionIcon, institutionLabel])
        institutionRow.axis = .horizontal
        institutionRow.spacing = 6
        institutionRow.alignment = .center
        institutionIcon.snp.makeConstraints { $0.size.equalTo(16) }

        let topRow = UIStackView(arrangedSubviews: [institutionRow, statusContainer])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = 8
        institutionLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        statusContainer.setContentHuggingPriority(.required, for: .horizontal)

        coverView.backgroundColor = .fdSurface2
        coverView.layer.cornerRadius = 10
        coverView.clipsToBounds = true
        coverView.snp.makeConstraints { $0.size.equalTo(72) }

        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverView.addSubview(coverImageView)
        coverImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        coverPlaceholder.text = "套餐"
        coverPlaceholder.font = .fdCaptionSemibold
        coverPlaceholder.textColor = .fdMuted
        coverPlaceholder.textAlignment = .center
        coverView.addSubview(coverPlaceholder)
        coverPlaceholder.snp.makeConstraints { $0.center.equalToSuperview() }

        nameLabel.font = .fdBodySemibold
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 2

        introLabel.font = .fdCaption
        introLabel.textColor = .fdSubtext
        introLabel.numberOfLines = 1
        introLabel.lineBreakMode = .byTruncatingTail

        priceLabel.font = .fdMonoFont(ofSize: 16, weight: .heavy)
        priceLabel.textColor = .fdPrimary
        priceLabel.textAlignment = .right
        priceLabel.setContentHuggingPriority(.required, for: .horizontal)
        priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let textCol = UIStackView(arrangedSubviews: [nameLabel, introLabel])
        textCol.axis = .vertical
        textCol.spacing = 4
        textCol.alignment = .fill

        let mainRow = UIStackView(arrangedSubviews: [textCol, priceLabel])
        mainRow.axis = .horizontal
        mainRow.alignment = .top
        mainRow.spacing = 8

        let bodyRow = UIStackView(arrangedSubviews: [coverView, mainRow])
        bodyRow.axis = .horizontal
        bodyRow.alignment = .top
        bodyRow.spacing = 12

        actionsStack.axis = .horizontal
        actionsStack.spacing = 8
        actionsStack.alignment = .center
        actionsStack.distribution = .fill
        // 右对齐：左侧弹性空间
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let actionsRow = UIStackView(arrangedSubviews: [spacer, actionsStack])
        actionsRow.axis = .horizontal
        actionsRow.spacing = 0

        let root = UIStackView(arrangedSubviews: [topRow, bodyRow, actionsRow])
        root.axis = .vertical
        root.spacing = 12
        root.setContentHuggingPriority(.required, for: .vertical)
        root.setContentCompressionResistancePriority(.required, for: .vertical)
        cardView.addSubview(root)
        root.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        actionsRow.isHidden = true
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        let width = targetSize.width > 0 ? targetSize.width : UIScreen.main.bounds.width
        contentView.bounds.size.width = width
        setNeedsLayout()
        layoutIfNeeded()
        return contentView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }

    // MARK: - Configure

    func configure(order: MOrder) {
        institutionLabel.text = {
            let name = order.hospitalName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return name.isEmpty ? "服务机构" : name
        }()

        statusLabel.text = order.statusLabel
        if let status = order.orderStatus {
            statusContainer.backgroundColor = UIColor(hexString: status.tagBgHex)
            statusLabel.textColor = UIColor(hexString: status.tagTextHex)
        } else {
            statusContainer.backgroundColor = .fdSurface2
            statusLabel.textColor = .fdMuted
        }

        nameLabel.text = order.orderName?.nilIfEmpty ?? "未命名订单"

        let intro = order.packageDescription?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        introLabel.text = intro
        introLabel.isHidden = intro.isEmpty

        priceLabel.text = order.displayAmountText

        configureCover(urlString: order.packageImageUrl)
        configureActions(for: order)
    }

    private func configureCover(urlString: String?) {
        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = nil
        if let urlString, let url = URL(string: urlString), !urlString.isEmpty {
            coverPlaceholder.isHidden = true
            coverImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        } else {
            coverPlaceholder.isHidden = false
        }
    }

    private func configureActions(for order: MOrder) {
        actionsStack.arrangedSubviews.forEach {
            actionsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let actions = OrderListCardAction.actions(for: order.orderStatus, packageType: order.packageType)
        guard !actions.isEmpty else {
            actionsStack.superview?.isHidden = true
            return
        }
        actionsStack.superview?.isHidden = false

        for (index, action) in actions.enumerated() {
            let isPrimary = index == actions.count - 1
            let button = makeActionButton(action: action, primary: isPrimary)
            actionsStack.addArrangedSubview(button)
        }
        setNeedsLayout()
    }

    private func makeActionButton(action: OrderListCardAction, primary: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(action.title, for: .normal)
        button.titleLabel?.font = .fdCaptionSemibold
        button.contentEdgeInsets = UIEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
        button.layer.cornerRadius = 16
        if primary {
            button.backgroundColor = .fdPrimary
            button.setTitleColor(.white, for: .normal)
        } else {
            button.backgroundColor = .fdSurface
            button.setTitleColor(.fdText2, for: .normal)
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.fdBorder.cgColor
        }
        button.addAction(UIAction { [weak self] _ in
            self?.onAction?(action)
        }, for: .touchUpInside)
        return button
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = nil
        onAction = nil
        actionsStack.arrangedSubviews.forEach {
            actionsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        actionsStack.superview?.isHidden = true
    }
}

// MARK: - Card actions

enum OrderListCardAction: Equatable {
    case cancel
    case pay
    case confirmShip
    case confirmReceipt
    case afterSale
    case renew
    case settle

    var title: String {
        switch self {
        case .cancel: return "取消订单"
        case .pay: return "去支付"
        case .confirmShip: return "确认发货"
        case .confirmReceipt: return "确认收货"
        case .afterSale: return "退款/售后"
        case .renew: return "续费订单"
        case .settle: return "结算订单"
        }
    }

    /// 按主状态与套餐类型展示操作按钮
    static func actions(for status: AppOrderStatus?, packageType: Int? = nil) -> [OrderListCardAction] {
        guard let status else { return [] }
        switch status {
        case .pendingPayment:
            return [.cancel, .pay]
        case .pendingShip:
            return [.confirmShip, .cancel]
        case .pendingReceive:
            return [.afterSale, .confirmReceipt]
        case .inProgress, .overdue:
            return inProgressOrOverdueActions(packageType: packageType)
        case .completed, .refund, .cancelled, .refundReview:
            return []
        }
    }

    private static func inProgressOrOverdueActions(packageType: Int?) -> [OrderListCardAction] {
        var actions: [OrderListCardAction] = []
        if AppPackageType.supportsRenewal(packageType: packageType) {
            actions.append(.renew)
        }
        actions.append(.settle)
        return actions
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
