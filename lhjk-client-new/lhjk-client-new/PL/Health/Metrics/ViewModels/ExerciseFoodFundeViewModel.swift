import Combine
import Foundation

@MainActor
final class ExerciseFoodFundeViewModel: ObservableObject {

    @Published private(set) var summary: ExerciseFoodDaySummary?
    @Published private(set) var isLoading = false

    let toastMessage = PassthroughSubject<String, Never>()

    private let service: ExerciseFoodService

    init(service: ExerciseFoodService = AppContainer.shared.exerciseFoodService) {
        self.service = service
    }

    var intakeText: String { summary?.intake?.value ?? "--" }

    var remainLabel: String {
        let remaining = Double(summary?.remainingIntake?.value ?? "") ?? 0
        return ExerciseFoodCalorieCenter.title(
            recommendCalories: summary?.recommendCalories,
            remaining: remaining
        )
    }

    var remainValue: String {
        ExerciseFoodCalorieCenter.valueText(remainingRaw: summary?.remainingIntake?.value)
    }

    var sportConsume: String { summary?.sport?.consumeNum?.value ?? "--" }

    /// 估算展示目标：摄入 + remaining（有方案时）；无方案仅展示摄入
    var targetHint: String {
        let intake = Double(summary?.intake?.value ?? "") ?? 0
        let remaining = Double(summary?.remainingIntake?.value ?? "") ?? 0
        if summary?.recommendCalories != nil {
            let target = max(intake + remaining, 0)
            return String(format: "%.0f", target)
        }
        return "--"
    }

    func load() {
        isLoading = true
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.string(from: Date())
        Task {
            do {
                summary = try await service.fetchDaySummary(date: date)
            } catch {
                summary = nil
                toastMessage.send(error.localizedDescription)
            }
            isLoading = false
        }
    }
}
