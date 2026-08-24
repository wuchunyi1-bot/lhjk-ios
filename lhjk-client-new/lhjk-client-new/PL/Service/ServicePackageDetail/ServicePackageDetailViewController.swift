import UIKit
import SnapKit
import Combine

/// 服务套餐详情 — 三段式：Banner / 价格与简介 / 独立卡片楼层（对齐 Figma 3805:20762）
final class ServicePackageDetailViewController: BaseViewController {

    private let viewModel: ServicePackageDetailViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let contentStack = UIStackView()

    private let backButton = UIButton(type: .custom)
    private let orderBar = PackageDetailOrderBarView()
    private let statusLabel = UILabel()

    private var carouselView: PackageDetailCarouselView?
    private let infoView = PackageDetailInfoView()
    private var tierPickerView: PackageDetailTierPickerView?

    // 页面内 Tab 选择头（贴边全宽）与三张独立卡片
    private let inPageTabBarView = PackageDetailTabBarView()
    private let benefitsCardView = PackageDetailBenefitsCardView()
    private let detailCardView = PackageDetailDetailCardView()
    private let guaranteeView = PackageDetailGuaranteeView()

    private var autoScrollTimer: Timer?

    // 吸顶区：状态栏占位 + 导航标题 + Tab（对齐 Figma 3805:21131 / 3805:21478）
    private let stickyHeaderContainer = UIView()
    private let stickyStatusBarFill = UIView()
    private let stickyNavBar = UIView()
    private let stickyBackButton = UIButton(type: .custom)
    private let stickyTitleLabel = UILabel()
    private let stickyTabBarView = PackageDetailTabBarView()

    private enum StickyHeaderMetrics {
        static let navRowHeight: CGFloat = 44
        static let tabBarHeight: CGFloat = 56
        static var contentHeight: CGFloat { navRowHeight + tabBarHeight }
    }

    private var activeTab: PackageDetailTab = .benefits
    private var isUserScrollingToTab = false
    private var tierIndex = 0
    private var radioPicks: [String: Int] = [:]
    private var checkPicks: [String: Set<Int>] = [:]

    private var package: ServicePackageDetail? { viewModel.package }

    private var activeTier: ServicePackageTier? {
        guard let package, package.tiers.indices.contains(tierIndex) else { return nil }
        return package.tiers[tierIndex]
    }

    private var visibleGroups: [ServicePackageComboGroup] {
        activeTier?.groups.filter { group in
            group.selectMode != .checkbox || !group.items.isEmpty
        } ?? []
    }

    private var hasDetailImages: Bool {
        !(package?.detailImageURLs.isEmpty ?? true)
    }

    init(
        packageId: String,
        hospitalId: String? = nil,
        categoryServiceId: String? = nil,
        renewalParentOrderId: Int64? = nil
    ) {
        self.viewModel = ServicePackageDetailViewModel(
            packageId: packageId,
            hospitalId: hospitalId,
            categoryServiceId: categoryServiceId,
            renewalParentOrderId: renewalParentOrderId
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit { stopAutoScroll() }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = UIColor(hexString: "#FDF6F4")

        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self
        scrollView.isHidden = true
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView.snp.width)
        }

        contentStack.axis = .vertical
        contentStack.spacing = 14
        contentView.addSubview(contentStack)
        contentStack.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-24)
        }

        inPageTabBarView.delegate = self
        detailCardView.onHeightChanged = { [weak self] in
            self?.view.layoutIfNeeded()
        }

        // 悬浮返回按钮（黑色半透明背景）
        backButton.backgroundColor = UIColor(white: 0, alpha: 0.5)
        backButton.layer.cornerRadius = 8
        backButton.clipsToBounds = true
        let chevron = UIImage(systemName: "chevron.left")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        )
        backButton.setImage(chevron, for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        view.addSubview(backButton)
        backButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(6)
            $0.leading.equalToSuperview().offset(16)
            $0.size.equalTo(32)
        }

        // 吸顶标题 + Tab
        setupStickyHeader()

        statusLabel.font = .fdBody
        statusLabel.textColor = .fdSubtext
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.text = "套餐信息加载中..."
        view.addSubview(statusLabel)
        statusLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview().offset(-40)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
    }

    private func setupStickyHeader() {
        stickyHeaderContainer.backgroundColor = .white
        stickyHeaderContainer.layer.shadowColor = UIColor.black.cgColor
        stickyHeaderContainer.layer.shadowOpacity = 0.06
        stickyHeaderContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        stickyHeaderContainer.layer.shadowRadius = 4
        stickyHeaderContainer.alpha = 0
        stickyHeaderContainer.isHidden = true

        view.addSubview(stickyHeaderContainer)
        stickyHeaderContainer.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }

        stickyStatusBarFill.backgroundColor = .white
        stickyHeaderContainer.addSubview(stickyStatusBarFill)
        stickyStatusBarFill.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.top)
        }

        stickyNavBar.backgroundColor = .white
        stickyHeaderContainer.addSubview(stickyNavBar)
        stickyNavBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(StickyHeaderMetrics.navRowHeight)
        }

        let stickyChevron = UIImage(systemName: "chevron.left")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        )
        stickyBackButton.setImage(stickyChevron, for: .normal)
        stickyBackButton.tintColor = UIColor(hexString: "#1F2942")
        stickyBackButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        stickyNavBar.addSubview(stickyBackButton)
        stickyBackButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(8)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(44)
        }

        stickyTitleLabel.font = .fdFont(ofSize: 20, weight: .medium)
        stickyTitleLabel.textColor = UIColor(hexString: "#1F2942")
        stickyTitleLabel.textAlignment = .center
        stickyTitleLabel.lineBreakMode = .byTruncatingTail
        stickyNavBar.addSubview(stickyTitleLabel)
        stickyTitleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.greaterThanOrEqualTo(stickyBackButton.snp.trailing).offset(8)
            $0.trailing.lessThanOrEqualToSuperview().offset(-52)
        }

        let navDivider = UIView()
        navDivider.backgroundColor = UIColor(hexString: "#F0F2F5")
        stickyNavBar.addSubview(navDivider)
        navDivider.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }

        stickyTabBarView.delegate = self
        stickyHeaderContainer.addSubview(stickyTabBarView)
        stickyTabBarView.snp.makeConstraints {
            $0.top.equalTo(stickyNavBar.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(StickyHeaderMetrics.tabBarHeight)
            $0.bottom.equalToSuperview()
        }

        view.bringSubviewToFront(backButton)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        stickyHeaderContainer.isHidden ? .lightContent : .darkContent
    }

    @objc private func didTapBack() {
        navigationController?.popViewController(animated: true)
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

        viewModel.$isSubmitting
            .receive(on: DispatchQueue.main)
            .sink { [weak self] submitting in
                self?.orderBar.setActionsEnabled(!submitting)
            }
            .store(in: &cancellables)

        viewModel.load()
    }

    private func render(_ pkg: ServicePackageDetail) {
        stopAutoScroll()
        orderBar.removeFromSuperview()
        carouselView = nil
        tierPickerView = nil
        tierIndex = 0
        activeTab = .benefits

        resetPicks(for: pkg.tiers[tierIndex])
        carouselView = PackageDetailCarouselView(
            labels: pkg.carouselLabels,
            imageURLs: pkg.carouselImageURLs,
            accent: pkg.accent
        )
        infoView.configure(with: pkg)
        stickyTitleLabel.text = pkg.name
        if pkg.tiers.count > 1 {
            let picker = PackageDetailTierPickerView()
            picker.delegate = self
            picker.configure(tiers: pkg.tiers, selectedIndex: tierIndex, accent: pkg.accent)
            tierPickerView = picker
        }
        refreshCards()
        rebuildViews()
        setupOrderBar()
        inPageTabBarView.select(activeTab, animated: false)
        stickyTabBarView.select(activeTab, animated: false)

        statusLabel.isHidden = true
        scrollView.isHidden = false
        view.layoutIfNeeded()
        startAutoScroll()
        refreshPayable()
    }

    private func setupOrderBar() {
        orderBar.configure(renewalMode: viewModel.isRenewalMode)
        orderBar.onAddToCart = { [weak self] in
            guard let self else { return }
            if self.viewModel.isRenewalMode {
                self.navigationController?.popViewController(animated: true)
                return
            }
            self.tapCart()
        }
        orderBar.onOrder = { [weak self] in self?.tapOrder() }
        orderBar.attach(to: view, below: scrollView)
        scrollView.contentInset.bottom = 12
    }

    private func rebuildViews() {
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        if let carousel = carouselView {
            contentStack.addArrangedSubview(carousel)
            // 向上覆盖 Banner 底部 28pt（对齐 Figma 3805:20762）
            contentStack.setCustomSpacing(-28, after: carousel)
        }

        // 1. 商品价格与标题卡片：全宽贴边
        infoView.layer.zPosition = 1
        contentStack.addArrangedSubview(infoView)

        // 2. 规格选择卡片（如果有）：16pt margin
        if let tierPickerView {
            let wrappedPicker = wrapWithHorizontalInsets(tierPickerView)
            wrappedPicker.layer.zPosition = 1
            contentStack.addArrangedSubview(wrappedPicker)
        }

        // 3. Tab 选择头：全宽贴边
        inPageTabBarView.layer.zPosition = 1
        contentStack.addArrangedSubview(inPageTabBarView)

        // 4. 权益独立卡片：16pt margin
        let wrappedBenefits = wrapWithHorizontalInsets(benefitsCardView)
        wrappedBenefits.layer.zPosition = 1
        contentStack.addArrangedSubview(wrappedBenefits)

        // 6. 详情信息独立卡片（若有详情图）：16pt margin
        if hasDetailImages {
            let wrappedDetail = wrapWithHorizontalInsets(detailCardView)
            wrappedDetail.layer.zPosition = 1
            contentStack.addArrangedSubview(wrappedDetail)
        }

        // 7. 服务保障独立卡片：16pt margin
        let wrappedGuarantee = wrapWithHorizontalInsets(guaranteeView)
        wrappedGuarantee.layer.zPosition = 1
        contentStack.addArrangedSubview(wrappedGuarantee)
    }

    private func wrapWithHorizontalInsets(_ view: UIView, insets: CGFloat = 16) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        container.addSubview(view)
        view.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(insets)
        }
        return container
    }

    private func refreshCards() {
        guard let package else { return }
        let groupViews = visibleGroups.map { group in
            makeComboGroupView(group)
        }
        benefitsCardView.setGroupViews(groupViews)

        detailCardView.configure(with: package)

        inPageTabBarView.setDetailTabVisible(hasDetailImages)
        stickyTabBarView.setDetailTabVisible(hasDetailImages)
    }

    private func resetPicks(for tier: ServicePackageTier) {
        var radios: [String: Int] = [:]
        var checks: [String: Set<Int>] = [:]
        for group in tier.groups {
            switch group.selectMode {
            case .radio:
                radios[group.name] = group.firstParentIndex
            case .checkbox:
                let picked = group.items.enumerated().compactMap { idx, item -> Int? in
                    guard !item.isChild else { return nil }
                    return (item.defaultCheck == 1 || item.defaultSelected) ? idx : nil
                }
                checks[group.name] = Set(picked)
            case .required:
                break
            }
        }
        radioPicks = radios
        checkPicks = checks
    }

    private func makeComboGroupView(_ group: ServicePackageComboGroup) -> PackageComboGroupView {
        let view = PackageComboGroupView()
        view.configure(
            group: group,
            radioPick: radioPicks[group.name],
            checkPicks: checkPicks[group.name] ?? []
        )
        view.onRadioSelect = { [weak self] index in
            guard let self else { return }
            guard group.items.indices.contains(index), !group.items[index].isChild else { return }
            self.radioPicks[group.name] = index
            self.refreshPayable()
        }
        view.onCheckToggle = { [weak self] index in
            guard let self else { return }
            guard group.items.indices.contains(index), !group.items[index].isChild else { return }
            var set = self.checkPicks[group.name] ?? []
            if set.contains(index) { set.remove(index) } else { set.insert(index) }
            self.checkPicks[group.name] = set
            self.refreshPayable()
        }
        return view
    }

    private func selectedItemPrices() -> [Double] {
        guard let tier = activeTier else { return [] }
        var prices: [Double] = []
        for group in tier.groups {
            for index in selectedSubtreeIndices(in: group) {
                prices.append(group.items[index].priceValue)
            }
        }
        return prices
    }

    private func selectedSubtreeIndices(in group: ServicePackageComboGroup) -> [Int] {
        switch group.selectMode {
        case .required:
            return Array(group.items.indices)
        case .radio:
            let parent = radioPicks[group.name] ?? group.firstParentIndex
            return group.subtreeIndices(forParentAt: parent)
        case .checkbox:
            let picked = checkPicks[group.name] ?? []
            return picked
                .filter { group.items.indices.contains($0) && !group.items[$0].isChild }
                .sorted()
                .flatMap { group.subtreeIndices(forParentAt: $0) }
        }
    }

    private func refreshPayable() {
        let prices = selectedItemPrices()
        guard !prices.isEmpty else {
            orderBar.setPayableText("0.00")
            return
        }
        let total = prices.reduce(0, +)
        orderBar.setPayableText(ServicePackageMoney.yen(total))
    }

    private func scrollToFloor(_ tab: PackageDetailTab, animated: Bool) {
        if tab == .detail, !hasDetailImages { return }

        view.layoutIfNeeded()

        let anchor: UIView
        switch tab {
        case .benefits:
            anchor = benefitsCardView
        case .detail:
            anchor = detailCardView
        }

        let targetRect = anchor.convert(anchor.bounds, to: scrollView)
        let topOffset = view.safeAreaInsets.top + StickyHeaderMetrics.contentHeight + 4
        let targetY = max(0, targetRect.minY - topOffset)

        let maxOffset = max(0, scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom)
        let clampedY = min(targetY, maxOffset)

        activeTab = tab
        inPageTabBarView.select(activeTab, animated: true)
        stickyTabBarView.select(activeTab, animated: true)

        isUserScrollingToTab = true
        scrollView.setContentOffset(CGPoint(x: 0, y: clampedY), animated: animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.isUserScrollingToTab = false
        }
    }

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

    private func tapCart() {
        guard package != nil, !viewModel.isSubmitting else { return }

        guard viewModel.usesRemoteCartAPI else {
            showToast("请选择正式套餐后再加入购物车")
            return
        }

        let details = buildSelectedSubmitDetails()
        guard !details.isEmpty else {
            showToast("套餐内容配置异常")
            return
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.viewModel.addToCart(selectedDetails: details)
                await MainActor.run {
                    self.showToast("已加入购物车") {
                        Router.shared.push("/services/cart")
                    }
                }
            } catch {
                await MainActor.run {
                    self.showToast(error.localizedDescription)
                }
            }
        }
    }

    private func tapOrder() {
        guard let pkg = package, !viewModel.isSubmitting else { return }
        let selectedItems = buildSelectedComboItems()

        guard viewModel.usesRemoteCartAPI else {
            saveOrderDraft(package: pkg, selectedItems: selectedItems)
            showToast("请使用正式套餐下单")
            return
        }

        let details = selectedItems.compactMap { $0.toSubmitItem() }
        guard !details.isEmpty else {
            showToast("套餐内容配置异常")
            return
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                let orderId = try await self.viewModel.purchaseNow(selectedDetails: details)
                await MainActor.run {
                    Router.shared.push("/orders/confirm", params: ["orderId": String(orderId)])
                }
            } catch {
                await MainActor.run {
                    self.showToast(error.localizedDescription)
                }
            }
        }
    }

    private func buildSelectedComboItems() -> [ServicePackageComboItem] {
        guard let tier = activeTier else { return [] }
        var items: [ServicePackageComboItem] = []
        for group in tier.groups {
            for index in selectedSubtreeIndices(in: group) {
                items.append(group.items[index])
            }
        }
        return items
    }

    private func saveOrderDraft(package: ServicePackageDetail, selectedItems: [ServicePackageComboItem]) {
        let institution = AppContainer.shared.institutionSelectionStore.selected
        let draft = PackageOrderDraft.fromPackageDetail(
            package: package,
            selectedItems: selectedItems,
            hospitalId: institution?.id ?? AppContainer.shared.institutionSelectionStore.selectedHospitalId,
            hospitalName: institution?.name,
            hospitalAddress: institution?.fullAddress,
            categoryServiceId: package.categoryServiceId
        )
        PackageOrderDraftStore.shared.save(draft)
    }

    private func buildSelectedSubmitDetails() -> [PackageHospitalDetailSubmitItem] {
        buildSelectedComboItems().compactMap { $0.toSubmitItem() }
    }

    private func showToast(_ message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            alert.dismiss(animated: true) {
                completion?()
            }
        }
    }
}

// MARK: - UIScrollViewDelegate

extension ServicePackageDetailViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let tabPos = inPageTabBarView.convert(inPageTabBarView.bounds, to: view)
        let stickyThreshold = view.safeAreaInsets.top

        let shouldShowSticky = tabPos.minY <= stickyThreshold
        if shouldShowSticky != !stickyHeaderContainer.isHidden {
            stickyHeaderContainer.isHidden = !shouldShowSticky
            UIView.animate(withDuration: 0.15) {
                self.stickyHeaderContainer.alpha = shouldShowSticky ? 1.0 : 0.0
                self.backButton.alpha = shouldShowSticky ? 0.0 : 1.0
            }
            backButton.isUserInteractionEnabled = !shouldShowSticky
            if shouldShowSticky {
                view.bringSubviewToFront(stickyHeaderContainer)
            } else {
                view.bringSubviewToFront(backButton)
            }
            setNeedsStatusBarAppearanceUpdate()
        }

        guard !isUserScrollingToTab else { return }

        // 根据滚动位置自动同步当前高亮 Tab
        let topCheckPoint = stickyThreshold + StickyHeaderMetrics.contentHeight + 8
        let benefitsY = benefitsCardView.convert(CGPoint.zero, to: view).y
        let detailY = detailCardView.convert(CGPoint.zero, to: view).y

        var detectedTab: PackageDetailTab = .benefits
        if hasDetailImages && detailY <= topCheckPoint {
            detectedTab = .detail
        } else if benefitsY <= topCheckPoint + 100 {
            detectedTab = .benefits
        }

        if detectedTab != activeTab {
            activeTab = detectedTab
            inPageTabBarView.select(detectedTab, animated: true)
            stickyTabBarView.select(detectedTab, animated: true)
        }
    }
}

// MARK: - Delegates

extension ServicePackageDetailViewController: PackageDetailTabBarViewDelegate {

    func tabBarView(_ view: PackageDetailTabBarView, didSelect tab: PackageDetailTab) {
        scrollToFloor(tab, animated: true)
    }
}

extension ServicePackageDetailViewController: PackageDetailTierPickerViewDelegate {

    func tierPickerView(_ view: PackageDetailTierPickerView, didSelect index: Int) {
        guard let pkg = package, index != tierIndex else { return }
        tierIndex = index
        resetPicks(for: pkg.tiers[tierIndex])
        view.configure(tiers: pkg.tiers, selectedIndex: tierIndex, accent: pkg.accent)
        refreshCards()
        refreshPayable()
    }
}
