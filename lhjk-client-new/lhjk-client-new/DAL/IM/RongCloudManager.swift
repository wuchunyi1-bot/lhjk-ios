import Foundation
import Combine
import RongIMLibCore

// MARK: - 融云连接状态

/// 融云连接状态
enum RCConnectionStatus: Int {
    case connected = 0
    case connecting = 1
    case disconnected = 2
    case tokenIncorrect = 3

    var description: String {
        switch self {
        case .connected:      return "已连接"
        case .connecting:     return "连接中"
        case .disconnected:   return "未连接"
        case .tokenIncorrect: return "Token 错误"
        }
    }
}

// MARK: - Token 响应模型

/// `POST /mobile/v1/account/addRongImAccount` 返回的 data 字段
private struct RongCloudTokenResponse: Decodable {
    let token: String?
}

// MARK: - 融云 SDK 管理器 (DAL)

/// 融云 SDK 封装管理器（基于 RongIMLibCore 5.x）
final class RongCloudManager {

    // MARK: - Singleton

    static let shared = RongCloudManager()

    // MARK: - Publishers

    /// 连接状态变化
    let connectionStatusPublisher = PassthroughSubject<RCConnectionStatus, Never>()
    /// 收到的新消息
    let messageReceivedPublisher = PassthroughSubject<ChatMessage, Never>()
    /// 远端会话列表同步完成
    let remoteConversationListDidSyncPublisher = PassthroughSubject<RCErrorCode, Never>()

    // MARK: - Properties

    /// 是否已初始化
    private(set) var isInitialized: Bool = false
    /// 当前连接状态
    private(set) var connectionStatus: RCConnectionStatus = .disconnected
    /// 当前登录用户的融云 userId
    private(set) var currentUserId: String?

    /// 融云核心客户端
    private var client: RCCoreClient { RCCoreClient.shared() }

    /// 当前存储的融云 token（内存缓存）
    private(set) var currentToken: String?

    // MARK: - Token Storage Keys

    private static let tokenKey = "rc_im_token"

    // MARK: - Initialization

    private init() {
        // 冷启动时从 UserDefaults 恢复 token
        currentToken = loadToken()
    }

    // MARK: - Public Methods

    /// 初始化融云 SDK（App 启动时调用一次）
    /// - Parameter appKey: 融云应用 Key
    func initialize(appKey: String) {
        guard !isInitialized else {
            print("[RongCloud] SDK already initialized")
            return
        }
        client.initWithAppKey(appKey, option: nil)
        setupConversationDelegate()
        isInitialized = true

        // 开启 SDK 控制台日志（Debug 级别）
        #if DEBUG
        RCFwLog.setRcDebugLogLevel(1)  // 1 = 开启 Debug 日志
        print("[RongCloud] SDK log level: verbose")
        #endif

        print("[RongCloud] SDK initialized with appKey: \(appKey.prefix(4))****")
    }

    /// 登录后完整流程：调后端获取 Token → 存本地 → 连接融云
    /// - 失败时自动重试 1 次（含 2s 延迟）
    func fetchTokenAndConnect() {
        guard isInitialized else {
            print("[RongCloud] Error: SDK not initialized")
            return
        }

        Task {
            await fetchTokenWithRetry()
        }
    }

    /// 用已存储的 Token 连接（冷启动恢复用）
    func reconnect() {
        guard let token = loadToken() else {
            print("[RongCloud] reconnect → no stored token, skip")
            return
        }
        print("[RongCloud] reconnect → token=\(token)")
        connect(with: token)
    }

    /// 连接融云服务（连上后融云 SDK 内部自动维持/重连，App 侧无需干预）
    /// - Parameter token: 融云 Token（从服务端获取）
    func connect(with token: String) {
        guard isInitialized else {
            print("[RongCloud] Error: SDK not initialized")
            return
        }

        currentToken = token
        saveToken(token)

        connectionStatus = .connecting
        connectionStatusPublisher.send(.connecting)
        print("[RongCloud] Connecting...")

        client.connect(withToken: token, dbOpened: nil, success: { [weak self] userId in
            guard let self = self else { return }
            self.currentUserId = userId
            self.connectionStatus = .connected
            self.connectionStatusPublisher.send(.connected)
            print("[RongCloud] ✓ Connected, userId=\(userId)")
            // 连接成功后同步服务端会话到本地，确保 getConversations 能查到最新数据
            self.syncConversationsFromServer()
        }, error: { [weak self] errorCode in
            guard let self = self else { return }
            self.handleConnectionError(errorCode)
        })
    }

    /// 断开融云连接（登出时调用）
    func disconnect() {
        client.disconnect()
        currentUserId = nil
        currentToken = nil
        connectionStatus = .disconnected
        connectionStatusPublisher.send(.disconnected)
        clearToken()
        print("[RongCloud] Disconnected, token cleared")
    }

    /// 获取单聊会话列表（异步）
    func getConversationList(completion: @escaping ([RCConversation]) -> Void) {
        client.getConversationList([
            NSNumber(value: RCConversationType.ConversationType_GROUP.rawValue),NSNumber(value: RCConversationType.ConversationType_PRIVATE.rawValue)
        ]) { conversationList in
            completion(conversationList ?? [])
        }
    }

    /// 批量按 ID 获取会话 (5.8.2+)，只返回存在的会话，不存在的不返回
    /// 内部分批查询，每批 100 个
    /// - Parameter targetIds: 会话 ID 列表
    /// - Parameter completion: 异步回调
    func getConversations(by targetIds: [String], completion: @escaping ([RCConversation]) -> Void) {
        getConversationsByIdBatch(targetIds: targetIds, completion: completion)
    }

    /// 按时间戳方式获取会话列表，startTime 为一周前，count=100
    /// 拉取后按 targetIds 过滤，不存在的不返回
    /// - Parameter targetIds: 会话 ID 列表
    /// - Parameter completion: 异步回调
    func getConversationsByTime(targetIds: [String], completion: @escaping ([RCConversation]) -> Void) {
        guard !targetIds.isEmpty else {
            completion([])
            return
        }
        let oneWeekAgoMs = Int64((Date().timeIntervalSince1970 - 7 * 24 * 60 * 60) * 1000)
        client.getConversationList(
            [NSNumber(value: RCConversationType.ConversationType_GROUP.rawValue),NSNumber(value: RCConversationType.ConversationType_PRIVATE.rawValue)],
            count: 100,
            startTime: oneWeekAgoMs
        ) { [weak self] conversationList in
            guard let self = self else { return }
            let list = conversationList ?? []
            print("[RongCloud] getConversationsByTime total=\(list.count)")
            for conv in list {
                let typeStr: String
                switch conv.conversationType {
                case .ConversationType_PRIVATE: typeStr = "单聊"
                case .ConversationType_GROUP:   typeStr = "群聊"
                default:                        typeStr = "其他(\(conv.conversationType.rawValue))"
                }
                print("[RongCloud]   conv id=\(conv.targetId), type=\(typeStr), unread=\(conv.unreadMessageCount)")
            }
            let filtered = list.filter { targetIds.contains($0.targetId) }
            print("[RongCloud] getConversationsByTime filtered=\(filtered.count)")
            completion(filtered)
        }
    }

    /// [保留] 原按 ID 分批查询逻辑，每批 10 个
    /// 当前未使用，后续如需切回可按需调用
    private func getConversationsByIdBatch(targetIds: [String], completion: @escaping ([RCConversation]) -> Void) {
        guard !targetIds.isEmpty else {
            completion([])
            return
        }
        let batchSize = 100
        let chunks = stride(from: 0, to: targetIds.count, by: batchSize).map {
            Array(targetIds[$0..<min($0 + batchSize, targetIds.count)])
        }

        var allResults: [RCConversation] = []
        let group = DispatchGroup()

        for chunk in chunks {
            let identifiers = chunk.map { id in
                RCConversationIdentifier(conversationIdentifier: .ConversationType_GROUP, targetId: id)
            }
            group.enter()
            client.getConversations(identifiers, success: { conversations in
                print("+++++++++\(conversations.count)")
                allResults.append(contentsOf: conversations)
                group.leave()
            }, error: { [weak self] errorCode in
                self?.logError("getConversations batch", code: errorCode)
                group.leave()
            })
        }

        group.notify(queue: .main) {
            completion(allResults)
        }
    }

    /// 获取指定会话的历史消息（异步）
    func getMessages(
        conversationType: RCConversationType = .ConversationType_GROUP,
        targetId: String,
        oldestMessageId: Int = -1,
        count: Int = 20,
        completion: @escaping ([RCMessage]) -> Void
    ) {
        client.getHistoryMessages(
            conversationType,
            targetId: targetId,
            oldestMessageId: oldestMessageId,
            count: Int32(count)
        ) { messages in
            completion(messages ?? [])
        }
    }

    /// 发送文本消息
    func sendTextMessage(
        conversationType: RCConversationType,
        targetId: String,
        content: String,
        completion: @escaping (RCMessage?, RCErrorCode) -> Void
    ) {
        let textMsg = RCTextMessage(content: content)
        client.sendMessage(
            conversationType,
            targetId: targetId,
            content: textMsg,
            pushContent: nil,
            pushData: nil,
            attached: nil,
            success: { [weak self] messageId in
                guard let self = self else { return }
                print("[RongCloud] sendTextMessage ✓ messageId=\(messageId)")
                self.client.getMessage(messageId) { message in
                    completion(message, .RC_SUCCESS)
                }
            },
            error: { [weak self] errorCode, _ in
                self?.logError("sendTextMessage", code: errorCode)
                completion(nil, errorCode)
            }
        )
    }

    /// 获取总未读消息数（异步）
    func getTotalUnreadCount(completion: @escaping (Int) -> Void) {
        client.getTotalUnreadCount { count in
            completion(Int(count))
        }
    }

    /// 清除会话未读数
    func clearUnreadCount(for conversationId: String) {
        client.clearMessagesUnreadStatus(.ConversationType_PRIVATE, targetId: conversationId, completion: nil)
    }

    // MARK: - Private Methods

    /// 连接成功后拉取远端会话列表同步到本地
    /// 融云批量查询 API (`getConversations`) 只查本地数据，必须先同步远端
    private func syncConversationsFromServer() {
        client.getRemoteConversationList(success: {
            print("[RongCloud] Remote conversations synced to local")
        }, error: { [weak self] errorCode in
            self?.logError("Sync remote conversations", code: errorCode)
        })
    }

    /// 调后端获取 Token，失败重试 1 次
    private func fetchTokenWithRetry() async {
        print("[RongCloud] fetchToken → calling POST /mobile/v1/account/addRongImAccount")

        let token = await fetchTokenOnce()
        if let token = token {
            connect(with: token)
            return
        }

        // 重试
        print("[RongCloud] fetchToken → retrying in 2s...")
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        let retryToken = await fetchTokenOnce()
        if let retryToken = retryToken {
            connect(with: retryToken)
        } else {
            print("[RongCloud] fetchToken → failed after retry, giving up")
        }
    }

    /// 单次请求 Token
    private func fetchTokenOnce() async -> String? {
        do {
            let response: APIResponse<RongCloudTokenResponse> = try await APIManager.shared
                .postAsync(
                    path: "/mobile/v1/account/addRongImAccount",
                    parameters: nil,
                    responseType: APIResponse<RongCloudTokenResponse>.self
                )

            guard response.isSuccess, let token = response.data?.token, !token.isEmpty else {
                print("[RongCloud] fetchTokenOnce ✗ code=\(response.code) msg=\(response.msg ?? "") data=\(response.data?.token ?? "nil")")
                return nil
            }

            print("[RongCloud] fetchTokenOnce ✓ token=\(token.prefix(8))…")
            return token
        } catch {
            print("[RongCloud] fetchTokenOnce ✗ error: \(error.localizedDescription)")
            return nil
        }
    }

    private func handleConnectionError(_ errorCode: RCErrorCode) {
        let desc = errorDescription(errorCode)
        switch errorCode {
        case .RC_CONN_TOKEN_INCORRECT, .RC_CONN_TOKEN_EXPIRE:
            connectionStatus = .tokenIncorrect
            print("[RongCloud] ✗ Connect failed: \(desc)")
        default:
            connectionStatus = .disconnected
            print("[RongCloud] ✗ Connect failed: \(desc) (SDK will auto-retry)")
        }
        connectionStatusPublisher.send(connectionStatus)
    }

    /// RCErrorCode → 可读错误描述
    private func errorDescription(_ code: RCErrorCode) -> String {
        switch code {
        case .RC_CONN_TOKEN_INCORRECT:  return "TOKEN_INCORRECT (31004)"
        case .RC_CONN_TOKEN_EXPIRE:     return "TOKEN_EXPIRE (31008)"
        case .RC_CONN_APP_BLOCKED_OR_DELETED: return "APP_BLOCKED_OR_DELETED (34001)"
        default:                        return "\(code) raw=\(code.rawValue)"
        }
    }

    /// 打印所有 callback 的完整错误信息
    private func logError(_ context: String, code: RCErrorCode) {
        print("[RongCloud] ✗ \(context) — \(errorDescription(code))")
    }

    // MARK: - Token Persistence

    private func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: Self.tokenKey)
    }

    private func loadToken() -> String? {
        let token = UserDefaults.standard.string(forKey: Self.tokenKey)
        if let token = token, !token.isEmpty {
            return token
        }
        return nil
    }

    private func clearToken() {
        UserDefaults.standard.removeObject(forKey: Self.tokenKey)
    }

    // MARK: - RCConversationDelegate Bridge

    /// 内部 NSObject 桥接，因为 RCConversationDelegate 继承自 NSObjectProtocol
    private var conversationDelegateBridge: RongCloudConversationDelegateBridge?

    private func setupConversationDelegate() {
        let bridge = RongCloudConversationDelegateBridge(manager: self)
        conversationDelegateBridge = bridge
        client.setRCConversationDelegate(bridge)
    }
}

// MARK: - RCConversationDelegate Bridge

/// RCConversationDelegate 要求 NSObjectProtocol，用内部类桥接
private final class RongCloudConversationDelegateBridge: NSObject, RCConversationDelegate {
    private weak var manager: RongCloudManager?

    init(manager: RongCloudManager) {
        self.manager = manager
        super.init()
    }

    func conversationDidSync() {
        print("[RongCloud] conversationDidSync")
    }

    func remoteConversationListDidSync(_ code: RCErrorCode) {
        print("[RongCloud] remoteConversationListDidSync code=\(code.rawValue)")
        manager?.remoteConversationListDidSyncPublisher.send(code)
    }
}
