# IM / Chat & Conversation List — ViewModel

## Purpose

为 `ChatViewController` 引入 `ChatViewModel`，为 `ConversationListViewController` 引入 `ConversationListViewModel`。

- **ChatViewModel**: 消息管理、发送/撤回/引用/复制、实时订阅、时间标记插入、乐观更新、输入状态
- **ConversationListViewModel**: 5 路 Combine 订阅、会话增量/批量/全量刷新、缓存策略

> **Reference**: `PL/Message/Chat/ChatViewController.swift`、`PL/Message/ConversationListViewController.swift`、`BLL/Message/IMService.swift`、`DAL/IM/RongCloudManager.swift`

---

## Requirements

### Requirement: ChatViewModel Data Ownership

`ChatViewModel` SHALL 作为聊天页所有消息数据和状态的 **单一数据源**。

#### Scenario: ViewModel 数据结构
- **WHEN** `ChatViewModel` 被初始化（传入 `conversationId: String`）
- **THEN** 它包含以下 `@Published` 属性：
  - `messages: [ChatMessage]` — 消息列表（含时间标记）
  - `conversation: Conversation?` — 当前会话元数据
  - `isLoadingMore: Bool` — 是否正在加载更早消息
  - `hasMoreMessages: Bool` — 是否还有更早消息可加载
  - `isSending: Bool` — 是否正在发送消息
  - `quotedMessage: ChatMessage?` — 当前引用的消息（nil = 未引用）

#### Scenario: 内部状态（非 @Published）
- **WHEN** ViewModel 需要追踪翻页游标
- **THEN** `lastTimestamp: Int64` 和 `cancellables: Set<AnyCancellable>` 为私有属性

### Requirement: ChatViewModel BLL Integration

`ChatViewModel` SHALL 通过 `init` 参数接收 BLL/DAL Service，默认值使用 `.shared`。

#### Scenario: 依赖注入
- **WHEN** `ChatViewModel` 被创建
- **THEN** 接受以下参数（均有默认值）：
  - `conversationId: String`（必传，无默认值）
  - `imService: IMService = .shared`
  - `rongCloudManager: RongCloudManager = .shared`
  - `rongCloudMessageDelegate: RongCloudMessageDelegate = .shared`

### Requirement: Message Loading

`ChatViewModel` SHALL 封装历史消息加载、翻页、实时消息接收。

#### Scenario: 首次加载历史消息
- **WHEN** ViewController 调用 `viewModel.loadMessages()`
- **THEN** ViewModel 调用 `IMService.shared.loadMessages(conversationId:)`
- **AND** 将返回的消息列表通过 `insertTimeMarkers()` 插入日期分隔标记后更新 `messages`
- **AND** 更新 `lastTimestamp` 和 `hasMoreMessages`
- **AND** 若返回空列表，则 fallback 到 `IMService.shared.getMessages(conversationId:)`（缓存）

#### Scenario: 加载更早消息（上拉翻页）
- **WHEN** ViewController 调用 `viewModel.loadOlderMessages()`
- **THEN** 若 `isLoadingMore == true` 或 `hasMoreMessages == false`，直接 return
- **AND** 设置 `isLoadingMore = true`
- **AND** 调用 `IMService.shared.loadOlderMessages(conversationId:timestamp:)`
- **AND** 去重后与现有 messages 合并，重新排序，重新调用 `insertTimeMarkers()`
- **AND** 设置 `isLoadingMore = false`

#### Scenario: 实时消息接收
- **WHEN** ViewModel 初始化
- **THEN** 自动订阅 `RongCloudManager.shared.messageReceivedPublisher`
- **AND** 过滤 `conversationId` 匹配的消息
- **AND** 去重后追加到 `messages` 末尾

### Requirement: Message Sending

`ChatViewModel` SHALL 封装文本、图片、语音消息的发送逻辑，包含乐观更新。

#### Scenario: 发送文本消息
- **WHEN** ViewController 调用 `viewModel.sendText(_ text: String)`
- **THEN** 先创建乐观本地消息（`id = "local-{timestamp}"`，`type = .text`，`time = "刚刚"`）
- **AND** 追加到 `messages` 末尾
- **AND** 异步调用 `IMService.shared.sendMessage(text, conversationId:, replyMessage:)`
- **AND** 发送成功后用服务端返回的消息替换本地消息
- **AND** 若引用了消息，发送后自动清除 `quotedMessage`

#### Scenario: 发送图片消息
- **WHEN** ViewController 调用 `viewModel.sendImage(_ image: UIImage)`
- **THEN** 先保存图片到临时目录 → 创建乐观本地消息
- **AND** 异步调用 `IMService.shared.sendImage(image, conversationId:, replyMessage:)`
- **AND** 发送成功后替换本地消息

#### Scenario: 发送语音消息
- **WHEN** ViewController 调用 `viewModel.sendVoice(localPath: String, duration: Int)`
- **THEN** 异步调用 `IMService.shared.sendVoice(localPath:, duration:, conversationId:, replyMessage:)`
- **AND** 发送成功后替换本地消息

#### Scenario: 快捷回复
- **WHEN** ViewController 调用 `viewModel.quickReplies(for:)` 获取快捷回复列表
- **THEN** ViewModel 根据 `conversation.role` 返回对应的文案数组
- **AND** 不包含 UI 构建逻辑（UI 构建由 ViewController 负责）

### Requirement: Message Actions

`ChatViewModel` SHALL 封装消息操作：撤回、引用、复制、引用预览点击。

#### Scenario: 撤回消息
- **WHEN** ViewController 调用 `viewModel.recallMessage(_ message: ChatMessage)`
- **THEN** 调用 `IMService.shared.recallMessage(messageId:)`
- **AND** 成功后将对应消息替换为 `type = .recall` 的提示消息
- **AND** 返回 `Bool` 表示成功/失败

#### Scenario: 引用消息
- **WHEN** ViewController 调用 `viewModel.startQuote(_ message: ChatMessage)`
- **THEN** 设置 `quotedMessage = message`

#### Scenario: 取消引用
- **WHEN** ViewController 调用 `viewModel.dismissQuote()`
- **THEN** 设置 `quotedMessage = nil`

#### Scenario: 复制消息文本
- **WHEN** ViewController 调用 `viewModel.copyMessageText(_ message: ChatMessage) -> String?`
- **THEN** 返回 `message.text`（供 ViewController 写入 `UIPasteboard`）

#### Scenario: 引用预览交互
- **WHEN** ViewController 调用 `viewModel.handleQuotePreviewTap(reply:)` 判断点击行为
- **THEN** 返回一个 enum 指示后续操作：`.showImage(path)` / `.playVoice(path)` / `.playVideo(path)` / `.none`
- **AND** ViewController 根据返回值执行对应的 UIKit 操作

### Requirement: Time Markers

`ChatViewModel` SHALL 提供时间标记插入逻辑。

#### Scenario: 插入日期分隔标记
- **WHEN** 消息列表发生变化（首次加载、翻页）
- **THEN** ViewModel 调用 `insertTimeMarkers(_:)` 方法
- **AND** 比较相邻消息的 `sentTime`，跨天时插入 `type = .timeMarker` 的 `ChatMessage`
- **AND** 日期格式：今天 / 昨天 / MM-dd / yyyy-MM-dd

### Requirement: ChatViewController Refactor

`ChatViewController` SHALL 只保留 UI 职责和 UIKit 特有逻辑。

#### Scenario: 留在 ViewController 的代码
- **WHEN** 完成重构
- **THEN** 以下逻辑保留在 ViewController：
  - `setupUI()` — 所有 UI 布局（tableView、inputBar、quickReplyButtons 等）
  - `keyboardWillShow/Hide` — 键盘适配
  - `UIImagePickerControllerDelegate` — 图片选择
  - `UILongPressGestureRecognizer` — 语音录制手势（录音由 `AudioRecorder` 处理）
  - `MessageActionMenu` — 长按菜单 UI
  - `QuotePreviewBar` — 引用预览条 UI
  - `scrollToBottom` — 滚动控制
  - `showToast` — Toast 提示
  - `showImagePreview` — 图片预览
  - `playAudioFile` — 语音播放

#### Scenario: 移除的代码
- **WHEN** 完成重构
- **THEN** 以下代码从 ViewController 移除：
  - `private var messages: [ChatMessage]` → 改为 `viewModel.messages`
  - `private var isLoadingMore / hasMoreMessages / lastTimestamp` → ViewModel
  - `private var isVoiceMode / quotedMessage` → ViewModel
  - `loadMessages()` 方法 → `viewModel.loadMessages()`
  - `handleRefresh()` 方法 → `viewModel.loadOlderMessages()`
  - `send(text:)` 方法 → `viewModel.sendText(text)`
  - `sendImage(_:)` 方法 → `viewModel.sendImage(image)`
  - `handleCopy/Recall/Quote` 方法 → ViewModel
  - `performRecall` / `replaceMessageWithRecall` → ViewModel
  - `insertTimeMarkers` / `parseMessageDate` / `parseTime` / `formatDateMarker` → ViewModel
  - `setupRealtimeSubscription()` → ViewModel.init 中自动订阅
  - `setupQuickReplies` 中的 reply 文案 → `viewModel.quickReplies(for:)`

#### Scenario: ViewModel 桥接
- **WHEN** ViewModel 需要通知 ViewController 执行 UI 操作（如 Toast、滚动）
- **THEN** 使用 `PassthroughSubject` 回调风格：
  - `toastPublisher: PassthroughSubject<String, Never>` — 提示信息
  - `scrollToBottomPublisher: PassthroughSubject<Bool, Never>` — 滚动指令
  - `presentImagePreviewPublisher: PassthroughSubject<String, Never>` — 图片预览

---

## States

| State | 表现 |
|-------|------|
| **默认** | 消息流加载完成，自动滚至底部 |
| **加载中** | `isLoadingMore == true` 时 refreshControl 显示 loading |
| **发送中** | 乐观消息已展示，发送成功后替换 |
| **发送失败** | 乐观消息保留（当前无失败标记，后续可扩展） |
| **无更多消息** | `hasMoreMessages == false` 时下拉不触发请求 |
| **引用模式** | `quotedMessage != nil` 时显示引用预览条 |
| **实时消息** | Combine 订阅自动追加新消息 |

## Acceptance Checklist

- [ ] `PL/Message/Chat/ViewModels/ChatViewModel.swift` 文件存在
- [ ] `ChatViewModel` 为 `struct`，包含上述全部 `@Published` 属性和方法
- [ ] `ChatViewController.messages` 改为 `viewModel.messages`
- [ ] 文本、图片、语音发送均通过 ViewModel
- [ ] 撤回、引用、复制操作通过 ViewModel
- [ ] 历史消息加载和翻页通过 ViewModel
- [ ] 实时消息订阅在 ViewModel.init 中自动启动
- [ ] 时间标记插入逻辑在 ViewModel 中
- [ ] 所有聊天功能与重构前行为一致
- [ ] ViewController 代码量从 ~1175 行降到 ~875 行

---

## ConversationListViewModel

### Requirement: Data Ownership

`ConversationListViewModel` SHALL 作为会话列表的单一数据源。

#### Scenario: Published 状态
- **WHEN** ViewModel 初始化
- **THEN** `@Published var conversations: [Conversation]`
- **AND** `var totalUnread: Int`（遍历累加 unread）

### Requirement: Combine 订阅管理

ViewModel SHALL 在 `init` 中订阅 5 路数据源：`messageReceivedPublisher`、`remoteConversationListDidSyncPublisher`、`conversationDidSyncPublisher`、`messageSentPublisher`、`conversationMarkedReadPublisher`。

### Requirement: 缓存优先加载

- `loadData()` → 若 `IMService.hasLoadedConversations` 为 true，直接用缓存；否则 `forceReload()`
- `forceReload()` → 调用 `IMService.loadConversations()` 全量加载

### Requirement: 局部更新与降级

- `handleConversationUpdate` 匹配成功 → 置顶该会话；匹配失败 → 降级为 `forceReload()`
- `handleBatchConversationUpdate` → 遍历本地 conversations 批量更新 unread/lastMessage

### Requirement: ViewController 重构

| 移到 ViewModel | 留在 VC |
|---|---|
| conversations 数组、5 路订阅、loadData/forceReload、增量/批量更新逻辑 | TeamBannerCell、TableView dataSource/delegate、导航、onDataChanged |

### Acceptance Checklist

- [ ] `PL/Message/ViewModels/ConversationListViewModel.swift` 创建
- [ ] 5 路订阅在 ViewModel.init 中自动启动
- [ ] VC 通过 `$conversations` 驱动 TableView
- [ ] Tab Bar 角标通过 `totalUnread` 正常更新
- [ ] VC 代码量从 ~270 行降到 ~160 行
