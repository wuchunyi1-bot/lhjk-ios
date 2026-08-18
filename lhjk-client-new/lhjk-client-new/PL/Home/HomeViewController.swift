import UIKit
import SnapKit
import Combine

/// 首页 Hub — 对齐 Figma 3021:784
final class HomeViewController: BaseViewController {

    private let viewModel = HomeViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = UIColor(hexString: "#FFF9F7")
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.contentInsetAdjustmentBehavior = .never
        tv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 90, right: 0)
        tv.sectionHeaderHeight = 0
        tv.sectionFooterHeight = 0
        tv.estimatedSectionHeaderHeight = 0
        tv.estimatedSectionFooterHeight = 0
        tv.estimatedRowHeight = 200
        tv.rowHeight = UITableView.automaticDimension
        tv.clipsToBounds = false
        return tv
    }()

    private var dataSource: UITableViewDiffableDataSource<HomeViewModel.HomeSection, HomeViewModel.HomeItem>!

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        setNeedsStatusBarAppearanceUpdate()
        viewModel.loadUserProfile()
        viewModel.loadBanners()
        viewModel.loadQuickLinks()
        viewModel.loadHealthServices()
        viewModel.loadNews()
        viewModel.loadTodayTasks(forceRefresh: true)
        viewModel.loadDoctorTeam()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 冷启动时 viewDidLoad 可能尚未挂上 window，补一次 apply
        applyHomeSnapshot(viewModel.snapshot)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = UIColor(hexString: "#FFF9F7")

        tableView.register(HomeBannerCarouselCell.self, forCellReuseIdentifier: HomeBannerCarouselCell.reuseID)
        tableView.register(HomeQuickActionsCell.self, forCellReuseIdentifier: HomeQuickActionsCell.reuseID)
        tableView.register(HomeMembershipPackagesCell.self, forCellReuseIdentifier: HomeMembershipPackagesCell.reuseID)
        tableView.register(HomeTeamCardCell.self, forCellReuseIdentifier: HomeTeamCardCell.reuseID)
        tableView.register(HomeTaskCardCell.self, forCellReuseIdentifier: HomeTaskCardCell.reuseID)
        tableView.register(HomeArticleCell.self, forCellReuseIdentifier: HomeArticleCell.reuseID)

        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tv, indexPath, item in
            guard let self else { return UITableViewCell() }
            return self.cell(for: item, tableView: tv, indexPath: indexPath)
        }
        dataSource.defaultRowAnimation = .none
        tableView.dataSource = dataSource
        tableView.delegate = self

        // 先入层级，再 apply；否则 DiffableDataSource 会触发
        // UITableViewAlertForLayoutOutsideViewHierarchy
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        // Banner 延伸到状态栏下方
        tableView.contentInset.top = 0
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
    }

    override func bindViewModel() {
        viewModel.$snapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.applyHomeSnapshot(snapshot)
            }
            .store(in: &cancellables)
    }

    /// 仅在 tableView 已挂到 window 时 apply，避免层级外布局告警
    private func applyHomeSnapshot(
        _ snapshot: NSDiffableDataSourceSnapshot<HomeViewModel.HomeSection, HomeViewModel.HomeItem>
    ) {
        guard dataSource != nil, tableView.window != nil else { return }
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func handleColumnContentPageUrl(_ pageUrl: String?) {
        FundePageURL.open(pageUrl, from: self)
    }

    private func handleArticlesMoreTapped() {
        Router.shared.push("/companion", from: self)
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
        case .membership:
            let cell = tv.dequeueReusableCell(withIdentifier: HomeMembershipPackagesCell.reuseID, for: indexPath) as! HomeMembershipPackagesCell
            cell.configure(packages: viewModel.membershipPackages)
            cell.onPackageTapped = { [weak self] package in
                self?.handleColumnContentPageUrl(package.pageUrl)
            }
            return cell
        case .teamList:
            let cell = tv.dequeueReusableCell(withIdentifier: HomeTeamCardCell.reuseID, for: indexPath) as! HomeTeamCardCell
            cell.configure(members: viewModel.teamMembers, daysLeft: viewModel.daysLeft)
            cell.onMessageTapped = { member in
                guard let groupId = member.groupId, !groupId.isEmpty else { return }
                // 会话 id = groupId，直接进聊天详情（见 home-doctor-team / im spec）
                Router.shared.push("/conversations/:id", params: ["id": groupId])
            }
            return cell
        case .taskCard:
            let cell = tv.dequeueReusableCell(withIdentifier: HomeTaskCardCell.reuseID, for: indexPath) as! HomeTaskCardCell
            cell.configure(
                previewTasks: viewModel.taskPreview,
                doneCount: viewModel.taskDoneCount,
                totalCount: viewModel.taskTotalCount
            )
            cell.onTaskAction = { task in
                let route = task.actionRoute.isEmpty ? "/health/metrics" : task.actionRoute
                Router.shared.push(route)
            }
            cell.onViewAll = {
                Router.shared.push("/home/tasks")
            }
            return cell
        case .articlesCard:
            let cell = tv.dequeueReusableCell(withIdentifier: HomeArticleCell.reuseID, for: indexPath) as! HomeArticleCell
            cell.configure(articles: viewModel.articles)
            cell.onTapped = { [weak self] article in
                self?.handleNewsArticleTap(article)
            }
            cell.onMoreTapped = { [weak self] in
                self?.handleArticlesMoreTapped()
            }
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

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

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        nil
    }
}
