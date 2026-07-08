import Foundation
import Combine

/// 团队对话列表 ViewModel — 会话数据、实时订阅、增量/批量/全量刷新
final class ConversationListViewModel: ObservableObject {

    // MARK: - Published State

    @Published var conversations: [Conversation] = []
    var totalUnread: Int { conversations.reduce(0) { $0 + $1.unread } }

    // MARK: - Dependencies

    private let imService: IMService
    private let rongCloudManager: RongCloudManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(imService: IMService = .shared,
         rongCloudManager: RongCloudManager = .shared) {
        self.imService = imService
        self.rongCloudManager = rongCloudManager
        setupSubscriptions()
    }

    // MARK: - Subscriptions

    private func setupSubscriptions() {
        // 收到新消息 → 局部更新
        rongCloudManager.messageReceivedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                self?.handleConversationUpdate(conversationId: msg.conversationId)
            }
            .store(in: &cancellables)

        // 远端会话同步完成 → 全量刷新
        rongCloudManager.remoteConversationListDidSyncPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.forceReload()
            }
            .store(in: &cancellables)

        // 多端会话同步 → 批量局部更新
        rongCloudManager.conversationDidSyncPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleBatchConversationUpdate()
            }
            .store(in: &cancellables)

        // 自己发送消息成功 → 局部更新
        rongCloudManager.messageSentPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] convId in
                self?.handleConversationUpdate(conversationId: convId)
            }
            .store(in: &cancellables)

        // 会话被标记已读 → 局部更新
        imService.conversationMarkedReadPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] convId in
                self?.handleConversationUpdate(conversationId: convId)
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading

    func loadData() {
        if imService.hasLoadedConversations {
            conversations = imService.getConversations()
            return
        }
        forceReload()
    }

    func forceReload() {
        Task {
            let list = await imService.loadConversations()
            await MainActor.run {
                self.conversations = list
            }
        }
    }

    // MARK: - Incremental Updates

    private func handleConversationUpdate(conversationId: String?) {
        guard let convId = conversationId else { return }
        Task {
            if let updated = await imService.updateConversation(id: convId) {
                await MainActor.run {
                    var list = self.conversations
                    list.removeAll { $0.id == convId }
                    list.insert(updated, at: 0)
                    self.conversations = list
                }
            } else {
                await MainActor.run { self.forceReload() }
            }
        }
    }

    private func handleBatchConversationUpdate() {
        Task {
            var list = self.conversations
            var anyChanged = false
            for i in list.indices {
                if let updated = await imService.updateConversation(id: list[i].id) {
                    list[i] = updated
                    anyChanged = true
                }
            }
            if anyChanged {
                await MainActor.run { self.conversations = list }
            }
        }
    }

    // MARK: - Actions

    func markAsRead(_ conversationId: String) {
        imService.markAsRead(conversationId)
    }
}
