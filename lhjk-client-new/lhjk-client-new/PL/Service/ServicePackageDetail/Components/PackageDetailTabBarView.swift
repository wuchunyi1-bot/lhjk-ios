import UIKit
import SnapKit

enum PackageDetailTab: Int, CaseIterable, Equatable {
    case benefits = 0
    case detail = 1
}

protocol PackageDetailTabBarViewDelegate: AnyObject {
    func tabBarView(_ view: PackageDetailTabBarView, didSelect tab: PackageDetailTab)
}

// MARK: - 套餐详情 Tab 选择头

/// 套餐详情 Tab 选择头 — 贴边全宽、等宽均分（对齐 Figma 3805:20813 / 3805:21478）
final class PackageDetailTabBarView: UIView {

    weak var delegate: PackageDetailTabBarViewDelegate?

    private let bgGradientLayer = CAGradientLayer()
    private let bottomDivider = UIView()
    private let buttonsStack = UIStackView()
    private let benefitsButton = UIButton(type: .custom)
    private let detailButton = UIButton(type: .custom)
    private let indicator = UIView()

    private(set) var selectedTab: PackageDetailTab = .benefits

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        bgGradientLayer.frame = bounds
        updateIndicatorPosition(animated: false)
    }

    func setDetailTabVisible(_ visible: Bool) {
        detailButton.isHidden = !visible
        if !visible, selectedTab == .detail {
            select(.benefits, animated: false)
        } else {
            setNeedsLayout()
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 56)
    }

    func select(_ tab: PackageDetailTab, animated: Bool) {
        selectedTab = tab
        benefitsButton.isSelected = tab == .benefits
        detailButton.isSelected = tab == .detail

        benefitsButton.titleLabel?.font = tab == .benefits ? .fdFont(ofSize: 16, weight: .medium) : .fdFont(ofSize: 16, weight: .regular)
        detailButton.titleLabel?.font = tab == .detail ? .fdFont(ofSize: 16, weight: .medium) : .fdFont(ofSize: 16, weight: .regular)

        updateIndicatorPosition(animated: animated)
    }

    private func updateIndicatorPosition(animated: Bool) {
        let target: UIButton
        switch selectedTab {
        case .benefits: target = benefitsButton
        case .detail: target = detailButton
        }

        indicator.snp.remakeConstraints {
            $0.bottom.equalToSuperview().offset(-8)
            $0.width.equalTo(16)
            $0.height.equalTo(4)
            $0.centerX.equalTo(target)
        }

        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut]) {
                self.layoutIfNeeded()
            }
        }
    }

    private func setupUI() {
        backgroundColor = .white
        clipsToBounds = true
        layer.cornerRadius = 16
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        bgGradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor(hexString: "#FDF6F4").cgColor
        ]
        bgGradientLayer.locations = [0.33, 1.0]
        bgGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        bgGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.insertSublayer(bgGradientLayer, at: 0)

        bottomDivider.backgroundColor = UIColor(hexString: "#F0F2F5")
        addSubview(bottomDivider)
        bottomDivider.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }

        configureButton(benefitsButton, title: "权益", tag: PackageDetailTab.benefits.rawValue)
        configureButton(detailButton, title: "详情信息", tag: PackageDetailTab.detail.rawValue)

        benefitsButton.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        detailButton.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)

        buttonsStack.axis = .horizontal
        buttonsStack.distribution = .fillEqually
        buttonsStack.alignment = .fill
        buttonsStack.spacing = 0
        buttonsStack.addArrangedSubview(benefitsButton)
        buttonsStack.addArrangedSubview(detailButton)

        addSubview(buttonsStack)
        buttonsStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        indicator.backgroundColor = UIColor(hexString: "#FF7A50")
        indicator.layer.cornerRadius = 2
        addSubview(indicator)
        indicator.snp.makeConstraints {
            $0.bottom.equalToSuperview().offset(-8)
            $0.width.equalTo(16)
            $0.height.equalTo(4)
            $0.centerX.equalTo(benefitsButton)
        }

        select(.benefits, animated: false)
    }

    private func configureButton(_ button: UIButton, title: String, tag: Int) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor(hexString: "#535D72"), for: .normal)
        button.setTitleColor(UIColor(hexString: "#1F2942"), for: .selected)
        button.titleLabel?.font = .fdFont(ofSize: 16, weight: .regular)
        button.tag = tag
    }

    @objc private func tabTapped(_ sender: UIButton) {
        guard let tab = PackageDetailTab(rawValue: sender.tag) else { return }
        select(tab, animated: true)
        delegate?.tabBarView(self, didSelect: tab)
    }
}

// MARK: - 权益独立卡片

/// 套餐详情 — 权益卡片（对齐 Figma 3805:20862）
final class PackageDetailBenefitsCardView: UIView {

    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let groupsStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .clear

        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.04
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 6

        addSubview(cardView)
        cardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        titleLabel.text = "权益"
        titleLabel.font = .fdFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = UIColor(hexString: "#1F2942")
        cardView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(14)
        }

        groupsStack.axis = .vertical
        groupsStack.spacing = 12
        cardView.addSubview(groupsStack)
        groupsStack.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview().inset(14)
        }
    }

    func setGroupViews(_ views: [UIView]) {
        groupsStack.arrangedSubviews.forEach {
            groupsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        views.forEach { groupsStack.addArrangedSubview($0) }
    }
}

// MARK: - 详情信息独立卡片

/// 套餐详情 — 详情信息卡片（对齐 Figma 3805:20929）
final class PackageDetailDetailCardView: UIView {

    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let detailImageViews = PackageDetailCardView()

    var onHeightChanged: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .clear

        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.04
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 6

        addSubview(cardView)
        cardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        titleLabel.text = "详情信息"
        titleLabel.font = .fdFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = UIColor(hexString: "#1F2942")
        cardView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(14)
        }

        detailImageViews.onImagesLoaded = { [weak self] in
            self?.onHeightChanged?()
        }

        cardView.addSubview(detailImageViews)
        detailImageViews.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview().inset(14)
        }
    }

    func configure(with pkg: ServicePackageDetail) {
        detailImageViews.configure(with: pkg)
        isHidden = pkg.detailImageURLs.isEmpty
    }
}

// MARK: - 底部保障卡片

/// 套餐详情底部服务保障卡片及协议文案 — 对齐 Figma 3805:21099
final class PackageDetailGuaranteeView: UIView {

    private let cardView = UIView()
    private let agreementLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .clear

        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.04
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 6

        addSubview(cardView)
        cardView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }

        let item1 = makeGuaranteeItem(icon: "pkg_guarantee_refund", title: "多学科专业系统")
        let item2 = makeGuaranteeItem(icon: "pkg_guarantee_response", title: "膳食运动指导")
        let item3 = makeGuaranteeItem(icon: "pkg_guarantee_team", title: "持证专业团队")

        let stack = UIStackView(arrangedSubviews: [item1, item2, item3])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
        stack.alignment = .center

        cardView.addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 8, bottom: 14, right: 8))
        }

        agreementLabel.text = "退款与售后规则以购买页服务协议为准"
        agreementLabel.font = .fdFont(ofSize: 14, weight: .regular)
        agreementLabel.textColor = UIColor(hexString: "#8591AB")
        agreementLabel.textAlignment = .center

        addSubview(agreementLabel)
        agreementLabel.snp.makeConstraints {
            $0.top.equalTo(cardView.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func makeGuaranteeItem(icon: String, title: String) -> UIView {
        let container = UIView()

        let iv = UIImageView(image: UIImage(named: icon))
        iv.contentMode = .scaleAspectFit

        let lbl = UILabel()
        lbl.text = title
        lbl.font = .fdFont(ofSize: 14, weight: .regular)
        lbl.textColor = UIColor(hexString: "#6D7381")
        lbl.textAlignment = .center
        lbl.numberOfLines = 1

        let itemStack = UIStackView(arrangedSubviews: [iv, lbl])
        itemStack.axis = .vertical
        itemStack.spacing = 6
        itemStack.alignment = .center

        iv.snp.makeConstraints {
            $0.size.equalTo(46)
        }

        container.addSubview(itemStack)
        itemStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        return container
    }
}
