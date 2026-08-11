import Foundation
import Combine
import UIKit

/// 首页 ViewModel — Figma 首页结构 + 今日任务 / 管家团队真实 API
final class HomeViewModel: ObservableObject {

    enum HomeSection: Int, CaseIterable {
        case banner
        case quickActions
        case membership
        case team
        case tasks
        case articles
    }

    enum HomeItem: Hashable {
        case banner(String)
        case quickActions
        case membership
        case teamList
        case taskCard(String)
        case articlesCard
    }

    @Published var daysLeft: Int = 45
    @Published var banners: [ServiceHubBanner] = []
    @Published var quickActions: [HomeQuickActionsCell.Action]
    @Published var membershipPackages: [HomeMembershipPackagesCell.Package]
    @Published var teamMembers: [HomeTeamCardCell.Member] = []
    @Published var tasks: [DailyHealthTask] = []
    @Published var articles: [HomeArticleCell.Article]
    @Published var snapshot = NSDiffableDataSourceSnapshot<HomeSection, HomeItem>()
    @Published private(set) var isTasksLoading = false
    @Published private(set) var isTeamLoading = false
    @Published private(set) var isBannersLoading = false

    private let userManager: UserManager
    private let homeService: HomeService
    private let columnContentCache: ColumnContentCacheService
    private var cancellables = Set<AnyCancellable>()
    private var tasksLoadTask: Task<Void, Never>?
    private var teamLoadTask: Task<Void, Never>?
    private var bannersLoadTask: Task<Void, Never>?

    init(
        userManager: UserManager = AppContainer.shared.userManager,
        homeService: HomeService = .shared,
        columnContentCache: ColumnContentCacheService = AppContainer.shared.columnContentCacheService
    ) {
        self.userManager = userManager
        self.homeService = homeService
        self.columnContentCache = columnContentCache
        self.quickActions = Self.defaultQuickActions
        self.membershipPackages = Self.defaultMembershipPackages
        self.articles = Self.defaultArticles

        NotificationCenter.default.publisher(for: .userDidUpdate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applySnapshot()
                self?.loadTodayTasks()
                self?.loadDoctorTeam()
            }
            .store(in: &cancellables)

        applySnapshot()
    }

    func loadUserProfile() {
        applySnapshot()
    }

    func loadBanners() {
        bannersLoadTask?.cancel()
        bannersLoadTask = Task { [weak self] in
            await self?.fetchBanners()
        }
    }

    func loadTodayTasks() {
        tasksLoadTask?.cancel()
        tasksLoadTask = Task { [weak self] in
            await self?.fetchTodayTasks()
        }
    }

    func loadDoctorTeam() {
        teamLoadTask?.cancel()
        teamLoadTask = Task { [weak self] in
            await self?.fetchDoctorTeam()
        }
    }

    @MainActor
    private func fetchBanners() async {
        isBannersLoading = true
        defer { isBannersLoading = false }

        let remote = await columnContentCache.banners(for: ColumnContentService.homeBannerCode)
        guard !Task.isCancelled else { return }
        banners = remote.filter(\.hasImage)
        applySnapshot()
    }

    @MainActor
    private func fetchTodayTasks() async {
        guard let userId = resolveUserId() else {
            tasks = []
            applySnapshot()
            return
        }

        isTasksLoading = true
        defer { isTasksLoading = false }

        do {
            let remote = try await homeService.getUserTodayMonitorTask(userId: userId)
            guard !Task.isCancelled else { return }
            tasks = remote.map { $0.asDailyHealthTask() }
            applySnapshot()
        } catch {
            guard !Task.isCancelled else { return }
            print("[HomeViewModel] loadTodayTasks ✗ \(error.localizedDescription)")
            tasks = []
            applySnapshot()
        }
    }

    @MainActor
    private func fetchDoctorTeam() async {
        guard let userId = resolveUserId() else {
            teamMembers = []
            applySnapshot()
            return
        }

        isTeamLoading = true
        defer { isTeamLoading = false }

        do {
            let teams = try await homeService.getUserParticipateAllTeam(userId: userId)
            guard !Task.isCancelled else { return }
            let staff = teams.firstTeamStaff(excludingUserId: userId)
            teamMembers = staff.enumerated().compactMap { Self.mapTeamMember($0.element, index: $0.offset) }
            applySnapshot()
        } catch {
            guard !Task.isCancelled else { return }
            print("[HomeViewModel] loadDoctorTeam ✗ \(error.localizedDescription)")
            teamMembers = []
            applySnapshot()
        }
    }

    private func resolveUserId() -> String? {
        userManager.resolvedUserId
    }

    private func applySnapshot() {
        var snap = NSDiffableDataSourceSnapshot<HomeSection, HomeItem>()
        var sections = HomeSection.allCases
        if banners.isEmpty {
            sections.removeAll { $0 == .banner }
        }
        if membershipPackages.isEmpty {
            sections.removeAll { $0 == .membership }
        }
        if teamMembers.isEmpty {
            sections.removeAll { $0 == .team }
        }
        if tasks.isEmpty {
            sections.removeAll { $0 == .tasks }
        }
        snap.appendSections(sections)
        if !banners.isEmpty {
            let bannerSig = banners.map(\.id).joined(separator: "|")
            snap.appendItems([.banner(bannerSig)], toSection: .banner)
        }
        snap.appendItems([.quickActions], toSection: .quickActions)
        if !membershipPackages.isEmpty {
            snap.appendItems([.membership], toSection: .membership)
        }
        if !teamMembers.isEmpty {
            snap.appendItems([.teamList], toSection: .team)
        }
        if !tasks.isEmpty {
            let taskSig = tasks.map { "\($0.id):\($0.done)" }.joined(separator: "|")
                + "#\(tasks.count)"
            snap.appendItems([.taskCard(taskSig)], toSection: .tasks)
        }
        snap.appendItems([.articlesCard], toSection: .articles)
        snapshot = snap
    }

    var taskPreview: [DailyHealthTask] {
        Array(tasks.prefix(3))
    }

    var taskDoneCount: Int { tasks.filter(\.done).count }
    var taskTotalCount: Int { tasks.count }

    private static func mapTeamMember(_ vo: MyDoctorTeamVO, index: Int) -> HomeTeamCardCell.Member? {
        let name = (vo.userName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }

        let role = vo.resolvedRole()
        let titleText = (vo.position ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let title: String
        if titleText.isEmpty {
            switch role {
            case "doctor": title = "医师"
            case "nutrition": title = "营养师"
            default: title = "健康管理师"
            }
        } else {
            title = titleText
        }

        let fallbackTag: String
        switch role {
        case "doctor": fallbackTag = "高血压·心脑血管"
        case "nutrition": fallbackTag = "慢病饮食干预"
        default: fallbackTag = "随访｜行为干预"
        }

        // 接口无在线态：按角色给设计稿同款展示标签（非真实在线探测）
        let statusPair: (String, String)
        switch role {
        case "doctor": statusPair = ("在线", "success")
        case "nutrition": statusPair = ("今日值班", "warning")
        default: statusPair = ("您的专属", "success")
        }

        let placeholders = ["home_team_1", "home_team_2", "home_team_3"]

        return HomeTeamCardCell.Member(
            role: role,
            initial: String(name.prefix(1)),
            name: name,
            title: title,
            tags: vo.resolvedTags(fallback: fallbackTag),
            status: statusPair.0,
            statusType: statusPair.1,
            groupId: vo.groupId,
            imageUrl: vo.imageUrl,
            userId: vo.userId,
            placeholderImageName: placeholders[min(index, placeholders.count - 1)]
        )
    }
}

// MARK: - 本地样例（未接 API 的区块）

extension HomeViewModel {

    static var defaultQuickActions: [HomeQuickActionsCell.Action] {
        [
            .init(icon: "bubble.left.and.bubble.right.fill", title: "咨询健管师",
                  bgColor: UIColor(hexString: "#FFF3EE"), iconColor: .fdPrimary, route: "/messages"),
            .init(icon: "calendar", title: "预约体检",
                  bgColor: UIColor(hexString: "#FFF3EE"), iconColor: .fdPrimary, route: "/appointments/exams"),
            .init(icon: "cross.case", title: "就医协助",
                  bgColor: UIColor(hexString: "#FFF3EE"), iconColor: .fdPrimary, route: "/services/medical-assist"),
            .init(icon: "creditcard", title: "激活兑换",
                  bgColor: UIColor(hexString: "#FFF3EE"), iconColor: .fdPrimary, route: "/activate"),
        ]
    }

    static var defaultMembershipPackages: [HomeMembershipPackagesCell.Package] {
        [
            .init(id: "pkg-plan-001", name: "体验套餐", intro: "7天健康管理体验", priceText: "¥19.9", badge: "热门"),
            .init(id: "pkg-plan-002", name: "基础健康服务套餐", intro: "3个月基础健康管理", priceText: "¥199", badge: nil),
            .init(id: "pkg-plan-003", name: "进阶健康管理套餐", intro: "12个月全面健康管理", priceText: "¥980", badge: "推荐"),
        ]
    }

    static var defaultArticles: [HomeArticleCell.Article] {
        [
            .init(tag: "高血压", tagType: "warning", title: "为什么医生说「早晨的第一杯水」不能省？",
                  author: "张建国｜主任医师", reads: "2.3K 阅读", imageName: "home_article_1"),
            .init(tag: "膳食干预", tagType: "success", title: "低钠≠无味——3 个让餐桌更香的代盐技巧",
                  author: "陈梅｜注册营养师", reads: "1.8K 阅读", imageName: "home_article_2"),
            .init(tag: "运动", tagType: "primary", title: "每天30分钟快走，血压能下降多少？",
                  author: "王顾问｜健康管理师", reads: "3.1K 阅读", imageName: "home_article_3"),
            .init(tag: "睡眠", tagType: "info", title: "睡眠不足1小时，血压可能上升 10 个百分点",
                  author: "张建国｜主任医师", reads: "2.8K 阅读", imageName: "home_article_4"),
            .init(tag: "体重管理", tagType: "warning", title: "减重 5 %，血糖能有多大改变？",
                  author: "陈梅｜注册营养师", reads: "1.5K 阅读", imageName: "home_article_5"),
        ]
    }
}
