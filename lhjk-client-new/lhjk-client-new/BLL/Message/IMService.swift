import Foundation

/// IM 业务服务 — 会话管理 / 消息收发
/// V1.0 mock 实现，数据来源 funde-im prototype/src/mock/
final class IMService {

    static let shared = IMService()

    private var conversations: [Conversation] = Conversation.mockData()
    private var messagesStore: [String: [Message]] = [:]

    private init() {}

    // MARK: - Conversations

    func getConversations(filterBy tag: ConversationTag? = nil) -> [Conversation] {
        let filtered = tag.map { t in conversations.filter { $0.tags.contains(t) } } ?? conversations
        return filtered.sorted { $0.lastMessageAt > $1.lastMessageAt }
    }

    func markAsRead(_ conversationId: String) {
        if let idx = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[idx].unreadCount = 0
        }
    }

    func deleteConversation(_ conversationId: String) {
        conversations.removeAll { $0.id == conversationId }
    }

    // MARK: - Messages

    func getMessages(conversationId: String) -> [Message] {
        if messagesStore[conversationId] == nil {
            messagesStore[conversationId] = Message.mockMessages(for: conversationId)
        }
        return messagesStore[conversationId] ?? []
    }

    func sendMessage(_ text: String, conversationId: String) -> Message {
        let msg = Message(
            id: "MSG_SEND_\(UUID().uuidString.prefix(8))",
            conversationId: conversationId,
            type: .text,
            sender: .patient,
            senderName: nil, senderRole: nil, avatarText: nil,
            content: text,
            payload: nil,
            createdAt: Date(),
            recalled: false,
            status: .sending
        )
        messagesStore[conversationId, default: []].append(msg)

        // Simulate delivery
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if let idx = self?.messagesStore[conversationId]?.firstIndex(where: { $0.id == msg.id }) {
                self?.messagesStore[conversationId]?[idx].status = .sent
            }
        }
        return msg
    }
}
