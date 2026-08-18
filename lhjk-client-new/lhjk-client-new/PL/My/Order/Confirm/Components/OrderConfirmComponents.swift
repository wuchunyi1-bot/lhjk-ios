import UIKit
import SnapKit

private enum OrderConfirmFigma {
    static let title = UIColor(hexString: "#1F2942")
    static let subtitle = UIColor(hexString: "#8591AB")
    static let primary = UIColor(hexString: "#FF7A50")
    static let selectionOrange = UIColor(hexString: "#FF9D45")
    static let cardBackground = UIColor(hexString: "#FDF6F3")
    static let pinBackground = UIColor(hexString: "#FFF2E6")
    static let hintBackground = UIColor(red: 255 / 255, green: 112 / 255, blue: 21 / 255, alpha: 0.08)
    static let hintText = UIColor(hexString: "#FF7015")
}

// MARK: - Card 容器

final class OrderConfirmCardView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 6
        layer.shadowOpacity = 0.03
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - 收货方式（对齐 Figma 3566:7152）

final class OrderConfirmFulfillmentView: UIView {

    var onSelect: ((OrderFulfillmentMethod) -> Void)?

    private let titleLabel = UILabel()
    private let optionStack = UIStackView()
    private let pickupOption = OrderConfirmFulfillmentOptionView(
        title: "机构自提",
        iconName: "order_confirm_fulfillment_pickup",
        iconSize: 10
    )
    private let expressOption = OrderConfirmFulfillmentOptionView(
        title: "快递配送",
        iconName: "order_confirm_fulfillment_express",
        iconSize: 11
    )

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.text = "收货方式"
        titleLabel.font = .fdFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = OrderConfirmFigma.title

        optionStack.axis = .horizontal
        optionStack.spacing = 13
        optionStack.distribution = .fillEqually
        optionStack.addArrangedSubview(pickupOption)
        optionStack.addArrangedSubview(expressOption)

        addSubview(titleLabel)
        addSubview(optionStack)
        titleLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(27)
        }
        optionStack.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(58)
            $0.bottom.equalToSuperview().offset(-16)
        }

        pickupOption.addTarget(self, action: #selector(tapPickup), for: .touchUpInside)
        expressOption.addTarget(self, action: #selector(tapExpress), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(selected: OrderFulfillmentMethod, supportsExpress: Bool) {
        expressOption.isHidden = !supportsExpress
        pickupOption.configure(selected: selected == .selfPickup)
        expressOption.configure(selected: selected == .express)
    }

    @objc private func tapExpress() { onSelect?(.express) }
    @objc private func tapPickup() { onSelect?(.selfPickup) }
}

private final class OrderConfirmFulfillmentOptionView: UIControl {
    private let iconBackground = UIView()
    private let iconView: UIImageView
    private let titleLabel = UILabel()
    private let selectedBadge = UIImageView(image: UIImage(named: "order_confirm_fulfillment_selected"))
    private let contentStack = UIStackView()
    private let iconSize: CGFloat

    init(title: String, iconName: String, iconSize: CGFloat) {
        self.iconView = UIImageView(image: UIImage(named: iconName))
        self.iconSize = iconSize
        super.init(frame: .zero)

        backgroundColor = OrderConfirmFigma.cardBackground
        layer.cornerRadius = 12
        clipsToBounds = true

        iconBackground.backgroundColor = OrderConfirmFigma.selectionOrange
        iconBackground.layer.cornerRadius = 9
        iconBackground.clipsToBounds = true
        iconView.contentMode = .scaleAspectFit
        iconBackground.addSubview(iconView)
        iconBackground.snp.makeConstraints { $0.size.equalTo(18) }
        iconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(iconSize)
        }

        titleLabel.text = title
        titleLabel.font = .fdFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = OrderConfirmFigma.title

        contentStack.axis = .horizontal
        contentStack.spacing = 8
        contentStack.alignment = .center
        contentStack.isUserInteractionEnabled = false
        contentStack.addArrangedSubview(iconBackground)
        contentStack.addArrangedSubview(titleLabel)
        addSubview(contentStack)
        contentStack.snp.makeConstraints { $0.center.equalToSuperview() }

        selectedBadge.contentMode = .scaleAspectFit
        selectedBadge.isHidden = true
        addSubview(selectedBadge)
        selectedBadge.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-1.5)
            $0.bottom.equalToSuperview().offset(-1.5)
            $0.size.equalTo(CGSize(width: 21.5, height: 21.5))
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(selected: Bool) {
        isSelected = selected
        layer.borderWidth = selected ? 1 : 0
        layer.borderColor = OrderConfirmFigma.primary.cgColor
        selectedBadge.isHidden = !selected
    }
}

// MARK: - 快递收货地址（背景节点 3566:7493 / 3566:7651）

final class OrderConfirmAddressView: UIView {

    var onTap: (() -> Void)?

    private let backgroundView = UIImageView()
    private let avatarContainer = UIView()
    private let avatarView = UIImageView()
    private let personStack = UIStackView()
    private let personLabel = UILabel()
    private let mobileLabel = UILabel()
    private let addressLabel = UILabel()
    private let chevronGroup = UIView()
    private let chevronCircle = UIImageView()
    private let chevronView = UIImageView()
    private let selectButton = UIButton(type: .system)
    private var heightConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))

        backgroundView.contentMode = .scaleToFill
        backgroundView.isUserInteractionEnabled = false
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        avatarContainer.backgroundColor = OrderConfirmFigma.pinBackground
        avatarContainer.layer.cornerRadius = 22
        avatarContainer.clipsToBounds = true
        addSubview(avatarContainer)
        avatarContainer.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.top.equalToSuperview().offset(18)
            $0.size.equalTo(44)
        }

        avatarView.contentMode = .scaleAspectFit
        avatarContainer.addSubview(avatarView)
        avatarView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(32)
        }

        addSubview(chevronGroup)
        personStack.axis = .horizontal
        personStack.spacing = 8
        personStack.alignment = .center
        personStack.isUserInteractionEnabled = false
        addSubview(personStack)
        personStack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(68)
            $0.top.equalToSuperview().offset(12)
            $0.trailing.lessThanOrEqualTo(chevronGroup.snp.leading).offset(-12)
            $0.height.equalTo(27)
        }

        personLabel.font = .fdFont(ofSize: 16, weight: .medium)
        personLabel.textColor = OrderConfirmFigma.title
        personLabel.setContentHuggingPriority(.required, for: .horizontal)
        personLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        mobileLabel.font = .fdFont(ofSize: 16, weight: .medium)
        mobileLabel.textColor = OrderConfirmFigma.title
        mobileLabel.setContentHuggingPriority(.required, for: .horizontal)
        mobileLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        personStack.addArrangedSubview(personLabel)
        personStack.addArrangedSubview(mobileLabel)

        addressLabel.font = .fdFont(ofSize: 14, weight: .regular)
        addressLabel.textColor = OrderConfirmFigma.subtitle
        addressLabel.numberOfLines = 1
        addressLabel.lineBreakMode = .byTruncatingTail
        addSubview(addressLabel)
        addressLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(68)
            $0.top.equalToSuperview().offset(41)
            $0.trailing.equalToSuperview().offset(-12)
            $0.height.equalTo(27)
        }

        chevronCircle.image = UIImage(named: "order_confirm_address_chevron_circle")
        chevronCircle.contentMode = .scaleAspectFit
        chevronView.image = UIImage(named: "order_confirm_address_chevron")
        chevronView.contentMode = .scaleAspectFit
        chevronGroup.addSubview(chevronCircle)
        chevronGroup.addSubview(chevronView)
        chevronGroup.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-12)
            $0.top.equalToSuperview().offset(17)
            $0.size.equalTo(18)
        }
        chevronCircle.snp.makeConstraints { $0.edges.equalToSuperview() }
        chevronView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(14)
        }

        selectButton.setTitle("去选择", for: .normal)
        selectButton.titleLabel?.font = .fdFont(ofSize: 12, weight: .medium)
        selectButton.setTitleColor(OrderConfirmFigma.primary, for: .normal)
        selectButton.layer.cornerRadius = 14
        selectButton.layer.borderWidth = 0.5
        selectButton.layer.borderColor = OrderConfirmFigma.primary.cgColor
        selectButton.backgroundColor = .clear
        selectButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        addSubview(selectButton)
        selectButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-12)
            $0.top.equalToSuperview().offset(22)
            $0.size.equalTo(CGSize(width: 70, height: 28))
        }

        snp.makeConstraints {
            heightConstraint = $0.height.equalTo(80).constraint
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configureExpress(address: MAddress?) {
        let hasAddress = address != nil
        backgroundView.image = UIImage(named: hasAddress
            ? "order_confirm_address_express_bg"
            : "order_confirm_address_empty_bg")
        avatarView.image = UIImage(named: hasAddress
            ? "order_confirm_express_pin"
            : "order_confirm_empty_address_pin")

        if let address {
            personLabel.text = address.name?.trimmingCharacters(in: .whitespacesAndNewlines)
            mobileLabel.text = address.mobile?.trimmingCharacters(in: .whitespacesAndNewlines)
            personLabel.isHidden = (personLabel.text ?? "").isEmpty
            mobileLabel.isHidden = (mobileLabel.text ?? "").isEmpty
            addressLabel.text = address.fullAddress
            addressLabel.isHidden = false
            avatarContainer.snp.updateConstraints { $0.top.equalToSuperview().offset(18) }
            personStack.snp.updateConstraints { $0.top.equalToSuperview().offset(12) }
            chevronGroup.isHidden = false
            selectButton.isHidden = true
            heightConstraint?.update(offset: 80)
        } else {
            personLabel.text = "暂无默认地址"
            mobileLabel.text = nil
            personLabel.isHidden = false
            mobileLabel.isHidden = true
            addressLabel.text = nil
            addressLabel.isHidden = true
            avatarContainer.snp.updateConstraints { $0.top.equalToSuperview().offset(14) }
            personStack.snp.updateConstraints { $0.top.equalToSuperview().offset(23) }
            chevronGroup.isHidden = true
            selectButton.isHidden = false
            heightConstraint?.update(offset: 72)
        }
        setNeedsLayout()
    }

    @objc private func handleTap() { onTap?() }
}

// MARK: - 机构自提地址（背景节点 3566:7680）

final class OrderConfirmPickupView: UIView {

    var onCall: (() -> Void)?

    private let backgroundView = UIImageView(image: UIImage(named: "order_confirm_address_pickup_bg"))
    private let titleLabel = UILabel()
    private let hintContainer = UIView()
    private let hintLabel = UILabel()
    private let pinContainer = UIView()
    private let pinView = UIImageView(image: UIImage(named: "order_confirm_pickup_pin"))
    private let institutionLabel = UILabel()
    private let addressLabel = UILabel()
    private let callBar = OrderConfirmInstitutionCallBar()
    private var heightConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true

        backgroundView.contentMode = .scaleToFill
        backgroundView.isUserInteractionEnabled = false
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { $0.edges.equalToSuperview() }

        titleLabel.text = "自提地址"
        titleLabel.font = .fdFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = OrderConfirmFigma.title
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(16)
            $0.height.equalTo(24)
        }

        hintContainer.backgroundColor = OrderConfirmFigma.hintBackground
        hintContainer.layer.cornerRadius = 11.5
        hintContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        hintContainer.clipsToBounds = true
        addSubview(hintContainer)
        hintContainer.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.top.equalToSuperview().offset(16)
            $0.size.equalTo(CGSize(width: 156, height: 23))
        }

        hintLabel.text = "请前往以下机构领取商品/设备"
        hintLabel.font = .fdFont(ofSize: 10, weight: .regular)
        hintLabel.textColor = OrderConfirmFigma.hintText
        hintLabel.numberOfLines = 1
        hintContainer.addSubview(hintLabel)
        hintLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.trailing.lessThanOrEqualToSuperview().offset(-4)
            $0.centerY.equalToSuperview()
        }

        pinContainer.backgroundColor = OrderConfirmFigma.pinBackground
        pinContainer.layer.cornerRadius = 8
        pinContainer.clipsToBounds = true
        addSubview(pinContainer)
        pinContainer.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(58)
            $0.size.equalTo(16)
        }
        pinView.contentMode = .scaleAspectFit
        pinContainer.addSubview(pinView)
        pinView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(12)
        }

        institutionLabel.font = .fdFont(ofSize: 16, weight: .regular)
        institutionLabel.textColor = OrderConfirmFigma.title
        institutionLabel.numberOfLines = 1
        addSubview(institutionLabel)
        institutionLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(39)
            $0.top.equalToSuperview().offset(52)
            $0.trailing.equalToSuperview().offset(-12)
            $0.height.equalTo(27)
        }

        addressLabel.font = .fdFont(ofSize: 14, weight: .regular)
        addressLabel.textColor = OrderConfirmFigma.subtitle
        addressLabel.numberOfLines = 1
        addressLabel.lineBreakMode = .byTruncatingTail
        addSubview(addressLabel)
        addressLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(39)
            $0.top.equalToSuperview().offset(81)
            $0.trailing.equalToSuperview().offset(-12)
            $0.height.equalTo(27)
        }

        addSubview(callBar)
        callBar.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(-8)
            $0.trailing.equalToSuperview().offset(8)
            $0.top.equalToSuperview().offset(120)
            $0.height.equalTo(46)
        }
        callBar.onCall = { [weak self] in
            self?.onCall?()
        }

        snp.makeConstraints {
            heightConstraint = $0.height.equalTo(158).constraint
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(name: String, address: String, showCall: Bool) {
        institutionLabel.text = name
        addressLabel.text = address
        callBar.isHidden = !showCall
        heightConstraint?.update(offset: showCall ? 158 : 112)
    }
}

private final class OrderConfirmInstitutionCallBar: UIView {
    var onCall: (() -> Void)?

    private let callControl = UIControl()
    private let iconView = UIImageView(image: UIImage(named: "order_confirm_phone"))
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        iconView.contentMode = .scaleAspectFit
        iconView.isUserInteractionEnabled = false
        iconView.snp.makeConstraints { $0.size.equalTo(14) }
        titleLabel.text = "联系机构"
        titleLabel.font = .fdFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = OrderConfirmFigma.primary
        titleLabel.isUserInteractionEnabled = false

        let content = UIStackView(arrangedSubviews: [iconView, titleLabel])
        content.axis = .horizontal
        content.spacing = 4
        content.alignment = .center
        content.isUserInteractionEnabled = false
        callControl.addSubview(content)
        content.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.height.equalTo(14)
        }
        callControl.addTarget(self, action: #selector(tapCall), for: .touchUpInside)
        addSubview(callControl)
        callControl.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func tapCall() { onCall?() }
}

// MARK: - 套餐卡（对齐 Figma 3479:8213）

final class OrderConfirmPackageView: UIView {

    var onToggleContent: (() -> Void)?

    private let nameLabel = UILabel()
    private let introLabel = UILabel()
    private let priceLabel = UILabel()

    // 浅橙渐变容器
    private let itemsContainer = PackageItemsGradientContainer()
    private let sectionHeaderView = UIView()
    private let sectionIcon = UIImageView()
    private let sectionTitleLabel = UILabel()
    private let contentStack = UIStackView()
    private let toggleContainer = UIControl()
    private let toggleTitleLabel = UILabel()
    private let toggleIcon = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        nameLabel.font = .fdFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = UIColor(hexString: "#1F2942")
        nameLabel.numberOfLines = 2

        introLabel.font = .fdFont(ofSize: 14, weight: .regular)
        introLabel.textColor = UIColor(hexString: "#8591AB")
        introLabel.numberOfLines = 1

        priceLabel.textAlignment = .right
        priceLabel.setContentHuggingPriority(.required, for: .horizontal)
        priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        // 头部信息
        let textCol = UIStackView(arrangedSubviews: [nameLabel, introLabel])
        textCol.axis = .vertical
        textCol.spacing = 4

        let topRow = UIStackView(arrangedSubviews: [textCol, priceLabel])
        topRow.axis = .horizontal
        topRow.alignment = .top
        topRow.spacing = 12

        // 套餐内容渐变容器内部结构
        sectionIcon.image = UIImage(named: "order_confirm_package_icon")
        sectionIcon.contentMode = .scaleAspectFit
        sectionIcon.snp.makeConstraints { $0.size.equalTo(16) }

        sectionTitleLabel.text = "套餐内容"
        sectionTitleLabel.font = .fdFont(ofSize: 14, weight: .medium)
        sectionTitleLabel.textColor = UIColor(hexString: "#1F2942")

        let headerStack = UIStackView(arrangedSubviews: [sectionIcon, sectionTitleLabel])
        headerStack.axis = .horizontal
        headerStack.spacing = 4
        headerStack.alignment = .center

        sectionHeaderView.addSubview(headerStack)
        headerStack.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
        }

        contentStack.axis = .vertical
        contentStack.spacing = 12

        // 展开/收起按钮
        toggleTitleLabel.font = .fdFont(ofSize: 12, weight: .regular)
        toggleTitleLabel.textColor = UIColor(hexString: "#8591AB")

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

        let itemsInnerStack = UIStackView(arrangedSubviews: [sectionHeaderView, contentStack, toggleContainer])
        itemsInnerStack.axis = .vertical
        itemsInnerStack.spacing = 12

        itemsContainer.addSubview(itemsInnerStack)
        itemsInnerStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(12)
        }

        let mainStack = UIStackView(arrangedSubviews: [topRow, itemsContainer])
        mainStack.axis = .vertical
        mainStack.spacing = 16

        addSubview(mainStack)
        mainStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
        }
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

        priceLabel.attributedText = OrderConfirmMoney.formatPrice(amount, symbolSize: 16, valueSize: 18, color: UIColor(hexString: "#1F2942"))

        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for item in items {
            contentStack.addArrangedSubview(makeContentRow(item))
        }

        toggleContainer.isHidden = !canExpand
        if canExpand {
            let title = expanded ? "收起" : "展开 (共\(totalCount)项)"
            toggleTitleLabel.text = title
            toggleIcon.image = UIImage(named: expanded ? "order_confirm_collapse_icon" : "order_confirm_expand_icon")
        }
    }

    private func makeContentRow(_ item: PackageOrderDraftItem) -> UIView {
        let name = UILabel()
        name.font = .fdFont(ofSize: 12, weight: .regular)
        name.textColor = UIColor(hexString: "#1F2942")
        name.text = item.name
        name.lineBreakMode = .byTruncatingTail

        let meta = UILabel()
        meta.font = .fdFont(ofSize: 12, weight: .regular)
        meta.textColor = UIColor(hexString: "#1F2942")
        meta.text = item.unit.isEmpty ? item.qty : "\(item.qty)\(item.unit)"
        meta.textAlignment = .right
        meta.setContentHuggingPriority(.required, for: .horizontal)

        let price = UILabel()
        price.font = .fdFont(ofSize: 12, weight: .medium)
        price.textColor = UIColor(hexString: "#1F2942")
        price.text = OrderConfirmMoney.yen(item.price)
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

/// 浅橙色渐变背景容器
private final class PackageItemsGradientContainer: UIView {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 12
        clipsToBounds = true

        gradientLayer.colors = [
            UIColor(red: 255/255, green: 178/255, blue: 154/255, alpha: 0.12).cgColor,
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

// MARK: - 三合一卡片：订单备注 / 优惠券 / 权益卡（对齐 Figma 3479:8247）

final class OrderConfirmOptionsCardView: UIView {

    var onTapRemark: (() -> Void)?
    var onTapCoupon: (() -> Void)?
    var onTapBenefit: (() -> Void)?

    private let card = OrderConfirmCardView()

    // 备注行
    private let remarkRow = UIControl()
    private let remarkIcon = UIImageView(image: UIImage(named: "order_confirm_remark_icon"))
    private let remarkTitleLabel = UILabel()
    private let remarkValueLabel = UILabel()
    private let remarkArrow = UIImageView(image: UIImage(named: "order_confirm_arrow_right"))
    private let divider1 = UIView()

    // 优惠券行
    private let couponRow = UIControl()
    private let couponIcon = UIImageView(image: UIImage(named: "order_confirm_coupon_icon"))
    private let couponTitleLabel = UILabel()
    private let couponBadge = UIImageView(image: UIImage(named: "order_confirm_coupon_badge"))
    private let couponValueLabel = UILabel()
    private let couponArrow = UIImageView(image: UIImage(named: "order_confirm_arrow_right"))
    private let divider2 = UIView()

    // 权益卡行
    private let benefitRow = UIControl()
    private let benefitIcon = UIImageView(image: UIImage(named: "order_confirm_benefit_icon"))
    private let benefitTitleLabel = UILabel()
    private let benefitValueLabel = UILabel()
    private let benefitArrow = UIImageView(image: UIImage(named: "order_confirm_arrow_right"))

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }

        // Setup 备注
        setupRow(
            container: remarkRow,
            icon: remarkIcon,
            titleLabel: remarkTitleLabel,
            title: "订单备注",
            valueLabel: remarkValueLabel,
            arrow: remarkArrow,
            action: #selector(handleRemark)
        )

        // Setup 优惠券
        setupCouponRow()

        // Setup 权益卡
        setupRow(
            container: benefitRow,
            icon: benefitIcon,
            titleLabel: benefitTitleLabel,
            title: "权益卡",
            valueLabel: benefitValueLabel,
            arrow: benefitArrow,
            action: #selector(handleBenefit)
        )

        divider1.backgroundColor = UIColor(hexString: "#F0F0F0")
        divider2.backgroundColor = UIColor(hexString: "#F0F0F0")

        let stack = UIStackView(arrangedSubviews: [remarkRow, divider1, couponRow, divider2, benefitRow])
        stack.axis = .vertical
        stack.spacing = 0

        card.addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
        }

        remarkRow.snp.makeConstraints { $0.height.equalTo(48) }
        couponRow.snp.makeConstraints { $0.height.equalTo(48) }
        benefitRow.snp.makeConstraints { $0.height.equalTo(48) }
        divider1.snp.makeConstraints { $0.height.equalTo(0.5) }
        divider2.snp.makeConstraints { $0.height.equalTo(0.5) }
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupRow(
        container: UIControl,
        icon: UIImageView,
        titleLabel: UILabel,
        title: String,
        valueLabel: UILabel,
        arrow: UIImageView,
        action: Selector
    ) {
        icon.contentMode = .scaleAspectFit
        icon.snp.makeConstraints { $0.size.equalTo(16) }

        titleLabel.text = title
        titleLabel.font = .fdFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = UIColor(hexString: "#1F2942")

        let leftStack = UIStackView(arrangedSubviews: [icon, titleLabel])
        leftStack.axis = .horizontal
        leftStack.spacing = 6
        leftStack.alignment = .center
        leftStack.isUserInteractionEnabled = false

        valueLabel.font = .fdFont(ofSize: 12, weight: .regular)
        valueLabel.textColor = UIColor(hexString: "#717885")
        valueLabel.textAlignment = .right
        valueLabel.lineBreakMode = .byTruncatingTail
        valueLabel.isUserInteractionEnabled = false

        arrow.contentMode = .scaleAspectFit
        arrow.snp.makeConstraints { $0.size.equalTo(12) }
        arrow.isUserInteractionEnabled = false

        let rightStack = UIStackView(arrangedSubviews: [valueLabel, arrow])
        rightStack.axis = .horizontal
        rightStack.spacing = 2
        rightStack.alignment = .center
        rightStack.isUserInteractionEnabled = false

        container.addSubview(leftStack)
        container.addSubview(rightStack)

        leftStack.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
        }
        rightStack.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
            $0.leading.greaterThanOrEqualTo(leftStack.snp.trailing).offset(12)
        }
        container.addTarget(self, action: action, for: .touchUpInside)
    }

    private func setupCouponRow() {
        couponIcon.contentMode = .scaleAspectFit
        couponIcon.snp.makeConstraints { $0.size.equalTo(16) }

        couponTitleLabel.text = "优惠券"
        couponTitleLabel.font = .fdFont(ofSize: 14, weight: .medium)
        couponTitleLabel.textColor = UIColor(hexString: "#1F2942")

        let leftStack = UIStackView(arrangedSubviews: [couponIcon, couponTitleLabel])
        leftStack.axis = .horizontal
        leftStack.spacing = 6
        leftStack.alignment = .center
        leftStack.isUserInteractionEnabled = false

        couponBadge.contentMode = .scaleAspectFit
        couponBadge.snp.makeConstraints { $0.size.equalTo(14) }

        couponValueLabel.font = .fdFont(ofSize: 12, weight: .regular)
        couponValueLabel.textColor = UIColor(hexString: "#717885")
        couponValueLabel.textAlignment = .right
        couponValueLabel.lineBreakMode = .byTruncatingTail

        couponArrow.contentMode = .scaleAspectFit
        couponArrow.snp.makeConstraints { $0.size.equalTo(12) }

        let rightStack = UIStackView(arrangedSubviews: [couponBadge, couponValueLabel, couponArrow])
        rightStack.axis = .horizontal
        rightStack.spacing = 2
        rightStack.alignment = .center
        rightStack.isUserInteractionEnabled = false

        couponRow.addSubview(leftStack)
        couponRow.addSubview(rightStack)

        leftStack.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
        }
        rightStack.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
            $0.leading.greaterThanOrEqualTo(leftStack.snp.trailing).offset(12)
        }
        couponRow.addTarget(self, action: #selector(handleCoupon), for: .touchUpInside)
    }

    func configureRemark(text: String) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.isEmpty {
            remarkValueLabel.text = "请填写"
            remarkValueLabel.textColor = UIColor(hexString: "#717885")
        } else {
            remarkValueLabel.text = clean
            remarkValueLabel.textColor = UIColor(hexString: "#1F2942")
        }
    }

    func configureCoupon(text: String, isPlaceholder: Bool, hasAvailable: Bool) {
        couponValueLabel.text = text
        if hasAvailable || !isPlaceholder {
            couponValueLabel.textColor = UIColor(hexString: "#F93838")
            couponBadge.isHidden = false
        } else {
            couponValueLabel.textColor = UIColor(hexString: "#717885")
            couponBadge.isHidden = true
        }
    }

    func configureBenefit(text: String, isPlaceholder: Bool, hasDiscount: Bool) {
        benefitValueLabel.text = text
        if hasDiscount {
            benefitValueLabel.textColor = UIColor(hexString: "#F93838")
        } else {
            benefitValueLabel.textColor = UIColor(hexString: "#717885")
        }
    }

    @objc private func handleRemark() { onTapRemark?() }
    @objc private func handleCoupon() { onTapCoupon?() }
    @objc private func handleBenefit() { onTapBenefit?() }
}

// MARK: - 费用明细（对齐 Figma 3479:8317）

final class OrderConfirmFeeView: UIView {

    private let card = OrderConfirmCardView()
    private let titleLabel = UILabel()
    private let rowsStack = UIStackView()
    private let divider = UIView()
    private let totalLeft = UILabel()
    private let totalRight = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.text = "费用明细"
        titleLabel.font = .fdFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = UIColor(hexString: "#1F2942")

        rowsStack.axis = .vertical
        rowsStack.spacing = 12

        divider.backgroundColor = UIColor(hexString: "#F0F0F0")

        totalLeft.text = "应付金额"
        totalLeft.font = .fdFont(ofSize: 16, weight: .medium)
        totalLeft.textColor = UIColor(hexString: "#1F2942")

        totalRight.textAlignment = .right

        let totalRow = UIStackView(arrangedSubviews: [totalLeft, totalRight])
        totalRow.axis = .horizontal
        totalRow.alignment = .center
        totalRow.spacing = 12

        let root = UIStackView(arrangedSubviews: [titleLabel, rowsStack, divider, totalRow])
        root.axis = .vertical
        root.spacing = 16

        addSubview(card)
        card.addSubview(root)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }
        root.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        divider.snp.makeConstraints { $0.height.equalTo(0.5) }
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
        rowsStack.addArrangedSubview(row("套餐金额", OrderConfirmMoney.yen(packageAmount), isHighlight: false))
        rowsStack.addArrangedSubview(row("运费", OrderConfirmMoney.yen(shipping), isHighlight: false))
        rowsStack.addArrangedSubview(row("优惠券抵扣", "-\(OrderConfirmMoney.yen(coupon))", isHighlight: coupon > 0))
        rowsStack.addArrangedSubview(row("权益卡抵扣", "-\(OrderConfirmMoney.yen(benefit))", isHighlight: benefit > 0))

        totalRight.attributedText = OrderConfirmMoney.formatPrice(payable, symbolSize: 16, valueSize: 18, color: UIColor(hexString: "#F93838"))
    }

    private func row(_ title: String, _ value: String, isHighlight: Bool) -> UIView {
        let left = UILabel()
        left.text = title
        left.font = .fdFont(ofSize: 14, weight: .regular)
        left.textColor = UIColor(hexString: "#1F2942")
        left.setContentHuggingPriority(.required, for: .horizontal)

        let right = UILabel()
        right.text = value
        right.font = .fdFont(ofSize: 14, weight: .medium)
        right.textColor = isHighlight ? UIColor(hexString: "#F93838") : UIColor(hexString: "#1F2942")
        right.textAlignment = .right

        let row = UIStackView(arrangedSubviews: [left, right])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        return row
    }
}

// MARK: - 支付方式（对齐 Figma 3479:8299）

final class OrderConfirmPayMethodView: UIView {

    var onSelect: ((OrderPayMethod) -> Void)?

    private let card = OrderConfirmCardView()
    private let titleLabel = UILabel()

    private let wechatRow = UIControl()
    private let wechatIcon = UIImageView(image: UIImage(named: "order_confirm_wechat_icon"))
    private let wechatLabel = UILabel()
    private let wechatRadio = UIImageView()

    private let divider = UIView()

    private let alipayRow = UIControl()
    private let alipayIcon = UIImageView(image: UIImage(named: "order_confirm_alipay_icon"))
    private let alipayLabel = UILabel()
    private let alipayRadio = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.text = "支付方式"
        titleLabel.font = .fdFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = UIColor(hexString: "#1F2942")

        // 微信
        setupMethodRow(
            container: wechatRow,
            icon: wechatIcon,
            titleLabel: wechatLabel,
            title: "微信支付",
            radio: wechatRadio,
            action: #selector(tapWechat)
        )

        // 支付宝
        setupMethodRow(
            container: alipayRow,
            icon: alipayIcon,
            titleLabel: alipayLabel,
            title: "支付宝支付",
            radio: alipayRadio,
            action: #selector(tapAlipay)
        )

        divider.backgroundColor = UIColor(hexString: "#F0F0F0")

        let contentStack = UIStackView(arrangedSubviews: [wechatRow, divider, alipayRow])
        contentStack.axis = .vertical
        contentStack.spacing = 0

        let root = UIStackView(arrangedSubviews: [titleLabel, contentStack])
        root.axis = .vertical
        root.spacing = 12

        addSubview(card)
        card.addSubview(root)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }
        root.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        wechatRow.snp.makeConstraints { $0.height.equalTo(44) }
        alipayRow.snp.makeConstraints { $0.height.equalTo(44) }
        divider.snp.makeConstraints { $0.height.equalTo(0.5) }
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupMethodRow(
        container: UIControl,
        icon: UIImageView,
        titleLabel: UILabel,
        title: String,
        radio: UIImageView,
        action: Selector
    ) {
        icon.contentMode = .scaleAspectFit
        icon.snp.makeConstraints { $0.size.equalTo(16) }

        titleLabel.text = title
        titleLabel.font = .fdFont(ofSize: 14, weight: .regular)
        titleLabel.textColor = UIColor(hexString: "#1F2942")

        let leftStack = UIStackView(arrangedSubviews: [icon, titleLabel])
        leftStack.axis = .horizontal
        leftStack.spacing = 6
        leftStack.alignment = .center
        leftStack.isUserInteractionEnabled = false

        radio.contentMode = .scaleAspectFit
        radio.snp.makeConstraints { $0.size.equalTo(14) }
        radio.isUserInteractionEnabled = false

        container.addSubview(leftStack)
        container.addSubview(radio)

        leftStack.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
        }
        radio.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
        }
        container.addTarget(self, action: action, for: .touchUpInside)
    }

    func configure(
        selected: OrderPayMethod,
        supportsWechat: Bool = true,
        supportsAlipay: Bool = true
    ) {
        wechatRow.isHidden = !supportsWechat
        alipayRow.isHidden = !supportsAlipay
        divider.isHidden = !(supportsWechat && supportsAlipay)

        let selectedImage = UIImage(named: "order_confirm_radio_selected")
        let unselectedImage = UIImage(named: "order_confirm_radio_unselected")

        wechatRadio.image = (selected == .wechat) ? selectedImage : unselectedImage
        alipayRadio.image = (selected == .alipay) ? selectedImage : unselectedImage
    }

    @objc private func tapWechat() { onSelect?(.wechat) }
    @objc private func tapAlipay() { onSelect?(.alipay) }
}

// MARK: - 底栏（对齐 Figma 3479:8338）

final class OrderConfirmSubmitBar: UIView {

    var onPay: (() -> Void)?
    var onCancel: (() -> Void)?

    private let label = UILabel()
    private let priceLabel = UILabel()
    private let cancelButton = UIButton(type: .system)
    private let payButton = UIButton(type: .system)
    private let actionsStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.05
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 8

        label.text = "应付金额"
        label.font = .fdFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor(hexString: "#1F2430")

        cancelButton.setTitle("取消订单", for: .normal)
        cancelButton.titleLabel?.font = .fdFont(ofSize: 14, weight: .regular)
        cancelButton.setTitleColor(UIColor(hexString: "#535D72"), for: .normal)
        cancelButton.backgroundColor = .white
        cancelButton.layer.cornerRadius = 20
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor(hexString: "#E5E7EB").cgColor
        cancelButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        cancelButton.addTarget(self, action: #selector(tapCancel), for: .touchUpInside)
        cancelButton.isHidden = true

        payButton.setTitle("立即支付", for: .normal)
        payButton.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        payButton.setTitleColor(.white, for: .normal)
        payButton.backgroundColor = UIColor(hexString: "#FF7A50")
        payButton.layer.cornerRadius = 20
        payButton.clipsToBounds = true
        payButton.addTarget(self, action: #selector(tapPay), for: .touchUpInside)

        actionsStack.axis = .horizontal
        actionsStack.spacing = 10
        actionsStack.alignment = .center
        actionsStack.addArrangedSubview(cancelButton)
        actionsStack.addArrangedSubview(payButton)

        let copy = UIStackView(arrangedSubviews: [label, priceLabel])
        copy.axis = .vertical
        copy.spacing = 2

        addSubview(copy)
        addSubview(actionsStack)

        copy.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(14)
            $0.trailing.lessThanOrEqualTo(actionsStack.snp.leading).offset(-12)
        }
        actionsStack.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.top.equalToSuperview().offset(14)
            $0.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-14)
        }
        cancelButton.snp.makeConstraints {
            $0.height.equalTo(40)
        }
        payButton.snp.makeConstraints {
            $0.height.equalTo(40)
            $0.width.equalTo(112)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(
        amount: Double,
        submitting: Bool,
        showsCancel: Bool = false,
        payTitle: String? = nil
    ) {
        priceLabel.attributedText = OrderConfirmMoney.formatPrice(amount, symbolSize: 14, valueSize: 20, color: UIColor(hexString: "#F93838"))
        cancelButton.isHidden = !showsCancel
        cancelButton.isEnabled = !submitting
        cancelButton.alpha = submitting ? 0.6 : 1
        payButton.isEnabled = !submitting
        payButton.alpha = submitting ? 0.6 : 1
        let resolvedPayTitle: String
        if submitting {
            resolvedPayTitle = "提交中..."
        } else if let payTitle {
            resolvedPayTitle = payTitle
        } else {
            resolvedPayTitle = amount <= 0 ? "确认下单" : "立即支付"
        }
        payButton.setTitle(resolvedPayTitle, for: .normal)
    }

    @objc private func tapPay() { onPay?() }
    @objc private func tapCancel() { onCancel?() }
}

// MARK: - Money Formatting

enum OrderConfirmMoney {
    static func yen(_ value: Double) -> String {
        let safe = max(0, value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        let num = formatter.string(from: NSNumber(value: safe))
            ?? String(format: "%.2f", safe)
        return "¥\(num)"
    }

    static func formatPrice(_ value: Double, symbolSize: CGFloat, valueSize: CGFloat, color: UIColor) -> NSAttributedString {
        let safe = max(0, value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        let num = formatter.string(from: NSNumber(value: safe))
            ?? String(format: "%.2f", safe)

        let result = NSMutableAttributedString()
        result.append(NSAttributedString(
            string: "¥",
            attributes: [
                .font: UIFont.fdFont(ofSize: symbolSize, weight: .medium),
                .foregroundColor: color
            ]
        ))
        result.append(NSAttributedString(
            string: num,
            attributes: [
                .font: UIFont.fdFont(ofSize: valueSize, weight: .medium),
                .foregroundColor: color
            ]
        ))
        return result
    }
}
