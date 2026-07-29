import Foundation
import Combine
import UIKit

/// 首页 ViewModel — 对齐 HomeView.vue 区块与 mock
final class HomeViewModel: ObservableObject {

    // MARK: - Section / Item

    enum HomeSection: Int, CaseIterable {
        case banner
        case quickActions
        case membership
        case team
        case tasks
        case articles
    }

    enum HomeItem: Hashable {
        case banner
        case quickActions
        case membership
        case teamMember(Int)
        case taskCard
        case article(Int)
    }

    // MARK: - Published

    @Published var daysLeft: Int = 45
    @Published var quickActions: [HomeQuickActionsCell.Action]
    @Published var membershipPackages: [HomeMembershipPackagesCell.Package]
    @Published var teamMembers: [HomeTeamCardCell.Member]
    @Published var tasks: [HomeTaskCardCell.Task]
    @Published var articles: [HomeArticleCell.Article]
    @Published var snapshot = NSDiffableDataSourceSnapshot<HomeSection, HomeItem>()

    private let userManager: UserManager
    private var cancellables = Set<AnyCancellable>()

    init(userManager: UserManager = AppContainer.shared.userManager) {
        self.userManager = userManager
        self.quickActions = Self.defaultQuickActions
        self.membershipPackages = Self.defaultMembershipPackages
        self.teamMembers = Self.defaultTeamMembers
        self.tasks = Self.defaultTasks
        self.articles = Self.defaultArticles

        NotificationCenter.default.publisher(for: .userDidUpdate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.loadUserProfile() }
            .store(in: &cancellables)

        loadUserProfile()
    }

    func loadUserProfile() {
        applySnapshot()
    }

    private func applySnapshot() {
        var snap = NSDiffableDataSourceSnapshot<HomeSection, HomeItem>()
        let sections: [HomeSection] = membershipPackages.isEmpty
            ? HomeSection.allCases.filter { $0 != .membership }
            : HomeSection.allCases
        snap.appendSections(sections)
        snap.appendItems([.banner], toSection: .banner)
        snap.appendItems([.quickActions], toSection: .quickActions)
        if !membershipPackages.isEmpty {
            snap.appendItems([.membership], toSection: .membership)
        }
        snap.appendItems(teamMembers.indices.map { HomeItem.teamMember($0) }, toSection: .team)
        snap.appendItems([.taskCard], toSection: .tasks)
        snap.appendItems(articles.indices.map { HomeItem.article($0) }, toSection: .articles)
        snapshot = snap
    }
}

// MARK: - Mock

extension HomeViewModel {

    static var defaultQuickActions: [HomeQuickActionsCell.Action] {
        [
            .init(icon: "bubble.left.and.bubble.right.fill", title: "咨询健管师",
                  bgColor: UIColor(hexString: "#FFF3EE"), iconColor: .fdPrimary, route: "/messages"),
            .init(icon: "calendar", title: "预约体检",
                  bgColor: UIColor(hexString: "#EAF3FF"), iconColor: UIColor(hexString: "#3D6FB8"), route: "/appointments/exams"),
            .init(icon: "cross.case", title: "就医协助",
                  bgColor: UIColor(hexString: "#E6F7EF"), iconColor: UIColor(hexString: "#1F9A6B"), route: "/services/medical-assist"),
            .init(icon: "creditcard", title: "激活兑换",
                  bgColor: UIColor(hexString: "#FFF3DC"), iconColor: UIColor(hexString: "#B47300"), route: "/activate"),
        ]
    }

    static var defaultMembershipPackages: [HomeMembershipPackagesCell.Package] {
        [
            .init(id: "pkg-plan-003", name: "进阶会员", intro: "12个月全面健康管理", priceText: "¥980", badge: "推荐"),
            .init(id: "pkg-plan-001", name: "体验套餐", intro: "7天健康管理体验", priceText: "¥19.9", badge: "热门"),
            .init(id: "pkg-plan-002", name: "基础健康服务套餐", intro: "3个月基础健康管理", priceText: "¥199", badge: nil),
        ]
    }

    static var defaultTeamMembers: [HomeTeamCardCell.Member] {
        [
            .init(role: "doctor", initial: "张", name: "张建国", title: "内科主任医师",
                  tags: "高血压·心脑血管", status: "在线", statusType: "success"),
            .init(role: "nutrition", initial: "陈", name: "陈梅", title: "国家注册营养师",
                  tags: "慢病饮食干预", status: "今日值班", statusType: "primary"),
            .init(role: "manager", initial: "王", name: "王顾问", title: "健康管理专家",
                  tags: "随访·行为干预", status: "您的专属", statusType: "warning"),
        ]
    }

    static var defaultTasks: [HomeTaskCardCell.Task] {
        [
            .init(title: "晨起血压测量", description: "建议 6:30–8:00 静坐 5 分钟后测量", points: 5, isDone: false, isHighlighted: false),
            .init(title: "目标步数 8000 步", description: "今日已走 8,432 步 · 棒极了", points: 10, isDone: true, isHighlighted: false),
            .init(title: "完善健康档案", description: "完整度 72% · 缺心电图、家族史", points: 20, isDone: false, isHighlighted: true),
        ]
    }

    static var defaultArticles: [HomeArticleCell.Article] {
        [
            .init(tag: "高血压", tagType: "warning", title: "为什么医生说「早晨的第一杯水」不能省?", author: "张建国 主任医师", reads: "2.3k 阅读"),
            .init(tag: "膳食干预", tagType: "success", title: "低钠≠无味——3 个让餐桌更香的代盐技巧", author: "陈梅 注册营养师", reads: "1.8k 阅读"),
            .init(tag: "运动", tagType: "primary", title: "每天 30 分钟快走，血压能下降多少?", author: "王顾问 健康管理师", reads: "3.1k 阅读"),
            .init(tag: "睡眠", tagType: "info", title: "睡眠不足 1 小时，血压可能上升 10 个百分点", author: "张建国 主任医师", reads: "2.8k 阅读"),
            .init(tag: "体重管理", tagType: "warning", title: "减重 5%，血糖能有多大改变?", author: "陈梅 注册营养师", reads: "1.5k 阅读"),
        ]
    }
}
