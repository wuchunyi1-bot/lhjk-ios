import Combine
import Foundation

@MainActor
final class BloodSugarFundeViewModel: ObservableObject {

    struct ChartDay: Equatable {
        let label: String
        let fasting: Double?
        let postMeal: Double?
        let anyValue: Double?
    }

    @Published private(set) var chartDays: [ChartDay] = []
    @Published private(set) var logItems: [BloodSugarLogItem] = []
    @Published var periodIndex = 1
    @Published private(set) var isLoading = false

    let toastMessage = PassthroughSubject<String, Never>()

    private let service: BloodSugarService
    private let periodDays = [1, 7, 30]

    init(service: BloodSugarService = AppContainer.shared.bloodSugarService) {
        self.service = service
    }

    var selectedDays: Int { periodDays[periodIndex] }

    var maxValue: Double? {
        let values = chartDays.flatMap { [$0.fasting, $0.postMeal, $0.anyValue].compactMap { $0 } }
        return values.max()
    }

    var minValue: Double? {
        let values = chartDays.flatMap { [$0.fasting, $0.postMeal, $0.anyValue].compactMap { $0 } }
        return values.min()
    }

    var variation: Double? {
        guard let max = maxValue, let min = minValue else { return nil }
        return max - min
    }

    func load() {
        isLoading = true
        let days = selectedDays
        Task {
            do {
                async let history = service.fetchHistory(days: days)
                async let logs = service.fetchLogRecords(
                    monthMilliStamp: BloodPressureTime.milliStamp(
                        from: Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
                    ),
                    pageNum: 1,
                    pageSize: 10
                )
                let (hist, items) = try await (history, logs)
                chartDays = Self.mapChartDays(hist.monitors ?? [])
                logItems = items
            } catch {
                chartDays = []
                logItems = []
                toastMessage.send(error.localizedDescription)
            }
            isLoading = false
        }
    }

    private static func mapChartDays(_ monitors: [BloodSugarMonitorDay]) -> [ChartDay] {
        monitors.map { day in
            var fasting: Double?
            var postMeal: Double?
            var anyValue: Double?
            for point in day.data ?? [] {
                let value = point.value?.value.flatMap(Double.init)
                anyValue = anyValue ?? value
                let remark = point.typeRemark ?? ""
                if remark.contains("空腹") || point.type?.value == 1 {
                    fasting = value
                } else if remark.contains("餐后") || remark.contains("午餐") || remark.contains("晚餐") {
                    postMeal = postMeal ?? value
                }
            }
            return ChartDay(label: day.chartLabel, fasting: fasting, postMeal: postMeal, anyValue: anyValue)
        }
    }
}
