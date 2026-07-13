import UIKit
import SnapKit
import Combine
import Kingfisher

/// 服务套餐详情 — 对齐图示；数据优先 `getHospitalPackageDetail`
final class ServicePackageDetailViewController: BaseViewController {

    private let viewModel: ServicePackageDetailViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let orderBar = UIView()
    private let statusLabel = UILabel()

    private let contentTabBody = UIView()
    private let detailTabBody = UIView()
    private let tabBar = UIView()
    private let tabIndicator = UIView()
    private var contentTabButton: UIButton!
    private var detailTabButton: UIButton!

    private var carouselView: PackageDetailCarouselView?
    private var heroView: UIView!
    private var tierRow: UIStackView?
    private var payableLabel: UILabel!
    private var autoScrollTimer: Timer?

    private enum Tab { case content, detail }
    private var activeTab: Tab = .content
    private var tierIndex = 0
    /// 单选组：groupName → 选中下标（第 0 项锁定）
    private var radioPicks: [String: Int] = [:]
    /// 多选组：groupName → 选中下标集合
    private var checkPicks: [String: Set<Int>] = [:]

    private var package: ServicePackageDetail? { viewModel.package }

    private var activeTier: ServicePackageTier? {
        guard let package, package.tiers.indices.contains(tierIndex) else { return nil }
        return package.tiers[tierIndex]
    }

    init(
        packageId: String,
        hospitalId: String? = nil
    ) {
        self.viewModel = ServicePackageDetailViewModel(
            packageId: packageId,
            hospitalId: hospitalId
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit { stopAutoScroll() }

    override func setupUI() {
        view.backgroundColor = .fdBg
        title = "套餐详情"

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        statusLabel.font = .fdBody
        statusLabel.textColor = .fdSubtext
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.text = "套餐信息加载中..."
        contentView.addSubview(statusLabel)
        statusLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(80)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalToSuperview().offset(-40)
        }
    }

    override func bindViewModel() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                guard let self, self.package == nil else { return }
                self.statusLabel.text = loading ? "套餐信息加载中..." : self.statusLabel.text
            }
            .store(in: &cancellables)

        viewModel.$package
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pkg in
                guard let self, let pkg else { return }
                self.render(pkg)
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self, self.package == nil, let message, !message.isEmpty else { return }
                self.statusLabel.text = message
            }
            .store(in: &cancellables)

        viewModel.load()
    }

    private func render(_ pkg: ServicePackageDetail) {
        stopAutoScroll()
        orderBar.removeFromSuperview()
        contentView.subviews.forEach { $0.removeFromSuperview() }
        carouselView = nil
        heroView = nil
        tierRow = nil
        tierIndex = 0
        activeTab = .content

        resetPicks(for: pkg.tiers[tierIndex])
        buildCarousel(pkg)
        buildInfo(pkg)
        if pkg.tiers.count > 1 {
            buildTierRow(pkg)
        }
        buildTabs()
        rebuildContentTab()
        buildDetailTab(pkg)
        buildOrderBar(pkg)
        selectTab(.content, animated: false)
        startAutoScroll()
        refreshPayable()
    }

    // MARK: - Empty (unused after async load; statusLabel covers loading/error)

    private func buildCarousel(_ pkg: ServicePackageDetail) {
        let carousel = PackageDetailCarouselView(
            labels: pkg.carouselLabels,
            imageURLs: pkg.carouselImageURLs,
            accent: pkg.accent
        )
        carouselView = carousel
        contentView.addSubview(carousel)
        carousel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }

    // MARK: - Info

    private func buildInfo(_ pkg: ServicePackageDetail) {
        let hero = UIView()
        heroView = hero
        contentView.addSubview(hero)
        hero.snp.makeConstraints {
            $0.top.equalTo(carouselView!.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        let titleRow = UIStackView()
        titleRow.axis = .horizontal
        titleRow.spacing = 8
        titleRow.alignment = .center

        if !pkg.tag.isEmpty {
            let badge = UILabel()
            badge.text = " \(pkg.tag) "
            badge.font = .fdMicroSemibold
            badge.textColor = .white
            badge.backgroundColor = .fdPrimary
            badge.layer.cornerRadius = 4
            badge.clipsToBounds = true
            titleRow.addArrangedSubview(badge)
        }

        let name = UILabel()
        name.text = pkg.name
        name.font = .fdFont(ofSize: 20, weight: .heavy)
        name.textColor = .fdText
        name.numberOfLines = 2
        titleRow.addArrangedSubview(name)
        hero.addSubview(titleRow)
        titleRow.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }

        let subtitle = UILabel()
        subtitle.text = pkg.subtitle
        subtitle.font = .fdCaption
        subtitle.textColor = .fdSubtext
        subtitle.numberOfLines = 2
        subtitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let price = UILabel()
        let unitSuffix = pkg.priceUnit.contains("面议") ? "" : " \(pkg.priceUnit)"
        price.text = "\(pkg.priceText)\(unitSuffix)"
        price.font = .fdMonoFont(ofSize: 18, weight: .bold)
        price.textColor = .fdPrimary
        price.setContentHuggingPriority(.required, for: .horizontal)

        let mid = UIStackView(arrangedSubviews: [subtitle, price])
        mid.axis = .horizontal
        mid.alignment = .top
        mid.spacing = 12
        hero.addSubview(mid)
        mid.snp.makeConstraints {
            $0.top.equalTo(titleRow.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
        }

        if pkg.tags.isEmpty {
            mid.snp.makeConstraints { $0.bottom.equalToSuperview() }
        } else {
            let tagStack = UIStackView()
            tagStack.axis = .horizontal
            tagStack.spacing = 8
            tagStack.alignment = .leading
            for text in pkg.tags.prefix(4) {
                let tag = UILabel()
                let short = text.count > 4 ? String(text.prefix(4)) + "…" : text
                tag.text = " \(short) "
                tag.font = .fdCaptionSemibold
                tag.textColor = .fdPrimary
                tag.backgroundColor = UIColor.fdPrimary.withAlphaComponent(0.08)
                tag.layer.cornerRadius = 999
                tag.layer.borderWidth = 1
                tag.layer.borderColor = UIColor.fdPrimary.withAlphaComponent(0.25).cgColor
                tag.clipsToBounds = true
                tagStack.addArrangedSubview(tag)
            }
            hero.addSubview(tagStack)
            tagStack.snp.makeConstraints {
                $0.top.equalTo(mid.snp.bottom).offset(10)
                $0.leading.trailing.bottom.equalToSuperview()
            }
        }
    }

    // MARK: - Tier

    private func buildTierRow(_ pkg: ServicePackageDetail) {
        let title = UILabel()
        title.text = "选择档次"
        title.font = .fdFont(ofSize: 15, weight: .heavy)
        title.textColor = .fdText
        contentView.addSubview(title)
        title.snp.makeConstraints {
            $0.top.equalTo(heroView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        tierRow = row
        contentView.addSubview(row)
        row.snp.makeConstraints {
            $0.top.equalTo(title.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        for (i, tier) in pkg.tiers.enumerated() {
            let chip = makeTierChip(tier: tier, index: i, selected: i == tierIndex, accent: pkg.accent)
            row.addArrangedSubview(chip)
        }
    }

    private func makeTierChip(tier: ServicePackageTier, index: Int, selected: Bool, accent: UIColor) -> UIView {
        let chip = UIControl()
        chip.tag = index
        chip.layer.cornerRadius = 12
        chip.layer.borderWidth = 1.5
        chip.backgroundColor = selected ? accent.withAlphaComponent(0.06) : .fdSurface
        chip.layer.borderColor = (selected ? accent : UIColor.fdBorder).cgColor
        chip.addTarget(self, action: #selector(tierTapped(_:)), for: .touchUpInside)

        let name = UILabel()
        name.text = tier.name
        name.font = .fdCaptionSemibold
        name.textColor = selected ? accent : .fdText
        name.textAlignment = .center
        let price = UILabel()
        price.text = tier.priceLabel
        price.font = .fdMicro
        price.textColor = selected ? accent : .fdSubtext
        price.textAlignment = .center
        let stack = UIStackView(arrangedSubviews: [name, price])
        stack.axis = .vertical
        stack.spacing = 3
        stack.isUserInteractionEnabled = false
        chip.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(10) }
        return chip
    }

    @objc private func tierTapped(_ sender: UIControl) {
        guard let pkg = package, sender.tag != tierIndex else { return }
        tierIndex = sender.tag
        resetPicks(for: pkg.tiers[tierIndex])
        if let row = tierRow {
            row.arrangedSubviews.forEach { $0.removeFromSuperview() }
            for (i, tier) in pkg.tiers.enumerated() {
                row.addArrangedSubview(makeTierChip(tier: tier, index: i, selected: i == tierIndex, accent: pkg.accent))
            }
        }
        rebuildContentTab()
        refreshPayable()
    }

    // MARK: - Tabs

    private func buildTabs() {
        tabBar.subviews.forEach { $0.removeFromSuperview() }
        contentTabBody.subviews.forEach { $0.removeFromSuperview() }
        detailTabBody.subviews.forEach { $0.removeFromSuperview() }

        let border = UIView()
        border.backgroundColor = .fdBorder
        tabBar.addSubview(border)
        border.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(2)
        }

        contentTabButton = makeTabButton(title: "套餐内容", tag: 0)
        detailTabButton = makeTabButton(title: "套餐详情", tag: 1)
        contentTabButton.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        detailTabButton.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [contentTabButton, detailTabButton])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        tabBar.addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(44)
        }

        tabIndicator.backgroundColor = .fdPrimary
        tabIndicator.layer.cornerRadius = 1.5
        tabBar.addSubview(tabIndicator)
        tabIndicator.snp.makeConstraints {
            $0.bottom.equalToSuperview()
            $0.width.equalTo(40)
            $0.height.equalTo(3)
            $0.centerX.equalTo(contentTabButton)
        }

        let anchor: ConstraintItem
        if let tierRow {
            anchor = tierRow.snp.bottom
        } else {
            anchor = heroView.snp.bottom
        }

        contentView.addSubview(tabBar)
        tabBar.snp.makeConstraints {
            $0.top.equalTo(anchor).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        contentView.addSubview(contentTabBody)
        contentView.addSubview(detailTabBody)
        contentTabBody.snp.makeConstraints {
            $0.top.equalTo(tabBar.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-24)
        }
        detailTabBody.snp.makeConstraints {
            $0.top.equalTo(tabBar.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.lessThanOrEqualToSuperview().offset(-24)
        }
    }

    private func makeTabButton(title: String, tag: Int) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.fdSubtext, for: .normal)
        btn.setTitleColor(.fdText, for: .selected)
        btn.titleLabel?.font = .fdBodySemibold
        btn.tag = tag
        return btn
    }

    @objc private func tabTapped(_ sender: UIButton) {
        selectTab(sender.tag == 0 ? .content : .detail, animated: true)
    }

    private func selectTab(_ tab: Tab, animated: Bool) {
        activeTab = tab
        contentTabButton.isSelected = tab == .content
        detailTabButton.isSelected = tab == .detail
        contentTabButton.titleLabel?.font = tab == .content ? .fdFont(ofSize: 15, weight: .heavy) : .fdBodySemibold
        detailTabButton.titleLabel?.font = tab == .detail ? .fdFont(ofSize: 15, weight: .heavy) : .fdBodySemibold
        contentTabBody.isHidden = tab != .content
        detailTabBody.isHidden = tab != .detail

        let target = tab == .content ? contentTabButton! : detailTabButton!
        tabIndicator.snp.remakeConstraints {
            $0.bottom.equalToSuperview()
            $0.width.equalTo(40)
            $0.height.equalTo(3)
            $0.centerX.equalTo(target)
        }
        if animated {
            UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
        } else {
            view.layoutIfNeeded()
        }
    }

    // MARK: - Content tab (combo)

    private func rebuildContentTab() {
        contentTabBody.subviews.forEach { $0.removeFromSuperview() }
        guard let tier = activeTier else { return }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        contentTabBody.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }

        for group in tier.groups {
            stack.addArrangedSubview(makeComboGroupView(group))
        }
    }

    private func makeComboGroupView(_ group: ServicePackageComboGroup) -> UIView {
        let box = DashedBorderView()
        let isRequired = group.selectMode == .required
        box.backgroundColor = isRequired ? UIColor(hexString: "#FFF7F8") : .fdSurface
        box.layer.cornerRadius = 12
        box.clipsToBounds = true
        box.borderColor = isRequired ? UIColor(hexString: "#F0708C") : .fdBorder
        box.dashed = isRequired
        box.solidBorder = !isRequired

        let head = UIStackView()
        head.axis = .horizontal
        head.spacing = 8
        head.alignment = .center

        let badge = UILabel()
        if isRequired {
            badge.text = " 必选 "
            badge.backgroundColor = UIColor(hexString: "#FDE3E9")
            badge.textColor = UIColor(hexString: "#E0436B")
        } else {
            badge.text = " \(group.selectMode.rawValue) "
            badge.backgroundColor = .fdBg2
            badge.textColor = .fdText2
        }
        badge.font = .fdMicroSemibold
        badge.layer.cornerRadius = 999
        badge.clipsToBounds = true
        head.addArrangedSubview(badge)

        let gName = UILabel()
        gName.text = "\(group.emoji) \(group.name)"
        gName.font = .fdCaptionSemibold
        gName.textColor = .fdText
        head.addArrangedSubview(gName)

        let rows = UIStackView()
        rows.axis = .vertical
        rows.spacing = 0

        for (i, item) in group.items.enumerated() {
            rows.addArrangedSubview(makeComboRow(group: group, index: i, item: item, showDivider: i < group.items.count - 1))
        }

        let stack = UIStackView(arrangedSubviews: [head, rows])
        stack.axis = .vertical
        stack.spacing = 8
        box.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
        return box
    }

    private func makeComboRow(
        group: ServicePackageComboGroup,
        index: Int,
        item: ServicePackageComboItem,
        showDivider: Bool
    ) -> UIView {
        let row = UIControl()
        row.tag = index
        let selected = isSelected(group: group, index: index)

        let ctrl = makeCtrl(group: group, index: index, selected: selected)
        let name = UILabel()
        name.text = item.name
        name.font = .fdBody
        name.textColor = .fdText
        name.numberOfLines = 2
        let qty = UILabel()
        qty.text = item.qtyLabel
        qty.font = .fdCaption
        qty.textColor = .fdSubtext
        qty.setContentHuggingPriority(.required, for: .horizontal)
        let price = UILabel()
        price.text = item.priceLabel
        price.font = .fdMonoFont(ofSize: 13, weight: .semibold)
        price.textColor = .fdText
        price.setContentHuggingPriority(.required, for: .horizontal)
        price.snp.makeConstraints { $0.width.greaterThanOrEqualTo(44) }

        let stack = UIStackView(arrangedSubviews: [ctrl, name, qty, price])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        row.addSubview(stack)
        stack.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.bottom.equalToSuperview().inset(10)
        }

        if showDivider {
            let d = UIView()
            d.backgroundColor = .fdBorder
            row.addSubview(d)
            d.snp.makeConstraints {
                $0.leading.trailing.bottom.equalToSuperview()
                $0.height.equalTo(1)
            }
        }

        switch group.selectMode {
        case .required:
            break
        case .radio:
            if index > 0 {
                row.addAction(UIAction { [weak self] _ in
                    self?.radioPicks[group.name] = index
                    self?.rebuildContentTab()
                    self?.refreshPayable()
                }, for: .touchUpInside)
            }
        case .checkbox:
            row.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                var set = self.checkPicks[group.name] ?? []
                if set.contains(index) { set.remove(index) } else { set.insert(index) }
                self.checkPicks[group.name] = set
                self.rebuildContentTab()
                self.refreshPayable()
            }, for: .touchUpInside)
        }
        return row
    }

    private func makeCtrl(group: ServicePackageComboGroup, index: Int, selected: Bool) -> UIView {
        let onColor = UIColor(hexString: "#EE4D6F")
        let box = UIView()
        box.snp.makeConstraints { $0.size.equalTo(20) }

        let isRadio = group.selectMode == .radio && index > 0
        box.layer.cornerRadius = isRadio ? 10 : 6
        box.layer.borderWidth = 1.5

        if selected {
            if isRadio {
                box.backgroundColor = .white
                box.layer.borderColor = onColor.cgColor
                let dot = UIView()
                dot.backgroundColor = onColor
                dot.layer.cornerRadius = 5
                box.addSubview(dot)
                dot.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(10) }
            } else {
                box.backgroundColor = onColor
                box.layer.borderColor = onColor.cgColor
                let iv = UIImageView(image: UIImage(systemName: "checkmark"))
                iv.tintColor = .white
                iv.contentMode = .scaleAspectFit
                box.addSubview(iv)
                iv.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(12) }
            }
        } else {
            box.backgroundColor = .clear
            box.layer.borderColor = UIColor.fdBorder.cgColor
        }
        return box
    }

    private func isSelected(group: ServicePackageComboGroup, index: Int) -> Bool {
        switch group.selectMode {
        case .required:
            return true
        case .radio:
            if index == 0 { return true }
            return radioPicks[group.name] == index
        case .checkbox:
            return checkPicks[group.name]?.contains(index) ?? false
        }
    }

    private func resetPicks(for tier: ServicePackageTier) {
        var radios: [String: Int] = [:]
        var checks: [String: Set<Int>] = [:]
        for group in tier.groups {
            switch group.selectMode {
            case .radio:
                let preferred = group.items.enumerated().first { $0.offset > 0 && $0.element.defaultSelected }?.offset
                radios[group.name] = preferred ?? (group.items.count > 1 ? 1 : 0)
            case .checkbox:
                checks[group.name] = Set(
                    group.items.enumerated().compactMap { $0.element.defaultSelected ? $0.offset : nil }
                )
            case .required:
                break
            }
        }
        radioPicks = radios
        checkPicks = checks
    }

    // MARK: - Detail tab

    private func buildDetailTab(_ pkg: ServicePackageDetail) {
        detailTabBody.subviews.forEach { $0.removeFromSuperview() }
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12
        detailTabBody.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }

        let title = UILabel()
        title.text = "套餐说明"
        title.font = .fdFont(ofSize: 15, weight: .heavy)
        title.textColor = .fdText
        let body = UILabel()
        body.text = pkg.detailText
        body.font = .fdBody
        body.textColor = .fdText2
        body.numberOfLines = 0
        let deliveryTitle = UILabel()
        deliveryTitle.text = "交付说明"
        deliveryTitle.font = .fdFont(ofSize: 15, weight: .heavy)
        deliveryTitle.textColor = .fdText
        let delivery = UILabel()
        delivery.text = ServicePackageDetailCopy.deliveryNote
        delivery.font = .fdBody
        delivery.textColor = .fdText2
        delivery.numberOfLines = 0

        var arranged: [UIView] = [title, body, deliveryTitle, delivery]
        for urlString in pkg.detailImageURLs {
            guard let url = URL(string: urlString) else { continue }
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.layer.cornerRadius = 8
            iv.backgroundColor = .fdBg2
            iv.kf.setImage(with: url, options: [.transition(.fade(0.2))])
            iv.snp.makeConstraints { $0.height.equalTo(160) }
            arranged.append(iv)
        }

        let stack = UIStackView(arrangedSubviews: arranged)
        stack.axis = .vertical
        stack.spacing = 8
        stack.setCustomSpacing(16, after: body)
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }
    }

    // MARK: - Order bar

    private func buildOrderBar(_ pkg: ServicePackageDetail) {
        orderBar.subviews.forEach { $0.removeFromSuperview() }
        orderBar.backgroundColor = UIColor.fdSurface.withAlphaComponent(0.96)
        let border = UIView()
        border.backgroundColor = .fdBorder
        orderBar.addSubview(border)
        border.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }

        let tip = UILabel()
        tip.text = "应付"
        tip.font = .fdMicro
        tip.textColor = .fdSubtext
        payableLabel = UILabel()
        payableLabel.font = .fdMonoFont(ofSize: 20, weight: .heavy)
        payableLabel.textColor = .fdPrimary
        let priceStack = UIStackView(arrangedSubviews: [tip, payableLabel])
        priceStack.axis = .vertical
        priceStack.spacing = 2

        let cart = UIButton(type: .system)
        cart.setTitle("加入购物车", for: .normal)
        cart.setTitleColor(.fdPrimary, for: .normal)
        cart.titleLabel?.font = .fdBody
        cart.layer.cornerRadius = 22
        cart.layer.borderWidth = 1
        cart.layer.borderColor = UIColor.fdPrimary.cgColor
        cart.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        cart.addTarget(self, action: #selector(tapCart), for: .touchUpInside)

        let order = UIButton(type: .system)
        order.setTitle("立即下单", for: .normal)
        order.setTitleColor(.white, for: .normal)
        order.titleLabel?.font = .fdBodySemibold
        order.backgroundColor = .fdPrimary
        order.layer.cornerRadius = 22
        order.contentEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        order.addTarget(self, action: #selector(tapOrder), for: .touchUpInside)

        let actions = UIStackView(arrangedSubviews: [cart, order])
        actions.axis = .horizontal
        actions.spacing = 10
        cart.snp.makeConstraints { $0.height.equalTo(44) }
        order.snp.makeConstraints { $0.height.equalTo(44) }

        orderBar.addSubview(priceStack)
        orderBar.addSubview(actions)
        view.addSubview(orderBar)

        orderBar.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview() }
        priceStack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalTo(actions)
        }
        actions.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.top.equalToSuperview().offset(10)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-10)
            $0.leading.greaterThanOrEqualTo(priceStack.snp.trailing).offset(12)
        }
        scrollView.snp.remakeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(orderBar.snp.top)
        }
        _ = pkg
    }

    private func refreshPayable() {
        guard let tier = activeTier else {
            payableLabel?.text = "—"
            return
        }
        if tier.price == 0 && tier.priceUnit.contains("面议") {
            payableLabel.text = "面议"
            return
        }
        var total = tier.price
        for group in tier.groups where group.selectMode == .checkbox {
            let picked = checkPicks[group.name] ?? []
            for i in picked {
                total += group.items[safe: i]?.price ?? 0
            }
        }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        let num = f.string(from: NSNumber(value: total)) ?? "\(total)"
        payableLabel.text = "¥\(num)"
    }

    // MARK: - Carousel timer

    private func startAutoScroll() {
        stopAutoScroll()
        guard let carousel = carouselView, carousel.pageCount > 1 else { return }
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 2.8, repeats: true) { [weak self] _ in
            self?.carouselView?.advancePage()
        }
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    @objc private func tapCart() {
        guard let pkg = package else { return }
        AppContainer.shared.cartService.addPackage(pkg)
        Router.shared.push("/services/cart")
    }

    @objc private func tapOrder() {
        let id = package?.id ?? ""
        Router.shared.push("/orders/confirm", params: ["id": id])
    }
}

// MARK: - Helpers

private final class DashedBorderView: UIView {
    var borderColor: UIColor = .fdBorder
    var dashed = false
    var solidBorder = true
    private let shape = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        shape.fillColor = nil
        shape.lineWidth = 1.5
        layer.addSublayer(shape)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        shape.frame = bounds
        let inset = bounds.insetBy(dx: 0.75, dy: 0.75)
        shape.path = UIBezierPath(roundedRect: inset, cornerRadius: 11.25).cgPath
        shape.strokeColor = borderColor.cgColor
        shape.lineDashPattern = dashed ? [6, 4] : nil
        shape.isHidden = !dashed
        layer.borderWidth = solidBorder ? 1.5 : 0
        layer.borderColor = solidBorder ? borderColor.cgColor : nil
    }
}
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Carousel

private final class PackageDetailCarouselView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    let pageCount: Int
    private let labels: [String]
    private let imageURLs: [String]
    private let accent: UIColor
    private var currentPage = 0

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.register(CarouselSlideCell.self, forCellWithReuseIdentifier: CarouselSlideCell.reuseID)
        cv.layer.cornerRadius = 14
        cv.clipsToBounds = true
        return cv
    }()

    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = .fdPrimary
        pc.pageIndicatorTintColor = UIColor.fdPrimary.withAlphaComponent(0.25)
        pc.hidesForSinglePage = true
        return pc
    }()

    init(labels: [String], imageURLs: [String] = [], accent: UIColor) {
        self.imageURLs = imageURLs
        let count = max(imageURLs.count, labels.count, 1)
        if imageURLs.isEmpty {
            self.labels = labels.isEmpty ? ["套餐详情"] : labels
        } else {
            self.labels = (0..<count).map { idx in
                labels.indices.contains(idx) ? labels[idx] : "套餐图 \(idx + 1)"
            }
        }
        self.accent = accent
        self.pageCount = imageURLs.isEmpty ? self.labels.count : imageURLs.count
        super.init(frame: .zero)
        addSubview(collectionView)
        addSubview(pageControl)
        collectionView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(collectionView.snp.width).multipliedBy(9.0 / 16.0)
        }
        pageControl.snp.makeConstraints {
            $0.top.equalTo(collectionView.snp.bottom).offset(6)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        pageControl.numberOfPages = pageCount
    }

    required init?(coder: NSCoder) { fatalError() }

    func advancePage() {
        guard pageCount > 1, collectionView.bounds.width > 0 else { return }
        currentPage = (currentPage + 1) % pageCount
        collectionView.setContentOffset(CGPoint(x: CGFloat(currentPage) * collectionView.bounds.width, y: 0), animated: true)
        pageControl.currentPage = currentPage
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { pageCount }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CarouselSlideCell.reuseID, for: indexPath) as! CarouselSlideCell
        let url = imageURLs.indices.contains(indexPath.item) ? imageURLs[indexPath.item] : nil
        let label = labels.indices.contains(indexPath.item) ? labels[indexPath.item] : ""
        cell.configure(label: label, imageURL: url, accent: accent, alternate: indexPath.item % 2 == 1)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { updatePage() }
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) { updatePage() }

    private func updatePage() {
        guard collectionView.bounds.width > 0 else { return }
        currentPage = Int(round(collectionView.contentOffset.x / collectionView.bounds.width))
        pageControl.currentPage = currentPage
    }
}

private final class CarouselSlideCell: UICollectionViewCell {
    static let reuseID = "CarouselSlideCell"
    private let gradient = CAGradientLayer()
    private let imageView = UIImageView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        contentView.layer.insertSublayer(gradient, at: 0)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        label.font = .fdFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 3
        contentView.addSubview(label)
        label.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = contentView.bounds
    }

    func configure(label text: String, imageURL: String?, accent: UIColor, alternate: Bool) {
        label.text = text
        label.textColor = accent
        let c1 = accent.withAlphaComponent(alternate ? 0.12 : 0.18)
        let c2 = accent.withAlphaComponent(alternate ? 0.22 : 0.32)
        gradient.colors = [c1.cgColor, c2.cgColor]

        if let imageURL, let url = URL(string: imageURL) {
            imageView.isHidden = false
            label.isHidden = true
            imageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        } else {
            imageView.isHidden = true
            label.isHidden = false
            imageView.image = nil
        }
    }
}
