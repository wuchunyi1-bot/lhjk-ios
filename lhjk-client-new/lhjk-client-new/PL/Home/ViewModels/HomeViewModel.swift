import Foundation
import Combine
import UIKit

/// 首页 ViewModel — 持有所有展示数据，负责数据加载与 Snapshot 构建
///
/// ViewController 通过订阅 `$snapshot` 驱动 TableView 刷新，
/// 导航逻辑（Router.push、Tab 切换）保留在 ViewController
final class HomeViewModel: ObservableObject {

    // MARK: - Section / Item Types

    enum HomeSection: Int, CaseIterable {
        case hero
        case quickActions
        case team
        case tasks
        case serviceBanner
        case articles
    }

    enum HomeItem: Hashable {
        case hero
        case quickActions
        case teamMember(Int)
        case taskCard
        case serviceBanner
        case article(Int)
    }

    // MARK: - Published State

    @Published var userName: String = "加载中…"
    @Published var avatarChar: String = "我"
    @Published var advisor: String
    @Published var daysLeft: Int
    @Published var riskScore: Int
    @Published var riskLevel: String
    @Published var riskHint: String

    @Published var metrics: [HomeHeroCell.Metric]
    @Published var quickActions: [HomeQuickActionsCell.Action]
    @Published var teamMembers: [HomeTeamCardCell.Member]
    @Published var tasks: [HomeTaskCardCell.Task]
    @Published var articles: [HomeArticleCell.Article]

    /// TableView DiffableDataSource snapshot，驱动 UI 刷新
    @Published var snapshot = NSDiffableDataSourceSnapshot<HomeSection, HomeItem>()

    // MARK: - Dependencies

    private let userManager: UserManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(userManager: UserManager = .shared) {
        self.userManager = userManager

        // 默认值（用户信息未加载时的占位）
        self.advisor = "王顾问"
        self.daysLeft = 45
        self.riskScore = 62
        self.riskLevel = "中风险"
        self.riskHint = "血压持续偏高，建议本周完成晨起测量 3 次"

        self.metrics = Self.defaultMetrics
        self.quickActions = Self.defaultQuickActions
        self.teamMembers = Self.defaultTeamMembers
        self.tasks = Self.defaultTasks
        self.articles = Self.defaultArticles

        // 监听用户信息更新
        NotificationCenter.default.publisher(for: .userDidUpdate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadUserProfile()
            }
            .store(in: &cancellables)

        // 首次加载
        loadUserProfile()
    }

    // MARK: - Public Methods

    /// 从 UserManager 读取用户信息并刷新 Snapshot
    func loadUserProfile() {
        guard let user = userManager.currentUser else {
            applySnapshot()
            return
        }
        let name = user.chineseName ?? user.surname ?? user.nickname ?? "用户"
        userName = name
        avatarChar = String(name.prefix(1))
        applySnapshot()
    }

    // MARK: - Private

    private func applySnapshot() {
        var snap = NSDiffableDataSourceSnapshot<HomeSection, HomeItem>()
        snap.appendSections(HomeSection.allCases)
        snap.appendItems([.hero], toSection: .hero)
        snap.appendItems([.quickActions], toSection: .quickActions)
        snap.appendItems(teamMembers.indices.map { HomeItem.teamMember($0) }, toSection: .team)
        snap.appendItems([.taskCard], toSection: .tasks)
        snap.appendItems([.serviceBanner], toSection: .serviceBanner)
        snap.appendItems(articles.indices.map { HomeItem.article($0) }, toSection: .articles)
        snapshot = snap
    }
}

// MARK: - Default Mock Data

extension HomeViewModel {

    static var defaultMetrics: [HomeHeroCell.Metric] {
        [
            HomeHeroCell.Metric(name: "血压", value: "138/88", unit: "mmHg", status: "偏高", statusType: "warning"),
            HomeHeroCell.Metric(name: "血糖", value: "5.8", unit: "mmol/L", status: "正常", statusType: "success"),
            HomeHeroCell.Metric(name: "体重", value: "68.5", unit: "kg", status: "正常", statusType: "success"),
            HomeHeroCell.Metric(name: "心率", value: "76", unit: "bpm", status: "正常", statusType: "success"),
        ]
    }

    static var defaultQuickActions: [HomeQuickActionsCell.Action] {
        [
            HomeQuickActionsCell.Action(icon: "bubble.left.and.bubble.right", title: "咨询健管师", bgColor: UIColor(hexString: "#FFF3EE"), iconColor: .fdPrimary, route: "/messages"),
            HomeQuickActionsCell.Action(icon: "calendar.badge.clock", title: "预约体检", bgColor: UIColor(hexString: "#EAF3FF"), iconColor: UIColor(hexString: "#3D6FB8"), route: "/web/appointments"),
            HomeQuickActionsCell.Action(icon: "heart", title: "录入体征", bgColor: UIColor(hexString: "#E6F7EF"), iconColor: UIColor(hexString: "#1F9A6B"), route: "/health/metrics"),
            HomeQuickActionsCell.Action(icon: "gift", title: "查看权益", bgColor: UIColor(hexString: "#FFF3DC"), iconColor: UIColor(hexString: "#B47300"), route: "/web/membership"),
        ]
    }

    static var defaultTeamMembers: [HomeTeamCardCell.Member] {
        [
            HomeTeamCardCell.Member(role: "doctor", initial: "张", name: "张建国", title: "内科主任医师", tags: "高血压·心脑血管", status: "在线", statusType: "success"),
            HomeTeamCardCell.Member(role: "nutrition", initial: "陈", name: "陈梅", title: "国家注册营养师", tags: "慢病饮食干预", status: "今日值班", statusType: "primary"),
            HomeTeamCardCell.Member(role: "manager", initial: "王", name: "王顾问", title: "健康管理专家", tags: "随访·行为干预", status: "您的专属", statusType: "warning"),
        ]
    }

    static var defaultTasks: [HomeTaskCardCell.Task] {
        [
            HomeTaskCardCell.Task(title: "晨起血压测量", description: "建议 6:30–8:00 静坐 5 分钟后测量", points: 5, isDone: false, isHighlighted: false),
            HomeTaskCardCell.Task(title: "目标步数 8000 步", description: "今日已走 8,432 步 · 棒极了", points: 10, isDone: true, isHighlighted: false),
            HomeTaskCardCell.Task(title: "完善健康档案", description: "完整度 72% · 缺心电图、家族史", points: 20, isDone: false, isHighlighted: true),
        ]
    }

    static var defaultArticles: [HomeArticleCell.Article] {
        [
            HomeArticleCell.Article(tag: "高血压", tagType: "warning", title: "为什么医生说「早晨的第一杯水」不能省?", author: "张建国 主任医师", reads: "2.3k 阅读"),
            HomeArticleCell.Article(tag: "膳食干预", tagType: "success", title: "低钠≠无味——3 个让餐桌更香的代盐技巧", author: "陈梅 注册营养师", reads: "1.8k 阅读"),
            HomeArticleCell.Article(tag: "运动", tagType: "primary", title: "每天 30 分钟快走，血压能下降多少?", author: "王顾问 健康管理师", reads: "3.1k 阅读"),
            HomeArticleCell.Article(tag: "睡眠", tagType: "info", title: "睡眠不足 1 小时，血压可能上升 10 个百分点", author: "张建国 主任医师", reads: "2.8k 阅读"),
            HomeArticleCell.Article(tag: "体重管理", tagType: "warning", title: "减重 5%，血糖能有多大改变?", author: "陈梅 注册营养师", reads: "1.5k 阅读"),
        ]
    }
}
