import Foundation
import RongIMLibCore

/// IM 业务服务 — 会话 / 消息 / 通知管理
///
/// 会话列表优先从融云 SDK 获取真实数据，融云未连接时 fallback 到 mock 数据
final class IMService {

    static let shared = IMService()

    private var conversations: [Conversation] = []
    private var notifications: [AppNotification] = AppNotification.mockData()
    private var messagesStore: [String: [ChatMessage]] = [:]

    private init() {}

    // MARK: - Conversations

    /// 两步合并加载会话列表：
    /// 1. `GET /mobile/v1/session/getGroup` 获取群组元数据
    /// 2. 用 groupId 列表调融云 `getConversations` 批量查询本地会话
    /// 3. 以融云返回数据为基准遍历，匹配 GroupVO 元数据，按 sentTime 倒序排列
    /// 失败时 fallback 到 mock 数据
    func loadConversations() async -> [Conversation] {
        let isConnected = RongCloudManager.shared.connectionStatus == .connected

        // Step 1: 获取群组列表 → 构建 groupId → GroupVO 查找表
        let groupDict: [String: GroupVO]
        do {
            let response: GroupListResponse = try await APIManager.shared
                .getAsync(path: "/mobile/v1/session/getGroup", parameters: nil, responseType: GroupListResponse.self)
            if response.isSuccess, let data = response.data {
                var dict: [String: GroupVO] = [:]
                for g in data {
                    if let gid = g.groupId { dict[gid] = g }
                }
                groupDict = dict
            } else {
                print("[IMService] getGroup ✗ code=\(response.code)")
                conversations = Conversation.mockData()
                return conversations
            }
        } catch {
            print("[IMService] getGroup ✗ error: \(error.localizedDescription)")
            conversations = Conversation.mockData()
            return conversations
        }
        print("groupDict ====  \(groupDict)")
        guard !groupDict.isEmpty else {
            conversations = Conversation.mockData()
            return conversations
        }

        // Step 2: 提取 groupId 列表，批量查融云本地会话
        let groupIds = Array(groupDict.keys)
        print("groupIds ====  \(groupIds)")
        if isConnected {
            let rcList: [RCConversation] = await withCheckedContinuation { continuation in
                RongCloudManager.shared.getConversations(by: groupIds) { list in
                    continuation.resume(returning: list)
                }
            }

            // Step 3: 以融云返回数据为基准遍历，按 sentTime 倒序
            let sortedRC = rcList.sorted { $0.sentTime > $1.sentTime }
            let list: [Conversation] = sortedRC.map { rc in
                if let group = groupDict[rc.targetId] {
                    return Conversation.fromGroupVO(group, rc: rc)
                } else {
                    // 融云有会话但群组 API 未返回 → fallback 元数据
                    return Conversation.fromRongCloud(rc)
                }
            }

            conversations = list
        } else {
            conversations = Conversation.mockData()
        }

        return conversations
    }

    func getConversations() -> [Conversation] {
        if conversations.isEmpty {
            conversations = Conversation.mockData()
        }
        return conversations
    }

    /// 团队对话总未读数
    func totalUnreadCount() -> Int {
        conversations.reduce(0) { $0 + $1.unread }
    }

    /// 通知未读数
    func notiUnreadCount() -> Int {
        notifications.filter { $0.unread }.count
    }

    func markAsRead(_ conversationId: String) {
        if let idx = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[idx].unread = 0
        }
    }

    func deleteConversation(_ conversationId: String) {
        conversations.removeAll { $0.id == conversationId }
    }

    // MARK: - Notifications

    func getNotifications() -> [AppNotification] {
        notifications
    }

    func markNotificationsRead() {
        for i in notifications.indices { notifications[i].unread = false }
    }

    // MARK: - Messages

    func getMessages(conversationId: String) -> [ChatMessage] {
        if messagesStore[conversationId] == nil {
            messagesStore[conversationId] = ChatMessage.mockMessages(for: conversationId)
        }
        return messagesStore[conversationId] ?? []
    }

    func sendMessage(_ text: String, conversationId: String) -> ChatMessage {
        let msg = ChatMessage(
            id: "local-\(Int(Date().timeIntervalSince1970 * 1000))",
            type: .text,
            role: .user,
            senderName: nil,
            senderRole: nil,
            avatar: nil,
            text: text,
            time: "刚刚",
            card: nil,
            meal: nil,
            report: nil
        )
        messagesStore[conversationId, default: []].append(msg)
        return msg
    }
}
