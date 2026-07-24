import UIKit
import SnapKit

// MARK: - Card

final class OrderDetailCardView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdSurface
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 6
        layer.shadowOpacity = 0.03
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - 状态头（对齐 funde OrderDetailStatusCard）

final class OrderDetailStatusView: UIView {
    private let card = UIView()
    private let iconContainer = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03

        titleLabel.font = .fdH3
        titleLabel.textColor = .fdText
        titleLabel.numberOfLines = 1

        iconView.contentMode = .scaleAspectFit
        iconContainer.layer.cornerRadius = 16
        iconContainer.clipsToBounds = true
        iconContainer.addSubview(iconView)
        iconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(18)
        }
        iconContainer.snp.makeConstraints { $0.size.equalTo(32) }

        let main = UIStackView(arrangedSubviews: [iconContainer, titleLabel])
        main.axis = .horizontal
        main.spacing = 12
        main.alignment = .center
        card.addSubview(main)
        main.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16))
        }

        addSubview(card)
        card.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(4)
            $0.leading.trailing.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(presentation: OrderDetailStatusPresentation) {
        titleLabel.text = presentation.title
        iconView.image = UIImage(systemName: presentation.systemImageName)
        iconContainer.backgroundColor = presentation.iconBackgroundColor
        iconView.tintColor = presentation.iconTintColor
    }

    /// 兼容旧调用
    func configure(status: AppOrderStatus?, title: String? = nil, hint: String = "", preferPrimaryForPending: Bool = false) {
        configure(presentation: .make(status: status, title: title, preferPrimaryForPending: preferPrimaryForPending))
    }
}

// MARK: - 状态提示条（对齐 funde OrderHintBar，卡片外展示）

final class OrderDetailHintBar: UIView {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdBg2
        layer.cornerRadius = 8
        label.font = .fdCaption
        label.textColor = .fdSubtext
        label.numberOfLines = 0
        addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)) }
        isHidden = true
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        label.text = trimmed
        isHidden = trimmed.isEmpty
    }
}

// MARK: - 履约地址（遗留，详情页已拆分为独立卡片）

final class OrderDetailFulfillmentView: UIView {
    private let titleLabel = UILabel()
    private let personLabel = UILabel()
    private let detailLabel = UILabel()
    private let logisticsLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = .fdBodySemibold
        titleLabel.textColor = .fdText
        personLabel.font = .fdBodySemibold
        personLabel.textColor = .fdText
        detailLabel.font = .fdCaption
        detailLabel.textColor = .fdSubtext
        detailLabel.numberOfLines = 0
        logisticsLabel.font = .fdCaption
        logisticsLabel.textColor = .fdPrimary
        logisticsLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, personLabel, detailLabel, logisticsLabel])
        stack.axis = .vertical
        stack.spacing = 8
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(detail: AppOrderDetailBO) {
        titleLabel.text = detail.fulfillmentTitle
        let receiver = detail.receiver?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let phone = detail.phone?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if receiver.isEmpty, phone.isEmpty {
            personLabel.text = detail.displayInstitutionName
        } else if phone.isEmpty {
            personLabel.text = receiver
        } else if receiver.isEmpty {
            personLabel.text = phone
        } else {
            personLabel.text = "\(receiver)  \(phone)"
        }

        let address = detail.address?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if detail.isExpressDelivery {
            detailLabel.text = address.isEmpty ? "暂无收货地址" : address
        } else {
            let institution = detail.displayInstitutionName
            detailLabel.text = address.isEmpty ? institution : "\(institution)\n\(address)"
        }

        if let logistics = detail.logisticsSummary {
            logisticsLabel.text = logistics
            logisticsLabel.isHidden = false
        } else {
            logisticsLabel.isHidden = true
        }
    }
}

// MARK: - 收货地址（对齐 funde address-row）

final class OrderDetailAddressView: UIView {
    private let titleLabel = UILabel()
    private let iconContainer = UIView()
    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let addressLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = "收货地址"
        titleLabel.font = .fdBodySemibold
        titleLabel.textColor = .fdText

        iconContainer.backgroundColor = .fdInfoSoft
        iconContainer.layer.cornerRadius = 12
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        iconView.image = UIImage(systemName: "location.fill", withConfiguration: iconConfig)
        iconView.tintColor = .fdInfo
        iconView.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconView)
        iconView.snp.makeConstraints { $0.center.equalToSuperview() }
        iconContainer.snp.makeConstraints { $0.size.equalTo(40) }

        nameLabel.font = .fdBodySemibold
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 1
        addressLabel.font = .fdCaption
        addressLabel.textColor = .fdSubtext
        addressLabel.numberOfLines = 0

        let body = UIStackView(arrangedSubviews: [nameLabel, addressLabel])
        body.axis = .vertical
        body.spacing = 4

        let row = UIStackView(arrangedSubviews: [iconContainer, body])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12

        let root = UIStackView(arrangedSubviews: [titleLabel, row])
        root.axis = .vertical
        root.spacing = 12
        addSubview(root)
        root.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(detail: AppOrderDetailBO) {
        let receiver = detail.receiver?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let phone = detail.phone?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if receiver.isEmpty, phone.isEmpty {
            nameLabel.text = "收货人"
        } else if phone.isEmpty {
            nameLabel.text = receiver
        } else if receiver.isEmpty {
            nameLabel.text = phone
        } else {
            nameLabel.text = "\(receiver)  \(phone)"
        }
        let address = detail.address?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        addressLabel.text = address.isEmpty ? "暂无收货地址" : address
    }
}

// MARK: - 服务机构 / 自提地址（对齐 funde institution-card）

final class OrderDetailInstitutionView: UIView {
    var onCall: (() -> Void)?

    private let titleLabel = UILabel()
    private let iconContainer = UIView()
    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let addressLabel = UILabel()
    private let callButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = .fdBodySemibold
        titleLabel.textColor = .fdText

        iconContainer.backgroundColor = .fdInfoSoft
        iconContainer.layer.cornerRadius = 12
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        iconView.image = UIImage(systemName: "building.2.fill", withConfiguration: iconConfig)
        iconView.tintColor = .fdInfo
        iconContainer.addSubview(iconView)
        iconView.snp.makeConstraints { $0.center.equalToSuperview() }
        iconContainer.snp.makeConstraints { $0.size.equalTo(24) }

        nameLabel.font = .fdBodySemibold
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 2
        addressLabel.font = .fdCaption
        addressLabel.textColor = .fdSubtext
        addressLabel.numberOfLines = 0

        let nameRow = UIStackView(arrangedSubviews: [iconContainer, nameLabel])
        nameRow.axis = .horizontal
        nameRow.spacing = 8
        nameRow.alignment = .top

        var callConfig = UIButton.Configuration.plain()
        callConfig.image = UIImage(systemName: "phone.fill")
        callConfig.title = "联系机构"
        callConfig.imagePadding = 6
        callConfig.baseForegroundColor = .fdPrimary
        callConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .fdCaptionSemibold
            return outgoing
        }
        callButton.configuration = callConfig
        callButton.addTarget(self, action: #selector(tapCall), for: .touchUpInside)

        let callRow = UIView()
        callRow.addSubview(callButton)
        callButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.bottom.equalToSuperview()
            $0.height.equalTo(40)
        }

        let root = UIStackView(arrangedSubviews: [titleLabel, nameRow, addressLabel, callRow])
        root.axis = .vertical
        root.spacing = 12
        root.setCustomSpacing(8, after: nameRow)
        addSubview(root)
        root.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(detail: AppOrderDetailBO) {
        titleLabel.text = detail.institutionCardTitle
        nameLabel.text = detail.displayInstitutionName
        addressLabel.text = detail.institutionAddressText
    }

    @objc private func tapCall() { onCall?() }
}

// MARK: - 物流任务卡（详情预览 / 发货记录列表复用）

final class OrderDetailShipmentTaskCardView: UIView {
    var onCopyTracking: ((String) -> Void)?

    private let iconContainer = UIView()
    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let bodyStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdBg
        layer.cornerRadius = 10

        iconContainer.backgroundColor = .fdInfoSoft
        iconContainer.layer.cornerRadius = 10
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .fdInfo
        iconContainer.addSubview(iconView)
        iconView.snp.makeConstraints { $0.center.equalToSuperview() }
        iconContainer.snp.makeConstraints { $0.size.equalTo(36) }

        nameLabel.font = .fdBodySemibold
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 2

        bodyStack.axis = .vertical
        bodyStack.spacing = 6

        let content = UIStackView(arrangedSubviews: [iconContainer, bodyStack])
        content.axis = .horizontal
        content.alignment = .top
        content.spacing = 12
        addSubview(content)
        content.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(
        line: OrderDetailPackageLineBO,
        isPickup: Bool,
        logisticsSummary: String?
    ) {
        let iconName = isPickup ? "storefront.fill" : "shippingbox.fill"
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        iconView.image = UIImage(systemName: iconName, withConfiguration: iconConfig)

        nameLabel.text = line.displayName
        bodyStack.arrangedSubviews.forEach {
            bodyStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let badge = Self.makeStatusBadge(text: line.shipmentStatusLabel, shipped: line.isShipped)
        let head = UIStackView(arrangedSubviews: [nameLabel, badge])
        head.axis = .horizontal
        head.alignment = .top
        head.spacing = 8
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        bodyStack.addArrangedSubview(head)

        if line.isShipped, let summary = logisticsSummary?.trimmingCharacters(in: .whitespacesAndNewlines), !summary.isEmpty {
            bodyStack.addArrangedSubview(makeLogisticsRow(summary: summary))
        } else if let secondary = line.logisticsSecondaryText(isPickup: isPickup, orderLogisticsSummary: nil) {
            let label = UILabel()
            label.font = .fdCaption
            label.textColor = .fdSubtext
            label.numberOfLines = 0
            label.text = secondary
            bodyStack.addArrangedSubview(label)
        }
    }

    private func makeLogisticsRow(summary: String) -> UIView {
        let label = UILabel()
        label.font = .fdCaption
        label.textColor = .fdText2
        label.numberOfLines = 2
        label.text = summary

        let copyButton = UIButton(type: .system)
        copyButton.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        copyButton.tintColor = .fdPrimary
        let trackingNo = summary.components(separatedBy: "：").last?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        copyButton.isHidden = trackingNo.isEmpty
        copyButton.addAction(UIAction { [weak self] _ in
            self?.onCopyTracking?(trackingNo)
        }, for: .touchUpInside)
        copyButton.snp.makeConstraints { $0.size.equalTo(28) }

        let row = UIStackView(arrangedSubviews: [label, copyButton])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 4
        return row
    }

    private static func makeStatusBadge(text: String, shipped: Bool) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = .fdMicroBold
        label.textColor = shipped ? .fdInfo : .fdWarning
        label.setContentHuggingPriority(.required, for: .horizontal)

        let container = UIView()
        container.backgroundColor = shipped ? .fdInfoSoft : .fdWarningSoft
        container.layer.cornerRadius = 10
        container.addSubview(label)
        label.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8))
        }
        return container
    }
}

// MARK: - 物流 / 自提信息（对齐 funde OrderLogisticsInfoSection）

final class OrderDetailLogisticsView: UIView {
    private static let previewLimit = 1

    var onCopyTracking: ((String) -> Void)?
    var onOpenRecords: (() -> Void)?

    private let titleLabel = UILabel()
    private let previewStack = UIStackView()
    private let recordsDivider = UIView()
    private let recordsButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = .fdBodySemibold
        titleLabel.textColor = .fdText

        previewStack.axis = .vertical
        previewStack.spacing = 10

        recordsDivider.backgroundColor = .fdBorder
        recordsButton.titleLabel?.font = .fdCaptionSemibold
        recordsButton.setTitleColor(.fdPrimary, for: .normal)
        recordsButton.addTarget(self, action: #selector(tapRecords), for: .touchUpInside)

        let root = UIStackView(arrangedSubviews: [titleLabel, previewStack, recordsDivider, recordsButton])
        root.axis = .vertical
        root.spacing = 12
        root.setCustomSpacing(12, after: previewStack)
        addSubview(root)
        root.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        recordsDivider.snp.makeConstraints { $0.height.equalTo(1) }
        recordsButton.snp.makeConstraints { $0.height.equalTo(40) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(
        lines: [OrderDetailPackageLineBO],
        isPickup: Bool,
        logisticsSummary: String?
    ) {
        titleLabel.text = isPickup ? "自提信息" : "物流信息"
        let totalCount = lines.count
        let previewLines = Array(lines.prefix(Self.previewLimit))

        previewStack.arrangedSubviews.forEach {
            previewStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for line in previewLines {
            let card = OrderDetailShipmentTaskCardView()
            card.configure(line: line, isPickup: isPickup, logisticsSummary: logisticsSummary)
            card.onCopyTracking = { [weak self] trackingNo in
                self?.onCopyTracking?(trackingNo)
            }
            previewStack.addArrangedSubview(card)
        }

        let recordsTitle = isPickup ? "自提记录" : "发货记录"
        recordsButton.setTitle("\(recordsTitle)（共\(totalCount)条） >", for: .normal)
    }

    @objc private func tapRecords() { onOpenRecords?() }
}

// MARK: - 套餐卡（对齐 OrderConfirmPackageView：名称 + 金额 + 套餐内容 + 展开收起）

final class OrderDetailPackageView: UIView {
    var onToggleContent: (() -> Void)?

    private let nameLabel = UILabel()
    private let introLabel = UILabel()
    private let amountLabel = UILabel()
    private let contentTitle = UILabel()
    private let contentStack = UIStackView()
    private let toggleButton = UIButton(type: .system)
    private let divider = UIView()
    private let contentSection = UIStackView()
    private let toggleRow = UIView()
    private let rootStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        nameLabel.font = .fdBodySemibold
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 2

        introLabel.font = .fdCaption
        introLabel.textColor = .fdSubtext
        introLabel.numberOfLines = 2

        amountLabel.font = .fdMonoFont(ofSize: 18, weight: .heavy)
        amountLabel.textColor = .fdPrimary
        amountLabel.textAlignment = .right

        contentTitle.text = "套餐内容"
        contentTitle.font = .fdBodySemibold
        contentTitle.textColor = .fdText

        contentStack.axis = .vertical
        contentStack.spacing = 0

        toggleButton.titleLabel?.font = .fdCaption
        toggleButton.setTitleColor(.fdSubtext, for: .normal)
        toggleButton.addTarget(self, action: #selector(tapToggle), for: .touchUpInside)

        divider.backgroundColor = .fdBorder

        let textCol = UIStackView(arrangedSubviews: [nameLabel, introLabel])
        textCol.axis = .vertical
        textCol.spacing = 4

        let top = UIStackView(arrangedSubviews: [textCol, amountLabel])
        top.axis = .horizontal
        top.alignment = .top
        top.spacing = 12
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)
        amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        contentSection.axis = .vertical
        contentSection.spacing = 8
        contentSection.addArrangedSubview(contentTitle)
        contentSection.addArrangedSubview(contentStack)

        toggleRow.addSubview(toggleButton)
        toggleButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.bottom.equalToSuperview()
        }

        rootStack.axis = .vertical
        rootStack.spacing = 12
        rootStack.addArrangedSubview(top)
        rootStack.addArrangedSubview(divider)
        rootStack.addArrangedSubview(contentSection)
        rootStack.addArrangedSubview(toggleRow)
        addSubview(rootStack)
        rootStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        divider.snp.makeConstraints { $0.height.equalTo(1) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(
        name: String,
        subtitle: String,
        amount: Double,
        lines: [OrderDetailPackageLineBO],
        canExpand: Bool,
        expanded: Bool,
        totalCount: Int
    ) {
        nameLabel.text = name
        introLabel.text = subtitle
        introLabel.isHidden = subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        amountLabel.text = ServicePackageMoney.yen(amount)

        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for line in lines {
            contentStack.addArrangedSubview(makeContentRow(line))
        }

        let hasContent = totalCount > 0
        contentSection.isHidden = !hasContent
        divider.isHidden = !hasContent
        let showToggle = hasContent && canExpand
        toggleRow.isHidden = !showToggle
        if showToggle {
            let title = expanded ? "收起" : "展开（共\(totalCount)项）"
            toggleButton.setTitle(title, for: .normal)
        }
    }

    private func makeContentRow(_ line: OrderDetailPackageLineBO) -> UIView {
        let name = UILabel()
        name.font = .fdCaption
        name.textColor = .fdText2
        name.text = line.displayName
        name.lineBreakMode = .byTruncatingTail

        let meta = UILabel()
        meta.font = .fdCaption
        meta.textColor = .fdSubtext
        meta.text = line.qtyLabel
        meta.setContentHuggingPriority(.required, for: .horizontal)

        let price = UILabel()
        price.font = .fdCaption
        price.textColor = .fdSubtext
        price.text = ServicePackageMoney.yen(line.priceValue)
        price.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [name, meta, price])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        row.snp.makeConstraints { $0.height.greaterThanOrEqualTo(32) }
        return row
    }

    @objc private func tapToggle() { onToggleContent?() }
}

// MARK: - 虚线分隔（与 OrderConfirmFeeView 一致）

private final class OrderDetailDashedLineView: UIView {
    private let shape = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        shape.strokeColor = UIColor.fdBorder.cgColor
        shape.lineWidth = 1
        shape.lineDashPattern = [4, 3]
        layer.addSublayer(shape)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        shape.frame = bounds
        shape.path = UIBezierPath(
            rect: CGRect(x: 0, y: bounds.midY, width: bounds.width, height: 0)
        ).cgPath
    }
}

// MARK: - 费用明细（对齐 OrderConfirmFeeView）

final class OrderDetailFeeView: UIView {
    private enum Metrics {
        static let rowHeight: CGFloat = 40
        static let labelFont: UIFont = .fdBody
        static let valueFont: UIFont = .fdBody
    }

    private let titleLabel = UILabel()
    private let rowsStack = UIStackView()
    private let totalDivider = OrderDetailDashedLineView()
    private let totalLeft = UILabel()
    private let totalRight = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.text = "费用明细"
        titleLabel.font = .fdBodySemibold
        titleLabel.textColor = .fdText

        rowsStack.axis = .vertical
        rowsStack.spacing = 0

        totalLeft.font = .fdBodySemibold
        totalLeft.textColor = .fdText

        totalRight.font = .fdNumM
        totalRight.textColor = .fdPrimary
        totalRight.textAlignment = .right

        let totalRow = UIStackView(arrangedSubviews: [totalLeft, totalRight])
        totalRow.axis = .horizontal
        totalRow.alignment = .center
        totalRow.spacing = 12
        totalRow.snp.makeConstraints { $0.height.equalTo(Metrics.rowHeight) }

        let root = UIStackView(arrangedSubviews: [titleLabel, rowsStack, totalDivider, totalRow])
        root.axis = .vertical
        root.spacing = 0
        root.setCustomSpacing(8, after: titleLabel)
        root.setCustomSpacing(12, after: rowsStack)
        root.setCustomSpacing(12, after: totalDivider)

        addSubview(root)
        root.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        totalDivider.snp.makeConstraints { $0.height.equalTo(1) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(detail: AppOrderDetailBO) {
        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        rowsStack.addArrangedSubview(row("套餐金额", ServicePackageMoney.yen(detail.packageAmount)))
        rowsStack.addArrangedSubview(row("运费", ServicePackageMoney.yen(detail.expressFee)))
        rowsStack.addArrangedSubview(
            row(
                "优惠券抵扣",
                "-\(ServicePackageMoney.yen(detail.couponDiscount))",
                minusValue: detail.couponDiscount > 0
            )
        )
        rowsStack.addArrangedSubview(row("权益卡抵扣", "-\(ServicePackageMoney.yen(0))", minusValue: false))

        let isPendingPayment = detail.orderStatus == .pendingPayment
        totalLeft.text = isPendingPayment ? "应付金额" : "实付金额"
        totalRight.text = ServicePackageMoney.yen(detail.paidAmount)
    }

    private func row(_ title: String, _ value: String, minusValue: Bool = false) -> UIView {
        let left = UILabel()
        left.text = title
        left.font = Metrics.labelFont
        left.textColor = .fdSubtext
        left.setContentHuggingPriority(.required, for: .horizontal)

        let right = UILabel()
        right.text = value
        right.font = Metrics.valueFont
        right.textColor = minusValue ? .fdSuccess : .fdText
        right.textAlignment = .right

        let row = UIStackView(arrangedSubviews: [left, right])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.snp.makeConstraints { $0.height.equalTo(Metrics.rowHeight) }
        return row
    }
}

// MARK: - 退款/售后信息（对齐 funde OrderAfterSaleInfoCard）

final class OrderDetailAfterSaleView: UIView {
    private enum Metrics {
        static let rowHeight: CGFloat = 40
        static let labelFont: UIFont = .fdBody
        static let valueFont: UIFont = .fdBody
    }

    private let titleLabel = UILabel()
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = "退款/售后信息"
        titleLabel.font = .fdBodySemibold
        titleLabel.textColor = .fdText
        stack.axis = .vertical
        stack.spacing = 0

        let root = UIStackView(arrangedSubviews: [titleLabel, stack])
        root.axis = .vertical
        root.spacing = 12
        root.setCustomSpacing(8, after: titleLabel)
        addSubview(root)
        root.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(detail: AppOrderDetailBO) {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        if let time = detail.refundApplyTimeText {
            stack.addArrangedSubview(infoRow("申请时间", time))
        }
        if let refundNo = detail.refundNoText {
            stack.addArrangedSubview(copyableRow("退款单号", refundNo))
        }
        if let reason = detail.refundReasonText {
            stack.addArrangedSubview(infoRow("申请退款原因", reason, multiline: true))
        }
        if let amount = detail.refundAmountValue {
            stack.addArrangedSubview(refundAmountRow(ServicePackageMoney.yen(amount)))
        }
    }

    private func infoRow(_ title: String, _ value: String, multiline: Bool = false) -> UIView {
        let left = UILabel()
        left.text = title
        left.font = Metrics.labelFont
        left.textColor = .fdSubtext
        left.setContentHuggingPriority(.required, for: .horizontal)
        let right = UILabel()
        right.text = value
        right.font = Metrics.valueFont
        right.textColor = .fdText
        right.numberOfLines = multiline ? 0 : 1
        right.textAlignment = .right
        let row = UIStackView(arrangedSubviews: [left, right])
        row.axis = .horizontal
        row.alignment = multiline ? .top : .center
        row.spacing = 12
        if !multiline {
            row.snp.makeConstraints { $0.height.equalTo(Metrics.rowHeight) }
        }
        return row
    }

    private func copyableRow(_ title: String, _ value: String) -> UIView {
        let row = infoRow(title, value)
        row.isUserInteractionEnabled = true
        row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(copyRefundNo)))
        row.accessibilityLabel = value
        return row
    }

    @objc private func copyRefundNo(_ gesture: UITapGestureRecognizer) {
        guard let value = gesture.view?.accessibilityLabel else { return }
        UIPasteboard.general.string = value
    }

    private func refundAmountRow(_ amount: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .fdDangerSoft
        container.layer.cornerRadius = 8

        let left = UILabel()
        left.text = "退款金额"
        left.font = .fdBodySemibold
        left.textColor = .fdText
        let right = UILabel()
        right.text = amount
        right.font = .fdNumM
        right.textColor = .fdDanger
        right.textAlignment = .right

        let row = UIStackView(arrangedSubviews: [left, right])
        row.axis = .horizontal
        row.alignment = .center
        container.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
        return container
    }
}

// MARK: - 订单信息（对齐 funde OrderDetailInfoSection）

final class OrderDetailInfoView: UIView {

    private enum Metrics {
        static let rowHeight: CGFloat = 40
        static let labelFont: UIFont = .fdBody
        static let valueFont: UIFont = .fdBody
    }

    var onOrderNumberCopied: (() -> Void)?

    private let titleLabel = UILabel()
    private let stack = UIStackView()
    private let toggleButton = UIButton(type: .system)
    private let expandedStack = UIStackView()
    private var isExpanded = false
    private var orderNumberText: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = "订单信息"
        titleLabel.font = .fdBodySemibold
        titleLabel.textColor = .fdText

        stack.axis = .vertical
        stack.spacing = 0

        expandedStack.axis = .vertical
        expandedStack.spacing = 0
        expandedStack.isHidden = true

        toggleButton.setTitleColor(.fdPrimary, for: .normal)
        toggleButton.titleLabel?.font = .fdBodySemibold
        toggleButton.addTarget(self, action: #selector(toggleExpanded), for: .touchUpInside)

        let root = UIStackView(arrangedSubviews: [titleLabel, stack, expandedStack, toggleButton])
        root.axis = .vertical
        root.spacing = 12
        root.setCustomSpacing(8, after: titleLabel)
        addSubview(root)
        root.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(
        detail: AppOrderDetailBO,
        paymentMethodOverride: String? = nil,
        remarkOverride: String? = nil,
        expandedRows: [(String, String)] = [],
        showsExpandToggle: Bool = true
    ) {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        expandedStack.arrangedSubviews.forEach {
            expandedStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        if let id = detail.id {
            orderNumberText = String(id)
            stack.addArrangedSubview(orderNumberRow(String(id)))
        }
        if let createTime = detail.createTime?.nilIfEmpty {
            stack.addArrangedSubview(infoRow("下单时间", createTime))
        }
        let remark = remarkOverride?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? detail.remarkText
        stack.addArrangedSubview(infoRow("订单备注", remark ?? "无", mutedValue: remark == nil))

        var mergedExpanded = expandedRows
        if let payment = paymentMethodOverride?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
           payment != "—",
           !mergedExpanded.contains(where: { $0.0 == "支付方式" }) {
            mergedExpanded.append(("支付方式", payment))
        }
        if let phone = trimmedNonEmpty(detail.phone),
           !mergedExpanded.contains(where: { $0.0 == "手机号" }) {
            mergedExpanded.insert(("手机号", phone), at: 0)
        }
        mergedExpanded.forEach { title, value in
            expandedStack.addArrangedSubview(infoRow(title, value))
        }

        let hasExpandedContent = !mergedExpanded.isEmpty
        toggleButton.isHidden = !showsExpandToggle || !hasExpandedContent
        if !toggleButton.isHidden {
            updateToggleTitle()
        } else {
            isExpanded = false
            expandedStack.isHidden = true
        }
    }

    private func trimmedNonEmpty(_ text: String?) -> String? {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private func orderNumberRow(_ value: String) -> UIView {
        let left = UILabel()
        left.text = "订单号"
        left.font = Metrics.labelFont
        left.textColor = .fdSubtext
        left.setContentHuggingPriority(.required, for: .horizontal)

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = Metrics.valueFont
        valueLabel.textColor = .fdText
        valueLabel.textAlignment = .right
        valueLabel.lineBreakMode = .byTruncatingMiddle

        let copyButton = UIButton(type: .system)
        copyButton.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        copyButton.tintColor = .fdPrimary
        copyButton.accessibilityLabel = "复制订单号"
        copyButton.addAction(UIAction { [weak self] _ in
            guard let text = self?.orderNumberText else { return }
            UIPasteboard.general.string = text
            self?.onOrderNumberCopied?()
        }, for: .touchUpInside)
        copyButton.snp.makeConstraints { $0.size.equalTo(28) }

        let right = UIStackView(arrangedSubviews: [valueLabel, copyButton])
        right.axis = .horizontal
        right.spacing = 6
        right.alignment = .center

        let row = UIStackView(arrangedSubviews: [left, right])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.snp.makeConstraints { $0.height.equalTo(Metrics.rowHeight) }
        return row
    }

    private func infoRow(_ title: String, _ value: String, mutedValue: Bool = false) -> UIView {
        let left = UILabel()
        left.text = title
        left.font = Metrics.labelFont
        left.textColor = .fdSubtext
        left.setContentHuggingPriority(.required, for: .horizontal)
        let right = UILabel()
        right.text = value
        right.font = Metrics.valueFont
        right.textColor = mutedValue ? .fdMuted : .fdText
        right.numberOfLines = 0
        right.textAlignment = .right
        let row = UIStackView(arrangedSubviews: [left, right])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.snp.makeConstraints { $0.height.equalTo(Metrics.rowHeight) }
        return row
    }

    @objc private func toggleExpanded() {
        isExpanded.toggle()
        expandedStack.isHidden = !isExpanded
        updateToggleTitle()
    }

    private func updateToggleTitle() {
        toggleButton.setTitle(isExpanded ? "收起" : "查看更多", for: .normal)
    }
}

// MARK: - 底部操作栏

final class OrderDetailActionBar: UIView {
    var onAction: ((OrderListCardAction) -> Void)?

    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdSurface
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 8

        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10).priority(UILayoutPriority(999))
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-10).priority(UILayoutPriority(999))
            make.height.greaterThanOrEqualTo(40).priority(UILayoutPriority(999))
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(actions: [OrderListCardAction]) {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        let hasActions = !actions.isEmpty
        stack.isHidden = !hasActions
        isHidden = !hasActions
        for (index, action) in actions.enumerated() {
            let primary = index == actions.count - 1
            stack.addArrangedSubview(makeButton(action: action, primary: primary))
        }
    }

    private func makeButton(action: OrderListCardAction, primary: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(action.title, for: .normal)
        button.titleLabel?.font = .fdBodySemibold
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        button.layer.cornerRadius = 20
        button.snp.makeConstraints { $0.height.equalTo(40) }
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
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
