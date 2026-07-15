import Combine
import Foundation

@MainActor
final class BloodPressureServiceViewModel: ObservableObject {

    @Published private(set) var record: BloodPressureRecord?
    @Published private(set) var stateText = "正常"
    @Published private(set) var dateText = ""
    @Published private(set) var adviceTitle = "还没有您的血压记录"
    @Published private(set) var adviceContent = "测量血压前，测量者至少安静休息5分钟。测量需要坐位或卧位。注意肢体放松，袖带大小合适。"
    @Published private(set) var showsAdviceMore = false
    @Published private(set) var equipment: BloodPressureEquipment?
    @Published private(set) var isLoading = false

    let toastMessage = PassthroughSubject<String, Never>()

    private let service: BloodPressureService
    private var loadTask: Task<Void, Never>?

    init(service: BloodPressureService = AppContainer.shared.bloodPressureService) {
        self.service = service
    }

    deinit { loadTask?.cancel() }

    func load() {
        loadTask?.cancel()
        isLoading = true
        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                async let home = service.fetchHomePage()
                async let devices = service.fetchBoundEquipments()
                let (record, list) = try await (home, devices)
                self.record = record
                self.equipment = list.first
                self.stateText = record.monitorResults ?? ""
                self.dateText = record.formattedRecordTime
                if let desc = record.description, !desc.isEmpty {
                    self.adviceTitle = "血压建议"
                    self.adviceContent = desc
                    self.showsAdviceMore = true
                } else {
                    self.adviceTitle = "还没有您的血压记录"
                    self.adviceContent = "测量血压前，测量者至少安静休息5分钟。测量需要坐位或卧位。注意肢体放松，袖带大小合适。"
                    self.showsAdviceMore = record.monitorId?.value != nil
                }
            } catch {
                self.record = nil
                self.stateText = ""
                self.dateText = ""
                if !Task.isCancelled {
                    self.toastMessage.send(error.localizedDescription)
                }
            }
            self.isLoading = false
        }
    }
}
