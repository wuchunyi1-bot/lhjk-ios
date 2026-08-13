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
        case quickActions(String)
        case membership(String)
        case teamList
        case taskCard(String)
        case articlesCard(String)
    }

    @Published var daysLeft: Int = 45
    @Published var banners: [ServiceHubBanner] = []
    @Published var quickActions: [HomeQuickActionsCell.Action] = []
    @Published var membershipPackages: [HomeMembershipPackagesCell.Package] = []
    @Published var teamMembers: [HomeTeamCardCell.Member] = []
    @Published var tasks: [DailyHealthTask] = []
    @Published var articles: [HomeArticleCell.Article] = []
    @Published var snapshot = NSDiffableDataSourceSnapshot<HomeSection, HomeItem>()
    @Published private(set) var isTasksLoading = false
    @Published private(set) var isTeamLoading = false
    @Published private(set) var isBannersLoading = false
    @Published private(set) var isQuickLinksLoading = false
    @Published private(set) var isHealthServicesLoading = false
    @Published private(set) var isNewsLoading = false

    private let userManager: UserManager
    private let homeService: HomeService
    private let columnContentCache: ColumnContentCacheService
    private var cancellables = Set<AnyCancellable>()
    private var tasksLoadTask: Task<Void, Never>?
    private var teamLoadTask: Task<Void, Never>?
    private var bannersLoadTask: Task<Void, Never>?
    private var quickLinksLoadTask: Task<Void, Never>?
    private var healthServicesLoadTask: Task<Void, Never>?
    private var newsLoadTask: Task<Void, Never>?

    init(
        userManager: UserManager = AppContainer.shared.userManager,
        homeService: HomeService = .shared,
        columnContentCache: ColumnContentCacheService = AppContainer.shared.columnContentCacheService
    ) {
        self.userManager = userManager
        self.homeService = homeService
        self.columnContentCache = columnContentCache

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

    func loadQuickLinks() {
        quickLinksLoadTask?.cancel()
        quickLinksLoadTask = Task { [weak self] in
            await self?.fetchQuickLinks()
        }
    }

    func loadHealthServices() {
        healthServicesLoadTask?.cancel()
        healthServicesLoadTask = Task { [weak self] in
            await self?.fetchHealthServices()
        }
    }

    func loadNews() {
        newsLoadTask?.cancel()
        newsLoadTask = Task { [weak self] in
            await self?.fetchNews()
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
    private func fetchQuickLinks() async {
        isQuickLinksLoading = true
        defer { isQuickLinksLoading = false }

        let remote = await columnContentCache.banners(for: ColumnContentService.homeQuickLinkCode)
        guard !Task.isCancelled else { return }
        quickActions = remote.compactMap(Self.mapQuickAction)
        applySnapshot()
    }

    @MainActor
    private func fetchHealthServices() async {
        isHealthServicesLoading = true
        defer { isHealthServicesLoading = false }

        let remote = await columnContentCache.banners(for: ColumnContentService.homeHealthServiceCode)
        guard !Task.isCancelled else { return }
        membershipPackages = remote.compactMap(Self.mapHealthServicePackage)
        applySnapshot()
    }

    @MainActor
    private func fetchNews() async {
        isNewsLoading = true
        defer { isNewsLoading = false }

        let remote = await columnContentCache.banners(for: ColumnContentService.homeNewsCode)
        guard !Task.isCancelled else { return }
        articles = remote.compactMap(Self.mapNewsArticle)
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
        if quickActions.isEmpty {
            sections.removeAll { $0 == .quickActions }
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
        if articles.isEmpty {
            sections.removeAll { $0 == .articles }
        }
        snap.appendSections(sections)
        if !banners.isEmpty {
            let bannerSig = banners.map(\.id).joined(separator: "|")
            snap.appendItems([.banner(bannerSig)], toSection: .banner)
        }
        if !quickActions.isEmpty {
            let quickSig = quickActions.map(\.id).joined(separator: "|")
            snap.appendItems([.quickActions(quickSig)], toSection: .quickActions)
        }
        if !membershipPackages.isEmpty {
            let membershipSig = membershipPackages.map(\.id).joined(separator: "|")
            snap.appendItems([.membership(membershipSig)], toSection: .membership)
        }
        if !teamMembers.isEmpty {
            snap.appendItems([.teamList], toSection: .team)
        }
        if !tasks.isEmpty {
            let taskSig = tasks.map { "\($0.id):\($0.done)" }.joined(separator: "|")
                + "#\(tasks.count)"
            snap.appendItems([.taskCard(taskSig)], toSection: .tasks)
        }
        if !articles.isEmpty {
            let articlesSig = articles.map(\.id).joined(separator: "|")
            snap.appendItems([.articlesCard(articlesSig)], toSection: .articles)
        }
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

    private static func mapQuickAction(_ banner: ServiceHubBanner) -> HomeQuickActionsCell.Action? {
        let title = banner.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasTitle = !title.isEmpty
        let hasImage = banner.hasImage
        guard hasTitle || hasImage else { return nil }
        return HomeQuickActionsCell.Action(
            id: banner.id,
            title: title,
            imageUrl: banner.imageUrl,
            pageUrl: banner.pageUrl
        )
    }

    private static func mapHealthServicePackage(_ banner: ServiceHubBanner) -> HomeMembershipPackagesCell.Package? {
        guard banner.hasImage,
              let imageUrl = banner.imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
              !imageUrl.isEmpty else {
            return nil
        }
        return HomeMembershipPackagesCell.Package(
            id: banner.id,
            imageUrl: imageUrl,
            pageUrl: banner.pageUrl
        )
    }

    private static func mapNewsArticle(_ banner: ServiceHubBanner) -> HomeArticleCell.Article? {
        let title = banner.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let imageUrl = banner.imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasImage = !(imageUrl?.isEmpty ?? true)
        guard !title.isEmpty || hasImage else { return nil }

        return HomeArticleCell.Article(
            id: banner.id,
            tag: banner.labelName ?? "",
            title: title,
            author: banner.authorName ?? "",
            reads: ColumnContentMapper.formatReadCount(banner.clickCount),
            imageUrl: hasImage ? imageUrl : nil,
            contentId: banner.contentId
        )
    }
}
