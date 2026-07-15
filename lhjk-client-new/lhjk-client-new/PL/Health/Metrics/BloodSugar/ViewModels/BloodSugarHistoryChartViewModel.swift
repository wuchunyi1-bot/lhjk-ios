import Combine
import Foundation

@MainActor
final class BloodSugarHistoryChartViewModel: ObservableObject {

    @Published private(set) var mealTypes: [BloodSugarMealType] = []
    @Published private(set) var points: [BloodSugarMonitorDay] = []
    @Published var selectedPeriodIndex = 0
    @Published var selectedMealIndex = 0
    @Published private(set) var chartTitle = ""

    let toastMessage = PassthroughSubject<String, Never>()

    private let service: BloodSugarService
    private let periods = [7, 30, 90]

    init(service: BloodSugarService = AppContainer.shared.bloodSugarService) {
        self.service = service
    }

    func load() {
        Task {
            do {
                if mealTypes.isEmpty {
                    mealTypes = try await service.fetchMealTypes()
                    chartTitle = mealTypes.first?.name ?? ""
                }
                guard mealTypes.indices.contains(selectedMealIndex) else { return }
                let mealType = mealTypes[selectedMealIndex].typeValue
                chartTitle = mealTypes[selectedMealIndex].name ?? ""
                let history = try await service.fetchHistory(
                    days: periods[selectedPeriodIndex],
                    mealType: mealType
                )
                points = history.monitors ?? []
            } catch {
                points = []
                toastMessage.send(error.localizedDescription)
            }
        }
    }
}
