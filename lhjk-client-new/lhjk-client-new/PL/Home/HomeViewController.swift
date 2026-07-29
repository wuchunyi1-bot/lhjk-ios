import UIKit
import SnapKit
import Combine

/// 首页 Hub — 对齐 HomeView.vue / home.page.yaml（现行布局）
final class HomeViewController: BaseViewController {

    private let viewModel = HomeViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var didApplyInitialSnapshot = false

    private let brandHeader = TabHubBrandHeaderView()

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.contentInsetAdjustmentBehavior = .never
        tv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 76, right: 0)
        tv.sectionHeaderHeight = 0
        tv.sectionFooterHeight = 0
        tv.estimatedSectionHeaderHeight = 0
        tv.estimatedSectionFooterHeight = 0
        tv.estimatedRowHeight = 200
        tv.rowHeight = UITableView.automaticDimension
        return tv
    }()

    private var dataSource: UITableViewDiffableDataSource<HomeViewModel.HomeSection, HomeViewModel.HomeItem>!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.loadUserProfile()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = .fdBg

        brandHeader.configure(
            title: "富德健康",
            subtitle: "健康生命 · 美好生活",
            titleColor: .fdPrimary
        )

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

        dataSource.apply(viewModel.snapshot, animatingDifferences: false)
        didApplyInitialSnapshot = true

        view.addSubview(brandHeader)
        view.addSubview(tableView)
        brandHeader.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
        }
        tableView.snp.makeConstraints {
            $0.top.equalTo(brandHeader.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func bindViewModel() {
        viewModel.$snapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                guard let self, self.dataSource != nil else { return }
                self.dataSource.apply(snapshot, animatingDifferences: false)
            }
            .store(in: &cancellables)
    }

    private func handleQuickRoute(_ route: String) {
        if route == "/messages" {
            tabBarController?.selectedIndex = 3
        } else {
            Router.shared.push(route)
        }
    }

    private func cell(
        for item: HomeViewModel.HomeItem,
        tableView tv: UITableView,
        indexPath: IndexPath
    ) -> UITableViewCell {
        switch item {
        case .banner:
            return tv.dequeueReusableCell(withIdentifier: HomeBannerCarouselCell.reuseID, for: indexPath)
        case .quickActions:
            let cell = tv.dequeueReusableCell(withIdentifier: HomeQuickActionsCell.reuseID, for: indexPath) as! HomeQuickActionsCell
            cell.configure(actions: viewModel.quickActions)
            cell.onActionTapped = { [weak self] route in self?.handleQuickRoute(route) }
            return cell
        case .membership:
            let cell = tv.dequeueReusableCell(withIdentifier: HomeMembershipPackagesCell.reuseID, for: indexPath) as! HomeMembershipPackagesCell
            cell.configure(packages: viewModel.membershipPackages)
            cell.onPackageTapped = { id in
                Router.shared.push("/services/pkg", params: ["id": id])
            }
            return cell
        case .teamMember(let idx):
            let cell = tv.dequeueReusableCell(withIdentifier: HomeTeamCardCell.reuseID, for: indexPath) as! HomeTeamCardCell
            cell.configure(member: viewModel.teamMembers[idx])
            cell.onMessageTapped = { name in
                Router.shared.push("/messages", params: ["name": name])
            }
            return cell
        case .taskCard:
            let cell = tv.dequeueReusableCell(withIdentifier: HomeTaskCardCell.reuseID, for: indexPath) as! HomeTaskCardCell
            cell.configure(tasks: viewModel.tasks)
            cell.onTaskTapped = { _ in }
            return cell
        case .article(let idx):
            let cell = tv.dequeueReusableCell(withIdentifier: HomeArticleCell.reuseID, for: indexPath) as! HomeArticleCell
            let article = viewModel.articles[idx]
            cell.configure(article: article, isLast: idx == viewModel.articles.count - 1)
            cell.onTapped = {}
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension HomeViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let s = sectionKind(section) else { return .leastNormalMagnitude }
        switch s {
        case .membership, .team, .tasks, .articles:
            return 40
        default:
            return .leastNormalMagnitude
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let s = sectionKind(section) else { return nil }
        switch s {
        case .membership:
            guard !viewModel.membershipPackages.isEmpty else { return nil }
            let header = SectionTitleView(title: "会员健康服务", more: "查看更多 ›")
            header.onMoreTapped = { Router.shared.push("/services/membership") }
            return wrapHeader(header)
        case .team:
            let header = SectionTitleView(title: "我的富德健康管家团队", more: "服务剩余 \(viewModel.daysLeft) 天 ›")
            return wrapHeader(header)
        case .tasks:
            let done = viewModel.tasks.filter(\.isDone).count
            let header = SectionTitleView(
                title: "今日健康任务",
                more: "已完成 \(done) / \(viewModel.tasks.count) · +10 分 ›"
            )
            return wrapHeader(header)
        case .articles:
            let header = SectionTitleView(title: "健康陪伴", more: "更多 ›")
            return wrapHeader(header)
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let s = sectionKind(section) else { return .leastNormalMagnitude }
        switch s {
        case .quickActions:
            return 10
        case .membership, .team, .tasks:
            return 20
        default:
            return .leastNormalMagnitude
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard sectionKind(section) != nil else { return nil }
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }

    private func sectionKind(_ section: Int) -> HomeViewModel.HomeSection? {
        guard dataSource != nil else { return nil }
        let ids = dataSource.snapshot().sectionIdentifiers
        guard section >= 0, section < ids.count else { return nil }
        return ids[section]
    }

    private func wrapHeader(_ titleView: SectionTitleView) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        container.addSubview(titleView)
        titleView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
        }
        return container
    }
}
