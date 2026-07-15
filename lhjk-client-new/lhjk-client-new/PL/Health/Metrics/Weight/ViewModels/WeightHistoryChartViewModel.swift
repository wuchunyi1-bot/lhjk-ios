import Combine
import Foundation

@MainActor
final class WeightHistoryChartViewModel: ObservableObject {

    @Published private(set) var points: [WeightHistoryDataPoint] = []
    @Published private(set) var isLoading = false

    let toastMessage = PassthroughSubject<String, Never>()

    private let service: WeightService

    init(service: WeightService = AppContainer.shared.weightService) {
        self.service = service
    }

    func load() {
        isLoading = true
        Task {
            do {
                points = try await service.fetchChartHistory()
            } catch {
                points = []
                toastMessage.send(error.localizedDescription)
            }
            isLoading = false
        }
    }
}
