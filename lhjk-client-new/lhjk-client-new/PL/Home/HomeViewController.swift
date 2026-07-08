import UIKit
import SnapKit
import Combine

/// 首页 Hub — UITableView 实现
/// 参考 funde-client: HomeView.vue
final class HomeViewController: BaseViewController {

    // MARK: - ViewModel

    private let viewModel = HomeViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI

    private lazy var tableView: UITableView = {
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
        tv.estimatedRowHeight = 300
        tv.rowHeight = UITableView.automaticDimension
        tv.register(HomeHeroCell.self, forCellReuseIdentifier: HomeHeroCell.reuseID)
        tv.register(HomeQuickActionsCell.self, forCellReuseIdentifier: HomeQuickActionsCell.reuseID)
        tv.register(HomeTeamCardCell.self, forCellReuseIdentifier: HomeTeamCardCell.reuseID)
        tv.register(HomeTaskCardCell.self, forCellReuseIdentifier: HomeTaskCardCell.reuseID)
        tv.register(HomeServiceBannerCell.self, forCellReuseIdentifier: HomeServiceBannerCell.reuseID)
        tv.register(HomeArticleCell.self, forCellReuseIdentifier: HomeArticleCell.reuseID)
        tv.delegate = self
        return tv
    }()

    private lazy var dataSource: UITableViewDiffableDataSource<HomeViewModel.HomeSection, HomeViewModel.HomeItem> = {
        UITableViewDiffableDataSource<HomeViewModel.HomeSection, HomeViewModel.HomeItem>(tableView: tableView) { [weak self] tv, indexPath, item in
            guard let self else { return UITableViewCell() }
            switch item {
            case .hero:
                let cell = tv.dequeueReusableCell(withIdentifier: HomeHeroCell.reuseID, for: indexPath) as! HomeHeroCell
                cell.configure(
                    name: self.viewModel.userName,
                    advisor: self.viewModel.advisor,
                    daysLeft: self.viewModel.daysLeft,
                    riskScore: self.viewModel.riskScore,
                    riskLevel: self.viewModel.riskLevel,
                    riskHint: self.viewModel.riskHint,
                    metrics: self.viewModel.metrics
                )
                return cell
            case .quickActions:
                let cell = tv.dequeueReusableCell(withIdentifier: HomeQuickActionsCell.reuseID, for: indexPath) as! HomeQuickActionsCell
                cell.configure(actions: self.viewModel.quickActions)
                cell.onActionTapped = { [weak self] route in
                    if route == "/messages" {
                        self?.tabBarController?.selectedIndex = 3
                    } else {
                        Router.shared.push(route)
                    }
                }
                return cell
            case .teamMember(let idx):
                let cell = tv.dequeueReusableCell(withIdentifier: HomeTeamCardCell.reuseID, for: indexPath) as! HomeTeamCardCell
                cell.configure(member: self.viewModel.teamMembers[idx])
                cell.onMessageTapped = { name in
                    Router.shared.push("/messages", params: ["name": name])
                }
                return cell
            case .taskCard:
                let cell = tv.dequeueReusableCell(withIdentifier: HomeTaskCardCell.reuseID, for: indexPath) as! HomeTaskCardCell
                cell.configure(tasks: self.viewModel.tasks)
                cell.onTaskTapped = { _ in
                    // TODO: toggle task completion when wired to real data
                }
                return cell
            case .serviceBanner:
                let cell = tv.dequeueReusableCell(withIdentifier: HomeServiceBannerCell.reuseID, for: indexPath) as! HomeServiceBannerCell
                cell.configure(week: 5, totalWeeks: 12, daysLeft: self.viewModel.daysLeft)
                cell.onTapped = {
                    Router.shared.push("/services")
                }
                return cell
            case .article(let idx):
                let cell = tv.dequeueReusableCell(withIdentifier: HomeArticleCell.reuseID, for: indexPath) as! HomeArticleCell
                let article = self.viewModel.articles[idx]
                cell.configure(article: article, isLast: idx == self.viewModel.articles.count - 1)
                cell.onTapped = {
                    // TODO: navigate to article detail
                }
                return cell
            }
        }
    }()

    // MARK: - Lifecycle

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
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    override func bindViewModel() {
        viewModel.$snapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.dataSource.apply(snapshot, animatingDifferences: false)
            }
            .store(in: &cancellables)
    }
}

// MARK: - UITableViewDelegate

extension HomeViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let s = HomeViewModel.HomeSection(rawValue: section) else { return 0 }
        switch s {
        case .hero, .quickActions, .serviceBanner:
            return 0
        case .team, .tasks, .articles:
            return 40
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let s = HomeViewModel.HomeSection(rawValue: section) else { return nil }
        switch s {
        case .hero, .quickActions, .serviceBanner:
            return nil
        case .team:
            let header = SectionTitleView(title: "我的富德健康管家团队", more: "服务剩余 \(viewModel.daysLeft) 天 ›")
            header.onMoreTapped = { [weak self] in
                // TODO: navigate to team detail
            }
            return wrapHeader(header)
        case .tasks:
            let tasks = viewModel.tasks
            let doneCount = tasks.filter { $0.isDone }.count
            let header = SectionTitleView(title: "今日健康任务", more: "已完成 \(doneCount) / \(tasks.count) · +10 分 ›")
            return wrapHeader(header)
        case .articles:
            let header = SectionTitleView(title: "健康陪伴", more: "更多 ›")
            header.onMoreTapped = {
                // TODO: navigate to articles list
            }
            return wrapHeader(header)
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let s = HomeViewModel.HomeSection(rawValue: section) else { return 0 }
        switch s {
        case .hero, .quickActions:
            return 0
        case .team, .tasks, .serviceBanner:
            return 20
        case .articles:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }

    private func wrapHeader(_ titleView: SectionTitleView) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        container.addSubview(titleView)
        titleView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }
        return container
    }
}
