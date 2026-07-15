import Combine
import Foundation

@MainActor
final class WeightHistoryLogViewModel: ObservableObject {

    @Published private(set) var items: [WeightLogItem] = []
    @Published var monthText = BloodPressureTime.monthString()
    @Published private(set) var isLoading = false
    @Published private(set) var hasMore = true

    let toastMessage = PassthroughSubject<String, Never>()

    private let service: WeightService
    private var pageNum = 1
    private var monthDate = Date()

    init(service: WeightService = AppContainer.shared.weightService) {
        self.service = service
    }

    func refresh() {
        pageNum = 1
        hasMore = true
        load(append: false)
    }

    func loadMore() {
        guard hasMore, !isLoading else { return }
        load(append: true)
    }

    func updateMonth(_ date: Date) {
        monthDate = date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        monthText = formatter.string(from: date)
        refresh()
    }

    private func load(append: Bool) {
        isLoading = true
        let currentPage = pageNum
        let stamp = monthMilliStamp(for: monthDate)
        Task {
            do {
                let list = try await service.fetchLogRecords(monthMilliStamp: stamp, pageNum: currentPage)
                if append {
                    items.append(contentsOf: list)
                } else {
                    items = list
                }
                hasMore = list.count >= WeightConstants.defaultPageSize
                if hasMore { pageNum = currentPage + 1 }
            } catch {
                if !append { items = [] }
                toastMessage.send(error.localizedDescription)
            }
            isLoading = false
        }
    }

    private func monthMilliStamp(for date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        var start = DateComponents()
        start.year = components.year
        start.month = components.month
        start.day = 1
        let monthStart = calendar.date(from: start) ?? date
        return BloodPressureTime.milliStamp(from: monthStart)
    }
}
