import Combine
import Foundation

@MainActor
final class BloodPressureManualViewModel: ObservableObject {

    @Published var systolicText = "--"
    @Published var diastolicText = "--"
    @Published var heartText = "--"
    @Published var dateText = BloodPressureTime.displayString(from: Date())
    @Published var tipText = " "
    @Published private(set) var isSaving = false

    let saveSucceeded = PassthroughSubject<String, Never>()
    let toastMessage = PassthroughSubject<String, Never>()

    var selectedDate = Date()

    private let service: BloodPressureService

    init(service: BloodPressureService = AppContainer.shared.bloodPressureService) {
        self.service = service
    }

    func loadAdvice() {
        Task {
            do {
                let record = try await service.fetchHomePage()
                tipText = record.description ?? " "
            } catch {
                // 静默失败，不影响手动录入
            }
        }
    }

    func updateSelection(_ selection: BloodPressureValuePickerView.Selection) {
        systolicText = String(selection.systolic)
        diastolicText = String(selection.diastolic)
        heartText = String(selection.heartRate)
    }

    func updateDate(_ date: Date) {
        selectedDate = date
        dateText = BloodPressureTime.displayString(from: date)
    }

    func save(selection: BloodPressureValuePickerView.Selection?) {
        guard let selection else {
            toastMessage.send("请选择收缩压、舒张压、心率")
            return
        }
        isSaving = true
        Task {
            do {
                let monitorId = try await service.saveRecord(
                    systolic: selection.systolic,
                    diastolic: selection.diastolic,
                    heartRate: selection.heartRate,
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
