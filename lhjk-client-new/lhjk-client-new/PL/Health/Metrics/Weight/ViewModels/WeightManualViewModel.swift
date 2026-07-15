import Combine
import Foundation

@MainActor
final class WeightManualViewModel: ObservableObject {

    @Published var weightText = "60.0"
    @Published var bmiText = "BMI --"
    @Published var dateText = BloodPressureTime.displayString(from: Date())
    @Published var tipText = " "
    @Published private(set) var isSaving = false

    let saveSucceeded = PassthroughSubject<String, Never>()
    let toastMessage = PassthroughSubject<String, Never>()

    var selectedDate = Date()
    private(set) var weightKg: Double = 60.0

    private let service: WeightService

    init(service: WeightService = AppContainer.shared.weightService) {
        self.service = service
    }

    func loadAdvice() {
        Task {
            do {
                let record = try await service.fetchHomePage()
                tipText = record.description ?? " "
            } catch { }
        }
    }

    func updateWeight(_ value: Double) {
        weightKg = value
        weightText = String(format: "%.1f", value)
        if let bmi = WeightBMI.calculate(weightKg: value, heightCm: nil) {
            bmiText = "BMI \(bmi)"
        } else {
            bmiText = "BMI --"
        }
    }

    func updateDate(_ date: Date) {
        selectedDate = date
        dateText = BloodPressureTime.displayString(from: date)
    }

    func save() {
        isSaving = true
        Task {
            do {
                let monitorId = try await service.saveRecord(
                    weightKg: weightKg,
                    recordTime: selectedDate,
                    collectionType: .manual
                )
                toastMessage.send("保存成功")
                saveSucceeded.send(monitorId)
            } catch {
                toastMessage.send(error.localizedDescription)
            }
            isSaving = false
        }
    }
}
