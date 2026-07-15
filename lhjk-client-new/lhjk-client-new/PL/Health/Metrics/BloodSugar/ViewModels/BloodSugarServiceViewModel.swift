import Combine
import Foundation

@MainActor
final class BloodSugarServiceViewModel: ObservableObject {

    @Published private(set) var record: BloodSugarRecord?
    @Published private(set) var stateText = ""
    @Published private(set) var dateText = ""
    @Published private(set) var diabetesTypeText = "--"
    @Published private(set) var adviceTitle = "还没有您的血糖记录"
    @Published private(set) var adviceContent = "请按时测量血糖，记录不同餐次的数据，有助于了解血糖变化趋势。"
    @Published private(set) var showsAdviceMore = false
    @Published private(set) var equipment: BloodPressureEquipment?

    let toastMessage = PassthroughSubject<String, Never>()

    private let service: BloodSugarService

    init(service: BloodSugarService = AppContainer.shared.bloodSugarService) {
        self.service = service
    }

    func load() {
        Task {
            do {
                async let home = service.fetchHomePage()
                async let devices = service.fetchBoundEquipments()
                let (record, list) = try await (home, devices)
                self.record = record
                self.equipment = list.first
                self.stateText = record.monitorResults ?? ""
                self.dateText = record.formattedRecordTime
                if let desc = record.description, !desc.isEmpty {
                    self.adviceTitle = "血糖建议"
                    self.adviceContent = desc
                    self.showsAdviceMore = true
                } else {
                    self.adviceTitle = "还没有您的血糖记录"
                    self.adviceContent = "请按时测量血糖，记录不同餐次的数据，有助于了解血糖变化趋势。"
                    self.showsAdviceMore = record.monitorId?.value != nil
                }
            } catch {
                self.record = nil
                self.toastMessage.send(error.localizedDescription)
            }
        }
    }
}
