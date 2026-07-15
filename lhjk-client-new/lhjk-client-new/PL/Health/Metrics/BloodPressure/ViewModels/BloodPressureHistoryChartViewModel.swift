import Combine
import Foundation

@MainActor
final class BloodPressureHistoryChartViewModel: ObservableObject {

    @Published private(set) var points: [BloodPressureChartPoint] = []
    @Published var selectedPeriodIndex = 0
    @Published private(set) var isLoading = false

    let toastMessage = PassthroughSubject<String, Never>()

    private let service: BloodPressureService
    private let periods = [7, 30, 90]

    init(service: BloodPressureService = AppContainer.shared.bloodPressureService) {
        self.service = service
    }

    var selectedDays: Int { periods[selectedPeriodIndex] }

    func load() {
        isLoading = true
        Task {
            do {
                points = try await service.fetchChartHistory(days: selectedDays)
            } catch {
                points = []
                toastMessage.send(error.localizedDescription)
            }
            isLoading = false
        }
    }
}
