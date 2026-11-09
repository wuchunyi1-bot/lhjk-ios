import Combine
import Foundation

struct MyActivityCard: Hashable {
    let id: String
    let theme: String
    let timeText: String
    let owner: String
    let statusText: String
    let isOngoing: Bool
    let isTappable: Bool
}

final class MyActivitiesViewModel: ObservableObject {

    @Published private(set) var cards: [MyActivityCard] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let service: MemberActivityService
    private var loadTask: Task<Void, Never>?

    init(service: MemberActivityService = AppContainer.shared.memberActivityService) {
        self.service = service
    }

    func load() {
        loadTask?.cancel()
        isLoading = cards.isEmpty
        errorMessage = nil
        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let list = try await service.listMyActivities()
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.cards = Self.cards(from: list)
                    self.isLoading = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = (error as? LocalizedError)?.errorDescription ?? "获取活动失败"
                }
            }
        }
    }

    private static func cards(from list: [MemberActivityClientListVO]) -> [MyActivityCard] {
        list.compactMap { item -> (MemberActivityBadge, MemberActivityClientListVO)? in
            guard !item.activityId.isEmpty, let badge = item.badge, badge.isListVisible else { return nil }
            return (badge, item)
        }
        .sorted { lhs, rhs in
            if lhs.0.sortRank != rhs.0.sortRank { return lhs.0.sortRank < rhs.0.sortRank }
            return lhs.1.startTime < rhs.1.startTime
        }
        .map { badge, item in
            MyActivityCard(
                id: item.activityId,
                theme: item.theme.isEmpty ? "—" : item.theme,
                timeText: MemberActivityDisplay.timeText(startTime: item.startTime, endTime: item.endTime),
                owner: item.ourLeaderName.isEmpty ? "—" : item.ourLeaderName,
                statusText: badge.title,
                isOngoing: badge.isOngoing,
                isTappable: item.detailAccessible
            )
        }
    }
}
