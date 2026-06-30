import Foundation
import Combine
import RongIMLibCore

/// IM 业务服务 — 会话 / 消息 / 通知管理
///
/// 会话列表优先从融云 SDK 获取真实数据，融云未连接时 fallback 到 mock 数据
final class IMService {

    static let shared = IMService()

    private var conversations: [Conversation] = []
    private var notifications: [AppNotification] = AppNotification.mockData()
    private var messagesStore: [String: [ChatMessage]] = [:]

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // 订阅实时消息，按 conversationId 缓存
        RongCloudManager.shared.messageReceivedPublisher
            .sink { [weak self] msg in
                self?.onMessageReceived(msg)
            }
            .store(in: &cancellables)
    }

    private func onMessageReceived(_ msg: ChatMessage) {
        guard let convId = msg.conversationId else { return }
        messagesStore[convId, default: []].append(msg)
        print("[IMService] real-time message received for conv=\(convId)")
    }

    // MARK: - Conversations

    /// 测试方法：获取所有会话列表，打印会话 ID 和会话类型
    /// 与 loadConversations() 并行调用以验证数据
    func testFetchAllConversations() async {
        let list: [RCConversation] = await withCheckedContinuation { continuation in
            RongCloudManager.shared.getConversationList { conversations in
                continuation.resume(returning: conversations)
            }
        }
        print("[IMService] ===== 会话列表测试 =====")
        for conv in list {
            let typeStr: String
            switch conv.conversationType {
            case .ConversationType_PRIVATE: typeStr = "单聊"
            case .ConversationType_GROUP:   typeStr = "群聊"
            default:                        typeStr = "其他(\(conv.conversationType.rawValue))"
            }
            print("[IMService] conv id=\(conv.targetId), type=\(typeStr), unread=\(conv.unreadMessageCount)")
        }
        print("[IMService] 共 \(list.count) 个会话")
    }

    /// 两步合并加载会话列表：
    /// 1. `GET /mobile/v1/session/getGroup` 获取群组元数据
    /// 2. 用 groupId 列表调融云 `getConversations` 批量查询本地会话
    /// 3. 匹配上融云的在前展示（按 sentTime 倒序），未匹配的 GroupVO 在后展示
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
//                print("[IMService] getGroup ✗ code=\(response.code)")
                conversations = Conversation.mockData()
                return conversations
            }
        } catch {
//            print("[IMService] getGroup ✗ error: \(error.localizedDescription)")
            conversations = Conversation.mockData()
            return conversations
        }
//        print("groupDict ====  \(groupDict)")
        guard !groupDict.isEmpty else {
            conversations = Conversation.mockData()
            return conversations
        }

        // Step 2: 提取 groupId 列表，批量查融云本地会话
        let groupIds = Array(groupDict.keys)
//        print("groupIds ====  \(groupIds)")
        if isConnected {
            let rcList: [RCConversation] = await withCheckedContinuation { continuation in
                RongCloudManager.shared.getConversations(by: groupIds) { list in
                    continuation.resume(returning: list)
                }
            }

            // Step 3: 匹配融云的在前展示，未匹配的在后
            // 先按 sentTime 倒序排列融云返回的会话
            let sortedRC = rcList.sorted { $0.sentTime > $1.sentTime }
            var matchedIds = Set<String>()

            // 匹配上融云的会话（RCConversation + GroupVO），在前展示
            var matchedList: [Conversation] = []
            for rc in sortedRC {
                if let group = groupDict[rc.targetId] {
                    matchedList.append(Conversation.fromGroupVO(group, rc: rc))
                    matchedIds.insert(rc.targetId)
                } else {
                    // 融云有会话但群组 API 未返回 → fallback 元数据
                    matchedList.append(Conversation.fromRongCloud(rc))
                    matchedIds.insert(rc.targetId)
                }
            }

            // 未匹配上融云的 GroupVO（只有群组 API 数据，无融云会话），在后展示
            var unmatchedList: [Conversation] = []
            for (gid, group) in groupDict {
                if !matchedIds.contains(gid) {
                    unmatchedList.append(Conversation.fromGroupVO(group, rc: nil))
                }
            }

            let list = matchedList + unmatchedList
//            print("[IMService] matched=\(matchedList.count) unmatched=\(unmatchedList.count)")

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

    /// 异步加载历史消息（从融云 SDK）
    func loadMessages(conversationId: String) async -> [ChatMessage] {
        let rcMessages: [RCMessage] = await withCheckedContinuation { continuation in
            RongCloudManager.shared.getMessages(
                targetId: conversationId,
                count: 20
            ) { messages in
                continuation.resume(returning: messages)
            }
        }
        // 发送已读回执（仅接收方向、且未读的消息）
        sendReadReceiptsIfNeeded(rcMessages)
        // 融云 getHistoryMessages 返回最新在前，倒序使最旧在上、最新在下
        let chatMessages = rcMessages.map { ChatMessage.fromRongCloud(rcMessage: $0) }.reversed()
        let sorted = Array(chatMessages)
        messagesStore[conversationId] = sorted
        print("[IMService] loadMessages conv=\(conversationId) count=\(sorted.count)")
        return sorted
    }

    /// 加载更早的历史消息
    func loadOlderMessages(conversationId: String, oldestMessageId: Int) async -> [ChatMessage] {
        let rcMessages: [RCMessage] = await withCheckedContinuation { continuation in
            RongCloudManager.shared.getMessages(
                targetId: conversationId,
                oldestMessageId: oldestMessageId,
                count: 20
            ) { messages in
                continuation.resume(returning: messages)
            }
        }
        // 发送已读回执（仅接收方向、且未读的消息）
        sendReadReceiptsIfNeeded(rcMessages)
        let older = rcMessages.map { ChatMessage.fromRongCloud(rcMessage: $0) }.reversed()
        let sorted = Array(older)
        // 插入到缓存前部
        messagesStore[conversationId] = sorted + (messagesStore[conversationId] ?? [])
        print("[IMService] loadOlderMessages conv=\(conversationId) count=\(sorted.count)")
        return sorted
    }

    /// 同步获取缓存消息（若缓存为空则 fallback 到 mock）
    func getMessages(conversationId: String) -> [ChatMessage] {
        if messagesStore[conversationId] == nil {
            messagesStore[conversationId] = ChatMessage.mockMessages(for: conversationId)
        }
        return messagesStore[conversationId] ?? []
    }

    /// 发送文本消息（通过融云 SDK）
    func sendMessage(_ text: String, conversationId: String) async -> ChatMessage? {
        let senderInfo = makeSenderUserInfo()
        let result: (RCMessage?, RCErrorCode) = await withCheckedContinuation { continuation in
            RongCloudManager.shared.sendTextMessage(
                conversationType: .ConversationType_GROUP,
                targetId: conversationId,
                content: text,
                senderUserInfo: senderInfo
            ) { message, errorCode in
                continuation.resume(returning: (message, errorCode))
            }
        }
        if let rcMsg = result.0 {
            let chatMsg = ChatMessage.fromRongCloud(rcMessage: rcMsg)
            messagesStore[conversationId, default: []].append(chatMsg)
            return chatMsg
        } else {
            print("[IMService] sendMessage ✗ errorCode=\(result.1.rawValue)")
            return nil
        }
    }

    /// 发送图片消息（通过融云 SDK）
    func sendImage(_ image: UIImage, conversationId: String) async -> ChatMessage? {
        let senderInfo = makeSenderUserInfo()
        let result: (RCMessage?, RCErrorCode) = await withCheckedContinuation { continuation in
            RongCloudManager.shared.sendImageMessage(
                conversationType: .ConversationType_GROUP,
                targetId: conversationId,
                image: image,
                senderUserInfo: senderInfo
            ) { message, errorCode in
                continuation.resume(returning: (message, errorCode))
            }
        }
        if let rcMsg = result.0 {
            let chatMsg = ChatMessage.fromRongCloud(rcMessage: rcMsg)
            messagesStore[conversationId, default: []].append(chatMsg)
            return chatMsg
        } else {
            print("[IMService] sendImage ✗ errorCode=\(result.1.rawValue)")
            return nil
        }
    }

    /// 发送文件消息（AD:FileMsg）
    func sendFile(fileUrl: String, fileName: String, fileSize: String,
                  fileSuffix: String, conversationId: String) async -> ChatMessage? {
        let senderInfo = makeSenderUserInfo()
        let pushContent = "\(senderInfo.name):[文件]"
        let result: (RCMessage?, RCErrorCode) = await withCheckedContinuation { continuation in
            RongCloudManager.shared.sendFileMessage(
                conversationType: .ConversationType_GROUP,
                targetId: conversationId,
                fileUrl: fileUrl,
                fileName: fileName,
                fileSize: fileSize,
                fileSuffix: fileSuffix,
                senderUserInfo: senderInfo,
                pushContent: pushContent
            ) { message, errorCode in
                continuation.resume(returning: (message, errorCode))
            }
        }
        if let rcMsg = result.0 {
            let chatMsg = ChatMessage.fromRongCloud(rcMessage: rcMsg)
            messagesStore[conversationId, default: []].append(chatMsg)
            return chatMsg
        } else {
            print("[IMService] sendFile ✗ errorCode=\(result.1.rawValue)")
            return nil
        }
    }

    /// 发送视频消息（AD:VideoMsg）
    func sendVideo(videoUrl: String, videoName: String, videoTime: Int,
                   videoCoverImg: String? = nil, conversationId: String) async -> ChatMessage? {
        let senderInfo = makeSenderUserInfo()
        let pushContent = "\(senderInfo.name):[视频]"
        let result: (RCMessage?, RCErrorCode) = await withCheckedContinuation { continuation in
            RongCloudManager.shared.sendVideoMessage(
                conversationType: .ConversationType_GROUP,
                targetId: conversationId,
                videoUrl: videoUrl,
                videoName: videoName,
                videoTime: videoTime,
                videoCoverImg: videoCoverImg,
                senderUserInfo: senderInfo,
                pushContent: pushContent
            ) { message, errorCode in
                continuation.resume(returning: (message, errorCode))
            }
        }
        if let rcMsg = result.0 {
            let chatMsg = ChatMessage.fromRongCloud(rcMessage: rcMsg)
            messagesStore[conversationId, default: []].append(chatMsg)
            return chatMsg
        } else {
            print("[IMService] sendVideo ✗ errorCode=\(result.1.rawValue)")
            return nil
        }
    }

    /// 发送套餐消息（AD:SysNotify）
    func sendSysNotify(businessData: String, title: String, content: String,
                       imageUrl: String? = nil, conversationId: String) async -> ChatMessage? {
        let senderInfo = makeSenderUserInfo()
        let pushContent = "\(senderInfo.name):[套餐]"
        let result: (RCMessage?, RCErrorCode) = await withCheckedContinuation { continuation in
            RongCloudManager.shared.sendSysNotifyMessage(
                conversationType: .ConversationType_GROUP,
                targetId: conversationId,
                businessData: businessData,
                title: title,
                content: content,
                imageUrl: imageUrl,
                senderUserInfo: senderInfo,
                pushContent: pushContent
            ) { message, errorCode in
                continuation.resume(returning: (message, errorCode))
            }
        }
        if let rcMsg = result.0 {
            let chatMsg = ChatMessage.fromRongCloud(rcMessage: rcMsg)
            messagesStore[conversationId, default: []].append(chatMsg)
            return chatMsg
        } else {
            print("[IMService] sendSysNotify ✗ errorCode=\(result.1.rawValue)")
            return nil
        }
    }

    /// 发送语音消息（RC:HQVCMsg）
    func sendVoice(localPath: String, duration: Int, conversationId: String) async -> ChatMessage? {
        let senderInfo = makeSenderUserInfo()
        let result: (RCMessage?, RCErrorCode) = await withCheckedContinuation { continuation in
            RongCloudManager.shared.sendHQVoiceMessage(
                conversationType: .ConversationType_GROUP,
                targetId: conversationId,
                localPath: localPath,
                duration: duration,
                senderUserInfo: senderInfo
            ) { message, errorCode in
                continuation.resume(returning: (message, errorCode))
            }
        }
        if let rcMsg = result.0 {
            let chatMsg = ChatMessage.fromRongCloud(rcMessage: rcMsg)
            messagesStore[conversationId, default: []].append(chatMsg)
            return chatMsg
        } else {
            print("[IMService] sendVoice ✗ errorCode=\(result.1.rawValue)")
            return nil
        }
    }

    /// 给需要回执且尚未发送的消息发已读回执
    private func sendReadReceiptsIfNeeded(_ messages: [RCMessage]) {
        for msg in messages {
            guard msg.messageDirection == .MessageDirection_RECEIVE else { continue }
            guard let receipt = msg.readReceiptInfo, receipt.isReceiptRequestMessage, !receipt.hasRespond else { continue }
            RongCloudManager.shared.sendReadReceiptRequest(messageId: msg.messageId)
        }
    }

    // MARK: - Helpers

    /// 构建融云发送者信息，数据来源于 UserManager 当前用户缓存
    private func makeSenderUserInfo() -> RCUserInfo {
        let user = UserManager.shared.currentUser
        return RCUserInfo(
            userId: user?.id ?? "",
            name: user?.chineseName ?? user?.nickname ?? "",
            portrait: user?.imageUrl ?? ""
        )
    }
}
