import UIKit
import SnapKit
import Combine

/// 套餐选择页 — 对齐 funde-client `ServiceListView.vue`
final class ServiceListViewController: BaseViewController {

    private let viewModel: ServiceListViewModel
    /// 只展示左类目 + 右套餐，不含顶部机构卡。用于健康服务页替换德系矩阵。
    private let showsPackageBrowserOnly: Bool
    /// 首页健康服务：Banner 和左右栏在同一条滚动里，Banner 离开后左侧分类吸顶。
    private let embedsInHomeShelf: Bool
    private var cancellables = Set<AnyCancellable>()
    private var lockRightScrollSync = false
    private var lockLeftScroll = false
    private let shelfScroll: UIScrollView = {
        let scroll = UIScrollView()
        scroll.backgroundColor = .fdBg
        scroll.alwaysBounceVertical = true
        scroll.showsVerticalScrollIndicator = false
        scroll.contentInsetAdjustmentBehavior = .never
        return scroll
    }()
    private let shelfContent = UIView()
    private let bannerSlot = UIView()
    private var bannerSlotHeightConstraint: Constraint?
    private var leftTopConstraint: Constraint?
    private var leftHeightConstraint: Constraint?
    private var rightHeightConstraint: Constraint?
    private var shelfBannerHeight: CGFloat = 0
    private var appliedRightHeight: CGFloat = -1
    private var appliedLeftTop: CGFloat = -1
    private var appliedLeftHeight: CGFloat = -1
    private let rightSafeAreaFill = UIView()
    private let rightTableContentFiller = UIView()

    private let institutionCard = ServiceInstitutionCardView()
    private let layoutContainer = UIView()
    private let topDivider = UIView()
    private let rightPanelBackground = UIView()

    private lazy var leftTable: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        // 白色底：未选中项圆弧裁切后露出白底，形成与选中区的内凹衔接
        tv.backgroundColor = .white
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.register(CategoryNavCell.self, forCellReuseIdentifier: CategoryNavCell.reuseID)
        tv.dataSource = self
        tv.delegate = self
        tv.tag = 0
        return tv
    }()

    private lazy var rightTable: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .white
        tv.isOpaque = true
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        tv.sectionHeaderTopPadding = 0
        let headerSpacer = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 16))
        headerSpacer.backgroundColor = .white
        tv.tableHeaderView = headerSpacer
        tv.backgroundView = UIView()
        tv.backgroundView?.backgroundColor = .white
        tv.register(PackageSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: PackageSectionHeaderView.reuseID)
        tv.register(PackageCardCell.self, forCellReuseIdentifier: PackageCardCell.reuseID)
        tv.dataSource = self
        tv.delegate = self
        tv.tag = 1
        return tv
    }()

    private enum Layout {
        /// Figma 左栏约 100，略加宽以适配文案
        static let sidebarWidth: CGFloat = 108
    }

    private let loadingIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        return spinner
    }()

    private let cartButton = ServiceCartBadgeButton(style: .nav)

    init(
        productCode: String,
        showsPackageBrowserOnly: Bool = false,
        embedsInHomeShelf: Bool = false
    ) {
        self.showsPackageBrowserOnly = showsPackageBrowserOnly
        self.embedsInHomeShelf = embedsInHomeShelf
        self.viewModel = ServiceListViewModel(routeCode: productCode)
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = !showsPackageBrowserOnly && !embedsInHomeShelf
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        if !showsPackageBrowserOnly {
            title = "选择套餐"
            setupNavigationItems()
        }
        institutionCard.configure(viewModel.institution)
        viewModel.load()
    }

    private func setupNavigationItems() {
        let iconSize = ServiceCartBadgeButton.Style.nav.iconSize
        let boxSize = cartButton.intrinsicContentSize

        let searchButton = UIButton(type: .custom)
        searchButton.setImage(.fdNavSearch, for: .normal)
        searchButton.tintColor = .fdText
        searchButton.adjustsImageWhenHighlighted = false
        searchButton.accessibilityLabel = "搜索"
        searchButton.addTarget(self, action: #selector(openSearch), for: .touchUpInside)

        // 与购物车同一盒子：24 图标贴左下，右上留给角标。两系统共用，避免一边 24 一边 33 对不齐
        let searchBox = UIView()
        searchBox.clipsToBounds = false
        searchBox.addSubview(searchButton)
        searchBox.snp.makeConstraints { $0.size.equalTo(boxSize) }
        searchButton.snp.makeConstraints {
            $0.leading.bottom.equalToSuperview()
            $0.size.equalTo(iconSize)
        }

        cartButton.addTarget(self, action: #selector(openCart), for: .touchUpInside)
        cartButton.setContentHuggingPriority(.required, for: .horizontal)
        cartButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        cartButton.snp.makeConstraints { $0.size.equalTo(boxSize) }

        let stack = UIStackView(arrangedSubviews: [searchBox, cartButton])
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .center
        stack.clipsToBounds = false
        stack.frame = CGRect(origin: .zero, size: CGSize(width: boxSize.width * 2 + 16, height: boxSize.height))

        let item = UIBarButtonItem(customView: stack)
        if #available(iOS 26.0, *) {
            item.hidesSharedBackground = true
        }
        navigationItem.rightBarButtonItem = item
    }

    @objc private func openSearch() {
        Router.shared.push("/services/search", params: ["hospitalId": viewModel.searchHospitalId])
    }

    @objc private func openCart() {
        Router.shared.push("/services/cart")
    }

    /// 把首页 Banner 放进这条滚动的最上面。高度由 Banner 自己按图片比例撑开。
    func installShelfBanner(_ banner: UIView) {
        guard embedsInHomeShelf else { return }
        banner.removeFromSuperview()
        bannerSlot.addSubview(banner)
        banner.snp.remakeConstraints { $0.edges.equalToSuperview() }
    }

    func updateShelfBannerHeight(_ height: CGFloat) {
        guard embedsInHomeShelf else { return }
        let next = max(0, height)
        let previous = shelfBannerHeight
        guard abs(next - previous) > 0.5 else { return }
        shelfBannerHeight = next
        bannerSlotHeightConstraint?.update(offset: next)
        if previous > 1, next > 1, shelfScroll.contentOffset.y > 0 {
            shelfScroll.contentOffset.y += next - previous
        }
        view.layoutIfNeeded()
        updateStickyLeftColumn()
    }

    private func setupShelfUI() {
        view.backgroundColor = .fdBg
        shelfScroll.delegate = self
        shelfContent.backgroundColor = .fdBg
        bannerSlot.backgroundColor = .clear
        rightPanelBackground.backgroundColor = .white
        rightTable.isScrollEnabled = false
        rightTable.bounces = false
        rightTable.contentInset = .zero
        rightTable.contentInsetAdjustmentBehavior = .never
        leftTable.contentInsetAdjustmentBehavior = .never
        leftTable.bounces = true
        leftTable.isScrollEnabled = false

        view.addSubview(shelfScroll)
        shelfScroll.addSubview(shelfContent)
        shelfContent.addSubview(bannerSlot)
        shelfContent.addSubview(rightPanelBackground)
        shelfContent.addSubview(rightTable)
        shelfContent.addSubview(leftTable)
        view.addSubview(loadingIndicator)

        shelfScroll.snp.makeConstraints { $0.edges.equalToSuperview() }
        shelfContent.snp.makeConstraints {
            $0.edges.equalTo(shelfScroll.contentLayoutGuide)
            $0.width.equalTo(shelfScroll.frameLayoutGuide)
        }
        bannerSlot.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            bannerSlotHeightConstraint = $0.height.equalTo(0).constraint
        }
        leftTable.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.width.equalTo(Layout.sidebarWidth)
            leftTopConstraint = $0.top.equalToSuperview().constraint
            leftHeightConstraint = $0.height.equalTo(0).constraint
        }
        rightTable.snp.makeConstraints {
            $0.top.equalTo(bannerSlot.snp.bottom)
            $0.trailing.bottom.equalToSuperview()
            $0.leading.equalTo(leftTable.snp.trailing)
            rightHeightConstraint = $0.height.equalTo(1).constraint
        }
        rightPanelBackground.snp.makeConstraints {
            $0.edges.equalTo(rightTable)
        }
        loadingIndicator.snp.makeConstraints {
            $0.center.equalTo(shelfScroll)
        }
    }

    override func setupUI() {
        if embedsInHomeShelf {
            setupShelfUI()
            return
        }
        view.backgroundColor = .fdBg
        topDivider.backgroundColor = .fdBorder
        layoutContainer.backgroundColor = .fdBg
        rightPanelBackground.backgroundColor = .white
        rightSafeAreaFill.backgroundColor = .white
        rightTableContentFiller.backgroundColor = .white
        // 两栏各自裁剪内容，右侧卡片不能溢出到左侧类目栏
        layoutContainer.clipsToBounds = true
        leftTable.clipsToBounds = true
        rightTable.clipsToBounds = true

        view.addSubview(institutionCard)
        view.addSubview(topDivider)
        view.addSubview(layoutContainer)
        view.insertSubview(rightSafeAreaFill, belowSubview: layoutContainer)
        layoutContainer.addSubview(rightPanelBackground)
        layoutContainer.addSubview(leftTable)
        layoutContainer.addSubview(rightTable)
        view.addSubview(loadingIndicator)

        institutionCard.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
        }
        topDivider.snp.makeConstraints {
            $0.top.equalTo(institutionCard.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }
        layoutContainer.snp.makeConstraints {
            $0.top.equalTo(topDivider.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        leftTable.snp.makeConstraints {
            $0.top.leading.bottom.equalToSuperview()
            $0.width.equalTo(Layout.sidebarWidth)
        }
        rightPanelBackground.snp.makeConstraints {
            $0.top.trailing.bottom.equalToSuperview()
            $0.leading.equalTo(leftTable.snp.trailing)
        }
        rightTable.snp.makeConstraints {
            $0.top.trailing.bottom.equalToSuperview()
            $0.leading.equalTo(leftTable.snp.trailing)
        }
        loadingIndicator.snp.makeConstraints {
            $0.center.equalTo(rightTable)
        }

        // Home Indicator 区域：右侧保持白底，避免露出页面 fdBg
        rightSafeAreaFill.snp.makeConstraints {
            $0.leading.equalTo(layoutContainer.snp.leading).offset(Layout.sidebarWidth)
            $0.trailing.bottom.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        if showsPackageBrowserOnly {
            institutionCard.isHidden = true
            topDivider.isHidden = true
            rightSafeAreaFill.isHidden = true
            institutionCard.snp.remakeConstraints {
                $0.top.leading.trailing.equalToSuperview()
                $0.height.equalTo(0)
            }
            topDivider.snp.remakeConstraints {
                $0.top.leading.trailing.equalToSuperview()
                $0.height.equalTo(0)
            }
        }

        institutionCard.onSwitchTap = { [weak self] in
            guard let self else { return }
            var params: [String: Any] = ["source": "services"]
            if let id = InstitutionSelectionStore.shared.selected?.id {
                params["selectedId"] = id
            }
            Router.shared.push("/services/institution", params: params)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        institutionCard.configure(viewModel.institution)
        AppContainer.shared.shoppingCartBadgeStore.refresh()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if embedsInHomeShelf {
            refreshShelfPackageHeight()
        } else {
            updateRightTableContentFillerIfNeeded()
        }
    }

    /// 右侧套餐不自己滚，高度等于内容高度，整页滚动由 shelfScroll 负责。
    private func refreshShelfPackageHeight() {
        guard embedsInHomeShelf, shelfScroll.bounds.width > 1 else { return }
        if rightTable.tableFooterView == nil {
            let spacer = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 24))
            spacer.backgroundColor = .white
            rightTable.tableFooterView = spacer
        }
        rightTable.layoutIfNeeded()
        let height = max(rightTable.contentSize.height, 1)
        guard abs(height - appliedRightHeight) > 0.5 else {
            updateStickyLeftColumn()
            return
        }
        appliedRightHeight = height
        rightHeightConstraint?.update(offset: height)
        updateStickyLeftColumn()
    }

    /// Banner 还在视口里时，左栏跟在 Banner 下面一起走。Banner 离开后，左栏吸在滚动区域顶部。
    private func updateStickyLeftColumn() {
        guard embedsInHomeShelf, shelfScroll.bounds.height > 1 else { return }
        leftTable.layoutIfNeeded()
        let leftContent = max(leftTable.contentSize.height, 1)
        let visible = shelfScroll.bounds.height
        let leftHeight = min(leftContent, visible)
        if abs(leftHeight - appliedLeftHeight) > 0.5 {
            appliedLeftHeight = leftHeight
            leftHeightConstraint?.update(offset: leftHeight)
        }

        let offset = shelfScroll.contentOffset.y
        let contentBottom = shelfBannerHeight + max(appliedRightHeight, leftHeight)
        let maxTop = max(shelfBannerHeight, contentBottom - leftHeight)
        let top = min(max(shelfBannerHeight, offset), maxTop)
        if abs(top - appliedLeftTop) > 0.5 {
            appliedLeftTop = top
            leftTopConstraint?.update(offset: top)
        }

        let bannerHidden = offset >= shelfBannerHeight - 1
        let overflows = leftContent > visible + 1
        if leftTable.isScrollEnabled != (bannerHidden && overflows) {
            leftTable.isScrollEnabled = bannerHidden && overflows
        }
    }

    /// 左栏已经滚到自己的顶部后再下拉，把整页拉下来，Banner 跟着出现。
    private func revealShelfBannerFromLeftPull() {
        let rest = -leftTable.adjustedContentInset.top
        let pulled = rest - leftTable.contentOffset.y
        guard pulled > 0.5, shelfScroll.contentOffset.y > 0 else { return }
        shelfScroll.contentOffset.y = max(0, shelfScroll.contentOffset.y - pulled)
        leftTable.contentOffset.y = rest
        updateStickyLeftColumn()
    }

    private func updateRightTableContentFillerIfNeeded() {
        guard rightTable.bounds.height > 0 else { return }
        rightTable.layoutIfNeeded()
        let fillerHeight = rightTable.bounds.height
            - rightTable.contentSize.height
            + rightTable.contentInset.top
        guard fillerHeight > 1 else {
            rightTable.tableFooterView = nil
            return
        }
        rightTableContentFiller.frame = CGRect(
            x: 0,
            y: 0,
            width: rightTable.bounds.width,
            height: fillerHeight
        )
        rightTable.tableFooterView = rightTableContentFiller
    }

    override func bindViewModel() {
        AppContainer.shared.shoppingCartBadgeStore.$count
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.cartButton.apply(count: count)
            }
            .store(in: &cancellables)

        viewModel.$categories
            .receive(on: DispatchQueue.main)
            .sink { [weak self] categories in
                guard let self else { return }
                self.leftTable.reloadData()
                self.scrollLeftTableToActiveCategory(in: categories, animated: false)
            }
            .store(in: &cancellables)

        viewModel.$packageSections
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.rightTable.reloadData()
                self.rightTable.layoutIfNeeded()
                if self.embedsInHomeShelf {
                    self.appliedRightHeight = -1
                    self.refreshShelfPackageHeight()
                } else {
                    self.updateRightTableContentFillerIfNeeded()
                }
            }
            .store(in: &cancellables)

        viewModel.$activeCategoryId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.leftTable.reloadData()
                if !self.lockRightScrollSync {
                    self.scrollLeftTableToActiveCategory(in: self.viewModel.categories, animated: true)
                }
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)

        viewModel.$institution
            .receive(on: DispatchQueue.main)
            .sink { [weak self] display in
                self?.institutionCard.configure(display)
            }
            .store(in: &cancellables)
    }

    private func scrollLeftTableToActiveCategory(in categories: [ServiceListCategory], animated: Bool) {
        guard let id = viewModel.activeCategoryId,
              let idx = categories.firstIndex(where: { $0.id == id }) else { return }
        lockLeftScroll = true
        leftTable.scrollToRow(
            at: IndexPath(row: idx, section: 0),
            at: .middle,
            animated: animated
        )
        if !animated || (!leftTable.isDragging && !leftTable.isDecelerating) {
            DispatchQueue.main.async { [weak self] in
                guard let self, !self.leftTable.isDragging, !self.leftTable.isDecelerating else { return }
                self.lockLeftScroll = false
            }
        }
    }

    private func scrollRightTable(toSectionHeader section: Int) {
        guard section < rightTable.numberOfSections else { return }
        rightTable.layoutIfNeeded()
        let headerY = rightTable.rectForHeader(inSection: section).minY
        if embedsInHomeShelf {
            refreshShelfPackageHeight()
            view.layoutIfNeeded()
            let maxY = max(0, shelfScroll.contentSize.height - shelfScroll.bounds.height)
            let y = min(max(shelfBannerHeight + headerY, 0), maxY)
            let animated = abs(shelfScroll.contentOffset.y - y) > 1
            shelfScroll.setContentOffset(CGPoint(x: 0, y: y), animated: animated)
            if !animated {
                releaseRightScrollSyncIfNeeded()
            }
            return
        }
        let minY = -rightTable.adjustedContentInset.top
        let maxY = max(
            minY,
            rightTable.contentSize.height - rightTable.bounds.height + rightTable.adjustedContentInset.bottom
        )
        let y = min(max(headerY - rightTable.adjustedContentInset.top, minY), maxY)
        rightTable.setContentOffset(CGPoint(x: 0, y: y), animated: true)
    }

    private func syncCategoryFromRightScroll() {
        guard !lockRightScrollSync, !viewModel.packageSections.isEmpty else { return }
        guard rightTable.contentSize.height > 1 else { return }

        let top = embedsInHomeShelf
            ? shelfScroll.contentOffset.y - shelfBannerHeight + 1
            : rightTable.contentOffset.y + rightTable.adjustedContentInset.top + 1
        var section = 0
        for index in 0..<viewModel.packageSections.count {
            let headerY = rightTable.rectForHeader(inSection: index).minY
            if headerY <= top {
                section = index
            } else {
                break
            }
        }
        viewModel.syncActiveCategory(fromRightIndexPath: IndexPath(row: 0, section: section))
    }

    private func releaseRightScrollSyncIfNeeded() {
        guard lockRightScrollSync else { return }
        lockRightScrollSync = false
    }
}

// MARK: - UITableViewDataSource / Delegate

extension ServiceListViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView.tag == 0 { return 1 }
        return viewModel.packageSections.isEmpty ? 1 : viewModel.packageSections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 0 {
            return viewModel.categories.count
        }
        if viewModel.packageSections.isEmpty { return 1 }
        return viewModel.packageSections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.tag == 0 {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: CategoryNavCell.reuseID,
                for: indexPath
            ) as! CategoryNavCell
            let category = viewModel.categories[indexPath.row]
            let isActive = category.id == viewModel.activeCategoryId
            let activeIndex = viewModel.categories.firstIndex(where: { $0.id == viewModel.activeCategoryId })

            let adjacentCorner: CategoryNavCell.AdjacentCorner
            if let activeIndex, !isActive {
                if indexPath.row == activeIndex - 1 {
                    adjacentCorner = .bottomRight
                } else if indexPath.row == activeIndex + 1 {
                    adjacentCorner = .topRight
                } else {
                    adjacentCorner = .none
                }
            } else {
                adjacentCorner = .none
            }

            let connectsAbove = isActive && indexPath.row > 0
            let connectsBelow = isActive && indexPath.row < viewModel.categories.count - 1

            cell.configure(
                title: category.title,
                active: isActive,
                adjacentCorner: adjacentCorner,
                connectsAbove: connectsAbove,
                connectsBelow: connectsBelow
            )
            return cell
        }

        if viewModel.packageSections.isEmpty {
            let cell = UITableViewCell()
            cell.selectionStyle = .none
            cell.backgroundColor = .white
            cell.contentView.backgroundColor = .white
            let empty = FDEmptyStateView(style: .compact, message: "暂无套餐")
            cell.contentView.addSubview(empty)
            empty.snp.makeConstraints {
                $0.edges.equalToSuperview()
                $0.height.equalTo(240)
            }
            return cell
        }

        let sectionData = viewModel.packageSections[indexPath.section]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: PackageCardCell.reuseID,
            for: indexPath
        ) as! PackageCardCell
        let row = sectionData.rows[indexPath.row]
        cell.configure(row.item, categoryServiceId: row.categoryServiceId)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard tableView.tag == 1, !viewModel.packageSections.isEmpty else { return nil }
        let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: PackageSectionHeaderView.reuseID
        ) as! PackageSectionHeaderView
        header.configure(title: viewModel.packageSections[section].category.title)
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard tableView.tag == 1, !viewModel.packageSections.isEmpty else {
            return .leastNormalMagnitude
        }
        return PackageSectionHeaderView.height
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView.tag == 0 { return CategoryNavCell.rowHeight }
        if viewModel.packageSections.isEmpty { return 240 }
        let cardWidth = max(0, tableView.bounds.width - PackageCardCell.cardHorizontalInsets)
        return PackageCardCell.rowHeight(forCardWidth: cardWidth)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.tag == 0 {
            let category = viewModel.categories[indexPath.row]
            viewModel.selectCategory(id: category.id)
            lockRightScrollSync = true
            if let target = viewModel.indexPath(forCategoryId: category.id) {
                scrollRightTable(toSectionHeader: target.section)
                if target.section == 0, !embedsInHomeShelf {
                    releaseRightScrollSyncIfNeeded()
                }
            } else {
                releaseRightScrollSyncIfNeeded()
            }
        } else if !viewModel.packageSections.isEmpty {
            let sectionData = viewModel.packageSections[indexPath.section]
            let row = sectionData.rows[indexPath.row]
            Router.shared.push(
                "/services/pkg",
                params: row.item.packageDetailRouteParams(categoryServiceId: row.categoryServiceId)
            )
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView === leftTable {
            lockLeftScroll = false
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if embedsInHomeShelf, scrollView === shelfScroll {
            updateStickyLeftColumn()
            syncCategoryFromRightScroll()
            return
        }
        if scrollView === leftTable {
            if embedsInHomeShelf {
                guard !lockLeftScroll else { return }
                revealShelfBannerFromLeftPull()
                return
            }
            return
        }
        guard scrollView === rightTable else { return }
        syncCategoryFromRightScroll()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if embedsInHomeShelf, scrollView === shelfScroll {
            releaseRightScrollSyncIfNeeded()
            return
        }
        if scrollView === leftTable {
            lockLeftScroll = false
            return
        }
        guard scrollView === rightTable else { return }
        releaseRightScrollSyncIfNeeded()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if embedsInHomeShelf, scrollView === shelfScroll {
            releaseRightScrollSyncIfNeeded()
            return
        }
        if scrollView === leftTable {
            lockLeftScroll = false
            return
        }
        guard scrollView === rightTable else { return }
        releaseRightScrollSyncIfNeeded()
    }
}
