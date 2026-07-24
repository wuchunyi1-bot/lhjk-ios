import UIKit
import SnapKit

// MARK: - Card 容器

final class OrderConfirmCardView: UIView {
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

// MARK: - 收货方式

final class OrderConfirmFulfillmentView: UIView {

    var onSelect: ((OrderFulfillmentMethod) -> Void)?

    private let titleLabel = UILabel()
    private let expressButton = UIButton(type: .system)
    private let pickupButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = "收货方式"
        titleLabel.font = .fdBodySemibold
        titleLabel.textColor = .fdText

        configureOption(expressButton, title: "快递配送", systemImage: "truck.box")
        configureOption(pickupButton, title: "机构自提", systemImage: "storefront")
        expressButton.addTarget(self, action: #selector(tapExpress), for: .touchUpInside)
        pickupButton.addTarget(self, action: #selector(tapPickup), for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [pickupButton, expressButton])
        row.axis = .horizontal
        row.spacing = 12
        row.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [titleLabel, row])
        stack.axis = .vertical
        stack.spacing = 12
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        expressButton.snp.makeConstraints { $0.height.equalTo(44) }
        pickupButton.snp.makeConstraints { $0.height.equalTo(44) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(selected: OrderFulfillmentMethod, supportsExpress: Bool) {
        expressButton.isHidden = !supportsExpress
        apply(expressButton, active: selected == .express)
        apply(pickupButton, active: selected == .selfPickup)
    }

    private func configureOption(_ button: UIButton, title: String, systemImage: String) {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(systemName: systemImage)
        config.imagePadding = 4
        config.baseForegroundColor = .fdText2
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .fdCaptionSemibold
            return outgoing
        }
        button.configuration = config
        button.layer.cornerRadius = 22
        button.layer.borderWidth = 1
        button.clipsToBounds = true
    }

    private func apply(_ button: UIButton, active: Bool) {
        if active {
            button.backgroundColor = .fdPrimarySoft
            button.layer.borderColor = UIColor.fdPrimary.cgColor
            button.configuration?.baseForegroundColor = .fdPrimary
        } else {
            button.backgroundColor = .fdSurface
            button.layer.borderColor = UIColor.fdBorder.cgColor
            button.configuration?.baseForegroundColor = .fdText2
        }
    }

    @objc private func tapExpress() { onSelect?(.express) }
    @objc private func tapPickup() { onSelect?(.selfPickup) }
}

// MARK: - 地址卡

final class OrderConfirmAddressView: UIView {

    var onTap: (() -> Void)?
    var onCall: (() -> Void)?

    private let iconView = UIImageView()
    private let personLabel = UILabel()
    private let detailLabel = UILabel()
    private let textStack = UIStackView()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
    private let callButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .fdPrimary
        iconView.backgroundColor = .fdPrimarySoft
        iconView.layer.cornerRadius = 19
        iconView.clipsToBounds = true

        personLabel.font = .fdBodySemibold
        personLabel.textColor = .fdText
        personLabel.numberOfLines = 1

        detailLabel.font = .fdCaption
        detailLabel.textColor = .fdSubtext
        detailLabel.numberOfLines = 0

        chevron.tintColor = .fdMuted
        chevron.contentMode = .scaleAspectFit

        callButton.setTitle("联系机构", for: .normal)
        callButton.titleLabel?.font = .fdCaptionSemibold
        callButton.setTitleColor(.fdPrimary, for: .normal)
        callButton.isHidden = true
        callButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        callButton.layer.cornerRadius = 14
        callButton.layer.borderWidth = 1
        callButton.layer.borderColor = UIColor.fdPrimary.withAlphaComponent(0.3).cgColor
        callButton.backgroundColor = .fdPrimarySoft
        callButton.addTarget(self, action: #selector(handleCall), for: .touchUpInside)

        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.alignment = .leading
        textStack.addArrangedSubview(personLabel)
        textStack.addArrangedSubview(detailLabel)

        addSubview(iconView)
        addSubview(textStack)
        addSubview(chevron)
        addSubview(callButton)

        iconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(16)
            $0.size.equalTo(38)
        }
        chevron.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalTo(iconView)
            $0.size.equalTo(14)
        }
        textStack.snp.makeConstraints {
            $0.leading.equalTo(iconView.snp.trailing).offset(12)
            $0.trailing.equalTo(chevron.snp.leading).offset(-8)
            $0.top.equalToSuperview().offset(16)
            $0.bottom.lessThanOrEqualToSuperview().offset(-16)
        }
        callButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-16)
            $0.height.equalTo(28)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configureExpress(address: MAddress?) {
        iconView.image = UIImage(systemName: "location.fill")
        callButton.isHidden = true
        chevron.isHidden = false
        isUserInteractionEnabled = true
        if let address {
            let name = address.name ?? ""
            let mobile = address.mobile ?? ""
            personLabel.text = [name, mobile].filter { !$0.isEmpty }.joined(separator: "  ")
            detailLabel.text = address.fullAddress
        } else {
            personLabel.text = "请选择收货地址"
            detailLabel.text = "点击添加或选择收货地址"
        }
        // 快递态：地址文本占满，按钮隐藏
        textStack.snp.remakeConstraints {
            $0.leading.equalTo(iconView.snp.trailing).offset(12)
            $0.trailing.equalTo(chevron.snp.leading).offset(-8)
            $0.top.equalToSuperview().offset(16)
            $0.bottom.equalToSuperview().offset(-16)
        }
        iconView.snp.remakeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(38)
        }
    }

    func configurePickup(name: String, address: String, showCall: Bool) {
        iconView.image = UIImage(systemName: "building.2.fill")
        personLabel.text = name
        detailLabel.text = address
        chevron.isHidden = true
        callButton.isHidden = !showCall
        isUserInteractionEnabled = false
        // 自提态：文本在上方，联系机构按钮右下
        iconView.snp.remakeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(16)
            $0.size.equalTo(38)
        }
        textStack.snp.remakeConstraints {
            $0.leading.equalTo(iconView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().offset(-16)
            $0.top.equalToSuperview().offset(16)
            $0.bottom.lessThanOrEqualTo(callButton.snp.top).offset(-12)
        }
    }

    @objc private func handleTap() { onTap?() }
    @objc private func handleCall() { onCall?() }
}

// MARK: - 机构自提卡（对齐 funde pickup-card）

final class OrderConfirmPickupView: UIView {

    var onCall: (() -> Void)?

    private let titleLabel = UILabel()
    private let hintLabel = UILabel()
    private let institutionIcon = UIImageView(image: UIImage(systemName: "building.2"))
    private let institutionLabel = UILabel()
    private let addressLabel = UILabel()
    private let divider = UIView()
    private let callRow = UIView()
    private let callButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.text = "自提地址"
        titleLabel.font = .fdBodySemibold
        titleLabel.textColor = .fdText

        hintLabel.text = "请前往以下机构领取商品/设备"
        hintLabel.font = .fdCaption
        hintLabel.textColor = .fdSubtext
        hintLabel.textAlignment = .right
        hintLabel.numberOfLines = 2

        institutionIcon.tintColor = .fdText
        institutionIcon.contentMode = .scaleAspectFit
        institutionIcon.snp.makeConstraints { $0.size.equalTo(16) }

        institutionLabel.font = .fdBodySemibold
        institutionLabel.textColor = .fdText
        institutionLabel.numberOfLines = 2

        addressLabel.font = .fdCaption
        addressLabel.textColor = .fdSubtext
        addressLabel.numberOfLines = 0

        divider.backgroundColor = .fdBorder

        var callConfig = UIButton.Configuration.plain()
        callConfig.title = "联系机构"
        callConfig.image = UIImage(systemName: "phone")
        callConfig.imagePadding = 4
        callConfig.baseForegroundColor = .fdPrimary
        callConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .fdCaptionSemibold
            return outgoing
        }
        callButton.configuration = callConfig
        callButton.addTarget(self, action: #selector(tapCall), for: .touchUpInside)

        let head = UIStackView(arrangedSubviews: [titleLabel, hintLabel])
        head.axis = .horizontal
        head.spacing = 8
        head.alignment = .top
        hintLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let nameRow = UIStackView(arrangedSubviews: [institutionIcon, institutionLabel])
        nameRow.axis = .horizontal
        nameRow.spacing = 6
        nameRow.alignment = .top

        let callRow = UIView()
        callRow.addSubview(callButton)
        callButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.bottom.equalToSuperview()
            $0.height.equalTo(40)
        }

        let stack = UIStackView(arrangedSubviews: [head, nameRow, addressLabel, divider, callRow])
        stack.axis = .vertical
        stack.spacing = 8
        stack.setCustomSpacing(12, after: addressLabel)
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        divider.snp.makeConstraints { $0.height.equalTo(1) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(name: String, address: String, showCall: Bool) {
        institutionLabel.text = name
        addressLabel.text = address
        callRow.isHidden = !showCall
        divider.isHidden = !showCall
    }

    @objc private func tapCall() { onCall?() }
}

// MARK: - 套餐卡

final class OrderConfirmPackageView: UIView {

    var onToggleContent: (() -> Void)?

    private let nameLabel = UILabel()
    private let introLabel = UILabel()
    private let amountLabel = UILabel()
    private let contentTitle = UILabel()
    private let contentStack = UIStackView()
    private let toggleButton = UIButton(type: .system)
    private let divider = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        nameLabel.font = .fdBodySemibold
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 2

        introLabel.font = .fdCaption
        introLabel.textColor = .fdSubtext
        introLabel.numberOfLines = 1

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

        let stack = UIStackView(arrangedSubviews: [top, divider, contentTitle, contentStack, toggleButton])
        stack.axis = .vertical
        stack.spacing = 12
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        divider.snp.makeConstraints { $0.height.equalTo(1) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(
        name: String,
        subtitle: String,
        amount: Double,
        items: [PackageOrderDraftItem],
        canExpand: Bool,
        expanded: Bool,
        totalCount: Int
    ) {
        nameLabel.text = name
        introLabel.text = subtitle
        introLabel.isHidden = subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        amountLabel.text = OrderConfirmMoney.yen(amount)

        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for item in items {
            contentStack.addArrangedSubview(makeContentRow(item))
        }

        toggleButton.isHidden = !canExpand
        if canExpand {
            let title = expanded ? "收起" : "展开（共\(totalCount)项）"
            toggleButton.setTitle(title, for: .normal)
        }
    }

    private func makeContentRow(_ item: PackageOrderDraftItem) -> UIView {
        let name = UILabel()
        name.font = .fdCaption
        name.textColor = .fdText2
        name.text = item.name
        name.lineBreakMode = .byTruncatingTail

        let meta = UILabel()
        meta.font = .fdCaption
        meta.textColor = .fdSubtext
        meta.text = item.unit.isEmpty ? item.qty : "\(item.qty)\(item.unit)"
        meta.setContentHuggingPriority(.required, for: .horizontal)

        let price = UILabel()
        price.font = .fdCaption
        price.textColor = .fdSubtext
        price.text = OrderConfirmMoney.yen(item.price)
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

// MARK: - 选择行

final class OrderConfirmSelectRow: UIControl {

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdSurface
        layer.cornerRadius = 12

        titleLabel.font = .fdBodySemibold
        titleLabel.textColor = .fdText

        valueLabel.font = .fdCaptionSemibold
        valueLabel.textColor = .fdText
        valueLabel.textAlignment = .right
        valueLabel.lineBreakMode = .byTruncatingTail

        chevron.tintColor = .fdMuted
        chevron.contentMode = .scaleAspectFit

        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(chevron)

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }
        chevron.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(14)
        }
        valueLabel.snp.makeConstraints {
            $0.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(12)
            $0.trailing.equalTo(chevron.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
        }
        snp.makeConstraints { $0.height.equalTo(52) }
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, value: String, placeholder: Bool, emphasis: Bool = false) {
        titleLabel.text = title
        valueLabel.text = value
        if emphasis {
            valueLabel.textColor = .fdPrimary
        } else {
            valueLabel.textColor = placeholder ? .fdMuted : .fdText2
        }
        titleLabel.font = .fdBodySemibold
        valueLabel.font = .fdCaptionSemibold
    }
}

// MARK: - 虚线分隔

private final class OrderConfirmDashedLineView: UIView {
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

// MARK: - 费用明细

final class OrderConfirmFeeView: UIView {

    private enum Metrics {
        static let rowHeight: CGFloat = 40
        static let labelFont: UIFont = .fdBody
        static let valueFont: UIFont = .fdBody
    }

    private let card = OrderConfirmCardView()
    private let titleLabel = UILabel()
    private let rowsStack = UIStackView()
    private let totalDivider = OrderConfirmDashedLineView()
    private let totalLeft = UILabel()
    private let totalRight = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.text = "费用明细"
        titleLabel.font = .fdBodySemibold
        titleLabel.textColor = .fdText

        rowsStack.axis = .vertical
        rowsStack.spacing = 0

        totalLeft.text = "应付金额"
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

        addSubview(card)
        card.addSubview(root)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }
        root.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        totalDivider.snp.makeConstraints { $0.height.equalTo(1) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(
        packageAmount: Double,
        shipping: Double,
        coupon: Double,
        benefit: Double,
        payable: Double
    ) {
        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        rowsStack.addArrangedSubview(row("套餐金额", OrderConfirmMoney.yen(packageAmount)))
        rowsStack.addArrangedSubview(row("运费", OrderConfirmMoney.yen(shipping)))
        rowsStack.addArrangedSubview(row("优惠券抵扣", "-\(OrderConfirmMoney.yen(coupon))", minusValue: coupon > 0))
        rowsStack.addArrangedSubview(row("权益卡抵扣", "-\(OrderConfirmMoney.yen(benefit))", minusValue: benefit > 0))
        totalRight.text = OrderConfirmMoney.yen(payable)
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

// MARK: - 支付方式

final class OrderConfirmPayMethodView: UIView {

    var onSelect: ((OrderPayMethod) -> Void)?

    private let card = OrderConfirmCardView()
    private let titleLabel = UILabel()
    private let wechatPill = PayMethodPill(
        method: .wechat,
        shortTitle: "微信",
        iconName: "bubble.left.and.bubble.right.fill"
    )
    private let alipayPill = PayMethodPill(
        method: .alipay,
        shortTitle: "支付宝",
        iconName: "a.circle.fill"
    )

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.text = "支付方式"
        titleLabel.font = .fdBodySemibold
        titleLabel.textColor = .fdText

        wechatPill.addTarget(self, action: #selector(tapWechat), for: .touchUpInside)
        alipayPill.addTarget(self, action: #selector(tapAlipay), for: .touchUpInside)

        let pillRow = UIStackView(arrangedSubviews: [wechatPill, alipayPill])
        pillRow.axis = .horizontal
        pillRow.spacing = 8
        pillRow.distribution = .fillEqually

        let root = UIStackView(arrangedSubviews: [titleLabel, pillRow])
        root.axis = .vertical
        root.spacing = 8

        addSubview(card)
        card.addSubview(root)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }
        root.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(
        selected: OrderPayMethod,
        supportsWechat: Bool = true,
        supportsAlipay: Bool = true
    ) {
        wechatPill.isHidden = !supportsWechat
        alipayPill.isHidden = !supportsAlipay
        wechatPill.setSelected(selected == .wechat)
        alipayPill.setSelected(selected == .alipay)
    }

    @objc private func tapWechat() { onSelect?(.wechat) }
    @objc private func tapAlipay() { onSelect?(.alipay) }
}

private final class PayMethodPill: UIControl {
    private let dotView = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    let method: OrderPayMethod

    init(method: OrderPayMethod, shortTitle: String, iconName: String) {
        self.method = method
        super.init(frame: .zero)

        layer.cornerRadius = 22
        layer.borderWidth = 1
        layer.borderColor = UIColor.fdBorder.cgColor
        backgroundColor = .fdSurface

        dotView.layer.cornerRadius = 5
        dotView.layer.borderWidth = 1
        dotView.layer.borderColor = UIColor.fdBorderStrong.cgColor
        dotView.backgroundColor = .fdSurface
        dotView.isUserInteractionEnabled = false

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        iconView.image = UIImage(systemName: iconName, withConfiguration: iconConfig)
        iconView.tintColor = .fdText2
        iconView.contentMode = .scaleAspectFit
        iconView.isUserInteractionEnabled = false

        titleLabel.text = shortTitle
        titleLabel.font = .fdCaptionSemibold
        titleLabel.textColor = .fdText2
        titleLabel.isUserInteractionEnabled = false

        let content = UIStackView(arrangedSubviews: [dotView, iconView, titleLabel])
        content.axis = .horizontal
        content.spacing = 6
        content.alignment = .center
        content.isUserInteractionEnabled = false

        addSubview(content)
        content.snp.makeConstraints { $0.center.equalToSuperview() }
        snp.makeConstraints { $0.height.equalTo(44) }
        dotView.snp.makeConstraints { $0.size.equalTo(10) }
        iconView.snp.makeConstraints { $0.size.equalTo(18) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func setSelected(_ selected: Bool) {
        if selected {
            layer.borderColor = UIColor.fdPrimary.cgColor
            backgroundColor = .fdPrimarySoft
            dotView.layer.borderColor = UIColor.fdPrimary.cgColor
            dotView.backgroundColor = .fdPrimary
            iconView.tintColor = .fdPrimary
            titleLabel.textColor = .fdPrimary
        } else {
            layer.borderColor = UIColor.fdBorder.cgColor
            backgroundColor = .fdSurface
            dotView.layer.borderColor = UIColor.fdBorderStrong.cgColor
            dotView.backgroundColor = .fdSurface
            iconView.tintColor = .fdText2
            titleLabel.textColor = .fdText2
        }
    }
}

// MARK: - 底栏

final class OrderConfirmSubmitBar: UIView {

    var onPay: (() -> Void)?

    private let label = UILabel()
    private let priceLabel = UILabel()
    private let payButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdSurface
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 8

        label.text = "应付金额"
        label.font = .fdCaption
        label.textColor = .fdSubtext

        priceLabel.font = .fdMonoFont(ofSize: 20, weight: .heavy)
        priceLabel.textColor = .fdPrimary

        payButton.setTitle("立即支付", for: .normal)
        payButton.titleLabel?.font = .fdBodySemibold
        payButton.setTitleColor(.white, for: .normal)
        payButton.backgroundColor = .fdPrimary
        payButton.layer.cornerRadius = 22
        payButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 28, bottom: 0, right: 28)
        payButton.addTarget(self, action: #selector(tapPay), for: .touchUpInside)

        let copy = UIStackView(arrangedSubviews: [label, priceLabel])
        copy.axis = .vertical
        copy.spacing = 2

        addSubview(copy)
        addSubview(payButton)
        copy.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalTo(payButton)
        }
        payButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.top.equalToSuperview().offset(12)
            $0.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-14)
            $0.height.equalTo(44)
            $0.width.greaterThanOrEqualTo(120)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(amount: Double, submitting: Bool) {
        priceLabel.text = OrderConfirmMoney.yen(amount)
        payButton.isEnabled = !submitting
        payButton.alpha = submitting ? 0.6 : 1
        payButton.setTitle(submitting ? "提交中..." : (amount <= 0 ? "确认下单" : "立即支付"), for: .normal)
    }

    @objc private func tapPay() { onPay?() }
}

// MARK: - Money

enum OrderConfirmMoney {
    static func yen(_ value: Double) -> String {
        let safe = max(0, value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        let num = formatter.string(from: NSNumber(value: safe))
            ?? String(format: "%.2f", safe)
        return "¥\(num)"
    }
}
