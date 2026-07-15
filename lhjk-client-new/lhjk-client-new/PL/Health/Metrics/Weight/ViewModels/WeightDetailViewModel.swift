import Combine
import Foundation

@MainActor
final class WeightDetailViewModel: ObservableObject {

    @Published private(set) var record: WeightRecord?
    @Published private(set) var isLoading = false
    @Published private(set) var isDeleting = false

    let deleteSucceeded = PassthroughSubject<Void, Never>()
    let toastMessage = PassthroughSubject<String, Never>()

    private let service: WeightService
    private let monitorId: String?

    init(monitorId: String?, service: WeightService = AppContainer.shared.weightService) {
        self.monitorId = monitorId
        self.service = service
    }

    func load() {
        isLoading = true
        Task {
            do {
                record = try await service.fetchHomePage(monitorId: monitorId)
            } catch {
                record = nil
                toastMessage.send(error.localizedDescription)
            }
            isLoading = false
        }
    }

    func delete() {
        guard let id = record?.monitorId?.value ?? monitorId else {
            toastMessage.send("无法删除：缺少记录 ID")
            return
        }
        isDeleting = true
        Task {
            do {
                try await service.deleteRecord(monitorId: id)
                NotificationCenter.default.post(name: .weightRecordDidDelete, object: nil)
                deleteSucceeded.send()
            } catch {
                toastMessage.send(error.localizedDescription)
            }
            isDeleting = false
        }
    }
}
