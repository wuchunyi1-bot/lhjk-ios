import Combine
import Foundation

@MainActor
final class BloodSugarHistoryFormViewModel: ObservableObject {

    @Published private(set) var mealTypes: [BloodSugarMealType] = []
    @Published private(set) var days: [BloodSugarMonitorDay] = []
    @Published var selectedPeriodIndex = 0
    @Published private(set) var totalText = "0"
    @Published private(set) var normalText = "0"
    @Published private(set) var highText = "0"
    @Published private(set) var lowText = "0"

    let toastMessage = PassthroughSubject<String, Never>()

    private let service: BloodSugarService
    private let periods = [7, 30, 90]

    init(service: BloodSugarService = AppContainer.shared.bloodSugarService) {
        self.service = service
    }

    var mealColumnTypes: [Int] {
        mealTypes.compactMap { $0.valueList?.intValue }
    }

    var mealColumnTitles: [String] {
        mealTypes.compactMap(\.name)
    }

    func load() {
        Task {
            do {
                if mealTypes.isEmpty {
                    mealTypes = try await service.fetchMealTypes()
                }
                let days = periods[selectedPeriodIndex]
                async let history = service.fetchHistory(days: days)
                async let stats = service.fetchStatistics()
                let (historyData, statistics) = try await (history, stats)
                self.days = historyData.monitors ?? []
                applyStats(statistics)
            } catch {
                days = []
                toastMessage.send(error.localizedDescription)
            }
        }
    }

    func rowValues(for day: BloodSugarMonitorDay) -> [(text: String, colorHex: String?)] {
        mealColumnTypes.map { type in
            let point = day.data?.first { $0.type?.value == type }
            return (point?.value?.value ?? " ", point?.color)
        }
    }

    private func applyStats(_ statistics: BloodPressureStatisticsData) {
        let stats: BloodPressurePeriodStats?
        switch selectedPeriodIndex {
        case 0: stats = statistics.seven
        case 1: stats = statistics.thirty
        default: stats = statistics.ninety
        }
        totalText = "\(stats?.total?.value ?? 0)"
        normalText = "\(stats?.normal?.value ?? 0)"
        highText = "\(stats?.high?.value ?? 0)"
        lowText = "\(stats?.low?.value ?? 0)"
    }
}
