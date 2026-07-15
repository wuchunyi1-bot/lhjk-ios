import Combine
import Foundation

@MainActor
final class BloodSugarDetailViewModel: ObservableObject {

    @Published private(set) var record: BloodSugarRecord?
    @Published private(set) var isDeleting = false

    let deleteSucceeded = PassthroughSubject<Void, Never>()
    let toastMessage = PassthroughSubject<String, Never>()

    private let service: BloodSugarService
    private let monitorId: String?
    private let sugarId: String?

    init(monitorId: String?, sugarId: String?, service: BloodSugarService = AppContainer.shared.bloodSugarService) {
        self.monitorId = monitorId
        self.sugarId = sugarId
        self.service = service
    }

    func load() {
        Task {
            do {
                record = try await service.fetchHomePage(monitorId: monitorId, sugarId: sugarId)
            } catch {
                record = nil
                toastMessage.send(error.localizedDescription)
            }
        }
    }

    func delete() {
        guard let id = record?.monitorId?.value ?? monitorId else {
            toastMessage.send("无法删除：缺少记录 ID")
            return
        }
        let sugar = record?.id?.value ?? sugarId
        isDeleting = true
        Task {
            do {
                try await service.deleteRecord(monitorId: id, sugarId: sugar)
                NotificationCenter.default.post(name: .bloodSugarRecordDidDelete, object: nil)
                deleteSucceeded.send()
            } catch {
                toastMessage.send(error.localizedDescription)
            }
            isDeleting = false
        }
    }
}
