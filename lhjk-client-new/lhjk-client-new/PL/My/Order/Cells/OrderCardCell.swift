import UIKit
import SnapKit
import Kingfisher

/// 订单列表卡片 — 对齐 Figma 3509:9304 设计
final class OrderCardCell: UITableViewCell {

    static let reuseIdentifier = "OrderCardCell"

    var onAction: ((OrderListCardAction) -> Void)?

    // MARK: - UI Elements

    private let cardView = UIView()

    // 头部：机构与状态
    private let institutionIcon = UIImageView()
    private let institutionLabel = UILabel()
    private let statusLabel = UILabel()

    // 特色提示条（拒绝退款等通知）
    private let noticeBannerView = UIView()
    private let noticeBgImageView = UIImageView()
    private let noticeAlertIcon = UIImageView()
    private let noticeLabel = UILabel()

    // 套餐/商品信息卡
    private let packageInfoContainer = UIView()
    private let coverImageView = UIImageView()
    private let nameLabel = UILabel()
    private let introLabel = UILabel()
    private let priceSymbolLabel = UILabel()
    private let priceValueLabel = UILabel()

    // 底部操作按钮栏
    private let actionsRow = UIView()
    private let actionsStack = UIStackView()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup UI

    private func setupUI() {
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 8
        cardView.layer.shadowOpacity = 0.04
        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-6).priority(UILayoutPriority(999))
        }

        // 1. 顶部 Header
        institutionIcon.image = UIImage(named: "order_institution_icon")
        institutionIcon.contentMode = .scaleAspectFit
        institutionIcon.snp.makeConstraints { $0.size.equalTo(16) }

        institutionLabel.font = .fdFont(ofSize: 16, weight: .medium)
        institutionLabel.textColor = UIColor(hexString: "#1F2430")
        institutionLabel.lineBreakMode = .byTruncatingTail

        let instRow = UIStackView(arrangedSubviews: [institutionIcon, institutionLabel])
        instRow.axis = .horizontal
        instRow.spacing = 6
        instRow.alignment = .center

        statusLabel.font = .fdFont(ofSize: 14, weight: .medium)
        statusLabel.textColor = UIColor(hexString: "#FF7A50")
        statusLabel.textAlignment = .right
        statusLabel.setContentHuggingPriority(.required, for: .horizontal)
        statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let headerRow = UIStackView(arrangedSubviews: [instRow, statusLabel])
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.distribution = .fill
        headerRow.spacing = 8

        // 2. 特色提示条
        setupNoticeBanner()

        // 3. 套餐信息卡
        setupPackageInfoContainer()

        // 4. 底部按钮栏
        setupActionsRow()

        // 垂直堆叠
        let mainStack = UIStackView(arrangedSubviews: [
            headerRow,
            noticeBannerView,
            packageInfoContainer,
            actionsRow
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.alignment = .fill
        mainStack.distribution = .fill

        cardView.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
    }

    private func setupNoticeBanner() {
        noticeBannerView.backgroundColor = UIColor(hexString: "#F93838").withAlphaComponent(0.05)
        noticeBannerView.layer.cornerRadius = 8
        noticeBannerView.clipsToBounds = true

        noticeBgImageView.image = UIImage(named: "order_notice_bg_single")
        noticeBgImageView.contentMode = .scaleToFill
        noticeBannerView.addSubview(noticeBgImageView)
        noticeBgImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        noticeAlertIcon.image = UIImage(named: "order_notice_alert_icon")
        noticeAlertIcon.contentMode = .scaleAspectFit
        noticeBannerView.addSubview(noticeAlertIcon)
        noticeAlertIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(14)
        }

        noticeLabel.font = .fdFont(ofSize: 10, weight: .regular)
        noticeLabel.textColor = UIColor(hexString: "#F93838")
        noticeLabel.numberOfLines = 0
        noticeBannerView.addSubview(noticeLabel)
        noticeLabel.snp.makeConstraints { make in
            make.leading.equalTo(noticeAlertIcon.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }

        noticeBannerView.isHidden = true
    }

    private func setupPackageInfoContainer() {
        packageInfoContainer.backgroundColor = UIColor(hexString: "#FFF9F6")
        packageInfoContainer.layer.cornerRadius = 12
        packageInfoContainer.clipsToBounds = true

        coverImageView.backgroundColor = .white
        coverImageView.layer.cornerRadius = 12
        coverImageView.clipsToBounds = true
        coverImageView.contentMode = .scaleAspectFill
        packageInfoContainer.addSubview(coverImageView)
        coverImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.equalToSuperview().offset(12)
            make.size.equalTo(84)
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
        }

        nameLabel.font = .fdFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = UIColor(hexString: "#1F2430")
        nameLabel.numberOfLines = 2
        packageInfoContainer.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(coverImageView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalToSuperview().offset(12)
        }

        introLabel.font = .fdFont(ofSize: 14, weight: .regular)
        introLabel.textColor = UIColor(hexString: "#8591AB")
        introLabel.numberOfLines = 1
        introLabel.lineBreakMode = .byTruncatingTail
        packageInfoContainer.addSubview(introLabel)
        introLabel.snp.makeConstraints { make in
            make.leading.equalTo(coverImageView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
        }

        // 价格部分（右下角）
        priceSymbolLabel.font = .fdFont(ofSize: 12, weight: .medium)
        priceSymbolLabel.textColor = UIColor(hexString: "#1F2942")
        priceSymbolLabel.text = "¥ "

        priceValueLabel.font = .fdMonoFont(ofSize: 16, weight: .medium)
        priceValueLabel.textColor = UIColor(hexString: "#1F2942")

        let priceStack = UIStackView(arrangedSubviews: [priceSymbolLabel, priceValueLabel])
        priceStack.axis = .horizontal
        priceStack.spacing = 2
        priceStack.alignment = .lastBaseline

        packageInfoContainer.addSubview(priceStack)
        priceStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-12)
            make.top.greaterThanOrEqualTo(introLabel.snp.bottom).offset(10)
        }

        packageInfoContainer.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(108)
        }
    }

    private func setupActionsRow() {
        actionsStack.axis = .horizontal
        actionsStack.spacing = 12
        actionsStack.alignment = .center
        actionsStack.distribution = .fill

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let wrapper = UIStackView(arrangedSubviews: [spacer, actionsStack])
        wrapper.axis = .horizontal
        wrapper.spacing = 0
        wrapper.alignment = .center

        actionsRow.addSubview(wrapper)
        wrapper.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(28)
        }

        actionsRow.isHidden = true
    }

    // MARK: - Configure

    func configure(order: MOrder) {
        // 机构名称
        let instName = order.hospitalName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        institutionLabel.text = instName.isEmpty ? "富德健康" : instName

        // 状态
        statusLabel.text = order.statusLabel
        statusLabel.textColor = UIColor(hexString: "#FF7A50")

        // 特色通知条
        if let notice = order.noticeText {
            noticeLabel.text = notice
            noticeBannerView.isHidden = false
            // 根据行数选择单行/双行背景
            if notice.count > 25 {
                noticeBgImageView.image = UIImage(named: "order_notice_bg_double")
            } else {
                noticeBgImageView.image = UIImage(named: "order_notice_bg_single")
            }
        } else {
            noticeBannerView.isHidden = true
        }

        // 商品/套餐标题与简介
        nameLabel.text = order.orderName?.nilIfEmpty ?? "未命名订单"
        let intro = order.packageDescription?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        introLabel.text = intro
        introLabel.isHidden = intro.isEmpty

        // 价格
        let cleanAmount = order.displayAmountText.replacingOccurrences(of: "¥", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        priceValueLabel.text = cleanAmount

        // 封面图
        configureCover(urlString: order.packageImageUrl)

        // 按钮栏
        configureActions(for: order)
    }

    private func configureCover(urlString: String?) {
        coverImageView.kf.cancelDownloadTask()
        let placeholder = UIImage(named: "order_package_placeholder")
        if let urlString, let url = URL(string: urlString), !urlString.isEmpty {
            coverImageView.kf.setImage(
                with: url,
                placeholder: placeholder,
                options: [.transition(.fade(0.2))]
            )
        } else {
            coverImageView.image = placeholder
        }
    }

    private func configureActions(for order: MOrder) {
        actionsStack.arrangedSubviews.forEach {
            actionsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let actions = OrderListCardAction.actions(for: order)
        guard !actions.isEmpty else {
            actionsRow.isHidden = true
            return
        }
        actionsRow.isHidden = false

        for (index, action) in actions.enumerated() {
            let isPrimary = index == actions.count - 1
            let button = makeActionButton(action: action, primary: isPrimary)
            actionsStack.addArrangedSubview(button)
        }
    }

    private func makeActionButton(action: OrderListCardAction, primary: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(action.title, for: .normal)
        button.titleLabel?.font = .fdFont(ofSize: 12, weight: .medium)
        button.layer.cornerRadius = 14
        button.clipsToBounds = true

        if primary {
            button.backgroundColor = UIColor(hexString: "#FF7950")
            button.setTitleColor(.white, for: .normal)
            button.layer.borderWidth = 0
        } else {
            button.backgroundColor = .white
            button.setTitleColor(UIColor(hexString: "#FF7950"), for: .normal)
            button.layer.borderWidth = 0.5
            button.layer.borderColor = UIColor(hexString: "#FF7950").cgColor
        }

        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        button.snp.makeConstraints { make in
            make.height.equalTo(28)
            make.width.greaterThanOrEqualTo(77)
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
        actionsRow.isHidden = true
        noticeBannerView.isHidden = true
    }
}

// MARK: - Card Actions (业务交互)

enum OrderListCardAction: Equatable {
    case cancel
    case pay
    case confirmShip
    case confirmReceipt
    case afterSale
    case renew
    case settle
    /// 退款审核通过后的退货处理
    case returnGoods

    var title: String {
        switch self {
        case .cancel: return "取消订单"
        case .pay: return "去支付"
        case .confirmShip: return "确认发货"
        case .confirmReceipt: return "确认收货"
        case .afterSale: return "退款/售后"
        case .renew: return "续费订单"
        case .settle: return "结算订单"
        case .returnGoods: return "去退货"
        }
    }

    /// 对齐 Figma 3546:4382：填充主按钮 vs 描边次按钮
    var isPrimary: Bool {
        switch self {
        case .pay, .confirmShip, .confirmReceipt, .settle, .returnGoods:
            return true
        case .cancel, .afterSale, .renew:
            return false
        }
    }

    /// 按订单状态、套餐类型与退款历史展示操作按钮（对齐 PRD 3.4 / 5.8 与 Figma 3509:9304）
    static func actions(for order: MOrder) -> [OrderListCardAction] {
        actions(
            for: order.orderStatus,
            packageType: order.packageType,
            hasRefundHistory: order.hasRefundHistory,
            canRenew: order.canShowRenewAction,
            canReturnGoods: order.canShowReturnGoodsAction
        )
    }

    static func actions(for detail: AppOrderDetailBO) -> [OrderListCardAction] {
        actions(
            for: detail.orderStatus,
            packageType: detail.packageType,
            hasRefundHistory: detail.hasRefundHistory,
            canRenew: detail.canShowRenewAction,
            canReturnGoods: detail.canShowReturnGoodsAction
        )
    }

    static func actions(
        for status: AppOrderStatus?,
        packageType: Int? = nil,
        hasRefundHistory: Bool = false,
        canRenew: Bool = false,
        canReturnGoods: Bool = false
    ) -> [OrderListCardAction] {
        guard let status else { return [] }
        switch status {
        case .pendingPayment:
            return [.cancel, .pay]
        case .pendingShip:
            return [.cancel]
        case .pendingReceive:
            return pendingReceiveActions(packageType: packageType, hasRefundHistory: hasRefundHistory)
        case .inProgress:
            return inProgressActions(
                packageType: packageType,
                hasRefundHistory: hasRefundHistory,
                canRenew: canRenew
            )
        case .overdue:
            return overdueActions(packageType: packageType, canRenew: canRenew)
        case .completed:
            return completedActions(packageType: packageType, hasRefundHistory: hasRefundHistory)
        case .refund:
            return canReturnGoods ? [.returnGoods] : []
        case .cancelled, .refundReview:
            return []
        }
    }

    private static func pendingReceiveActions(packageType: Int?, hasRefundHistory: Bool) -> [OrderListCardAction] {
        var actions: [OrderListCardAction] = []
        if AppPackageType.supportsAfterSale(packageType: packageType), !hasRefundHistory {
            actions.append(.afterSale)
        }
        actions.append(.confirmReceipt)
        return actions
    }

    private static func inProgressActions(
        packageType: Int?,
        hasRefundHistory: Bool,
        canRenew: Bool
    ) -> [OrderListCardAction] {
        guard let type = packageType.flatMap({ AppPackageType(rawValue: $0) }) else {
            return []
        }
        switch type {
        case .experience:
            return hasRefundHistory ? [] : [.afterSale]
        case .lease:
            return leaseRenewSettleActions(canRenew: canRenew)
        case .sale, .virtual:
            return []
        }
    }

    private static func overdueActions(packageType: Int?, canRenew: Bool) -> [OrderListCardAction] {
        guard AppPackageType(rawValue: packageType ?? -1) == .lease else { return [] }
        return leaseRenewSettleActions(canRenew: canRenew)
    }

    /// 已完成：仅售卖(电商零售)、体验套餐且未退款过可申请（PRD 5.8.1）
    private static func completedActions(packageType: Int?, hasRefundHistory: Bool) -> [OrderListCardAction] {
        guard AppPackageType.supportsAfterSale(packageType: packageType), !hasRefundHistory else {
            return []
        }
        return [.afterSale]
    }

    private static func leaseRenewSettleActions(canRenew: Bool) -> [OrderListCardAction] {
        var actions: [OrderListCardAction] = []
        if canRenew {
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
