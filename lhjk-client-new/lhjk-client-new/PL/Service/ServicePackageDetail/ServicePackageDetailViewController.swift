import UIKit
import SnapKit
import Combine

/// 服务套餐详情 — 三段式：Banner / 简介 / 权益+详情连续楼层
final class ServicePackageDetailViewController: BaseViewController {

    private let viewModel: ServicePackageDetailViewModel
    private var cancellables = Set<AnyCancellable>()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let orderBar = PackageDetailOrderBarView()
    private let statusLabel = UILabel()
    private let floatingTabBar = PackageDetailTabBarView()

    private var carouselView: PackageDetailCarouselView?
    private let infoView = PackageDetailInfoView()
    private let floorsView = PackageDetailFloorsView()
    private var tierPickerView: PackageDetailTierPickerView?
    private var autoScrollTimer: Timer?

    private enum TableRow: Equatable {
        case carousel
        case info
        case tier
        case floors
    }

    private var activeTab: PackageDetailTab = .content
    private var tierIndex = 0
    private var rows: [TableRow] = []
    private var radioPicks: [String: Int] = [:]
    private var checkPicks: [String: Set<Int>] = [:]
    private var floorsRowY: CGFloat = 0
    private var isScrollingToFloor = false

    /// floors cell 顶部 inset，与 cellForRow 保持一致
    private let floorsCellTopInset: CGFloat = 14
    /// 浮动 Tab 与楼层内容之间的间距
    private let stickyTabGap: CGFloat = 4
    private let floatingTabHeight: CGFloat = 44

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
        categoryServiceId: String? = nil
    ) {
        self.viewModel = ServicePackageDetailViewModel(
            packageId: packageId,
            hospitalId: hospitalId,
            categoryServiceId: categoryServiceId
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit { stopAutoScroll() }

    override func setupUI() {
        view.backgroundColor = .fdBg
        title = "套餐详情"

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.estimatedRowHeight = 200
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ServicePackageHostedCell.self, forCellReuseIdentifier: ServicePackageHostedCell.reuseID)
        tableView.isHidden = true
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        floorsView.tabDelegate = self

        floatingTabBar.isHidden = true
        floatingTabBar.backgroundColor = .fdSurface
        floatingTabBar.delegate = self
        view.addSubview(floatingTabBar)
        floatingTabBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(44)
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
        isScrollingToFloor = false

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
        rebuildRows()
        setupOrderBar()
        syncTabSelection(animated: false)

        statusLabel.isHidden = true
        tableView.isHidden = false
        floatingTabBar.isHidden = true
        tableView.reloadData()
        view.layoutIfNeeded()
        updateFloorsRowY()
        startAutoScroll()
        refreshPayable()
    }

    private func setupOrderBar() {
        orderBar.onAddToCart = { [weak self] in self?.tapCart() }
        orderBar.onOrder = { [weak self] in self?.tapOrder() }
        orderBar.attach(to: view, below: tableView)
        tableView.contentInset.bottom = 12
    }

    private func rebuildRows() {
        guard package != nil else {
            rows = []
            return
        }
        var next: [TableRow] = [.carousel, .info]
        if tierPickerView != nil { next.append(.tier) }
        next.append(.floors)
        rows = next
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

    private func reloadFloorsContent(heightMayChange: Bool = false) {
        // 勾选仅改选中态，高度不变；勿 reloadRows，否则托管 floorsView 行高会塌缩。
        refreshFloorsView()
        floorsView.setNeedsLayout()
        floorsView.layoutIfNeeded()
        if heightMayChange {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        updateFloorsRowY()
    }

    private func resetPicks(for tier: ServicePackageTier) {
        var radios: [String: Int] = [:]
        var checks: [String: Set<Int>] = [:]
        for group in tier.groups {
            switch group.selectMode {
            case .radio:
                // 单选：默认选中第一个父项
                radios[group.name] = group.firstParentIndex
            case .checkbox:
                // 可选：父项按 defaultCheck == 1 初始化，用户可取消
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
            self.reloadFloorsContent()
            self.refreshPayable()
        }
        view.onCheckToggle = { [weak self] index in
            guard let self else { return }
            guard group.items.indices.contains(index), !group.items[index].isChild else { return }
            var set = self.checkPicks[group.name] ?? []
            if set.contains(index) { set.remove(index) } else { set.insert(index) }
            self.checkPicks[group.name] = set
            self.reloadFloorsContent()
            self.refreshPayable()
        }
        return view
    }

    private func selectedItemPrices() -> [Int] {
        guard let tier = activeTier else { return [] }
        var prices: [Int] = []
        for group in tier.groups {
            for index in selectedSubtreeIndices(in: group) {
                prices.append(group.items[index].price)
            }
        }
        return prices
    }

    /// 已选父项及其子项下标（父选中则子项一并计入）
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
            orderBar.setPayableText("—")
            return
        }
        if prices.allSatisfy({ $0 == 0 }), activeTier?.priceUnit.contains("面议") == true {
            orderBar.setPayableText("面议")
            return
        }
        let total = prices.reduce(0, +)
        orderBar.setPayableText("¥\(grouped(total))")
    }

    private func grouped(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func syncTabSelection(animated: Bool) {
        floorsView.tabBarView.select(activeTab, animated: animated)
        floatingTabBar.setDetailTabVisible(hasDetailImages)
        floatingTabBar.select(activeTab, animated: animated)
    }

    /// 点击 Tab 时，将对应楼层锚点滚到浮动 Tab 正下方
    private func scrollToFloor(_ tab: PackageDetailTab, animated: Bool) {
        guard let index = rows.firstIndex(of: .floors) else { return }
        if tab == .detail, !hasDetailImages { return }

        view.layoutIfNeeded()
        tableView.layoutIfNeeded()
        floorsView.layoutIfNeeded()

        let cellRect = tableView.rectForRow(at: IndexPath(row: index, section: 0))
        guard let floorY = floorsView.floorMinY(for: tab) else { return }

        // cell 顶 + cell topInset + 楼层在 floorsView 内的 Y − 浮动 Tab 预留高度
        // 注意：floorMinY 不再扣 sticky，避免重复减偏移
        let reserved = floatingTabHeight + stickyTabGap
        let targetY = max(0, cellRect.minY + floorsCellTopInset + floorY - reserved)
        let maxOffset = max(0, tableView.contentSize.height - tableView.bounds.height + tableView.contentInset.bottom)
        let clampedY = min(targetY, maxOffset)

        isScrollingToFloor = true
        activeTab = tab
        syncTabSelection(animated: true)
        // 先显示浮动 Tab，避免滚动过程中内容被导航区遮挡观感不一致
        floatingTabBar.isHidden = false
        tableView.setContentOffset(CGPoint(x: 0, y: clampedY), animated: animated)

        let delay = animated ? 0.4 : 0.05
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            self.isScrollingToFloor = false
            self.updateFloatingTabVisibility()
            // 动画结束后再校正一次，消除自动行高带来的偏差
            self.correctFloorOffsetIfNeeded(for: tab)
        }
    }

    private func correctFloorOffsetIfNeeded(for tab: PackageDetailTab) {
        guard let index = rows.firstIndex(of: .floors) else { return }
        view.layoutIfNeeded()
        tableView.layoutIfNeeded()
        floorsView.layoutIfNeeded()

        let cellRect = tableView.rectForRow(at: IndexPath(row: index, section: 0))
        guard let floorY = floorsView.floorMinY(for: tab) else { return }
        let reserved = floatingTabHeight + stickyTabGap
        let targetY = max(0, cellRect.minY + floorsCellTopInset + floorY - reserved)
        let maxOffset = max(0, tableView.contentSize.height - tableView.bounds.height + tableView.contentInset.bottom)
        let clampedY = min(targetY, maxOffset)

        if abs(tableView.contentOffset.y - clampedY) > 2 {
            tableView.setContentOffset(CGPoint(x: 0, y: clampedY), animated: false)
        }
    }

    private func updateFloorsRowY() {
        guard let index = rows.firstIndex(of: .floors) else {
            floorsRowY = .greatestFiniteMagnitude
            return
        }
        floorsRowY = tableView.rectForRow(at: IndexPath(row: index, section: 0)).minY
    }

    private func updateFloatingTabVisibility() {
        guard package != nil else {
            floatingTabBar.isHidden = true
            return
        }
        // 卡片内 Tab 顶边滚到 table 可视区顶部附近时显示浮动副本
        let tabBarYInContent = floorsRowY + floorsCellTopInset + floorsView.tabBarView.frame.minY
        let shouldShow = tableView.contentOffset.y + stickyTabGap >= tabBarYInContent
        floatingTabBar.isHidden = !shouldShow
    }

    private func updateActiveTabFromScroll() {
        guard hasDetailImages, !isScrollingToFloor else { return }
        guard let index = rows.firstIndex(of: .floors) else { return }

        view.layoutIfNeeded()
        let cellRect = tableView.rectForRow(at: IndexPath(row: index, section: 0))
        guard let detailFloorY = floorsView.floorMinY(for: .detail) else {
            if activeTab != .content {
                activeTab = .content
                syncTabSelection(animated: true)
            }
            return
        }

        // 可视区顶部（扣掉浮动 Tab）越过详情锚点后切到「详情」
        let viewportTop = tableView.contentOffset.y + floatingTabHeight + stickyTabGap
        let detailAbsoluteY = cellRect.minY + floorsCellTopInset + detailFloorY
        let newTab: PackageDetailTab = viewportTop >= detailAbsoluteY - 8 ? .detail : .content
        guard newTab != activeTab else { return }
        activeTab = newTab
        syncTabSelection(animated: true)
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

        // 本地原型套餐：不调服务端、不写本地购物车
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
        let packageId = pkg.id
        let selectedItems = buildSelectedComboItems()

        // 本地原型套餐：无服务端订单 id，无法拉结算
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

    /// 按当前勾选组装展示/提交用明细（父选中则含子项）
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

    /// 按当前勾选组装提交明细（必选全部 / 单选一项 / 可选已勾选）
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

// MARK: - UITableView

extension ServicePackageDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ServicePackageHostedCell.reuseID,
            for: indexPath
        ) as! ServicePackageHostedCell

        switch row {
        case .carousel:
            if let carousel = carouselView {
                cell.host(carousel, insets: UIEdgeInsets(top: 8, left: 16, bottom: 0, right: 16))
            }
        case .info:
            cell.host(infoView, insets: UIEdgeInsets(top: 14, left: 16, bottom: 0, right: 16))
        case .tier:
            if let tierPickerView {
                cell.host(tierPickerView, insets: UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16))
            }
        case .floors:
            cell.host(
                floorsView,
                insets: UIEdgeInsets(top: floorsCellTopInset, left: 16, bottom: 24, right: 16)
            )
        }
        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateFloatingTabVisibility()
        updateActiveTabFromScroll()
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
        reloadFloorsContent(heightMayChange: true)
        refreshPayable()
    }
}
