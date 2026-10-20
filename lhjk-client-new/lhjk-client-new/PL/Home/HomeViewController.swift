import UIKit
import SnapKit
import Combine

/// 首页 Hub：顶栏 + 四个页签。底栏不再放「服务」。
final class HomeViewController: BaseViewController {

    private let viewModel = HomeViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var currentShelf: HomeShelf = HomeShelfStore.saved()

    private let topBar = HomeTopBarView()
    private let shelfBar = HomeShelfBar()
    private let contentContainer = UIView()

    private var serviceViewController: ServiceViewController?
    private var mallViewController: HealthMallViewController?
    private var knowledgeViewController: HomeKnowledgeViewController?
    /// 正在补地址的医院 id，避免顶栏刷新时重复打 `getById`。
    private var institutionDetailRequestedId: String?
    private var institutionDetailTask: Task<Void, Never>?

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.contentInsetAdjustmentBehavior = .never
        tv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)
        tv.sectionHeaderHeight = 0
        tv.sectionFooterHeight = 0
        tv.estimatedSectionHeaderHeight = 0
        tv.estimatedSectionFooterHeight = 0
        tv.estimatedRowHeight = 200
        tv.rowHeight = UITableView.automaticDimension
        tv.clipsToBounds = true
        return tv
    }()

    private var dataSource: UITableViewDiffableDataSource<HomeViewModel.HomeSection, HomeViewModel.HomeItem>!

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    override func refreshForSeniorMode() {
        super.refreshForSeniorMode()
        shelfBar.setSelected(currentShelf)
        tableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        setNeedsStatusBarAppearanceUpdate()
        refreshInstitution()
        viewModel.loadUserProfile()
        viewModel.loadBanners()
        viewModel.loadQuickLinks()
        viewModel.loadHealthServices()
        viewModel.loadNews()
        viewModel.loadTodayTasks(forceRefresh: true)
        viewModel.loadDoctorTeam()
        Task { await UserManager.shared.fetchArchiveCompletion() }
        AppContainer.shared.shoppingCartBadgeStore.refresh()
        if let pending = HomeShelfStore.pending {
            HomeShelfStore.pending = nil
            showShelf(pending, persist: true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applyHomeSnapshot(viewModel.snapshot)
        AppVersionCheckCoordinator.checkOnHomeAppeared()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = .fdBg

        tableView.register(HomeBannerCarouselCell.self, forCellReuseIdentifier: HomeBannerCarouselCell.reuseID)
        tableView.register(HomeQuickActionsCell.self, forCellReuseIdentifier: HomeQuickActionsCell.reuseID)
        tableView.register(HomeSupportCell.self, forCellReuseIdentifier: HomeSupportCell.reuseID)
        tableView.register(HomeMembershipPackagesCell.self, forCellReuseIdentifier: HomeMembershipPackagesCell.reuseID)
        tableView.register(HomeTeamCardCell.self, forCellReuseIdentifier: HomeTeamCardCell.reuseID)
        tableView.register(HomeTaskCardCell.self, forCellReuseIdentifier: HomeTaskCardCell.reuseID)

        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tv, indexPath, item in
            guard let self else { return UITableViewCell() }
            return self.cell(for: item, tableView: tv, indexPath: indexPath)
        }
        dataSource.defaultRowAnimation = .none
        tableView.dataSource = dataSource
        tableView.delegate = self
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        topBar.onInstitutionTap = { [weak self] in
            self?.openInstitutionPicker()
        }
        topBar.onSearchTap = { [weak self] in
            self?.openSearch()
        }
        topBar.onCartTap = { [weak self] in
            Router.shared.push("/services/cart", from: self)
        }
        shelfBar.onSelect = { [weak self] shelf in
            self?.showShelf(shelf, persist: true)
        }

        view.addSubview(contentContainer)
        view.addSubview(topBar)
        view.addSubview(shelfBar)
        contentContainer.clipsToBounds = true
        contentContainer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        contentContainer.setContentHuggingPriority(.defaultLow, for: .vertical)
        contentContainer.addSubview(tableView)

        topBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
        }
        shelfBar.snp.makeConstraints {
            $0.top.equalTo(topBar.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(44)
        }
        contentContainer.snp.makeConstraints {
            $0.top.equalTo(shelfBar.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(institutionDidChange),
            name: InstitutionSelectionStore.didChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(institutionDidChange),
            name: .defaultArchiveDidUpdate,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(shelfRequested(_:)),
            name: HomeShelfStore.didRequestNotification,
            object: nil
        )
        showShelf(currentShelf, persist: false)
    }

    override func bindViewModel() {
        viewModel.$snapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.applyHomeSnapshot(snapshot)
            }
            .store(in: &cancellables)

        viewModel.$articles
            .receive(on: DispatchQueue.main)
            .sink { [weak self] articles in
                self?.knowledgeViewController?.update(articles: articles)
            }
            .store(in: &cancellables)

        AppContainer.shared.shoppingCartBadgeStore.$count
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.topBar.applyCartCount(count)
            }
            .store(in: &cancellables)
    }

    private func applyHomeSnapshot(
        _ snapshot: NSDiffableDataSourceSnapshot<HomeViewModel.HomeSection, HomeViewModel.HomeItem>
    ) {
        guard dataSource != nil, tableView.window != nil else { return }
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func showShelf(_ shelf: HomeShelf, persist: Bool) {
        currentShelf = shelf
        if persist { HomeShelfStore.save(shelf) }
        shelfBar.setSelected(shelf)
        tableView.isHidden = shelf != .home
        serviceViewController?.view.isHidden = shelf != .service
        mallViewController?.view.isHidden = shelf != .mall
        knowledgeViewController?.view.isHidden = shelf != .articles
        switch shelf {
        case .home:
            break
        case .service:
            embedServiceIfNeeded()
        case .mall:
            embedMallIfNeeded()
        case .articles:
            embedKnowledgeIfNeeded()
        }
    }

    private func embedServiceIfNeeded() {
        if serviceViewController == nil {
            let child = ServiceViewController(embedsInHomeHub: true)
            serviceViewController = child
            embed(child)
        }
        serviceViewController?.view.isHidden = false
    }

    private func embedMallIfNeeded() {
        if mallViewController == nil {
            let child = HealthMallViewController(embedsInHomeHub: true)
            mallViewController = child
            embed(child)
        }
        mallViewController?.view.isHidden = false
    }

    private func embedKnowledgeIfNeeded() {
        if knowledgeViewController == nil {
            let child = HomeKnowledgeViewController()
            child.onArticleTap = { [weak self] article in
                self?.handleNewsArticleTap(article)
            }
            knowledgeViewController = child
            embed(child)
            child.update(articles: viewModel.articles)
        }
        knowledgeViewController?.view.isHidden = false
    }

    private func embed(_ child: UIViewController) {
        addChild(child)
        contentContainer.addSubview(child.view)
        child.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        child.didMove(toParent: self)
    }

    /// 有手动切换的机构就展示切换结果；没有则展示档案里的所属机构。
    /// 档案没有地址，地址为空时用该机构 id 调 `GET /v1/hospital/getById`（网关前缀 `/mobile`）补上。
    private func refreshInstitution() {
        if let selected = InstitutionSelectionStore.shared.selected {
            let name = selected.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                let address = selected.fullAddress.trimmingCharacters(in: .whitespacesAndNewlines)
                topBar.apply(name: name, address: address)
                if address.isEmpty {
                    loadInstitutionAddress(hospitalId: selected.id, fallbackName: name)
                }
                return
            }
        }
        let archive = UserManager.shared.defaultArchive
        let ownName = archive?.hospitalName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        topBar.apply(name: ownName, address: "")
        if let hospitalId = HospitalPackageService.apiHospitalId(archive?.hospitalId) {
            loadInstitutionAddress(hospitalId: hospitalId, fallbackName: ownName)
        }
    }

    /// 本地没有地址时拉医院详情，写回选中态后顶栏展示 `fullAddress`。
    private func loadInstitutionAddress(hospitalId: String, fallbackName: String) {
        guard institutionDetailRequestedId != hospitalId else { return }
        guard let numericId = Int64(hospitalId), numericId > 0 else { return }
        institutionDetailRequestedId = hospitalId
        institutionDetailTask?.cancel()
        institutionDetailTask = Task { [weak self] in
            do {
                let hospital = try await HospitalService.shared.getById(id: numericId)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.applyHospitalDetail(
                        hospital,
                        requestedId: hospitalId,
                        fallbackName: fallbackName
                    )
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    if self?.institutionDetailRequestedId == hospitalId {
                        self?.institutionDetailRequestedId = nil
                    }
                }
            }
        }
    }

    private func applyHospitalDetail(
        _ hospital: OHospital,
        requestedId: String,
        fallbackName: String
    ) {
        let currentId = InstitutionSelectionStore.shared.selected?.id
            ?? HospitalPackageService.apiHospitalId(UserManager.shared.defaultArchive?.hospitalId)
        guard currentId == requestedId else { return }
        guard let detail = SelectedServiceInstitution(hospital: hospital) else {
            let address = hospital.fullAddress.trimmingCharacters(in: .whitespacesAndNewlines)
            if !address.isEmpty {
                topBar.apply(name: fallbackName, address: address)
            }
            return
        }
        let name = detail.name.trimmingCharacters(in: .whitespacesAndNewlines)
        InstitutionSelectionStore.shared.select(detail, postingNotification: false)
        topBar.apply(
            name: name.isEmpty ? fallbackName : name,
            address: detail.fullAddress
        )
    }

    private func openInstitutionPicker() {
        var params: [String: Any] = [:]
        if let id = InstitutionSelectionStore.shared.selected?.id {
            params["selectedId"] = id
        }
        Router.shared.push("/services/institution", params: params, from: self)
    }

    private func openSearch() {
        var params: [String: Any] = [:]
        if let hospitalId = InstitutionSelectionStore.shared.selectedHospitalId {
            params["hospitalId"] = hospitalId
        }
        Router.shared.push("/services/search", params: params, from: self)
    }

    @objc private func institutionDidChange() {
        refreshInstitution()
    }

    @objc private func shelfRequested(_ note: Notification) {
        guard let raw = note.userInfo?["shelf"] as? String,
              let shelf = HomeShelf(rawValue: raw) else { return }
        HomeShelfStore.pending = nil
        showShelf(shelf, persist: true)
    }

    private func handleColumnContentPageUrl(_ pageUrl: String?) {
        FundePageURL.open(pageUrl, from: self)
    }

    private func handleHealthServicePackageTap(_ package: HomeMembershipPackagesCell.Package) {
        if FundePageURL.canOpen(package.pageUrl) {
            FundePageURL.open(package.pageUrl, from: self)
            return
        }

        guard package.contentType == ColumnContentJumpType.packageBridge.rawValue else { return }
        let contentId = package.contentId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !contentId.isEmpty else { return }

        var extraQuery: [String: String] = ["contentId": contentId]
        if let contentType = package.contentType {
            extraQuery["contentType"] = String(contentType)
        }
        if let hospitalId = HealthPageService.resolveHospitalId() {
            extraQuery["hospitalId"] = hospitalId
        }
        let url = H5Config.authenticatedPageURL(path: "package/bridge", extraQuery: extraQuery)
        let webVC = WebViewController(urlString: url.absoluteString)
        navigationController?.pushViewController(webVC, animated: true)
    }

    private func handleNewsArticleTap(_ article: HomeArticleCell.Article) {
        let contentId = article.contentId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !contentId.isEmpty else { return }
        let url = H5Config.contentDetailPageURL(contentId: contentId)
        let webVC = WebViewController(urlString: url.absoluteString, title: article.title)
        navigationController?.pushViewController(webVC, animated: true)
    }

    private func cell(
        for item: HomeViewModel.HomeItem,
        tableView tv: UITableView,
        indexPath: IndexPath
    ) -> UITableViewCell {
        switch item {
        case .banner:
            let cell = tv.dequeueReusableCell(withIdentifier: HomeBannerCarouselCell.reuseID, for: indexPath) as! HomeBannerCarouselCell
            cell.configure(viewModel.banners)
            cell.onBannerTap = { [weak self] banner in
                self?.handleColumnContentPageUrl(banner.pageUrl)
            }
            cell.onHeightUpdated = { [weak self] in
                guard let self else { return }
                UIView.performWithoutAnimation {
                    self.tableView.beginUpdates()
                    self.tableView.endUpdates()
                }
            }
            return cell
        case .quickActions:
            let cell = tv.dequeueReusableCell(withIdentifier: HomeQuickActionsCell.reuseID, for: indexPath) as! HomeQuickActionsCell
            cell.configure(actions: viewModel.quickActions)
            cell.onActionTapped = { [weak self] action in
                self?.handleColumnContentPageUrl(action.pageUrl)
            }
            return cell
        case .support:
            let cell = tv.dequeueReusableCell(withIdentifier: HomeSupportCell.reuseID, for: indexPath) as! HomeSupportCell
            cell.onTap = { [weak self] in
                self?.present(HomeSupportCallSheet(), animated: true)
            }
            return cell
        case .membership:
            let cell = tv.dequeueReusableCell(withIdentifier: HomeMembershipPackagesCell.reuseID, for: indexPath) as! HomeMembershipPackagesCell
            cell.configure(packages: viewModel.membershipPackages)
            cell.onPackageTapped = { [weak self] package in
                self?.handleHealthServicePackageTap(package)
            }
            return cell
        case .teamList:
            let cell = tv.dequeueReusableCell(withIdentifier: HomeTeamCardCell.reuseID, for: indexPath) as! HomeTeamCardCell
            cell.configure(members: viewModel.teamMembers, serviceDaysLeft: viewModel.teamServiceDaysLeft)
            cell.onMessageTapped = { member in
                guard let groupId = member.groupId, !groupId.isEmpty else { return }
                Router.shared.push("/conversations/:id", params: ["id": groupId])
            }
            return cell
        case .taskCard:
            let cell = tv.dequeueReusableCell(withIdentifier: HomeTaskCardCell.reuseID, for: indexPath) as! HomeTaskCardCell
            cell.configure(
                previewTasks: viewModel.taskPreview,
                doneCount: viewModel.taskDoneCount,
                totalCount: viewModel.taskTotalCount,
                earnedPoints: viewModel.taskEarnedPoints
            )
            cell.onTaskAction = { task in
                task.pushMonitorTaskRoute(source: "HomeTaskCard")
            }
            cell.onViewAll = {
                Router.shared.push("/home/tasks")
            }
            return cell
        }
    }
}

extension HomeViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }
}
