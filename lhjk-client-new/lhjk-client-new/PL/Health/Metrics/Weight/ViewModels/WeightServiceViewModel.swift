import Combine
import Foundation

@MainActor
final class WeightServiceViewModel: ObservableObject {

    @Published private(set) var record: WeightRecord?
    @Published private(set) var stateText = ""
    @Published private(set) var dateText = ""
    @Published private(set) var adviceTitle = "还没有您的体重记录"
    @Published private(set) var adviceContent = "建议每天固定时间测量体重，记录变化趋势。测量前请排空膀胱，穿着轻便衣物。"
    @Published private(set) var showsAdviceMore = false
    @Published private(set) var equipment: BloodPressureEquipment?
    @Published private(set) var isLoading = false

    let toastMessage = PassthroughSubject<String, Never>()

    private let service: WeightService
    private var loadTask: Task<Void, Never>?

    init(service: WeightService = AppContainer.shared.weightService) {
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
                    self.adviceTitle = "体重建议"
                    self.adviceContent = desc
                    self.showsAdviceMore = true
                } else {
                    self.adviceTitle = "还没有您的体重记录"
                    self.adviceContent = "建议每天固定时间测量体重，记录变化趋势。测量前请排空膀胱，穿着轻便衣物。"
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
