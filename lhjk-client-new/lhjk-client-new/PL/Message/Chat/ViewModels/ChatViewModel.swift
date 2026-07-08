import Foundation
import Combine
import UIKit
import RongIMLibCore

/// 聊天页 ViewModel — 消息管理、发送/撤回/引用、实时订阅、时间标记
///
/// ViewController 通过订阅 `$messages` 驱动 TableView 刷新，
/// 通过 `toastPublisher` / `scrollToBottomPublisher` 等响应一次性 UI 事件
final class ChatViewModel: ObservableObject {

    // MARK: - Published State

    @Published var messages: [ChatMessage] = []
    @Published var conversation: Conversation?
    @Published var isLoadingMore = false
    @Published var hasMoreMessages = true
    @Published var isSending = false
    @Published var quotedMessage: ChatMessage?

    // MARK: - One-shot UI Events

    let toastPublisher = PassthroughSubject<String, Never>()
    let scrollToBottomPublisher = PassthroughSubject<Bool, Never>()
    let presentImagePreviewPublisher = PassthroughSubject<String, Never>()
    let playVoicePublisher = PassthroughSubject<String, Never>()
    let dismissQuotePublisher = PassthroughSubject<Void, Never>()
    let showQuotePreviewPublisher = PassthroughSubject<ReplyMessage, Never>()

    // MARK: - Dependencies

    let conversationId: String
    private let imService: IMService
    private let rongCloudManager: RongCloudManager
    private let rongCloudMessageDelegate: RongCloudMessageDelegate
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Private State

    private var lastTimestamp: Int64 = 0

    // MARK: - Init

    init(conversationId: String,
         imService: IMService = .shared,
         rongCloudManager: RongCloudManager = .shared,
         rongCloudMessageDelegate: RongCloudMessageDelegate = .shared) {
        self.conversationId = conversationId
        self.imService = imService
        self.rongCloudManager = rongCloudManager
        self.rongCloudMessageDelegate = rongCloudMessageDelegate

        // 加载会话元数据
        self.conversation = imService.getConversations().first { $0.id == conversationId }

        setupRealtimeSubscription()
    }

    // MARK: - Quick Replies

    /// 根据会话角色返回快捷回复文案
    func quickReplies() -> [String] {
        guard let role = conversation?.role else {
            return ["上传血压", "查看监测方案", "联系健管师"]
        }
        switch role {
        case .ai:           return ["查看本周周报", "我的健康目标", "今日健康建议"]
        case .nutrition:    return ["今天早餐怎么吃？", "帮我调整晚餐", "查看饮食方案"]
        case .doctor:       return ["帮我看下指标", "用药需要调整吗", "预约复诊"]
        case .caseManager:  return ["查看个案进度", "补充资料", "联系家属"]
        case .psychology:   return ["开始放松练习", "记录睡眠", "预约咨询"]
        case .service:      return ["查看预约", "改约时间", "联系服务台"]
        case .team:         return ["同步今日指标", "请团队看一下", "查看本周目标"]
        default:            return ["上传血压", "查看监测方案", "联系健管师"]
        }
    }

    // MARK: - Message Loading

    /// 首次加载历史消息
    func loadMessages() async {
        let (msgs, timestamp, isRemaining) = await imService.loadMessages(conversationId: conversationId)
        await MainActor.run {
            lastTimestamp = timestamp
            hasMoreMessages = isRemaining
            let list = msgs.isEmpty
                ? imService.getMessages(conversationId: conversationId)
                : msgs
            messages = Self.insertTimeMarkers(list, conversationId: conversationId)
        }
    }

    /// 加载更早消息（上拉翻页）
    func loadOlderMessages() async {
        guard !isLoadingMore, hasMoreMessages else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        let (olderMessages, newTimestamp, isRemaining) = await imService.loadOlderMessages(
            conversationId: conversationId,
            timestamp: lastTimestamp
        )
        await MainActor.run {
            lastTimestamp = newTimestamp
            hasMoreMessages = isRemaining
            guard !olderMessages.isEmpty else { return }

            let existingIds = Set(messages.map { $0.id })
            let newOlder = olderMessages.filter { !existingIds.contains($0.id) }
            let raw = messages.filter { $0.type != .timeMarker } + newOlder
            messages = Self.insertTimeMarkers(
                raw.sorted { ($0.sentTime ?? Int64.max) < ($1.sentTime ?? Int64.max) },
                conversationId: conversationId
            )
        }
    }

    // MARK: - Real-time Subscription

    private func setupRealtimeSubscription() {
        // Combine 订阅：逐条追加新消息
        rongCloudManager.messageReceivedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                guard let self else { return }
                guard msg.conversationId == self.conversationId else { return }
                guard !self.messages.contains(where: { $0.id == msg.id }) else { return }
                self.messages.append(msg)
            }
            .store(in: &cancellables)

        // Delegate 回调：收到消息后全量刷新（融云同步触发）
        rongCloudMessageDelegate.onMessageReceived = { [weak self] rcMsg in
            guard let self else { return }
            guard rcMsg.targetId == self.conversationId else { return }
            Task {
                await self.loadMessages()
            }
        }
    }

    // MARK: - Message Sending

    /// 发送文本消息（含乐观更新）
    func sendText(_ text: String) {
        let localMsg = makeLocalMessage(type: MessageType.text, text: text, imagePath: nil, thumbWidth: nil, thumbHeight: nil)

        let reply = quotedMessage.flatMap { ReplyMessage.from($0) }
        quotedMessage = nil

        messages.append(localMsg)
        scrollToBottomPublisher.send(false)

        Task {
            let sentMsg = await imService.sendMessage(text, conversationId: conversationId, replyMessage: reply)
            await MainActor.run {
                self.replaceLocalMessage(localId: localMsg.id, with: sentMsg)
            }
        }
    }

    /// 发送图片消息（含乐观更新）
    func sendImage(_ image: UIImage) {
        guard let localPath = saveImageToTemp(image) else { return }
        let localMsg = makeLocalMessage(
            type: MessageType.image, text: nil,
            imagePath: localPath,
            thumbWidth: Int(image.size.width),
            thumbHeight: Int(image.size.height)
        )

        let reply = quotedMessage.flatMap { ReplyMessage.from($0) }
        quotedMessage = nil

        messages.append(localMsg)
        scrollToBottomPublisher.send(false)

        Task {
            let sentMsg = await imService.sendImage(image, conversationId: conversationId, replyMessage: reply)
            await MainActor.run {
                self.replaceLocalMessage(localId: localMsg.id, with: sentMsg)
            }
        }
    }

    /// 发送语音消息（含乐观更新）
    func sendVoice(localPath: String, duration: Int) {
        let reply = quotedMessage.flatMap { ReplyMessage.from($0) }
        quotedMessage = nil

        Task {
            let sent = await imService.sendVoice(
                localPath: localPath,
                duration: duration,
                conversationId: conversationId,
                replyMessage: reply
            )
            await MainActor.run {
                if let sent,
                   let localIdx = self.messages.firstIndex(where: { $0.type == .voice && $0.imagePath == localPath }) {
                    self.messages[localIdx] = sent
                }
            }
        }
    }

    // MARK: - Message Actions

    /// 撤回消息
    func recallMessage(_ message: ChatMessage) async -> Bool {
        guard let msgId = Int(message.id) else { return false }
        let success = await imService.recallMessage(msgId)
        if success {
            await MainActor.run {
                replaceWithRecall(message)
            }
        }
        return success
    }

    /// 开始引用消息
    func startQuote(_ message: ChatMessage) {
        quotedMessage = message
        showQuotePreviewPublisher.send(ReplyMessage.from(message))
    }

    /// 取消引用
    func dismissQuote() {
        quotedMessage = nil
    }

    /// 获取可复制的文本
    func copyMessageText(_ message: ChatMessage) -> String? {
        message.text
    }

    /// 获取引用消息的操作类型（图片/语音/视频/无）
    enum QuoteAction {
        case showImage(String)
        case playVoice(String)
        case playVideo(String)
        case none
    }

    func quoteAction(for reply: ReplyMessage) -> QuoteAction {
        if reply.isImage { return .showImage(reply.text) }
        if reply.isVoice { return .playVoice(reply.text) }
        if reply.isVideo { return .playVideo(reply.text) }
        return .none
    }

    /// 消息是否可执行操作
    func availableActions(for message: ChatMessage) -> [MessageActionMenu.Action] {
        var actions: [MessageActionMenu.Action] = []
        if message.canCopy { actions.append(.copy) }
        if message.canRecall { actions.append(.recall) }
        if message.canQuote { actions.append(.quote) }
        return actions
    }

    // MARK: - Mark as Read

    func markAsRead() {
        rongCloudManager.clearGroupUnreadCount(for: conversationId)
        imService.markAsRead(conversationId)
    }

    // MARK: - Private Helpers

    private func makeLocalMessage(
        type: MessageType,
        text: String?,
        imagePath: String?,
        thumbWidth: Int?,
        thumbHeight: Int?
    ) -> ChatMessage {
        ChatMessage(
            id: "local-\(Int(Date().timeIntervalSince1970 * 1000))",
            type: type,
            role: .user,
            senderName: nil, senderRole: nil, avatar: nil, portraitUrl: nil,
            text: text,
            time: "刚刚",
            sentTime: nil,
            card: nil, meal: nil, report: nil,
            imagePath: imagePath,
            thumbWidth: thumbWidth,
            thumbHeight: thumbHeight,
            conversationId: conversationId,
            extra: nil, reply: nil, messageId: -1
        )
    }

    private func replaceLocalMessage(localId: String, with sentMsg: ChatMessage?) {
        guard let sentMsg, let localIdx = messages.firstIndex(where: { $0.id == localId }) else { return }
        messages[localIdx] = sentMsg
    }

    private func replaceWithRecall(_ message: ChatMessage) {
        guard let idx = messages.firstIndex(where: { $0.id == message.id }) else { return }
        let recalMsg = ChatMessage(
            id: message.id,
            type: .recall,
            role: .user,
            senderName: nil, senderRole: nil, avatar: nil, portraitUrl: nil,
            text: "你撤回了一条消息",
            time: message.time,
            sentTime: message.sentTime,
            card: nil, meal: nil, report: nil,
            imagePath: nil, thumbWidth: nil, thumbHeight: nil,
            conversationId: message.conversationId,
            extra: nil, reply: nil, messageId: message.messageId
        )
        messages[idx] = recalMsg
    }

    private func saveImageToTemp(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let path = NSTemporaryDirectory() + "rc_img_\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
        try? data.write(to: URL(fileURLWithPath: path))
        return path
    }
}

// MARK: - Time Markers (Static)

extension ChatViewModel {

    /// 在消息列表中插入日期分隔标记
    static func insertTimeMarkers(_ list: [ChatMessage], conversationId: String) -> [ChatMessage] {
        guard !list.isEmpty else { return list }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        var result: [ChatMessage] = []
        var lastDate: Date?

        for msg in list {
            guard let sentTime = parseMessageDate(msg) else {
                result.append(msg)
                continue
            }
            let msgDate = calendar.startOfDay(for: sentTime)

            if lastDate == nil || msgDate != lastDate {
                let dateText = formatDateMarker(msgDate, today: today, yesterday: yesterday, calendar: calendar)
                let marker = ChatMessage(
                    id: "marker-\(msg.id)",
                    type: .timeMarker,
                    role: .user,
                    senderName: nil, senderRole: nil, avatar: nil, portraitUrl: nil,
                    text: dateText, time: "", sentTime: nil,
                    card: nil, meal: nil, report: nil,
                    imagePath: nil, thumbWidth: nil, thumbHeight: nil,
                    conversationId: conversationId,
                    extra: nil, reply: nil, messageId: -1
                )
                result.append(marker)
            }
            result.append(msg)
            lastDate = msgDate
        }

        return result
    }

    private static func parseMessageDate(_ msg: ChatMessage) -> Date? {
        if let st = msg.sentTime, st > 0 {
            return Date(timeIntervalSince1970: TimeInterval(st) / 1000.0)
        }
        guard !msg.time.isEmpty else { return Date() }
        let raw = msg.time
        if raw.hasPrefix("今天") {
            return parseTime(raw.replacingOccurrences(of: "今天 ", with: ""), baseDate: Date())
        }
        if raw.hasPrefix("昨天") {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            return parseTime(raw.replacingOccurrences(of: "昨天 ", with: ""), baseDate: yesterday)
        }
        return parseTime(raw, baseDate: Date())
    }

    private static func parseTime(_ timeStr: String, baseDate: Date) -> Date? {
        let parts = timeStr.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: baseDate)
    }

    private static func formatDateMarker(_ date: Date, today: Date, yesterday: Date, calendar: Calendar) -> String {
        if calendar.isDate(date, inSameDayAs: today) {
            return "今天"
        }
        if calendar.isDate(date, inSameDayAs: yesterday) {
            return "昨天"
        }
        let fmt = DateFormatter()
        let year = calendar.component(.year, from: date)
        let thisYear = calendar.component(.year, from: Date())
        if year == thisYear {
            fmt.dateFormat = "MM-dd"
        } else {
            fmt.dateFormat = "yyyy-MM-dd"
        }
        return fmt.string(from: date)
    }
}
