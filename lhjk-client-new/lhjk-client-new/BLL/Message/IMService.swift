import Foundation
import Combine
import RongIMLibCore

/// IM 业务服务 — 会话 / 消息 / 通知管理
///
/// 会话列表从融云 SDK + 后端 API 获取真实数据，无 fallback mock
final class IMService {

    static let shared = IMService()

    private var conversations: [Conversation] = []
    private var notifications: [AppNotification] = []
    private var messagesStore: [String: [ChatMessage]] = [:]

    private var cancellables = Set<AnyCancellable>()

    /// 是否已完成过会话列表加载，用于避免重复 HTTP 请求
    private(set) var hasLoadedConversations = false

    /// 会话已读状态变更（conversationId），用于会话列表局部刷新
    let conversationMarkedReadPublisher = PassthroughSubject<String, Never>()

    /// 团队对话总未读数变更，用于底部消息 Tab 角标更新
    let totalUnreadCountDidChangePublisher = PassthroughSubject<Int, Never>()

    private init() {
        // 订阅实时消息，按 conversationId 缓存
        RongCloudManager.shared.messageReceivedPublisher
            .sink { [weak self] msg in
                self?.onMessageReceived(msg)
            }
            .store(in: &cancellables)

        // IM 连接成功后主动加载会话列表，确保角标在 App 启动时即可用
        RongCloudManager.shared.connectionStatusPublisher
            .filter { $0 == .connected }
            .sink { [weak self] _ in
                guard let self, self.conversations.isEmpty else { return }
                Task { _ = await self.loadConversations() }
            }
            .store(in: &cancellables)
    }

    private func onMessageReceived(_ msg: ChatMessage) {
        guard let convId = msg.conversationId else { return }
        messagesStore[convId, default: []].append(msg)
        print("[IMService] real-time message received for conv=\(convId)")

        // 若会话列表已加载，主动更新该会话未读数（即使 ConversationListVC 未加载也能驱动角标刷新）
        guard !conversations.isEmpty,
              conversations.contains(where: { $0.id == convId }) else { return }
        Task {
            _ = await updateConversation(id: convId)
        }
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
                hasLoadedConversations = true
                notifyUnreadCountChanged()
                return conversations
            }
        } catch {
            hasLoadedConversations = true
            notifyUnreadCountChanged()
            return conversations
        }
        guard !groupDict.isEmpty else {
            hasLoadedConversations = true
            notifyUnreadCountChanged()
            return conversations
        }

        // Step 2: 提取 groupId 列表，批量查融云本地会话
        let groupIds = Array(groupDict.keys)
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
            conversations = list
        }

        hasLoadedConversations = true
        notifyUnreadCountChanged()
        return conversations
    }

    func getConversations() -> [Conversation] {
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

    /// 通知订阅者总未读数已变更
    private func notifyUnreadCountChanged() {
        totalUnreadCountDidChangePublisher.send(totalUnreadCount())
    }

    func markAsRead(_ conversationId: String) {
        if let idx = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[idx].unread = 0
        }
        RongCloudManager.shared.clearGroupUnreadCount(for: conversationId)
        conversationMarkedReadPublisher.send(conversationId)
        notifyUnreadCountChanged()
    }

    /// 撤回消息，成功返回 true
    func recallMessage(_ messageId: Int) async -> Bool {
        await withCheckedContinuation { continuation in
            RongCloudManager.shared.recallMessage(messageId: messageId) { success in
                continuation.resume(returning: success)
            }
        }
    }

    /// B方案：按 conversationId 从融云查单条 RCConversation，局部更新本地会话
    /// - Returns: 更新后的 Conversation；本地未找到该 id 返回 nil
    func updateConversation(id: String) async -> Conversation? {
        guard let idx = conversations.firstIndex(where: { $0.id == id }) else {
            print("[IMService] updateConversation ✗ convId=\(id) not found in local cache (count=\(conversations.count), ids=\(conversations.map { $0.id }))")
            return nil
        }
        let oldLastMsg = conversations[idx].lastMessage
        let oldUnread  = conversations[idx].unread

        guard RongCloudManager.shared.connectionStatus == .connected else {
            print("[IMService] updateConversation ✗ convId=\(id) RongCloud not connected, return cached")
            return conversations[idx]
        }

        let rcList: [RCConversation] = await withCheckedContinuation { continuation in
            RongCloudManager.shared.getConversations(by: [id]) { list in
                print("[IMService] updateConversation convId=\(id) getConversations callback, count=\(list.count)")
                continuation.resume(returning: list)
            }
        }

        guard let rc = rcList.first else {
            print("[IMService] updateConversation ✗ convId=\(id) RCConversation not found in RongCloud, keep cached")
            return conversations[idx]
        }

        // 只更新融云侧字段，不动后端元数据
        let lastMsg = Conversation.lastMessageText(from: rc.latestMessage)
        let newLastMsg = lastMsg.isEmpty ? "暂无消息" : lastMsg
        let newTime    = Conversation.formatRCTime(rc.sentTime)
        let newUnread  = Int(rc.unreadMessageCount)

        print("[IMService] updateConversation ✓ convId=\(id) lastMsg \"\(oldLastMsg.prefix(12))…\" → \"\(newLastMsg.prefix(12))…\" unread \(oldUnread)→\(newUnread) time=\(newTime)")

        conversations[idx].lastMessage = newLastMsg
        conversations[idx].lastTime   = newTime
        conversations[idx].unread     = newUnread
        notifyUnreadCountChanged()
        return conversations[idx]
    }

    func deleteConversation(_ conversationId: String) {
        conversations.removeAll { $0.id == conversationId }
        notifyUnreadCountChanged()
    }

    /// 登出时清除所有内存缓存
    func clear() {
        conversations.removeAll()
        messagesStore.removeAll()
        hasLoadedConversations = false
        notifyUnreadCountChanged()
        print("[IMService] cleared")
    }

    // MARK: - Notifications

    func getNotifications() -> [AppNotification] {
        notifications
    }

    func markNotificationsRead() {
        for i in notifications.indices { notifications[i].unread = false }
    }

    // MARK: - Messages

    /// 异步加载历史消息（直接走融云推荐 API，消息正常入库 messageId 可靠）
    /// - Returns: (消息列表, 下次翻页用的 timestamp, 是否还有更多远端消息)
    func loadMessages(conversationId: String) async -> (messages: [ChatMessage], timestamp: Int64, isRemaining: Bool) {
        let (rcMessages, timestamp, isRemaining) = await RongCloudManager.shared.getHistoryMessages(
            targetId: conversationId,
            recordTime: 0,
            count: 20
        )
        sendReadReceiptsIfNeeded(rcMessages)
        let chatMessages = rcMessages.map { ChatMessage.fromRongCloud(rcMessage: $0) }.reversed()
        let sorted = Array(chatMessages)
        if !sorted.isEmpty {
            messagesStore[conversationId] = sorted
        }
        print("[IMService] loadMessages conv=\(conversationId) count=\(sorted.count) timestamp=\(timestamp) isRemaining=\(isRemaining)")
        for msg in rcMessages {
            print("[IMService]   msgId=\(msg.messageId) sentTime=\(msg.sentTime)")
        }
        return (sorted, timestamp, isRemaining)
    }

    /// 加载更早的历史消息（用上次返回的 timestamp 翻页）
    /// - Parameter timestamp: 上次 getHistoryMessages 回调返回的翻页游标
    /// - Returns: (消息列表, 新的 timestamp, 是否还有更多)
    func loadOlderMessages(conversationId: String, timestamp: Int64) async -> (messages: [ChatMessage], timestamp: Int64, isRemaining: Bool) {
        print("[IMService] loadOlderMessages conv=\(conversationId) timestamp=\(timestamp)")

        let (rcMessages, newTimestamp, isRemaining) = await RongCloudManager.shared.getHistoryMessages(
            targetId: conversationId,
            recordTime: timestamp,
            count: 20
        )
        sendReadReceiptsIfNeeded(rcMessages)
        let older = rcMessages.map { ChatMessage.fromRongCloud(rcMessage: $0) }.reversed()
        let sorted = Array(older)
        if !sorted.isEmpty {
            messagesStore[conversationId] = sorted + (messagesStore[conversationId] ?? [])
        }
        print("[IMService] loadOlderMessages conv=\(conversationId) count=\(sorted.count) newTimestamp=\(newTimestamp) isRemaining=\(isRemaining)")
        return (sorted, newTimestamp, isRemaining)
    }

    /// 同步获取缓存消息
    func getMessages(conversationId: String) -> [ChatMessage] {
        return messagesStore[conversationId] ?? []
    }

    /// 发送文本消息（通过融云 SDK）
    func sendMessage(_ text: String, conversationId: String,
                     replyMessage: ReplyMessage? = nil) async -> ChatMessage? {
        let senderInfo = makeSenderUserInfo()
        let extra = replyMessage.flatMap { ReplyMessage.toExtraJSON($0) }
        let result: (RCMessage?, RCErrorCode) = await withCheckedContinuation { continuation in
            RongCloudManager.shared.sendTextMessage(
                conversationType: .ConversationType_GROUP,
                targetId: conversationId,
                content: text,
                extra: extra,
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
    func sendImage(_ image: UIImage, conversationId: String,
                   replyMessage: ReplyMessage? = nil) async -> ChatMessage? {
        let senderInfo = makeSenderUserInfo()
        let extra = replyMessage.flatMap { ReplyMessage.toExtraJSON($0) }
        let result: (RCMessage?, RCErrorCode) = await withCheckedContinuation { continuation in
            RongCloudManager.shared.sendImageMessage(
                conversationType: .ConversationType_GROUP,
                targetId: conversationId,
                image: image,
                extra: extra,
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
                  fileSuffix: String, conversationId: String,
                  replyMessage: ReplyMessage? = nil) async -> ChatMessage? {
        let senderInfo = makeSenderUserInfo()
        let pushContent = "\(senderInfo.name):[文件]"
        let extra = replyMessage.flatMap { ReplyMessage.toExtraJSON($0) }
        let result: (RCMessage?, RCErrorCode) = await withCheckedContinuation { continuation in
            RongCloudManager.shared.sendFileMessage(
                conversationType: .ConversationType_GROUP,
                targetId: conversationId,
                fileUrl: fileUrl,
                fileName: fileName,
                fileSize: fileSize,
                fileSuffix: fileSuffix,
                extra: extra,
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
                   videoCoverImg: String? = nil, conversationId: String,
                   replyMessage: ReplyMessage? = nil) async -> ChatMessage? {
        let senderInfo = makeSenderUserInfo()
        let pushContent = "\(senderInfo.name):[视频]"
        let extra = replyMessage.flatMap { ReplyMessage.toExtraJSON($0) }
        let result: (RCMessage?, RCErrorCode) = await withCheckedContinuation { continuation in
            RongCloudManager.shared.sendVideoMessage(
                conversationType: .ConversationType_GROUP,
                targetId: conversationId,
                videoUrl: videoUrl,
                videoName: videoName,
                videoTime: videoTime,
                videoCoverImg: videoCoverImg,
                extra: extra,
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
                       imageUrl: String? = nil, conversationId: String,
                       replyMessage: ReplyMessage? = nil) async -> ChatMessage? {
        let senderInfo = makeSenderUserInfo()
        let pushContent = "\(senderInfo.name):[套餐]"
        let extra = replyMessage.flatMap { ReplyMessage.toExtraJSON($0) }
        let result: (RCMessage?, RCErrorCode) = await withCheckedContinuation { continuation in
            RongCloudManager.shared.sendSysNotifyMessage(
                conversationType: .ConversationType_GROUP,
                targetId: conversationId,
                businessData: businessData,
                title: title,
                content: content,
                imageUrl: imageUrl,
                extra: extra,
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
    func sendVoice(localPath: String, duration: Int, conversationId: String,
                   replyMessage: ReplyMessage? = nil) async -> ChatMessage? {
        let senderInfo = makeSenderUserInfo()
        let extra = replyMessage.flatMap { ReplyMessage.toExtraJSON($0) }
        let result: (RCMessage?, RCErrorCode) = await withCheckedContinuation { continuation in
            RongCloudManager.shared.sendHQVoiceMessage(
                conversationType: .ConversationType_GROUP,
                targetId: conversationId,
                localPath: localPath,
                duration: duration,
                extra: extra,
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
