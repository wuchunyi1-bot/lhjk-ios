import Combine
import Foundation

@MainActor
final class WeightFundeViewModel: ObservableObject {

    @Published private(set) var allPoints: [WeightHistoryDataPoint] = []
    @Published private(set) var filteredPoints: [WeightHistoryDataPoint] = []
    @Published private(set) var logItems: [WeightLogItem] = []
    @Published private(set) var latest: WeightRecord?
    @Published var periodIndex = 1
    @Published private(set) var isLoading = false

    let toastMessage = PassthroughSubject<String, Never>()

    private let service: WeightService
    private let periodDays = [1, 7, 30]

    init(service: WeightService = AppContainer.shared.weightService) {
        self.service = service
    }

    var selectedDays: Int { periodDays[periodIndex] }

    var startWeight: Double? { filteredPoints.compactMap(\.weightValue).first }
    var currentWeight: Double? {
        if let w = latest?.weightDisplay, let value = Double(w) { return value }
        return filteredPoints.compactMap(\.weightValue).last
    }

    var maxWeight: Double? { filteredPoints.compactMap(\.weightValue).max() }
    var minWeight: Double? { filteredPoints.compactMap(\.weightValue).min() }
    var change: Double? {
        guard let max = maxWeight, let min = minWeight else { return nil }
        return max - min
    }

    var bmiText: String { latest?.bmiDisplay ?? "--" }

    func load() {
        isLoading = true
        Task {
            do {
                async let chart = service.fetchChartHistory()
                async let home = service.fetchHomePage()
                async let logs = service.fetchLogRecords(
                    monthMilliStamp: BloodPressureTime.milliStamp(
                        from: Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
                    ),
                    pageNum: 1,
                    pageSize: 10
                )
                let (points, record, items) = try await (chart, home, logs)
                allPoints = points
                latest = record
                logItems = items
                applyFilter()
            } catch {
                allPoints = []
                filteredPoints = []
                logItems = []
                latest = nil
                toastMessage.send(error.localizedDescription)
            }
            isLoading = false
        }
    }

    func applyFilter() {
        let days = selectedDays
        if days >= 1000 {
            filteredPoints = allPoints
            return
        }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        filteredPoints = allPoints.filter { point in
            guard let raw = point.dayStr ?? point.dateStr else { return true }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            for format in ["yyyy-MM-dd", "MM-dd", "yyyy.MM.dd", "MM.dd"] {
                formatter.dateFormat = format
                if let date = formatter.date(from: raw.split(separator: " ").first.map(String.init) ?? raw) {
                    if format.contains("yyyy") {
                        return date >= cutoff
                    }
                    var comps = Calendar.current.dateComponents([.month, .day], from: date)
                    comps.year = Calendar.current.component(.year, from: Date())
                    if let full = Calendar.current.date(from: comps) {
                        return full >= cutoff
                    }
                }
            }
            return true
        }
        if filteredPoints.isEmpty { filteredPoints = allPoints }
    }
}
