import UIKit
import SnapKit
import Combine

/// 服务套餐详情 — 三段式：Banner / 价格与简介 / 权益与详情连续楼层（对齐 Figma 3449:7764）
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
    private let floorsView = PackageDetailFloorsView()
    private var tierPickerView: PackageDetailTierPickerView?
    private var autoScrollTimer: Timer?

    private var activeTab: PackageDetailTab = .content
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

        floorsView.tabDelegate = self

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
        activeTab = .content

        resetPicks(for: pkg.tiers[tierIndex])
        carouselView = PackageDetailCarouselView(
            labels: pkg.carouselLabels,
            imageURLs: pkg.carouselImageURLs,
            accent: pkg.accent
        )
        infoView.configure(with: pkg)
        if pkg.tiers.count > 1 {
            let picker = PackageDetailTierPickerView()
            picker.delegate = self
            picker.configure(tiers: pkg.tiers, selectedIndex: tierIndex, accent: pkg.accent)
            tierPickerView = picker
        }
        refreshFloorsView()
        rebuildViews()
        setupOrderBar()
        floorsView.tabBarView.select(activeTab, animated: false)

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
            // 向上覆盖 Banner 底部 28pt（对齐 Figma 3449:7764）
            contentStack.setCustomSpacing(-28, after: carousel)
        }
        let wrappedInfo = wrapWithHorizontalInsets(infoView)
        wrappedInfo.layer.zPosition = 1
        contentStack.addArrangedSubview(wrappedInfo)
        if let tierPickerView {
            let wrappedPicker = wrapWithHorizontalInsets(tierPickerView)
            wrappedPicker.layer.zPosition = 1
            contentStack.addArrangedSubview(wrappedPicker)
        }
        let wrappedFloors = wrapWithHorizontalInsets(floorsView)
        wrappedFloors.layer.zPosition = 1
        contentStack.addArrangedSubview(wrappedFloors)
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

    private func refreshFloorsView() {
        guard let package else { return }
        floorsView.configure(
            package: package,
            groups: visibleGroups,
            radioPicks: radioPicks,
            checkPicks: checkPicks,
            makeGroupView: { [weak self] group in
                self?.makeComboGroupView(group) ?? PackageComboGroupView()
            }
        )
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
            self.refreshFloorsView()
            self.refreshPayable()
        }
        view.onCheckToggle = { [weak self] index in
            guard let self else { return }
            guard group.items.indices.contains(index), !group.items[index].isChild else { return }
            var set = self.checkPicks[group.name] ?? []
            if set.contains(index) { set.remove(index) } else { set.insert(index) }
            self.checkPicks[group.name] = set
            self.refreshFloorsView()
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
        floorsView.layoutIfNeeded()

        let anchor = tab == .content ? floorsView.contentFloorAnchor : floorsView.detailFloorAnchor
        let targetRect = anchor.convert(anchor.bounds, to: scrollView)
        let targetY = max(0, targetRect.minY - 20)

        let maxOffset = max(0, scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom)
        let clampedY = min(targetY, maxOffset)

        activeTab = tab
        floorsView.tabBarView.select(activeTab, animated: true)
        scrollView.setContentOffset(CGPoint(x: 0, y: clampedY), animated: animated)
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
        refreshFloorsView()
        refreshPayable()
    }
}
