import Combine
import Foundation

@MainActor
final class BloodSugarManualViewModel: ObservableObject {

    @Published private(set) var mealTypes: [BloodSugarMealType] = []
    @Published var selectedMealIndex = 0
    @Published var valueText = "6.0"
    @Published var tipText = ""
    @Published var dateText = BloodPressureTime.displayString(from: Date())
    @Published private(set) var isSaving = false

    let saveSucceeded = PassthroughSubject<BloodSugarSaveResult, Never>()
    let duplicateConfirm = PassthroughSubject<String, Never>()
    let toastMessage = PassthroughSubject<String, Never>()

    var selectedDate = Date()

    private let service: BloodSugarService

    init(service: BloodSugarService = AppContainer.shared.bloodSugarService) {
        self.service = service
    }

    var selectedMealType: BloodSugarMealType? {
        guard mealTypes.indices.contains(selectedMealIndex) else { return nil }
        return mealTypes[selectedMealIndex]
    }

    func load() {
        Task {
            do {
                let types = try await service.fetchMealTypes()
                mealTypes = types.filter(\.isVisibleOnMeasurePage)
                if let checkedIndex = mealTypes.firstIndex(where: { $0.checked == true }) {
                    selectedMealIndex = checkedIndex
                }
                updateTip()
                let record = try await service.fetchHomePage()
                if let value = record.value?.value, !value.isEmpty {
                    valueText = value
                }
            } catch {
                toastMessage.send(error.localizedDescription)
            }
        }
    }

    func selectMeal(at index: Int) {
        selectedMealIndex = index
        updateTip()
    }

    func updateValue(_ value: Double) {
        valueText = String(format: "%.1f", value)
    }

    func updateDate(_ date: Date) {
        selectedDate = date
        dateText = BloodPressureTime.displayString(from: date)
    }

    func save(submitTimes: Int = 1) {
        guard let mealType = selectedMealType else {
            toastMessage.send("餐次有误")
            return
        }
        isSaving = true
        Task {
            do {
                let result = try await service.saveRecord(
                    value: valueText,
                    mealType: mealType,
                    recordTime: selectedDate,
                    collectionType: .manual,
                    submitTimes: submitTimes
                )
                toastMessage.send("保存成功")
                saveSucceeded.send(result)
            } catch let error as BloodSugarServiceError {
                switch error {
                case .duplicateRecord(let message):
                    duplicateConfirm.send(message)
                case .apiFailed(let message):
                    toastMessage.send(message)
                }
            } catch {
                toastMessage.send(error.localizedDescription)
            }
            isSaving = false
        }
    }

    private func updateTip() {
        tipText = selectedMealType?.standardRangeText ?? ""
    }
}
