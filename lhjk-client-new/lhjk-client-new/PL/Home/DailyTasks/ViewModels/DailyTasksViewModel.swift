import Combine
import Foundation

/// 今日健康任务详情页 ViewModel — 接 `getUserToDayMonitorTask`
final class DailyTasksViewModel: ObservableObject {

    @Published private(set) var tasks: [DailyHealthTask] = []
    @Published private(set) var doneCount: Int = 0
    @Published private(set) var totalCount: Int = 0
    @Published private(set) var isLoading = false

    let tipText = "按时完成今日健康任务，有助于健管师更准确评估您的健康状态。如身体不适请优先联系健管师。"

    private let userManager: UserManager
    private let homeService: HomeService
    private var loadTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    var progressPercent: CGFloat {
        guard totalCount > 0 else { return 0 }
        return CGFloat(doneCount) / CGFloat(totalCount)
    }

    init(
        userManager: UserManager = AppContainer.shared.userManager,
        homeService: HomeService = .shared
    ) {
        self.userManager = userManager
        self.homeService = homeService

        NotificationCenter.default.publisher(for: .todayMonitorTaskShouldRefresh)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.load(forceRefresh: true)
            }
            .store(in: &cancellables)
    }

    func load(forceRefresh: Bool = false) {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.fetch(forceRefresh: forceRefresh)
        }
    }

    @MainActor
    private func fetch(forceRefresh: Bool = false) async {
        guard let userId = resolveUserId() else {
            apply([])
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let remote = try await homeService.getUserTodayMonitorTask(userId: userId, forceRefresh: forceRefresh)
            guard !Task.isCancelled else { return }
            apply(remote.map { $0.asDailyHealthTask() })
        } catch {
            guard !Task.isCancelled else { return }
            print("[DailyTasksViewModel] load ✗ \(error.localizedDescription)")
            apply([])
        }
    }

    private func apply(_ list: [DailyHealthTask]) {
        tasks = list
        doneCount = list.filter(\.done).count
        totalCount = list.count
    }

    private func resolveUserId() -> String? {
        userManager.resolvedUserId
    }

    func actionRoute(for task: DailyHealthTask) -> String? {
        guard !task.done else { return nil }
        let route = task.actionRoute.trimmingCharacters(in: .whitespacesAndNewlines)
        return route.isEmpty ? "/health/metrics" : route
    }
}
