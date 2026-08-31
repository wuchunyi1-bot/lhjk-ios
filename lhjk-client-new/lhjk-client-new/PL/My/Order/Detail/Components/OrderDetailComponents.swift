import UIKit
import SnapKit

// MARK: - Figma Design Tokens

private enum OrderDetailFigma {
    static let title = UIColor(hexString: "#1F2942")
    static let subtitle = UIColor(hexString: "#8591AB")
    static let priceRed = UIColor(hexString: "#F93838")
    static let primaryOrange = UIColor(hexString: "#FF7A50")
    static let pinBg = UIColor(hexString: "#FFF2E6")
    static let chipBg = UIColor(hexString: "#FFF4ED")
    static let chipText = UIColor(hexString: "#FF7015")
    static let divider = UIColor(hexString: "#F0F0F0")
    static let titleStart = UIColor(hexString: "#A15313")
    static let titleEnd = UIColor(hexString: "#522B0F")
    static let taskCardBg = UIColor(hexString: "#FDF6F3")
    static let ellipseBase = UIColor(hexString: "#FEC587").withAlphaComponent(0.23)
}

// MARK: - Card Container

final class OrderDetailCardView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 6
        layer.shadowOpacity = 0.03
        clipsToBounds = true
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - 状态头（对齐 Figma 3546:4382 / 3546:4549 / 3546:4611 等）

final class OrderDetailStatusView: UIView {
    private let bannerImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 16
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(bannerImageView)
        bannerImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(80)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(presentation: OrderDetailStatusPresentation) {
        bannerImageView.image = UIImage(named: presentation.illustrationName)
    }

    /// 兼容旧调用
    func configure(status: AppOrderStatus?, title: String? = nil, hint: String = "", preferPrimaryForPending: Bool = false) {
        configure(presentation: .make(status: status, title: title, preferPrimaryForPending: preferPrimaryForPending))
    }
}

// MARK: - 状态提示条（已废弃，兼容保留）

final class OrderDetailHintBar: UIView {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdBg2
        layer.cornerRadius = 8
        label.font = .fdFont(ofSize: 13, weight: .regular)
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

// MARK: - 履约地址（兼容保留）

final class OrderDetailFulfillmentView: UIView {
    private let titleLabel = UILabel()
    private let personLabel = UILabel()
    private let detailLabel = UILabel()
    private let logisticsLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = .fdFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .fdText
        personLabel.font = .fdFont(ofSize: 15, weight: .semibold)
        personLabel.textColor = .fdText
        detailLabel.font = .fdFont(ofSize: 13, weight: .regular)
        detailLabel.textColor = .fdSubtext
        detailLabel.numberOfLines = 0
        logisticsLabel.font = .fdFont(ofSize: 13, weight: .regular)
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

// MARK: - 收货地址（对齐 Figma 3546:4409）

final class OrderDetailAddressView: UIView {
    private let watermarkView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "order_detail_address_bg"))
        iv.contentMode = .scaleAspectFill
        iv.alpha = 0.20
        iv.isUserInteractionEnabled = false
        return iv
    }()

    private let titleLabel = UILabel()
    private let iconContainer = UIView()
    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let addressLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true

        insertSubview(watermarkView, at: 0)
        watermarkView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(-125)
            $0.trailing.equalToSuperview().offset(32)
            $0.size.equalTo(245)
        }

        titleLabel.text = "收货地址"
        titleLabel.font = .fdFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = OrderDetailFigma.title

        iconContainer.backgroundColor = OrderDetailFigma.pinBg
        iconContainer.layer.cornerRadius = 6
        iconContainer.clipsToBounds = true
        iconView.image = UIImage(named: "order_detail_address_pin")
        iconView.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconView)
        iconView.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(14) }
        iconContainer.snp.makeConstraints { $0.size.equalTo(24) }

        nameLabel.font = .fdFont(ofSize: 18, weight: .medium)
        nameLabel.textColor = OrderDetailFigma.title
        nameLabel.numberOfLines = 0

        addressLabel.font = .fdFont(ofSize: 16, weight: .regular)
        addressLabel.textColor = OrderDetailFigma.subtitle
        addressLabel.numberOfLines = 0

        let infoCol = UIStackView(arrangedSubviews: [nameLabel, addressLabel])
        infoCol.axis = .vertical
        infoCol.spacing = 6

        let nameRow = UIStackView(arrangedSubviews: [iconContainer, infoCol])
        nameRow.axis = .horizontal
        nameRow.spacing = 8
        nameRow.alignment = .top

        let root = UIStackView(arrangedSubviews: [titleLabel, nameRow])
        root.axis = .vertical
        root.spacing = 10
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

// MARK: - 服务机构 / 自提地址（对齐 Figma 3546:4425 / 3546:4941）

final class OrderDetailInstitutionView: UIView {
    var onCall: (() -> Void)?

    private let watermarkView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "order_detail_address_bg"))
        iv.contentMode = .scaleAspectFill
        iv.alpha = 0.20
        iv.isUserInteractionEnabled = false
        return iv
    }()

    private let titleLabel = UILabel()
    private let hintContainer = UIView()
    private let hintChip = UILabel()
    private let iconContainer = UIView()
    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let addressLabel = UILabel()
    private let callBar = OrderDetailInstitutionCallBar()

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true

        insertSubview(watermarkView, at: 0)
        watermarkView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(-125)
            $0.trailing.equalToSuperview().offset(32)
            $0.size.equalTo(245)
        }

        titleLabel.font = .fdFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = OrderDetailFigma.title

        hintContainer.backgroundColor = OrderDetailFigma.chipBg
        hintContainer.layer.cornerRadius = 11.5
        hintContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        hintContainer.clipsToBounds = true

        hintChip.text = "请前往以下机构领取商品/设备"
        hintChip.font = .fdFont(ofSize: 12, weight: .regular)
        hintChip.textColor = OrderDetailFigma.chipText
        hintChip.numberOfLines = 1
        hintContainer.setContentHuggingPriority(.required, for: .horizontal)
        hintContainer.setContentCompressionResistancePriority(.required, for: .horizontal)
        hintContainer.addSubview(hintChip)
        hintChip.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.trailing.equalToSuperview().offset(-8)
            $0.top.bottom.equalToSuperview().inset(4)
        }

        iconContainer.backgroundColor = OrderDetailFigma.pinBg
        iconContainer.layer.cornerRadius = 6
        iconContainer.clipsToBounds = true
        iconView.image = UIImage(named: "order_detail_address_pin")
        iconView.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconView)
        iconView.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(14) }
        iconContainer.snp.makeConstraints { $0.size.equalTo(24) }

        nameLabel.font = .fdFont(ofSize: 18, weight: .medium)
        nameLabel.textColor = OrderDetailFigma.title
        nameLabel.numberOfLines = 0

        addressLabel.font = .fdFont(ofSize: 16, weight: .regular)
        addressLabel.textColor = OrderDetailFigma.subtitle
        addressLabel.numberOfLines = 0

        let nameRow = UIStackView(arrangedSubviews: [iconContainer, nameLabel])
        nameRow.axis = .horizontal
        nameRow.spacing = 8
        nameRow.alignment = .top

        let institutionCol = UIStackView(arrangedSubviews: [nameRow, addressLabel])
        institutionCol.axis = .vertical
        institutionCol.spacing = 6
        institutionCol.setCustomSpacing(10, after: nameRow)

        callBar.onCall = { [weak self] in
            self?.onCall?()
        }

        addSubview(titleLabel)
        addSubview(hintContainer)
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(16)
        }
        hintContainer.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalTo(titleLabel)
            $0.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
        }

        let contentStack = UIStackView(arrangedSubviews: [institutionCol])
        contentStack.axis = .vertical
        contentStack.spacing = 12
        addSubview(contentStack)
        addSubview(callBar)
        contentStack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview()
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
        }

        callBar.snp.makeConstraints {
            $0.top.equalTo(contentStack.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(46)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(detail: AppOrderDetailBO) {
        titleLabel.text = detail.institutionCardTitle
        hintContainer.isHidden = detail.isExpressDelivery
        nameLabel.text = detail.displayInstitutionName
        addressLabel.text = detail.institutionAddressText
    }
}

// MARK: - 联系机构底栏

private final class OrderDetailInstitutionCallBar: UIView {
    var onCall: (() -> Void)?
    private let gradientLayer = CAGradientLayer()
    private let topBorder = UIView()
    private let button = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        gradientLayer.colors = [
            UIColor(hexString: "#FFF0EA").cgColor,
            UIColor(hexString: "#FFF0EA").withAlphaComponent(0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.insertSublayer(gradientLayer, at: 0)

        topBorder.backgroundColor = UIColor(hexString: "#FFECE4")
        addSubview(topBorder)
        topBorder.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(0.5)
        }

        var config = UIButton.Configuration.plain()
        config.image = UIImage(named: "order_detail_phone")
        config.title = "联系机构"
        config.imagePadding = 4
        config.baseForegroundColor = OrderDetailFigma.primaryOrange
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .fdFont(ofSize: 14, weight: .medium)
            return outgoing
        }
        button.configuration = config
        button.addAction(UIAction { [weak self] _ in self?.onCall?() }, for: .touchUpInside)
        addSubview(button)
        button.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.height.equalTo(46)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

// MARK: - 物流任务卡（对齐 Figma 3546:4446）

final class OrderDetailShipmentTaskCardView: UIView {
    var onCopyTracking: ((String) -> Void)?

    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let copyButton = UIButton(type: .system)
    private let stampImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = OrderDetailFigma.taskCardBg
        layer.cornerRadius = 12
        clipsToBounds = true

        iconView.image = UIImage(named: "order_confirm_transfer")
        iconView.contentMode = .scaleAspectFit

        nameLabel.font = .fdFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = OrderDetailFigma.title
        nameLabel.numberOfLines = 1

        subtitleLabel.font = .fdFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = OrderDetailFigma.subtitle
        subtitleLabel.numberOfLines = 1
        subtitleLabel.lineBreakMode = .byTruncatingTail

        copyButton.setImage(UIImage(named: "order_detail_copy")?.withRenderingMode(.alwaysOriginal), for: .normal)
        copyButton.tintColor = OrderDetailFigma.primaryOrange
        copyButton.addTarget(self, action: #selector(tapCopy), for: .touchUpInside)

        stampImageView.contentMode = .scaleAspectFit
        stampImageView.isUserInteractionEnabled = false

        addSubview(iconView)
        addSubview(nameLabel)
        addSubview(subtitleLabel)
        addSubview(copyButton)
        addSubview(stampImageView)

        iconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(iconView.snp.trailing).offset(8)
            $0.top.equalToSuperview().offset(14)
            $0.trailing.lessThanOrEqualTo(stampImageView.snp.leading).offset(-4)
        }
        subtitleLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.bottom.equalToSuperview().offset(-14)
        }
        copyButton.snp.makeConstraints {
            $0.leading.equalTo(subtitleLabel.snp.trailing).offset(4)
            $0.centerY.equalTo(subtitleLabel)
            $0.size.equalTo(14)
            $0.trailing.lessThanOrEqualTo(stampImageView.snp.leading).offset(-4)
        }
        stampImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.top.equalToSuperview()
            $0.size.equalTo(CGSize(width: 60, height: 51))
        }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(65) }
    }

    required init?(coder: NSCoder) { fatalError() }

    private var trackingNo: String = ""

    func configure(
        line: OrderDetailPackageLineBO,
        isPickup: Bool,
        logisticsSummary: String?,
        orderStatus: AppOrderStatus? = nil
    ) {
        nameLabel.text = line.displayName

        let stampAsset = line.stampAssetName(orderStatus: orderStatus, isPickup: isPickup)
        stampImageView.image = UIImage(named: stampAsset)
        stampImageView.isHidden = stampAsset.isEmpty

        let secondary = line.logisticsSecondaryText(
            isPickup: isPickup,
            orderLogisticsSummary: logisticsSummary,
            orderStatus: orderStatus
        )
        subtitleLabel.text = secondary
        subtitleLabel.isHidden = (secondary ?? "").isEmpty

        trackingNo = logisticsSummary?.components(separatedBy: "：").last?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let showsCopy = line.isShipped && !trackingNo.isEmpty
        copyButton.isHidden = !showsCopy
    }

    @objc private func tapCopy() {
        guard !trackingNo.isEmpty else { return }
        onCopyTracking?(trackingNo)
    }
}

// MARK: - 物流 / 自提信息（对齐 Figma 3546:4437）

final class OrderDetailLogisticsView: UIView {
    private static let previewLimit = 2

    var onCopyTracking: ((String) -> Void)?
    var onOpenRecords: (() -> Void)?

    private let titleLabel = UILabel()
    private let previewStack = UIStackView()
    private let recordsControl = UIControl()
    private let recordsLabel = UILabel()
    private let recordsIcon = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = .fdFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = OrderDetailFigma.title

        previewStack.axis = .vertical
        previewStack.spacing = 12

        recordsLabel.font = .fdFont(ofSize: 14, weight: .regular)
        recordsLabel.textColor = OrderDetailFigma.subtitle
        recordsIcon.image = UIImage(named: "order_detail_chevron_right")
        recordsIcon.contentMode = .scaleAspectFit
        recordsIcon.snp.makeConstraints { $0.size.equalTo(14) }

        let recordsStack = UIStackView(arrangedSubviews: [recordsLabel, recordsIcon])
        recordsStack.axis = .horizontal
        recordsStack.spacing = 2
        recordsStack.alignment = .center
        recordsStack.isUserInteractionEnabled = false
        recordsControl.addSubview(recordsStack)
        recordsStack.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.top.bottom.equalToSuperview()
        }
        recordsControl.addTarget(self, action: #selector(tapRecords), for: .touchUpInside)

        let root = UIStackView(arrangedSubviews: [titleLabel, previewStack, recordsControl])
        root.axis = .vertical
        root.spacing = 12
        addSubview(root)
        root.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        recordsControl.snp.makeConstraints { $0.height.equalTo(18) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(
        lines: [OrderDetailPackageLineBO],
        isPickup: Bool,
        logisticsSummary: String?,
        orderStatus: AppOrderStatus? = nil
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
            card.configure(
                line: line,
                isPickup: isPickup,
                logisticsSummary: logisticsSummary,
                orderStatus: orderStatus
            )
            card.onCopyTracking = { [weak self] trackingNo in
                self?.onCopyTracking?(trackingNo)
            }
            previewStack.addArrangedSubview(card)
        }

        let recordsTitle = isPickup ? "自提记录" : "发货记录"
        recordsLabel.text = "\(recordsTitle) (共\(totalCount)条)"
        previewStack.isHidden = previewLines.isEmpty
        recordsControl.isHidden = totalCount == 0
    }

    @objc private func tapRecords() { onOpenRecords?() }
}

// MARK: - 套餐卡（对齐 Figma 3546:4460）

final class OrderDetailPackageView: UIView {
    var onToggleContent: (() -> Void)?

    private let nameLabel = UILabel()
    private let introLabel = UILabel()
    private let amountLabel = UILabel()
    private let itemsContainer = OrderDetailPackageItemsGradientContainer()
    private let sectionIcon = UIImageView()
    private let sectionTitleLabel = UILabel()
    private let contentStack = UIStackView()
    private let toggleContainer = UIControl()
    private let toggleTitleLabel = UILabel()
    private let toggleIcon = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        nameLabel.font = .fdFont(ofSize: 18, weight: .medium)
        nameLabel.textColor = OrderDetailFigma.title
        nameLabel.numberOfLines = 2

        introLabel.font = .fdFont(ofSize: 16, weight: .regular)
        introLabel.textColor = OrderDetailFigma.subtitle
        introLabel.numberOfLines = 1

        amountLabel.textAlignment = .right
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)
        amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let textCol = UIStackView(arrangedSubviews: [nameLabel, introLabel])
        textCol.axis = .vertical
        textCol.spacing = 4

        let topRow = UIStackView(arrangedSubviews: [textCol, amountLabel])
        topRow.axis = .horizontal
        topRow.alignment = .top
        topRow.spacing = 12

        sectionIcon.image = UIImage(named: "order_confirm_package_icon")
        sectionIcon.contentMode = .scaleAspectFit
        sectionIcon.snp.makeConstraints { $0.size.equalTo(16) }

        sectionTitleLabel.text = "套餐内容"
        sectionTitleLabel.font = .fdFont(ofSize: 16, weight: .medium)
        sectionTitleLabel.textColor = OrderDetailFigma.title

        let headerStack = UIStackView(arrangedSubviews: [sectionIcon, sectionTitleLabel])
        headerStack.axis = .horizontal
        headerStack.spacing = 4
        headerStack.alignment = .center

        contentStack.axis = .vertical
        contentStack.spacing = 12

        toggleTitleLabel.font = .fdFont(ofSize: 14, weight: .regular)
        toggleTitleLabel.textColor = OrderDetailFigma.subtitle
        toggleIcon.contentMode = .scaleAspectFit
        toggleIcon.snp.makeConstraints { $0.size.equalTo(14) }

        let toggleStack = UIStackView(arrangedSubviews: [toggleTitleLabel, toggleIcon])
        toggleStack.axis = .horizontal
        toggleStack.spacing = 2
        toggleStack.alignment = .center
        toggleStack.isUserInteractionEnabled = false
        toggleContainer.addSubview(toggleStack)
        toggleStack.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.top.bottom.equalToSuperview().inset(4)
        }
        toggleContainer.addTarget(self, action: #selector(tapToggle), for: .touchUpInside)

        let itemsInner = UIStackView(arrangedSubviews: [headerStack, contentStack, toggleContainer])
        itemsInner.axis = .vertical
        itemsInner.spacing = 12
        itemsContainer.addSubview(itemsInner)
        itemsInner.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }

        let main = UIStackView(arrangedSubviews: [topRow, itemsContainer])
        main.axis = .vertical
        main.spacing = 16
        addSubview(main)
        main.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
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
        amountLabel.attributedText = OrderConfirmMoney.formatPrice(
            amount,
            symbolSize: 16,
            valueSize: 18,
            color: OrderDetailFigma.title
        )

        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for line in lines {
            contentStack.addArrangedSubview(makeContentRow(line))
        }

        let hasContent = totalCount > 0
        itemsContainer.isHidden = !hasContent
        toggleContainer.isHidden = !(hasContent && canExpand)
        if hasContent && canExpand {
            toggleTitleLabel.text = expanded ? "收起" : "展开 (共\(totalCount)项)"
            toggleIcon.image = UIImage(named: expanded ? "order_detail_collapse" : "order_detail_expand")
        }
    }

    private func makeContentRow(_ line: OrderDetailPackageLineBO) -> UIView {
        let name = UILabel()
        name.font = .fdFont(ofSize: 14, weight: .regular)
        name.textColor = OrderDetailFigma.title
        name.text = line.displayName
        name.lineBreakMode = .byTruncatingTail

        let meta = UILabel()
        meta.font = .fdFont(ofSize: 14, weight: .regular)
        meta.textColor = OrderDetailFigma.title
        meta.text = line.qtyLabel
        meta.textAlignment = .right
        meta.setContentHuggingPriority(.required, for: .horizontal)

        let price = UILabel()
        price.font = .fdFont(ofSize: 14, weight: .medium)
        price.textColor = OrderDetailFigma.title
        price.text = OrderConfirmMoney.yen(line.priceValue)
        price.textAlignment = .right
        price.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [name, meta, price])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        meta.snp.makeConstraints { $0.width.greaterThanOrEqualTo(30) }
        price.snp.makeConstraints { $0.width.greaterThanOrEqualTo(45) }
        return row
    }

    @objc private func tapToggle() { onToggleContent?() }
}

private final class OrderDetailPackageItemsGradientContainer: UIView {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 12
        clipsToBounds = true
        gradientLayer.colors = [
            UIColor(red: 255/255, green: 178/255, blue: 154/255, alpha: 0.10).cgColor,
            UIColor(red: 255/255, green: 122/255, blue: 80/255, alpha: 0.0).cgColor
        ]
        gradientLayer.locations = [0.0, 0.87]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

// MARK: - 费用明细（对齐 Figma 3546:4499）

final class OrderDetailFeeView: UIView {
    private let titleLabel = UILabel()
    private let rowsStack = UIStackView()
    private let totalDivider = UIView()
    private let totalLeft = UILabel()
    private let totalRight = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.text = "费用明细"
        titleLabel.font = .fdFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = OrderDetailFigma.title

        rowsStack.axis = .vertical
        rowsStack.spacing = 12

        totalDivider.backgroundColor = OrderDetailFigma.divider

        totalLeft.font = .fdFont(ofSize: 18, weight: .medium)
        totalLeft.textColor = OrderDetailFigma.title
        totalRight.textAlignment = .right

        let totalRow = UIStackView(arrangedSubviews: [totalLeft, totalRight])
        totalRow.axis = .horizontal
        totalRow.alignment = .center
        totalRow.spacing = 12

        let root = UIStackView(arrangedSubviews: [titleLabel, rowsStack, totalDivider, totalRow])
        root.axis = .vertical
        root.spacing = 16
        addSubview(root)
        root.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        totalDivider.snp.makeConstraints { $0.height.equalTo(0.5) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(detail: AppOrderDetailBO) {
        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        rowsStack.addArrangedSubview(row("套餐金额", OrderConfirmMoney.yen(detail.packageAmount), highlight: false))
        rowsStack.addArrangedSubview(row("运费", OrderConfirmMoney.yen(detail.expressFee), highlight: false))
        rowsStack.addArrangedSubview(
            row("优惠券抵扣", "-\(OrderConfirmMoney.yen(detail.couponDiscount))", highlight: detail.couponDiscount > 0)
        )
        rowsStack.addArrangedSubview(row("权益卡抵扣", "-\(OrderConfirmMoney.yen(0))", highlight: false))

        let isPendingPayment = detail.orderStatus == .pendingPayment
        totalLeft.text = isPendingPayment ? "应付金额" : "实付金额"
        totalRight.attributedText = OrderConfirmMoney.formatPrice(
            detail.paidAmount,
            symbolSize: 16,
            valueSize: 18,
            color: OrderDetailFigma.priceRed
        )
    }

    private func row(_ title: String, _ value: String, highlight: Bool) -> UIView {
        let left = UILabel()
        left.text = title
        left.font = .fdFont(ofSize: 16, weight: .regular)
        left.textColor = OrderDetailFigma.subtitle
        left.setContentHuggingPriority(.required, for: .horizontal)

        let right = UILabel()
        right.text = value
        right.font = .fdFont(ofSize: 16, weight: .medium)
        right.textColor = highlight ? OrderDetailFigma.priceRed : OrderDetailFigma.title
        right.textAlignment = .right

        let row = UIStackView(arrangedSubviews: [left, right])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        return row
    }
}

// MARK: - 退款/售后信息（对齐 Figma 3546:5429）

final class OrderDetailAfterSaleView: UIView {
    private let titleLabel = UILabel()
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = "退款/售后信息"
        titleLabel.font = .fdFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = OrderDetailFigma.title
        stack.axis = .vertical
        stack.spacing = 12

        let root = UIStackView(arrangedSubviews: [titleLabel, stack])
        root.axis = .vertical
        root.spacing = 12
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
            stack.addArrangedSubview(infoRow("退款金额", ServicePackageMoney.yen(amount), valueColor: OrderDetailFigma.priceRed))
        }
    }

    private func infoRow(
        _ title: String,
        _ value: String,
        multiline: Bool = false,
        valueColor: UIColor = OrderDetailFigma.title
    ) -> UIView {
        let left = UILabel()
        left.text = title
        left.font = .fdFont(ofSize: 16, weight: .regular)
        left.textColor = OrderDetailFigma.subtitle
        left.setContentHuggingPriority(.required, for: .horizontal)
        let right = UILabel()
        right.text = value
        right.font = .fdFont(ofSize: 16, weight: .regular)
        right.textColor = valueColor
        right.numberOfLines = multiline ? 0 : 1
        right.textAlignment = .right
        let row = UIStackView(arrangedSubviews: [left, right])
        row.axis = .horizontal
        row.alignment = multiline ? .top : .center
        row.spacing = 12
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
}

// MARK: - 订单信息（对齐 Figma 3546:4519）

final class OrderDetailInfoView: UIView {

    var onOrderNumberCopied: (() -> Void)?

    private let titleLabel = UILabel()
    private let stack = UIStackView()
    private let expandedStack = UIStackView()
    private let toggleControl = UIControl()
    private let toggleTitleLabel = UILabel()
    private let toggleIcon = UIImageView()
    private var isExpanded = true
    private var orderNumberText: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = "订单信息"
        titleLabel.font = .fdFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = OrderDetailFigma.title

        stack.axis = .vertical
        stack.spacing = 12

        expandedStack.axis = .vertical
        expandedStack.spacing = 12

        toggleTitleLabel.font = .fdFont(ofSize: 14, weight: .regular)
        toggleTitleLabel.textColor = OrderDetailFigma.subtitle
        toggleIcon.contentMode = .scaleAspectFit
        toggleIcon.snp.makeConstraints { $0.size.equalTo(14) }
        let toggleStack = UIStackView(arrangedSubviews: [toggleTitleLabel, toggleIcon])
        toggleStack.axis = .horizontal
        toggleStack.spacing = 2
        toggleStack.alignment = .center
        toggleStack.isUserInteractionEnabled = false
        toggleControl.addSubview(toggleStack)
        toggleStack.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.top.bottom.equalToSuperview()
        }
        toggleControl.addTarget(self, action: #selector(toggleExpanded), for: .touchUpInside)

        let root = UIStackView(arrangedSubviews: [titleLabel, stack, expandedStack, toggleControl])
        root.axis = .vertical
        root.spacing = 12
        addSubview(root)
        root.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        toggleControl.snp.makeConstraints { $0.height.equalTo(18) }
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
        if let reject = detail.refuseReasons?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
           !detail.isInAfterSaleFlow {
            stack.addArrangedSubview(infoRow("拒绝退款原因", reject, multiline: true))
        }
        let remark = remarkOverride?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? detail.remarkText
        stack.addArrangedSubview(infoRow("订单备注", remark ?? "无", mutedValue: remark == nil))

        var mergedExpanded = expandedRows
        if !mergedExpanded.contains(where: { $0.0 == "支付状态" }) {
            mergedExpanded.append(("支付状态", detail.paymentStatusText))
        }
        if let payment = paymentMethodOverride?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
           payment != "—",
           !mergedExpanded.contains(where: { $0.0 == "支付方式" }) {
            mergedExpanded.append(("支付方式", payment))
        }
        if let phone = trimmedNonEmpty(detail.phone),
           !mergedExpanded.contains(where: { $0.0 == "手机号" }) {
            mergedExpanded.append(("手机号", phone))
        }
        mergedExpanded.forEach { title, value in
            expandedStack.addArrangedSubview(infoRow(title, value))
        }

        let hasExpandedContent = !mergedExpanded.isEmpty
        toggleControl.isHidden = !showsExpandToggle || !hasExpandedContent
        if toggleControl.isHidden {
            isExpanded = false
            expandedStack.isHidden = true
        } else {
            expandedStack.isHidden = !isExpanded
            updateToggleTitle()
        }
    }

    private func trimmedNonEmpty(_ text: String?) -> String? {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private func orderNumberRow(_ value: String) -> UIView {
        let left = UILabel()
        left.text = "订单号"
        left.font = .fdFont(ofSize: 16, weight: .regular)
        left.textColor = OrderDetailFigma.subtitle
        left.setContentHuggingPriority(.required, for: .horizontal)

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .fdFont(ofSize: 16, weight: .regular)
        valueLabel.textColor = OrderDetailFigma.title
        valueLabel.textAlignment = .right
        valueLabel.lineBreakMode = .byTruncatingMiddle

        let copyButton = UIButton(type: .custom)
        copyButton.setImage(UIImage(named: "order_detail_copy")?.withRenderingMode(.alwaysOriginal), for: .normal)
        copyButton.tintColor = OrderDetailFigma.primaryOrange
        copyButton.accessibilityLabel = "复制订单号"
        copyButton.addAction(UIAction { [weak self] _ in
            guard let text = self?.orderNumberText else { return }
            UIPasteboard.general.string = text
            self?.onOrderNumberCopied?()
        }, for: .touchUpInside)
        copyButton.snp.makeConstraints { $0.size.equalTo(14) }

        let right = UIStackView(arrangedSubviews: [valueLabel, copyButton])
        right.axis = .horizontal
        right.spacing = 6
        right.alignment = .center

        let row = UIStackView(arrangedSubviews: [left, right])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        return row
    }

    private func infoRow(_ title: String, _ value: String, mutedValue: Bool = false, multiline: Bool = false) -> UIView {
        let left = UILabel()
        left.text = title
        left.font = .fdFont(ofSize: 16, weight: .regular)
        left.textColor = OrderDetailFigma.subtitle
        left.setContentHuggingPriority(.required, for: .horizontal)
        let right = UILabel()
        right.text = value
        right.font = .fdFont(ofSize: 16, weight: .regular)
        right.textColor = mutedValue ? OrderDetailFigma.subtitle : OrderDetailFigma.title
        right.numberOfLines = multiline ? 0 : 1
        right.textAlignment = .right
        let row = UIStackView(arrangedSubviews: [left, right])
        row.axis = .horizontal
        row.alignment = multiline ? .top : .center
        row.spacing = 12
        return row
    }

    @objc private func toggleExpanded() {
        isExpanded.toggle()
        expandedStack.isHidden = !isExpanded
        updateToggleTitle()
    }

    private func updateToggleTitle() {
        toggleTitleLabel.text = isExpanded ? "收起" : "展开"
        toggleIcon.image = UIImage(named: isExpanded ? "order_detail_collapse" : "order_detail_expand")
    }
}

// MARK: - 底部操作栏（对齐 Figma 3546:4382）

final class OrderDetailActionBar: UIView {
    enum Style {
        /// 屏幕底部固定操作栏
        case fixedBottom
        /// 滚动内容底部内嵌操作栏
        case scrollInline
    }

    var onAction: ((OrderListCardAction) -> Void)?

    private let style: Style
    private let stack = UIStackView()

    init(style: Style = .fixedBottom) {
        self.style = style
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        switch style {
        case .fixedBottom:
            backgroundColor = .white
            layer.cornerRadius = 16
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.04
            layer.shadowOffset = CGSize(width: 0, height: -2)
            layer.shadowRadius = 8
        case .scrollInline:
            backgroundColor = .clear
            clipsToBounds = false
        }

        stack.axis = .horizontal
        stack.spacing = 9
        stack.alignment = .fill
        stack.distribution = .fillEqually
        addSubview(stack)

        switch style {
        case .fixedBottom:
            stack.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(16)
                make.leading.trailing.equalToSuperview().inset(16)
                make.bottom.equalTo(safeAreaLayoutGuide).offset(-10)
                make.height.equalTo(40)
            }
        case .scrollInline:
            stack.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(8)
                make.leading.trailing.equalToSuperview().inset(16)
                make.bottom.equalToSuperview().offset(-8)
                make.height.equalTo(40)
            }
        }
    }

    func configure(actions: [OrderListCardAction]) {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        let hasActions = !actions.isEmpty
        stack.isHidden = !hasActions
        isHidden = !hasActions
        for action in actions {
            stack.addArrangedSubview(makeButton(action: action, primary: action.isPrimary))
        }
    }

    private func makeButton(action: OrderListCardAction, primary: Bool) -> UIButton {
        let button = UIButton(type: .custom)
        button.clipsToBounds = true
        button.layer.cornerRadius = 20

        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.cornerStyle = .capsule
            config.title = action.title
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .fdFont(ofSize: 16, weight: .medium)
                return outgoing
            }
            if primary {
                config.baseForegroundColor = .white
                config.background.backgroundColor = OrderDetailFigma.primaryOrange
                config.background.strokeWidth = 0
            } else {
                config.baseForegroundColor = OrderDetailFigma.primaryOrange
                config.background.backgroundColor = .clear
                config.background.strokeColor = OrderDetailFigma.primaryOrange
                config.background.strokeWidth = 0.5
            }
            button.configuration = config
        } else {
            button.setTitle(action.title, for: .normal)
            button.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
            if primary {
                button.backgroundColor = OrderDetailFigma.primaryOrange
                button.setTitleColor(.white, for: .normal)
                button.layer.borderWidth = 0
            } else {
                button.backgroundColor = .clear
                button.setTitleColor(OrderDetailFigma.primaryOrange, for: .normal)
                button.layer.borderWidth = 0.5
                button.layer.borderColor = OrderDetailFigma.primaryOrange.cgColor
            }
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
