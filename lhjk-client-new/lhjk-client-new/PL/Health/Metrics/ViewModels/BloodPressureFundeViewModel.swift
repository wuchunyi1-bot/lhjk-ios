import Combine
import Foundation

@MainActor
final class BloodPressureFundeViewModel: ObservableObject {

    @Published private(set) var chartPoints: [BloodPressureChartPoint] = []
    @Published private(set) var logItems: [BloodPressureLogItem] = []
    @Published var periodIndex = 1
    @Published private(set) var isLoading = false

    let toastMessage = PassthroughSubject<String, Never>()

    private let service: BloodPressureService
    private let periodDays = [1, 7, 30]

    init(service: BloodPressureService = AppContainer.shared.bloodPressureService) {
        self.service = service
    }

    var selectedDays: Int { periodDays[periodIndex] }

    var avgSystolic: Int? {
        let values = chartPoints.compactMap { $0.highBloodPressure?.value }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / values.count
    }

    var avgDiastolic: Int? {
        let values = chartPoints.compactMap { $0.lowBloodPressure?.value }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / values.count
    }

    var avgHeartRate: Int? {
        let values = chartPoints.compactMap { $0.heartRate?.value }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / values.count
    }

    func load() {
        isLoading = true
        let days = selectedDays
        Task {
            do {
                async let chart = service.fetchChartHistory(days: days)
                async let logs = service.fetchLogRecords(
                    monthMilliStamp: BloodPressureTime.milliStamp(
                        from: Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
                    ),
                    pageNum: 1,
                    pageSize: 10
                )
                let (points, items) = try await (chart, logs)
                chartPoints = points
                logItems = items
            } catch {
                chartPoints = []
                logItems = []
                toastMessage.send(error.localizedDescription)
            }
            isLoading = false
        }
    }
}
