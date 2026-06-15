import UIKit
import SnapKit

/// 首页 Hub — UITableView 实现
/// 参考 funde-client: HomeView.vue
final class HomeViewController: BaseViewController {

    // MARK: - Section / Item types

    private enum HomeSection: Int, CaseIterable {
        case hero
        case quickActions
        case team
        case tasks
        case serviceBanner
        case articles
    }

    private enum HomeItem: Hashable {
        case hero
        case quickActions
        case teamMember(Int)
        case taskCard
        case serviceBanner
        case article(Int)
    }

    // MARK: - Mock data

    private typealias Metric = HomeHeroCell.Metric
    private typealias QuickAction = HomeQuickActionsCell.Action
    private typealias TeamMember = HomeTeamCardCell.Member
    private typealias Task = HomeTaskCardCell.Task
    private typealias Article = HomeArticleCell.Article

    private let metrics: [Metric] = [
        Metric(name: "血压", value: "138/88", unit: "mmHg", status: "偏高", statusType: "warning"),
        Metric(name: "血糖", value: "5.8", unit: "mmol/L", status: "正常", statusType: "success"),
        Metric(name: "体重", value: "68.5", unit: "kg", status: "正常", statusType: "success"),
        Metric(name: "心率", value: "76", unit: "bpm", status: "正常", statusType: "success"),
    ]

    private let quickActions: [QuickAction] = [
        QuickAction(icon: "bubble.left.and.bubble.right", title: "咨询健管师", bgColor: UIColor(hexString: "#FFF3EE"), iconColor: .fdPrimary, route: "/messages"),
        QuickAction(icon: "calendar.badge.clock", title: "预约体检", bgColor: UIColor(hexString: "#EAF3FF"), iconColor: UIColor(hexString: "#3D6FB8"), route: "/web/appointments"),
        QuickAction(icon: "heart", title: "录入体征", bgColor: UIColor(hexString: "#E6F7EF"), iconColor: UIColor(hexString: "#1F9A6B"), route: "/health/metrics"),
        QuickAction(icon: "gift", title: "查看权益", bgColor: UIColor(hexString: "#FFF3DC"), iconColor: UIColor(hexString: "#B47300"), route: "/web/membership"),
    ]

    private let teamMembers: [TeamMember] = [
        TeamMember(role: "doctor", initial: "张", name: "张建国", title: "内科主任医师", tags: "高血压·心脑血管", status: "在线", statusType: "success"),
        TeamMember(role: "nutrition", initial: "陈", name: "陈梅", title: "国家注册营养师", tags: "慢病饮食干预", status: "今日值班", statusType: "primary"),
        TeamMember(role: "manager", initial: "王", name: "王顾问", title: "健康管理专家", tags: "随访·行为干预", status: "您的专属", statusType: "warning"),
    ]

    private let tasks: [Task] = [
        Task(title: "晨起血压测量", description: "建议 6:30–8:00 静坐 5 分钟后测量", points: 5, isDone: false, isHighlighted: false),
        Task(title: "目标步数 8000 步", description: "今日已走 8,432 步 · 棒极了", points: 10, isDone: true, isHighlighted: false),
        Task(title: "完善健康档案", description: "完整度 72% · 缺心电图、家族史", points: 20, isDone: false, isHighlighted: true),
    ]

    private let articles: [Article] = [
        Article(tag: "高血压", tagType: "warning", title: "为什么医生说「早晨的第一杯水」不能省?", author: "张建国 主任医师", reads: "2.3k 阅读"),
        Article(tag: "膳食干预", tagType: "success", title: "低钠≠无味——3 个让餐桌更香的代盐技巧", author: "陈梅 注册营养师", reads: "1.8k 阅读"),
        Article(tag: "运动", tagType: "primary", title: "每天 30 分钟快走，血压能下降多少?", author: "王顾问 健康管理师", reads: "3.1k 阅读"),
        Article(tag: "睡眠", tagType: "info", title: "睡眠不足 1 小时，血压可能上升 10 个百分点", author: "张建国 主任医师", reads: "2.8k 阅读"),
        Article(tag: "体重管理", tagType: "warning", title: "减重 5%，血糖能有多大改变?", author: "陈梅 注册营养师", reads: "1.5k 阅读"),
    ]

    private let userName = "李秀英"
    private let advisor = "王顾问"
    private let daysLeft = 45
    private let riskScore = 62
    private let riskLevel = "中风险"
    private let riskHint = "血压持续偏高，建议本周完成晨起测量 3 次"

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

    private lazy var dataSource: UITableViewDiffableDataSource<HomeSection, HomeItem> = {
        UITableViewDiffableDataSource<HomeSection, HomeItem>(tableView: tableView) { [weak self] tv, indexPath, item in
            guard let self else { return UITableViewCell() }
            switch item {
            case .hero:
                let cell = tv.dequeueReusableCell(withIdentifier: HomeHeroCell.reuseID, for: indexPath) as! HomeHeroCell
                cell.configure(
                    name: self.userName,
                    advisor: self.advisor,
                    daysLeft: self.daysLeft,
                    riskScore: self.riskScore,
                    riskLevel: self.riskLevel,
                    riskHint: self.riskHint,
                    metrics: self.metrics
                )
                return cell
            case .quickActions:
                let cell = tv.dequeueReusableCell(withIdentifier: HomeQuickActionsCell.reuseID, for: indexPath) as! HomeQuickActionsCell
                cell.configure(actions: self.quickActions)
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
                cell.configure(member: self.teamMembers[idx])
                cell.onMessageTapped = { name in
                    Router.shared.push("/messages", params: ["name": name])
                }
                return cell
            case .taskCard:
                let cell = tv.dequeueReusableCell(withIdentifier: HomeTaskCardCell.reuseID, for: indexPath) as! HomeTaskCardCell
                cell.configure(tasks: self.tasks)
                cell.onTaskTapped = { _ in
                    // TODO: toggle task completion when wired to real data
                }
                return cell
            case .serviceBanner:
                let cell = tv.dequeueReusableCell(withIdentifier: HomeServiceBannerCell.reuseID, for: indexPath) as! HomeServiceBannerCell
                cell.configure(week: 5, totalWeeks: 12, daysLeft: self.daysLeft)
                cell.onTapped = {
                    Router.shared.push("/services")
                }
                return cell
            case .article(let idx):
                let cell = tv.dequeueReusableCell(withIdentifier: HomeArticleCell.reuseID, for: indexPath) as! HomeArticleCell
                let article = self.articles[idx]
                cell.configure(article: article, isLast: idx == self.articles.count - 1)
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
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        applySnapshot()
    }

    // MARK: - Data source

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<HomeSection, HomeItem>()
        snapshot.appendSections(HomeSection.allCases)
        snapshot.appendItems([.hero], toSection: .hero)
        snapshot.appendItems([.quickActions], toSection: .quickActions)
        snapshot.appendItems(teamMembers.indices.map { HomeItem.teamMember($0) }, toSection: .team)
        snapshot.appendItems([.taskCard], toSection: .tasks)
        snapshot.appendItems([.serviceBanner], toSection: .serviceBanner)
        snapshot.appendItems(articles.indices.map { HomeItem.article($0) }, toSection: .articles)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - UITableViewDelegate

extension HomeViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let s = HomeSection(rawValue: section) else { return 0 }
        switch s {
        case .hero, .quickActions, .serviceBanner:
            return 0
        case .team, .tasks, .articles:
            return 40 // 28 (SectionTitleView) + 12 (spacing to card)
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let s = HomeSection(rawValue: section) else { return nil }
        switch s {
        case .hero, .quickActions, .serviceBanner:
            return nil
        case .team:
            let header = SectionTitleView(title: "我的富德健康管家团队", more: "服务剩余 \(daysLeft) 天 ›")
            header.onMoreTapped = { [weak self] in
                // TODO: navigate to team detail
            }
            return wrapHeader(header)
        case .tasks:
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
        guard let s = HomeSection(rawValue: section) else { return 0 }
        switch s {
        case .hero, .quickActions:
            return 0
        case .team, .tasks, .serviceBanner:
            return 20 // spacing between cards
        case .articles:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }

    /// 包装 SectionTitleView 到 header 容器（左边距对齐 card）
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
