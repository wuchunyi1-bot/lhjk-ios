import UIKit
import SnapKit
import Combine

/// 套餐选择页 — 对齐 funde-client `ServiceListView.vue`
final class ServiceListViewController: BaseViewController {

    private let viewModel: ServiceListViewModel
    private var cancellables = Set<AnyCancellable>()
    private var lockRightScrollSync = false
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
        tv.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 24, right: 0)
        tv.backgroundView = UIView()
        tv.backgroundView?.backgroundColor = .white
        tv.register(PackageHeaderCell.self, forCellReuseIdentifier: PackageHeaderCell.reuseID)
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

    init(productCode: String) {
        self.viewModel = ServiceListViewModel(routeCode: productCode)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "选择套餐"
        setupNavigationItems()
        institutionCard.configure(viewModel.institution)
        viewModel.load()
    }

    private func setupNavigationItems() {
        // Figma 3021:2143 — 搜索 + 购物车，间距 16
        let searchButton = UIButton(type: .system)
        searchButton.setImage(.fdNavSearch, for: .normal)
        searchButton.tintColor = .fdText
        searchButton.addTarget(self, action: #selector(openSearch), for: .touchUpInside)
        searchButton.snp.makeConstraints { $0.size.equalTo(24) }

        let cartButton = UIButton(type: .system)
        cartButton.setImage(.fdNavCart, for: .normal)
        cartButton.tintColor = .fdText
        cartButton.addTarget(self, action: #selector(openCart), for: .touchUpInside)
        cartButton.snp.makeConstraints { $0.size.equalTo(24) }

        let stack = UIStackView(arrangedSubviews: [searchButton, cartButton])
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .center
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stack)
    }

    @objc private func openSearch() {
        Router.shared.push("/services/search", params: ["hospitalId": viewModel.searchHospitalId])
    }

    @objc private func openCart() {
        Router.shared.push("/services/cart")
    }

    override func setupUI() {
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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateRightTableContentFillerIfNeeded()
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
                self.updateRightTableContentFillerIfNeeded()
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
        leftTable.scrollToRow(
            at: IndexPath(row: idx, section: 0),
            at: .middle,
            animated: animated
        )
    }

    private func syncCategoryFromRightScroll() {
        guard !lockRightScrollSync else { return }

        let probeY = rightTable.contentOffset.y + rightTable.adjustedContentInset.top + 1
        let probePoint = CGPoint(x: rightTable.bounds.midX, y: probeY)
        guard let indexPath = rightTable.indexPathForRow(at: probePoint) else { return }
        viewModel.syncActiveCategory(fromRightIndexPath: indexPath)
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
        // row 0 = 类目头，其余为套餐卡片
        return 1 + viewModel.packageSections[section].rows.count
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
            let label = UILabel()
            label.text = "暂无套餐"
            label.font = .fdBody
            label.textColor = .fdSubtext
            label.textAlignment = .center
            cell.contentView.addSubview(label)
            label.snp.makeConstraints {
                $0.center.equalToSuperview()
                $0.leading.trailing.equalToSuperview().inset(24)
                $0.top.bottom.equalToSuperview().inset(48)
            }
            return cell
        }

        let sectionData = viewModel.packageSections[indexPath.section]
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: PackageHeaderCell.reuseID,
                for: indexPath
            ) as! PackageHeaderCell
            cell.configure(categoryTitle: sectionData.category.title)
            return cell
        }

        let cell = tableView.dequeueReusableCell(
            withIdentifier: PackageCardCell.reuseID,
            for: indexPath
        ) as! PackageCardCell
        let row = sectionData.rows[indexPath.row - 1]
        cell.configure(row.item, categoryServiceId: row.categoryServiceId)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView.tag == 0 { return CategoryNavCell.rowHeight }
        if viewModel.packageSections.isEmpty { return UITableView.automaticDimension }
        if indexPath.row == 0 { return PackageHeaderCell.rowHeight }
        let cardWidth = max(0, tableView.bounds.width - PackageCardCell.cardHorizontalInsets)
        return PackageCardCell.rowHeight(forCardWidth: cardWidth)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.tag == 0 {
            let category = viewModel.categories[indexPath.row]
            viewModel.selectCategory(id: category.id)
            lockRightScrollSync = true
            if let target = viewModel.indexPath(forCategoryId: category.id) {
                rightTable.scrollToRow(
                    at: target,
                    at: .top,
                    animated: true
                )
                if target.section == 0, target.row == 0 {
                    releaseRightScrollSyncIfNeeded()
                }
            } else {
                releaseRightScrollSyncIfNeeded()
            }
        } else if indexPath.row > 0, !viewModel.packageSections.isEmpty {
            let sectionData = viewModel.packageSections[indexPath.section]
            let row = sectionData.rows[indexPath.row - 1]
            Router.shared.push(
                "/services/pkg",
                params: row.item.packageDetailRouteParams(categoryServiceId: row.categoryServiceId)
            )
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === rightTable else { return }
        syncCategoryFromRightScroll()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === rightTable else { return }
        releaseRightScrollSyncIfNeeded()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView === rightTable else { return }
        releaseRightScrollSyncIfNeeded()
    }
}
