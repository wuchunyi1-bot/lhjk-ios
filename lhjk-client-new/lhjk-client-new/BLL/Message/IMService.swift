import Foundation
import Combine
import RongIMLibCore

/// IM 业务服务 — 会话 / 消息 / 通知管理
///
/// 会话列表从融云 SDK + 后端 API 获取真实数据，无 fallback mock
final class IMService {

    static let shared = IMService()

    /// 保护 conversations / messagesStore / notifications / hasLoadedConversations（含融云回调线程）
    private let stateLock = NSLock()

    private var conversations: [Conversation] = []
    private var notifications: [AppNotification] = []
    /// 通知中心对应的融云单聊（与 notifications 同步）
    private var privateConversations: [Conversation] = []
    /// 通知中心当前展示的会话（单聊列表按 sentTime 最新的一条）
    private var notificationConversationId: String?
    private var notificationConversationType: RCConversationType = .ConversationType_PRIVATE
    private var messagesStore: [String: [ChatMessage]] = [:]

    private var cancellables = Set<AnyCancellable>()

    /// 通知中心拉取代数：较新的 load 完成后，丢弃过期结果，避免覆盖实时插入
    private var notificationsLoadGeneration = 0

    /// 是否已完成过会话列表加载，用于避免重复 HTTP 请求
    private var _hasLoadedConversations = false
    var hasLoadedConversations: Bool {
        withState { _hasLoadedConversations }
    }

    /// 会话已读状态变更（conversationId），用于会话列表局部刷新
    let conversationMarkedReadPublisher = PassthroughSubject<String, Never>()

    /// 团队对话总未读数变更，用于底部消息 Tab 角标更新
    let totalUnreadCountDidChangePublisher = PassthroughSubject<Int, Never>()

    /// 通知中心列表已更新（实时新消息或重新拉取）
    let notificationsDidChangePublisher = PassthroughSubject<Void, Never>()

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
                guard let self else { return }
                let empty = self.withState { self.conversations.isEmpty }
                if empty {
                    Task { _ = await self.loadConversations() }
                }
            }
            .store(in: &cancellables)

        // 远端会话真正写入本地后，再拉通知中心（success 回调不等于已入库）
        RongCloudManager.shared.remoteConversationListDidSyncPublisher
            .sink { [weak self] code in
                print("[IMService] remoteConversationListDidSync code=\(code.rawValue), load notifications")
                Task {
                    _ = await self?.loadNotifications()
                    self?.publishNotificationsDidChange()
                }
            }
            .store(in: &cancellables)
    }


    private func withState<T>(_ body: () -> T) -> T {
        stateLock.lock()
        defer { stateLock.unlock() }
        return body()
    }

    private func withState(_ body: () -> Void) {
        stateLock.lock()
        defer { stateLock.unlock() }
        body()
    }

    private func onMessageReceived(_ msg: ChatMessage) {
        guard let convId = msg.conversationId else { return }
        withState {
            messagesStore[convId, default: []].append(msg)
        }
        print("[IMService] real-time message received for conv=\(convId) type=\(msg.conversationTypeRaw) isNotification=\(msg.isNotificationConversation)")

        if msg.isNotificationConversation {
            ingestIncomingNotification(msg)
            Task {
                _ = await self.loadNotifications()
                self.publishNotificationsDidChange()
            }
            return
        }

        let shouldUpdateUnread = withState {
            !conversations.isEmpty && conversations.contains(where: { $0.id == convId })
        }
        guard shouldUpdateUnread else { return }
        Task {
            _ = await updateConversation(id: convId)
        }
    }

    /// 单聊/系统消息先插入内存并立刻通知 UI，不等待历史拉取
    private func ingestIncomingNotification(_ msg: ChatMessage) {
        guard msg.role != .user, msg.type != .recall else { return }
        guard let noti = AppNotification.fromChatMessage(
            msg,
            conversationType: msg.rongConversationType,
            unread: true
        ) else {
            print("[通知中心-BLL] ingest skip 无法从实时消息解析出通知 id=\(msg.id)")
            return
        }
        withState {
            notifications.removeAll { $0.id == noti.id }
            notifications.insert(noti, at: 0)
        }
        print("[通知中心-BLL] ingest inserted id=\(noti.id) title=\(noti.title)")
        publishNotificationsDidChange()
    }

    private func publishNotificationsDidChange() {
        notifyUnreadCountChanged()
        if Thread.isMainThread {
            notificationsDidChangePublisher.send()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.notificationsDidChangePublisher.send()
            }
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
    /// 1. `GET /v1/session/getGroup` 获取群组元数据
    /// 2. 用 groupId 列表调融云 `getConversations` 批量查询本地会话
    /// 3. 匹配上融云的在前展示（按 sentTime 倒序），未匹配的 GroupVO 在后展示
    func loadConversations() async -> [Conversation] {
        let isConnected = RongCloudManager.shared.connectionStatus == .connected

        // Step 1: 获取群组列表 → 构建 groupId → GroupVO 查找表
        let groupDict: [String: GroupVO]
        do {
            let response: GroupListResponse = try await APIManager.shared
                .getAsync(path: "/v1/session/getGroup", parameters: nil, responseType: GroupListResponse.self)
            if response.isSuccess, let data = response.data {
                var dict: [String: GroupVO] = [:]
                for g in data {
                    if let gid = g.groupId { dict[gid] = g }
                }
                groupDict = dict
            } else {
                return finishConversationsLoad()
            }
        } catch {
            return finishConversationsLoad()
        }
        guard !groupDict.isEmpty else {
            return finishConversationsLoad()
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
            // 按最后一条消息的服务端 sentTime 倒序（与 item 右上角时间一致，不用阅读/operationTime）
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

            let list = Conversation.sortedByLastMessage(matchedList + unmatchedList)
            return finishConversationsLoad(replacingWith: list)
        }

        return finishConversationsLoad()
    }

    private func finishConversationsLoad(replacingWith list: [Conversation]? = nil) -> [Conversation] {
        let snapshot = withState { () -> [Conversation] in
            if let list {
                conversations = list
            }
            _hasLoadedConversations = true
            return conversations
        }
        notifyUnreadCountChanged()
        return snapshot
    }

    func getConversations() -> [Conversation] {
        withState { conversations }
    }

    /// 消息 Tab 角标：团队对话未读 + 通知中心未读
    func totalUnreadCount() -> Int {
        withState {
            conversations.reduce(0) { $0 + $1.unread }
                + notifications.filter { $0.unread }.count
        }
    }

    /// 通知未读数
    func notiUnreadCount() -> Int {
        withState { notifications.filter { $0.unread }.count }
    }

    /// 通知订阅者总未读数已变更
    private func notifyUnreadCountChanged() {
        let send = { [weak self] in
            guard let self else { return }
            self.totalUnreadCountDidChangePublisher.send(self.totalUnreadCount())
        }
        if Thread.isMainThread {
            send()
        } else {
            DispatchQueue.main.async(execute: send)
        }
    }

    func markAsRead(_ conversationId: String) {
        withState {
            if let idx = conversations.firstIndex(where: { $0.id == conversationId }) {
                conversations[idx].unread = 0
            }
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

    /// 刷新指定群组的 `GET /v1/session/getGroup` 元数据（含 `status`），供聊天页判断是否只读
    /// - Returns: 更新后的 `Conversation`；接口失败或未找到该群时返回缓存中的会话或 nil
    func refreshGroupMetadata(conversationId: String) async -> Conversation? {
        let cached = withState { conversations.first(where: { $0.id == conversationId }) }

        do {
            let response: GroupListResponse = try await APIManager.shared
                .getAsync(path: "/v1/session/getGroup", parameters: nil, responseType: GroupListResponse.self)
            guard response.isSuccess, let data = response.data else {
                return cached
            }
            guard let group = data.first(where: { $0.groupId == conversationId }) else {
                return cached
            }

            let rcList: [RCConversation] = await withCheckedContinuation { continuation in
                RongCloudManager.shared.getConversations(by: [conversationId]) { list in
                    continuation.resume(returning: list)
                }
            }
            let rc = rcList.first
            let merged = Conversation.fromGroupVO(group, rc: rc)

            return withState { () -> Conversation in
                if let idx = conversations.firstIndex(where: { $0.id == conversationId }) {
                    conversations[idx] = merged
                    return conversations[idx]
                }
                return merged
            }
        } catch {
            print("[IMService] refreshGroupMetadata ✗ convId=\(conversationId) \(error.localizedDescription)")
            return cached
        }
    }

    /// `GET /v1/session/getGroupMembers` — 现网 `data` 为成员数组
    /// - Parameters:
    ///   - groupId: 必填，融云/第三方群 Id
    ///   - targetUserId: 可选；全量列表不传
    func fetchGroupMembers(groupId: String, targetUserId: Int64? = nil) async throws -> [ImSessionDetails] {
        var parameters: [String: Any] = ["groupId": groupId]
        if let targetUserId {
            parameters["targetUserId"] = targetUserId
        }
        let response: GroupMembersResponse = try await APIManager.shared.getAsync(
            path: "/v1/session/getGroupMembers",
            parameters: parameters,
            responseType: GroupMembersResponse.self
        )
        guard response.isSuccess else {
            throw APIError.businessError(code: 0, message: response.msg ?? "获取群成员失败")
        }
        return response.data ?? []
    }

    /// B方案：按 conversationId 从融云查单条 RCConversation，局部更新本地会话
    /// - Returns: 更新后的 Conversation；本地未找到该 id 返回 nil
    func updateConversation(id: String) async -> Conversation? {
        let lookup = withState { () -> (idx: Int, oldLastMsg: String, oldUnread: Int, snapshot: Conversation)? in
            guard let idx = conversations.firstIndex(where: { $0.id == id }) else { return nil }
            return (idx, conversations[idx].lastMessage, conversations[idx].unread, conversations[idx])
        }
        guard let lookup else {
            let ids = withState { conversations.map { $0.id } }
            print("[IMService] updateConversation ✗ convId=\(id) not found in local cache (count=\(ids.count), ids=\(ids))")
            return nil
        }

        guard RongCloudManager.shared.connectionStatus == .connected else {
            print("[IMService] updateConversation ✗ convId=\(id) RongCloud not connected, return cached")
            return lookup.snapshot
        }

        let rcList: [RCConversation] = await withCheckedContinuation { continuation in
            RongCloudManager.shared.getConversations(by: [id]) { list in
                print("[IMService] updateConversation convId=\(id) getConversations callback, count=\(list.count)")
                continuation.resume(returning: list)
            }
        }

        guard let rc = rcList.first else {
            print("[IMService] updateConversation ✗ convId=\(id) RCConversation not found in RongCloud, keep cached")
            return withState {
                conversations.first(where: { $0.id == id }) ?? lookup.snapshot
            }
        }

        // 只更新融云侧字段，不动后端元数据
        let lastMsg = Conversation.lastMessageText(from: rc.latestMessage)
        let newLastMsg = lastMsg.isEmpty ? "暂无消息" : lastMsg
        let newTime    = Conversation.formatRCTime(rc.sentTime)
        let newUnread  = Int(rc.unreadMessageCount)

        print("[IMService] updateConversation ✓ convId=\(id) lastMsg \"\(lookup.oldLastMsg.prefix(12))…\" → \"\(newLastMsg.prefix(12))…\" unread \(lookup.oldUnread)→\(newUnread) time=\(newTime) sentTime=\(rc.sentTime)")

        let updated = withState { () -> Conversation? in
            guard let idx = conversations.firstIndex(where: { $0.id == id }) else { return nil }
            conversations[idx].lastMessage = newLastMsg
            conversations[idx].lastMessageAt = rc.sentTime
            conversations[idx].lastTime   = newTime
            conversations[idx].unread     = newUnread
            conversations = Conversation.sortedByLastMessage(conversations)
            return conversations.first(where: { $0.id == id })
        }
        notifyUnreadCountChanged()
        return updated
    }

    func deleteConversation(_ conversationId: String) {
        withState {
            conversations.removeAll { $0.id == conversationId }
        }
        notifyUnreadCountChanged()
    }

    /// 登出时清除所有内存缓存
    func clear() {
        withState {
            conversations.removeAll()
            notifications.removeAll()
            privateConversations.removeAll()
            notificationConversationId = nil
            notificationConversationType = .ConversationType_PRIVATE
            messagesStore.removeAll()
            _hasLoadedConversations = false
            notificationsLoadGeneration = 0
        }
        notifyUnreadCountChanged()
        print("[IMService] cleared")
    }

    // MARK: - Notifications

    /// 通知中心：单聊会话列表 → 取 sentTime 最新的一条 → 拉取该会话历史消息平铺展示
    func loadNotifications() async -> [AppNotification] {
        let isConnected = RongCloudManager.shared.connectionStatus == .connected
        guard isConnected else {
            return withState { notifications }
        }
        let generation = withState {
            notificationsLoadGeneration += 1
            return notificationsLoadGeneration
        }

        let rcList: [RCConversation] = await withCheckedContinuation { continuation in
            RongCloudManager.shared.getPrivateConversationList { list in
                continuation.resume(returning: list)
            }
        }
        let sorted = rcList.sorted { $0.sentTime > $1.sentTime }
        let mappedConv = sorted.map { Conversation.fromRongCloud($0) }
        guard let first = sorted.first else {
            print("[IMService] loadNotifications privateCount=0")
            return withState {
                guard generation == notificationsLoadGeneration else { return notifications }
                notifications = []
                privateConversations = mappedConv
                notificationConversationId = nil
                return notifications
            }
        }

        let (rcMessages, _, _) = await RongCloudManager.shared.getHistoryMessages(
            targetId: first.targetId,
            conversationType: first.conversationType,
            recordTime: 0,
            count: 50
        )
        // getHistoryMessages 默认降序（新→旧）；通知中心按时间倒序，保持该顺序
        let incoming = rcMessages.filter { rc in
            rc.messageDirection != .MessageDirection_SEND
                && !(rc.content is RCRecallNotificationMessage)
        }
        print("[通知中心-BLL] loadNotifications conv=\(first.targetId) type=\(first.conversationType.rawValue) history=\(rcMessages.count) incoming=\(incoming.count)")
        let mappedNoti = incoming.enumerated().compactMap { index, rc -> AppNotification? in
            let raw = Self.debugMessageBody(rc)
            let unread = Self.isMessageUnread(rc)
            print("[通知中心-BLL] raw[\(index)] objectName=\(rc.objectName ?? "nil") msgId=\(rc.messageId) sentTime=\(rc.sentTime) unread=\(unread) body=\(raw)")
            guard let noti = AppNotification.fromPrivateMessage(rc, unread: unread) else {
                print("[通知中心-BLL] skip[\(index)] 无法从 body 解析出通知")
                return nil
            }
            print("[通知中心-BLL] mapped[\(index)] title=\(noti.title) body=\(noti.body) tag=\(noti.tag) route=\(noti.route ?? "nil") unread=\(noti.unread)")
            return noti
        }
        print("[通知中心-BLL] loadNotifications mappedCount=\(mappedNoti.count)")

        return withState {
            guard generation == notificationsLoadGeneration else {
                print("[通知中心-BLL] loadNotifications stale generation=\(generation) current=\(notificationsLoadGeneration), keep memory")
                return notifications
            }
            notifications = mappedNoti
            privateConversations = mappedConv
            notificationConversationId = first.targetId
            notificationConversationType = first.conversationType
            return notifications
        }
    }

    func getNotifications() -> [AppNotification] {
        withState { notifications }
    }

    func privateConversation(id: String) -> Conversation? {
        withState { privateConversations.first { $0.id == id } }
    }

    func markNotificationsRead() {
        withState {
            for i in notifications.indices { notifications[i].unread = false }
        }
        notifyUnreadCountChanged()
    }

    func markNotificationRead(_ id: String) {
        let messageId: Int = withState {
            guard let idx = notifications.firstIndex(where: { $0.id == id }) else { return -1 }
            notifications[idx].unread = false
            return notifications[idx].rongMessageId
        }
        print("[通知中心-BLL] markNotificationRead id=\(id) messageId=\(messageId)")
        RongCloudManager.shared.markMessageRead(messageId: messageId)
        notifyUnreadCountChanged()
    }

    private static func isMessageUnread(_ rc: RCMessage) -> Bool {
        guard rc.messageDirection == .MessageDirection_RECEIVE else { return false }
        return (rc.receivedStatus.rawValue & RCReceivedStatus.ReceivedStatus_READ.rawValue) == 0
    }

    func markPrivateAsRead(_ conversationId: String) {
        let type: RCConversationType = withState {
            for i in notifications.indices where notifications[i].conversationId == conversationId {
                notifications[i].unread = false
            }
            if let idx = privateConversations.firstIndex(where: { $0.id == conversationId }) {
                privateConversations[idx].unread = 0
            }
            return notifications.first(where: { $0.conversationId == conversationId })?.rongConversationType
                ?? notificationConversationType
        }
        RongCloudManager.shared.clearUnreadCount(for: conversationId, type: type)
        notifyUnreadCountChanged()
    }

    private static func debugMessageBody(_ rc: RCMessage) -> String {
        if let text = rc.content as? RCTextMessage {
            return "RCText extra=\(text.extra ?? "nil") content=\(text.content ?? "")"
        }
        if let data = rc.content?.encode(),
           let json = String(data: data, encoding: .utf8),
           !json.isEmpty {
            return json
        }
        if let extra = rc.content?.extra, !extra.isEmpty {
            return "extra=\(extra)"
        }
        return "objectName=\(rc.objectName ?? "nil") content=\(String(describing: rc.content))"
    }

    // MARK: - Messages

    /// 异步加载历史消息（直接走融云推荐 API，消息正常入库 messageId 可靠）
    /// - Returns: (消息列表, 下次翻页用的 timestamp, 是否还有更多远端消息)
    func loadMessages(
        conversationId: String,
        conversationType: RCConversationType = .ConversationType_GROUP
    ) async -> (messages: [ChatMessage], timestamp: Int64, isRemaining: Bool) {
        let (rcMessages, timestamp, isRemaining) = await RongCloudManager.shared.getHistoryMessages(
            targetId: conversationId,
            conversationType: conversationType,
            recordTime: 0,
            count: 20
        )
        sendReadReceiptsIfNeeded(rcMessages)
        let chatMessages = rcMessages.map { ChatMessage.fromRongCloud(rcMessage: $0) }.reversed()
        let sorted = Array(chatMessages)
        if !sorted.isEmpty {
            withState { messagesStore[conversationId] = sorted }
        }
        print("[IMService] loadMessages conv=\(conversationId) count=\(sorted.count) timestamp=\(timestamp) isRemaining=\(isRemaining)")
        for msg in rcMessages {
            let objectName = msg.objectName ?? "?"
            let uid = msg.messageUId ?? "nil"
            let body = ChatMessage.rawContentJSON(from: msg.content)
            print("[RongCloud][raw] loadMessages objectName=\(objectName) uid=\(uid) msgId=\(msg.messageId) sentTime=\(msg.sentTime) body=\(body)")
        }
        return (sorted, timestamp, isRemaining)
    }

    /// 加载更早的历史消息（用上次返回的 timestamp 翻页）
    /// - Parameter timestamp: 上次 getHistoryMessages 回调返回的翻页游标
    /// - Returns: (消息列表, 新的 timestamp, 是否还有更多)
    func loadOlderMessages(
        conversationId: String,
        timestamp: Int64,
        conversationType: RCConversationType = .ConversationType_GROUP
    ) async -> (messages: [ChatMessage], timestamp: Int64, isRemaining: Bool) {
        print("[IMService] loadOlderMessages conv=\(conversationId) timestamp=\(timestamp)")

        let (rcMessages, newTimestamp, isRemaining) = await RongCloudManager.shared.getHistoryMessages(
            targetId: conversationId,
            conversationType: conversationType,
            recordTime: timestamp,
            count: 20
        )
        sendReadReceiptsIfNeeded(rcMessages)
        let older = rcMessages.map { ChatMessage.fromRongCloud(rcMessage: $0) }.reversed()
        let sorted = Array(older)
        if !sorted.isEmpty {
            withState {
                messagesStore[conversationId] = sorted + (messagesStore[conversationId] ?? [])
            }
        }
        print("[IMService] loadOlderMessages conv=\(conversationId) count=\(sorted.count) newTimestamp=\(newTimestamp) isRemaining=\(isRemaining)")
        return (sorted, newTimestamp, isRemaining)
    }

    /// 同步获取缓存消息
    func getMessages(conversationId: String) -> [ChatMessage] {
        withState { messagesStore[conversationId] ?? [] }
    }

    /// 发送文本消息（通过融云 SDK）
    func sendMessage(_ text: String, conversationId: String,
                     conversationType: RCConversationType = .ConversationType_GROUP,
                     replyMessage: ReplyMessage? = nil) async -> ChatMessage? {
        let senderInfo = makeSenderUserInfo()
        let extra = replyMessage.flatMap { ReplyMessage.toExtraJSON($0) }
        let result: (RCMessage?, RCErrorCode) = await withCheckedContinuation { continuation in
            RongCloudManager.shared.sendTextMessage(
                conversationType: conversationType,
                targetId: conversationId,
                content: RongEmoji.emojiToSymbol(text),
                extra: extra,
                senderUserInfo: senderInfo
            ) { message, errorCode in
                continuation.resume(returning: (message, errorCode))
            }
        }
        if let rcMsg = result.0 {
            let chatMsg = ChatMessage.fromRongCloud(rcMessage: rcMsg)
            withState { messagesStore[conversationId, default: []].append(chatMsg) }
            return chatMsg
        } else {
            print("[IMService] sendMessage ✗ errorCode=\(result.1.rawValue)")
            return nil
        }
    }

    /// 发送图片消息（图片已上传 OSS，`imageUrl` 写入 extra）
    func sendImage(_ image: UIImage, imageUrl: String, conversationId: String,
                   conversationType: RCConversationType = .ConversationType_GROUP,
                   replyMessage: ReplyMessage? = nil) async -> ChatMessage? {
        let senderInfo = makeSenderUserInfo()
        let extra = ExtraPayload.buildJSON(replyMessage: replyMessage, imageUrl: imageUrl)
        let result: (RCMessage?, RCErrorCode) = await withCheckedContinuation { continuation in
            RongCloudManager.shared.sendImageMessage(
                conversationType: conversationType,
                targetId: conversationId,
                image: image,
                imageUrl: imageUrl,
                extra: extra,
                senderUserInfo: senderInfo
            ) { message, errorCode in
                continuation.resume(returning: (message, errorCode))
            }
        }
        if let rcMsg = result.0 {
            let chatMsg = ChatMessage.fromRongCloud(rcMessage: rcMsg)
            withState { messagesStore[conversationId, default: []].append(chatMsg) }
            return chatMsg
        } else {
            print("[IMService] sendImage ✗ errorCode=\(result.1.rawValue)")
            return nil
        }
    }

    /// 发送文件消息（AD:FileMsg）
    func sendFile(fileUrl: String, fileName: String, fileSize: String,
                  fileSuffix: String, conversationId: String,
                  conversationType: RCConversationType = .ConversationType_GROUP,
                  replyMessage: ReplyMessage? = nil) async -> ChatMessage? {
        let senderInfo = makeSenderUserInfo()
        let pushContent = "\(senderInfo.name):[文件]"
        let extra = replyMessage.flatMap { ReplyMessage.toExtraJSON($0) }
        let result: (RCMessage?, RCErrorCode) = await withCheckedContinuation { continuation in
            RongCloudManager.shared.sendFileMessage(
                conversationType: conversationType,
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
            withState { messagesStore[conversationId, default: []].append(chatMsg) }
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
            withState { messagesStore[conversationId, default: []].append(chatMsg) }
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
            withState { messagesStore[conversationId, default: []].append(chatMsg) }
            return chatMsg
        } else {
            print("[IMService] sendSysNotify ✗ errorCode=\(result.1.rawValue)")
            return nil
        }
    }

    /// 发送语音消息（语音已上传 OSS，`voiceUrl` 写入 extra）
    func sendVoice(localPath: String, duration: Int, voiceUrl: String, conversationId: String,
                   conversationType: RCConversationType = .ConversationType_GROUP,
                   replyMessage: ReplyMessage? = nil) async -> ChatMessage? {
        let senderInfo = makeSenderUserInfo()
        let extra = ExtraPayload.buildJSON(replyMessage: replyMessage, voiceUrl: voiceUrl)
        let result: (RCMessage?, RCErrorCode) = await withCheckedContinuation { continuation in
            RongCloudManager.shared.sendHQVoiceMessage(
                conversationType: conversationType,
                targetId: conversationId,
                localPath: localPath,
                duration: duration,
                voiceUrl: voiceUrl,
                extra: extra,
                senderUserInfo: senderInfo
            ) { message, errorCode in
                continuation.resume(returning: (message, errorCode))
            }
        }
        if let rcMsg = result.0 {
            let chatMsg = ChatMessage.fromRongCloud(rcMessage: rcMsg)
            withState { messagesStore[conversationId, default: []].append(chatMsg) }
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
