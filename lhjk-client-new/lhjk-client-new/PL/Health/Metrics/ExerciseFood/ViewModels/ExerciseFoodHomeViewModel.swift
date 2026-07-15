import Combine
import Foundation

@MainActor
final class ExerciseFoodHomeViewModel: ObservableObject {

    struct Section: Identifiable, Equatable {
        let id: String
        let title: String
        let hint: String?
        let consume: String?
        let isSport: Bool
        let items: [ExerciseFoodRecordItem]
    }

    @Published private(set) var summary: ExerciseFoodDaySummary?
    @Published private(set) var sections: [Section] = []
    @Published var selectedDate = Date()
    @Published private(set) var dateText = ""
    @Published private(set) var isLoading = false

    let toastMessage = PassthroughSubject<String, Never>()

    private let service: ExerciseFoodService
    private let calendar = Calendar.current

    init(service: ExerciseFoodService = AppContainer.shared.exerciseFoodService) {
        self.service = service
        updateDateText()
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }

    var canGoNext: Bool {
        !calendar.isDateInToday(selectedDate)
    }

    func load() {
        isLoading = true
        updateDateText()
        Task {
            do {
                let data = try await service.fetchDaySummary(date: dateString)
                summary = data
                sections = buildSections(from: data)
            } catch {
                summary = nil
                sections = []
                toastMessage.send(error.localizedDescription)
            }
            isLoading = false
        }
    }

    func shiftDay(by offset: Int) {
        guard let date = calendar.date(byAdding: .day, value: offset, to: selectedDate) else { return }
        if date > Date() { return }
        selectedDate = date
        load()
    }

    func setDate(_ date: Date) {
        selectedDate = min(date, Date())
        load()
    }

    func delete(item: ExerciseFoodRecordItem) {
        guard let monitorId = item.monitorId?.value else {
            toastMessage.send("无法删除：缺少记录 ID")
            return
        }
        Task {
            do {
                try await service.deleteRecord(monitorId: monitorId)
                NotificationCenter.default.post(name: .exerciseFoodRecordDidChange, object: nil)
                load()
            } catch {
                toastMessage.send(error.localizedDescription)
            }
        }
    }

    func update(item: ExerciseFoodRecordItem, quantity: Int, calorie: String, isSport: Bool) {
        let businessId = isSport ? ExerciseFoodConstants.sportBusinessId : ExerciseFoodConstants.dietBusinessId
        Task {
            do {
                try await service.updateRecord(
                    item: item,
                    quantity: quantity,
                    calorie: calorie,
                    businessId: businessId,
                    timeType: item.timeType?.value
                )
                NotificationCenter.default.post(name: .exerciseFoodRecordDidChange, object: nil)
                load()
            } catch {
                toastMessage.send(error.localizedDescription)
            }
        }
    }

    private func updateDateText() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年MM月dd日"
        dateText = formatter.string(from: selectedDate)
    }

    private func buildSections(from summary: ExerciseFoodDaySummary) -> [Section] {
        var result: [Section] = []
        for meal in MealTimeType.allCases {
            guard let section = summary.diet?.first(where: { $0.timeType?.value == meal.rawValue }),
                  let items = section.list, !items.isEmpty else { continue }
            result.append(Section(
                id: "diet-\(meal.rawValue)",
                title: meal.title,
                hint: nil,
                consume: section.consumeNum?.value,
                isSport: false,
                items: items
            ))
        }
        if let sport = summary.sport, let items = sport.list, !items.isEmpty {
            result.append(Section(
                id: "sport",
                title: "运动",
                hint: summary.recommendCalories,
                consume: sport.consumeNum?.value,
                isSport: true,
                items: items
            ))
        }
        return result
    }
}
