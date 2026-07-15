import Combine
import Foundation

@MainActor
final class BloodSugarHistoryStatsViewModel: ObservableObject {

    @Published private(set) var statistics: BloodPressureStatisticsData?

    let toastMessage = PassthroughSubject<String, Never>()

    private let service: BloodSugarService

    init(service: BloodSugarService = AppContainer.shared.bloodSugarService) {
        self.service = service
    }

    var complianceRateText: String {
        guard let total = statistics?.ninety?.total?.value, total > 0,
              let normal = statistics?.ninety?.normal?.value else { return "0%" }
        return String(format: "%.0f%%", Double(normal) / Double(total) * 100)
    }

    var complianceProgress: CGFloat {
        guard let total = statistics?.ninety?.total?.value, total > 0,
              let normal = statistics?.ninety?.normal?.value else { return 0 }
        return CGFloat(normal) / CGFloat(total)
    }

    func load() {
        Task {
            do {
                statistics = try await service.fetchStatistics()
            } catch {
                statistics = nil
                toastMessage.send(error.localizedDescription)
            }
        }
    }
}
