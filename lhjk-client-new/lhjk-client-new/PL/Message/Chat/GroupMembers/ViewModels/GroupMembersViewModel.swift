import Foundation
import Combine

/// 群成员列表 ViewModel — `GET /v1/session/getGroupMembers`
final class GroupMembersViewModel: ObservableObject {

    @Published var members: [ImSessionDetails] = []
    @Published var isLoading = true
    @Published var isEmpty = true

    let toastPublisher = PassthroughSubject<String, Never>()

    let groupId: String
    private let imService: IMService

    init(groupId: String, imService: IMService = AppContainer.shared.imService) {
        self.groupId = groupId
        self.imService = imService
    }

    func loadMembers() async {
        await MainActor.run {
            isLoading = true
        }
        do {
            let data = try await imService.fetchGroupMembers(groupId: groupId)
            let list = data.list ?? []
            await MainActor.run {
                members = list
                isEmpty = list.isEmpty
                isLoading = false
            }
        } catch {
            await MainActor.run {
                members = []
                isEmpty = true
                isLoading = false
                toastPublisher.send(error.localizedDescription)
            }
        }
    }
}
