import Foundation
import Combine
import UIKit

/// 首页 ViewModel — Figma 首页结构 + 今日任务 / 管家团队真实 API
final class HomeViewModel: ObservableObject {

    enum HomeSection: Int, CaseIterable {
        case banner
        case quickActions
        case support
        case appointments
        case membership
        case team
        case tasks
    }

    enum HomeItem: Hashable {
        case banner(String)
        case quickActions(String)
        case support
        case appointments(String)
        case membership(String)
        case teamList
        case taskCard(String)
    }

    @Published var banners: [ServiceHubBanner] = []
    @Published var quickActions: [HomeQuickActionsCell.Action] = []
    @Published var membershipPackages: [HomeMembershipPackagesCell.Package] = []
    @Published var pendingAppointments: [HomePendingAppointment] = []
    @Published var teamMembers: [HomeTeamCardCell.Member] = []
    /// 管家团队服务剩余天数；`nil` 或 `<= 0` 时不展示标题右侧文案
    @Published var teamServiceDaysLeft: Int?
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
    private let cabinService: CabinService
    private let columnContentCache: ColumnContentCacheService
    private var cancellables = Set<AnyCancellable>()
    private var tasksLoadTask: Task<Void, Never>?
    private var teamLoadTask: Task<Void, Never>?
    private var appointmentsLoadTask: Task<Void, Never>?
    private var bannersLoadTask: Task<Void, Never>?
    private var quickLinksLoadTask: Task<Void, Never>?
    private var healthServicesLoadTask: Task<Void, Never>?
    private var newsLoadTask: Task<Void, Never>?

    init(
        userManager: UserManager = AppContainer.shared.userManager,
        homeService: HomeService = .shared,
        cabinService: CabinService = AppContainer.shared.cabinService,
        columnContentCache: ColumnContentCacheService = AppContainer.shared.columnContentCacheService
    ) {
        self.userManager = userManager
        self.homeService = homeService
        self.cabinService = cabinService
        self.columnContentCache = columnContentCache

        NotificationCenter.default.publisher(for: .userDidUpdate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applySnapshot()
                self?.loadTodayTasks()
                self?.loadDoctorTeam()
                self?.loadPendingAppointments()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .todayMonitorTaskShouldRefresh)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadTodayTasks(forceRefresh: true)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .archiveCompletionDidUpdate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applySnapshot()
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

    func loadTodayTasks(forceRefresh: Bool = false) {
        tasksLoadTask?.cancel()
        tasksLoadTask = Task { [weak self] in
            await self?.fetchTodayTasks(forceRefresh: forceRefresh)
        }
    }

    func loadDoctorTeam() {
        teamLoadTask?.cancel()
        teamLoadTask = Task { [weak self] in
            await self?.fetchDoctorTeam()
        }
    }

    func loadPendingAppointments() {
        appointmentsLoadTask?.cancel()
        appointmentsLoadTask = Task { [weak self] in
            await self?.fetchPendingAppointments()
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
    private func fetchTodayTasks(forceRefresh: Bool = false) async {
        guard let userId = resolveUserId() else {
            tasks = []
            applySnapshot()
            return
        }

        isTasksLoading = true
        defer { isTasksLoading = false }

        do {
            let remote = try await homeService.getUserTodayMonitorTask(userId: userId, forceRefresh: forceRefresh)
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
            teamServiceDaysLeft = nil
            applySnapshot()
            return
        }

        isTeamLoading = true
        defer { isTeamLoading = false }

        do {
            async let teamsTask = homeService.getUserParticipateAllTeam(userId: userId)
            async let remainTask = homeService.getRemainServiceTime()

            let teams = try await teamsTask
            let remainVO = try? await remainTask
            guard !Task.isCancelled else { return }

            let staff = teams.firstTeamStaff(excludingUserId: userId)
            teamMembers = staff.compactMap { Self.mapTeamMember($0) }
            teamServiceDaysLeft = Self.normalizedServiceDaysLeft(remainVO?.remainDays)
            applySnapshot()
        } catch {
            guard !Task.isCancelled else { return }
            print("[HomeViewModel] loadDoctorTeam ✗ \(error.localizedDescription)")
            teamMembers = []
            teamServiceDaysLeft = nil
            applySnapshot()
        }
    }

    @MainActor
    private func fetchPendingAppointments() async {
        guard resolveUserId() != nil else {
            pendingAppointments = []
            applySnapshot()
            return
        }
        do {
            let page = try await cabinService.appointments(status: "3", pageNum: 1, pageSize: 20)
            guard !Task.isCancelled else { return }
            let records = (page.records ?? []).sorted {
                ($0.reserveDate, $0.startTime) < ($1.reserveDate, $1.startTime)
            }
            pendingAppointments = records.compactMap(Self.mapPendingAppointment)
            applySnapshot()
        } catch {
            guard !Task.isCancelled else { return }
            pendingAppointments = []
            applySnapshot()
        }
    }

    private static func mapPendingAppointment(_ item: CabinAppointmentVO) -> HomePendingAppointment? {
        let title = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !item.id.isEmpty, !title.isEmpty else { return nil }
        let time = [item.reserveDate, item.timeText].filter { !$0.isEmpty }.joined(separator: " ")
        return HomePendingAppointment(
            id: item.id,
            configId: item.configId,
            hospitalId: item.hospitalId,
            title: title,
            timeText: time,
            storeName: item.hospitalName,
            address: item.address,
            hint: item.overdueNotice ?? "请提前15分钟到店"
        )
    }

    private static func normalizedServiceDaysLeft(_ raw: Int?) -> Int? {
        guard let raw, raw > 0 else { return nil }
        return raw
    }

    private func resolveUserId() -> String? {
        userManager.resolvedUserId
    }

    private func applySnapshot() {
        var snap = NSDiffableDataSourceSnapshot<HomeSection, HomeItem>()
        var sections: [HomeSection] = [.support]
        if !tasks.isEmpty { sections.append(.tasks) }
        if !banners.isEmpty { sections.insert(.banner, at: 0) }
        if !quickActions.isEmpty {
            let index = sections.firstIndex(of: .support) ?? sections.count
            sections.insert(.quickActions, at: index)
        }
        if !pendingAppointments.isEmpty {
            let index = sections.firstIndex(of: .support).map { $0 + 1 } ?? sections.count
            sections.insert(.appointments, at: index)
        }
        if !membershipPackages.isEmpty {
            let anchor = sections.firstIndex(of: .appointments) ?? sections.firstIndex(of: .support)
            let index = anchor.map { $0 + 1 } ?? sections.count
            sections.insert(.membership, at: index)
        }
        if !teamMembers.isEmpty {
            let index = sections.firstIndex(of: .tasks) ?? sections.count
            sections.insert(.team, at: index)
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
        snap.appendItems([.support], toSection: .support)
        if !pendingAppointments.isEmpty {
            let signature = pendingAppointments.map { "\($0.id):\($0.hint)" }.joined(separator: "|")
            snap.appendItems([.appointments(signature)], toSection: .appointments)
        }
        if !teamMembers.isEmpty {
            snap.appendItems([.teamList], toSection: .team)
        }
        if !tasks.isEmpty {
            let taskSig = tasks.map { "\($0.id):\($0.done):\($0.typePointsEarned)" }.joined(separator: "|")
                + "#\(tasks.count)"
            snap.appendItems([.taskCard(taskSig)], toSection: .tasks)
        }
        snapshot = snap
    }

    var taskPreview: [DailyHealthTask] {
        Array(tasks.prefix(3))
    }

    var taskDoneCount: Int { tasks.filter(\.done).count }
    var taskTotalCount: Int { tasks.count }

    /// 今日已得积分：按监测 `type` 去重后累加 `pointsEarned`（类型日已得分，非单条 `quantity`）
    var taskEarnedPoints: Int {
        UserTodayMonitorTask.summedEarnedPointsByType(
            tasks.map { (type: $0.monitorType, pointsEarned: $0.typePointsEarned) }
        )
    }

    private static func mapTeamMember(_ vo: MyDoctorTeamVO) -> HomeTeamCardCell.Member? {
        let name = (vo.userName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }

        return HomeTeamCardCell.Member(
            role: vo.resolvedRole(),
            initial: String(name.prefix(1)),
            name: name,
            title: (vo.position ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            tags: vo.resolvedTags(),
            status: "",
            statusType: "",
            groupId: vo.groupId,
            imageUrl: vo.imageUrl,
            userId: vo.userId
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
            pageUrl: banner.pageUrl,
            contentType: banner.contentType,
            contentId: banner.contentId
        )
    }

    private static func mapNewsArticle(_ banner: ServiceHubBanner) -> HomeArticleCell.Article? {
        let title = banner.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let imageUrl = banner.imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasImage = !(imageUrl?.isEmpty ?? true)
        guard !title.isEmpty || hasImage else { return nil }

        let rawAuthor = (banner.authorName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let author = rawAuthor
            .components(separatedBy: CharacterSet(charactersIn: "｜|"))
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? rawAuthor

        return HomeArticleCell.Article(
            id: banner.id,
            tag: banner.labelName ?? "",
            title: title,
            author: author,
            reads: ColumnContentMapper.formatReadCount(banner.clickCount),
            imageUrl: hasImage ? imageUrl : nil,
            contentId: banner.contentId
        )
    }
}

struct HomePendingAppointment: Hashable {
    let id: String
    let configId: String
    let hospitalId: String
    let title: String
    let timeText: String
    let storeName: String
    let address: String
    let hint: String
}
