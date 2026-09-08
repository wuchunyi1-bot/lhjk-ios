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

    /// 当前登录用户：Figma 展示灰色「我」，不用医护角色胶囊
    func isSelf(_ member: ImSessionDetails) -> Bool {
        let role = member.roleName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if role == "我" { return true }
        let myId = UserManager.shared.currentUser?.id?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let memberId = member.userId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !myId.isEmpty && myId == memberId
    }

    func loadMembers() async {
        let trimmed = groupId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            await MainActor.run {
                members = []
                isEmpty = true
                isLoading = false
            }
            return
        }
        await MainActor.run {
            isLoading = true
        }
        do {
            let list = try await imService.fetchGroupMembers(groupId: trimmed)
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
