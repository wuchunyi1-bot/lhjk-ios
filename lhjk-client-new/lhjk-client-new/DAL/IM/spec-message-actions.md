# 消息长按操作 Spec — 复制 / 撤回 / 引用回复 / 远端消息加载

> 基于 RongIMLibCore 5.x，参考 Web 端 `message-send.md`

---

## 1. 需求概述

长按消息气泡弹出操作菜单，支持三个操作：

| 操作 | 适用条件 | 行为 |
|------|----------|------|
| **复制** | 仅 `type == .text` | 复制文本到系统剪贴板 |
| **撤回** | `role == .user` 且发送距今 ≤ 60 分钟 | 调融云 `recallMessage`，成功后本地替换为撤回通知 |
| **引用** | 所有非 `.recall` / `.timeMarker` 的消息 | 记录被引用消息，输入栏上方展示引用预览，发送时将引用信息写入 `content.extra` |

---

## 2. 整体流程

```
长按气泡
  → 命中 Cell 的 bubbleView
  → delegate 回传 (ChatMessage, IndexPath) 给 ChatViewController
  → ChatViewController 计算菜单按钮可见性
  → 展示 MessageActionMenu（自定义 UIView）
  → 用户点击按钮
      ├─ 复制 → UIPasteboard + Toast
      ├─ 撤回 → 确认弹窗 → RongCloudManager.recallMessage → 本地替换
      └─ 引用 → 记录 quotedMessage → 显示引用预览栏 → 下次发送带 extra
```

---

## 3. 各层改动明细

### 3.1 DAL — RongCloudManager 新增 API

#### 3.1.1 撤回消息

```swift
/// 撤回消息（融云限制：仅自己发送的消息，60 分钟内）
func recallMessage(messageId: Int, completion: @escaping (Bool) -> Void) {
    client.getMessage(messageId) { [weak self] message in
        guard let self, let message else {
            completion(false)
            return
        }
        self.client.recallMessage(message, success: { msgId in
            print("[RongCloud] recallMessage ✓ messageId=\(msgId)")
            completion(true)
        }, error: { errorCode in
            print("[RongCloud] recallMessage ✗ messageId=\(messageId) code=\(errorCode.rawValue)")
            completion(false)
        })
    }
}
```

**融云 SDK 签名：**
```objc
- (void)recallMessage:(RCMessage *)message
              success:(nullable void (^)(long messageId))successBlock
                error:(nullable void (^)(RCErrorCode errorCode))errorBlock;
```

**说明：**
- 撤回成功后，融云 SDK 会自动下发 `RC:RcNtf`（`RCRecallNotificationMessage`）到会话内所有成员
- 接收端 `fromRongCloud` 已支持解析 `RCRecallNotificationMessage` → `MessageType.recall`
- 本地也需要主动将消息替换为撤回样式（不等回调）

#### 3.1.2 发送方法增加 `extra` 参数（引用回复用）

现有发送方法签名不变，**在各 send 方法内部**，构造 message content 后设置 `extra`：

```swift
// 以 sendTextMessage 为例，新增 extra 参数
func sendTextMessage(
    conversationType: RCConversationType,
    targetId: String,
    content: String,
    extra: String? = nil,           // ← 新增：引用回复 JSON
    senderUserInfo: RCUserInfo? = nil,
    completion: @escaping (RCMessage?, RCErrorCode) -> Void
) {
    let textMsg = RCTextMessage(content: content)
    textMsg.extra = extra           // ← 设置引用信息
    // ... 其余不变
}
```

**所有 6 个发送方法都需要加 `extra: String? = nil` 参数：**
- `sendTextMessage`
- `sendImageMessage`（`RCImageMessage` 继承 `RCMessageContent`，有 `extra`）
- `sendHQVoiceMessage`（`RCHQVoiceMessage` 同样有 `extra`）
- `sendFileMessage`（自定义 `FileMessage` 继承 `RCMessageContent`）
- `sendVideoMessage`（自定义 `VideoMessage`）
- `sendSysNotifyMessage`（自定义 `SysNotifyMessage`）

> `RCMessageContent.extra` 是基类属性，所有消息类型均可设置。

---

### 3.2 BLL — IMService 新增能力

#### 3.2.1 撤回消息

```swift
/// 撤回消息，成功返回 true
func recallMessage(_ messageId: Int) async -> Bool {
    await withCheckedContinuation { continuation in
        RongCloudManager.shared.recallMessage(messageId: messageId) { success in
            continuation.resume(returning: success)
        }
    }
}
```

#### 3.2.2 发送方法增加引用参数

所有 `sendXxx` 方法增加 `replyMessage: ReplyMessage? = nil` 参数：

```swift
func sendMessage(_ text: String, conversationId: String, 
                 replyMessage: ReplyMessage? = nil) async -> ChatMessage? {
    let extra = replyMessage.flatMap { ReplyMessage.toExtraJSON($0) }
    // 传给 RongCloudManager.sendTextMessage(extra: extra, ...)
}
```

同理：`sendImage`、`sendVoice`、`sendFile`、`sendVideo`、`sendSysNotify`。

#### 3.2.3 构建引用 JSON

在 `ReplyMessage` 上增加序列化方法：

```swift
extension ReplyMessage {
    /// 将引用信息序列化为 content.extra JSON 字符串
    static func toExtraJSON(_ reply: ReplyMessage) -> String? {
        let payload = ExtraPayload(replyMessage: reply)
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// ExtraPayload 已有：private struct ExtraPayload: Codable { let replyMessage: ReplyMessage? }
// 需要把 ExtraPayload 访问级别改为 internal（去掉 private）
```

---

### 3.3 Message 模型扩展

#### 3.3.1 ChatMessage 增加计算属性

```swift
extension ChatMessage {
    /// 是否可撤回：自己发的，发送距今 ≤ 60 分钟
    var canRecall: Bool {
        guard role == .user, let sent = sentTime, sent > 0 else { return false }
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        return (nowMs - sent) <= 60 * 60 * 1000  // 60 min
    }

    /// 是否可复制：仅文本消息
    var canCopy: Bool { type == .text }

    /// 是否可引用：非撤回、非时间标记
    var canQuote: Bool { type != .recall && type != .timeMarker }

    /// 引用所需的 objectName（融云消息类型标识）
    var quoteObjectName: String {
        switch type {
        case .text:   return "RC:TxtMsg"
        case .image:  return "RC:ImgMsg"
        case .voice:  return "RC:HQVCMsg"
        case .file:   return "AD:FileMsg"
        case .video:  return "AD:VideoMsg"
        case .sysNotify: return "AD:SysNotify"
        default:      return "RC:TxtMsg"
        }
    }

    /// 引用所需的预览文本
    var quotePreviewText: String {
        if let t = text, !t.isEmpty { return t }
        switch type {
        case .image:  return "[图片]"
        case .voice:  return "[语音]"
        case .file:   return fileContent?.fileName ?? "[文件]"
        case .video:  return "[视频]"
        case .sysNotify: return sysNotifyContent?.title ?? "[套餐]"
        default:      return ""
        }
    }
}
```

#### 3.3.2 ReplyMessage 工厂方法

```swift
extension ReplyMessage {
    /// 从 ChatMessage 构建引用信息
    static func from(_ msg: ChatMessage) -> ReplyMessage {
        ReplyMessage(
            text: msg.quotePreviewText,
            senderName: msg.senderName ?? "",
            messageType: msg.quoteObjectName
        )
    }
}
```

#### 3.3.3 calcLastText 按消息类型区分

**规则**：`calcLastText` 的值取决于 `calcLastType`：

| calcLastType | calcLastText 内容 | 说明 |
|---|---|---|
| `RC:TxtMsg` | 消息文本内容 | 纯文本预览 |
| `RC:ImgMsg` | 远程图片 URL | 展示缩略图 |
| `RC:HQVCMsg` | 远程语音 URL | 展示语音图标 + 时长 |
| `AD:VideoMsg` | 视频 URL（优先 cover URL） | 展示封面缩略图 |
| `AD:FileMsg` | 文件 URL | 展示文件图标 + 文件名 |
| `AD:SysNotify` | 套餐标题 | 文本预览 |

**`ReplyMessage` 模型扩展**：

```swift
struct ReplyMessage: Codable {
    let text: String         // calcLastText — 文本或远程 URL
    let senderName: String   // calcLastName
    let messageType: String  // calcLastType
    // 可选附加字段（仅媒体类型有值）
    var duration: Int?       // 语音/视频时长（秒）
    var fileName: String?    // 文件名
    var fileSize: String?    // 文件大小

    // 类型判断
    var isImage: Bool { messageType == "RC:ImgMsg" }
    var isVoice: Bool { messageType == "RC:HQVCMsg" }
    var isVideo: Bool { messageType == "AD:VideoMsg" }
    var isFile: Bool  { messageType == "AD:FileMsg" }
    var isMediaType: Bool { isImage || isVoice || isVideo }
}
```

**JSON 格式（向后兼容）**：

核心 3 字段保持不变，附加字段可选：
```json
{
  "replyMessage": {
    "calcLastText": "https://xxx/image.jpg",
    "calcLastName": "张三",
    "calcLastType": "RC:ImgMsg",
    "duration": null,
    "fileName": null,
    "fileSize": null
  }
}
```

**`ReplyMessage.from(_:)` 更新**：

```swift
static func from(_ msg: ChatMessage) -> ReplyMessage {
    ReplyMessage(
        text: msg.quotePreviewText,    // 文本或远程 URL
        senderName: msg.senderName ?? "",
        messageType: msg.quoteObjectName,
        duration: msg.quoteMediaDuration,
        fileName: msg.quoteMediaFileName,
        fileSize: msg.quoteMediaFileSize
    )
}
```

**`ChatMessage.quotePreviewText` 更新**：

```swift
var quotePreviewText: String {
    switch type {
    case .text:
        return text ?? ""
    case .image:
        return imagePath ?? ""       // 远程 URL
    case .voice:
        return imagePath ?? ""       // 远程 URL
    case .video:
        return videoContent?.videoCoverImg ?? videoContent?.videoUrl ?? ""
    case .file:
        return fileContent?.fileUrl ?? ""
    case .sysNotify:
        return sysNotifyContent?.title ?? "[套餐]"
    default:
        return ""
    }
}
```

**新增引用辅助计算属性**：

```swift
/// 引用消息的媒体时长（语音/视频）
var quoteMediaDuration: Int? {
    switch type {
    case .voice: return thumbHeight  // duration 存在 thumbHeight
    case .video: return videoContent?.videoTime
    default:     return nil
    }
}

/// 引用消息的文件名
var quoteMediaFileName: String? {
    switch type {
    case .file:  return fileContent?.fileName
    case .video: return videoContent?.videoName
    default:     return nil
    }
}

/// 引用消息的文件大小
var quoteMediaFileSize: String? {
    switch type {
    case .file: return fileContent?.fileSize
    default:    return nil
    }
}
```

---

#### 3.3.4 引用展示样式（按类型）

##### QuotePreviewBar（输入栏上方预览条）

| calcLastType | 展示内容 |
|---|---|
| `RC:TxtMsg` | 左侧竖线 + "回复 xxx" + 文本预览（单行截断） |
| `RC:ImgMsg` | 左侧竖线 + "回复 xxx" + 32×32 缩略图（Kingfisher 加载 `calcLastText`） |
| `RC:HQVCMsg` | 左侧竖线 + "回复 xxx" + 语音图标（SF Symbol `waveform`）+ 时长 `N"` |
| `AD:VideoMsg` | 左侧竖线 + "回复 xxx" + 32×32 封面缩略图 |
| `AD:FileMsg` | 左侧竖线 + "回复 xxx" + 文件图标 + 文件名 |
| `AD:SysNotify` | 左侧竖线 + "回复 xxx" + 文本预览 |

##### 消息气泡内引用区（replyView）

同样的展示规则，32×32 缩略图或图标，staff 左对齐 / user 右对齐。

##### 点击行为

| 类型 | 点击效果 |
|---|---|
| `RC:ImgMsg` | 全屏预览图片（`ImagePreviewViewController`） |
| `RC:HQVCMsg` | 播放语音（`AVAudioPlayer`） |
| `AD:VideoMsg` | 播放视频（预留，当前可 Toast "视频播放"） |
| 其他 | 无操作（或滚动到被引用消息位置，后续实现） |

**QuotePreviewBar 新增回调**：
```swift
var onTap: (() -> Void)?   // 点击引用内容区域时触发
```

**TextBubbleCell replyView 新增手势**：
- 在 replyView 上添加 `UITapGestureRecognizer`
- 通过 delegate 回调给 `ChatViewController` 处理

---

### 3.4 PL — 消息操作菜单 UI

#### 3.4.1 新增文件：`PL/Message/Chat/MessageActionMenu.swift`

自定义横向按钮菜单，参考微信：

```
┌──────────────────────────────┐
│  ┌──────┐ ┌──────┐ ┌──────┐ │
│  │ 复制  │ │ 撤回  │ │ 引用  │ │
│  └──────┘ └──────┘ └──────┘ │
└──────────────────────────────┘
```

**设计：**
- 容器：白色圆角背景 + 阴影，水平包裹按钮
- 每个按钮：icon（SF Symbol）+ 文字，垂直排列
- 按钮宽度 ~56pt，文字 font 11
- 菜单位置：计算被长按 Cell 在屏幕上的位置，优先显示在气泡上方
- 点击空白区域 / 滚动 tableView 时消失

**按钮配置：**

| 按钮 | SF Symbol | 文字 | 可见条件 |
|------|-----------|------|----------|
| 复制 | `doc.on.doc` | 复制 | `msg.canCopy` |
| 撤回 | `arrow.uturn.backward` | 撤回 | `msg.canRecall` |
| 引用 | `arrowshape.turn.up.left` | 引用 | `msg.canQuote` |

**API：**
```swift
final class MessageActionMenu: UIView {
    /// 点击回调，返回操作类型
    var onAction: ((Action) -> Void)?

    enum Action { case copy, recall, quote }

    /// 配置并展示在指定位置
    func configure(above sourceRect: CGRect, in containerView: UIView, actions: [Action])
    func dismiss()
}
```

#### 3.4.2 新增文件：`PL/Message/Chat/QuotePreviewBar.swift`

输入栏上方的引用预览条：

```
┌──────────────────────────────────────────┐
│  ┃  回复 张三                             │
│  ┃  老张你好...                    ✕     │
└──────────────────────────────────────────┘
```

**设计：**
- 左侧竖线（fdPrimary 色，2pt 宽）
- 上方：`回复 xxx`（fdPrimary 色，font 11）
- 下方：被引用消息预览文本（fdSubtext 色，font 12，单行截断）
- 右侧：关闭按钮（`xmark`）
- 背景 `.white`，高度 52pt

**API：**
```swift
final class QuotePreviewBar: UIView {
    var onDismiss: (() -> Void)?
    func configure(with reply: ReplyMessage)
    func dismiss()
}
```

#### 3.4.3 ChatViewController 改动

##### a. Cell 长按回调

为每种消息 Cell 添加长按手势，通过 delegate 模式回调：

```swift
protocol ChatCellDelegate: AnyObject {
    func cellDidLongPress(_ cell: UITableViewCell, message: ChatMessage)
}
```

在 `ChatViewController.cellForRowAt` 中设置 `cell.delegate = self`。

**实现方式（两种可选）：**

**方案 A（推荐）：** 在每个 Cell 的 `bubbleView` 上添加 `UILongPressGestureRecognizer`，Cell 内部处理手势，通过 delegate 回调。

**方案 B：** 使用 `UITableViewDelegate` 的 `contextMenuConfigurationForRowAt`（iOS 13+），但自定义程度低，不推荐。

##### b. 菜单展示与交互

```swift
// ChatViewController
private var actionMenu: MessageActionMenu?
private var quotePreviewBar: QuotePreviewBar?
private var quotedMessage: ChatMessage?  // 当前引用的消息

func cellDidLongPress(_ cell: UITableViewCell, message: ChatMessage) {
    // 1. 计算菜单位置
    let cellRect = cell.convert(cell.bounds, to: view)
    
    // 2. 构建可见按钮列表
    var actions: [MessageActionMenu.Action] = []
    if message.canCopy { actions.append(.copy) }
    if message.canRecall { actions.append(.recall) }
    if message.canQuote { actions.append(.quote) }
    
    // 3. 展示菜单
    actionMenu?.dismiss()
    let menu = MessageActionMenu()
    menu.onAction = { [weak self] action in
        self?.handleAction(action, message: message)
    }
    menu.configure(above: cellRect, in: view, actions: actions)
    view.addSubview(menu)
    actionMenu = menu
}

private func handleAction(_ action: MessageActionMenu.Action, message: ChatMessage) {
    actionMenu?.dismiss()
    switch action {
    case .copy:    handleCopy(message)
    case .recall:  handleRecall(message)
    case .quote:   handleQuote(message)
    }
}
```

##### c. 复制

```swift
private func handleCopy(_ message: ChatMessage) {
    UIPasteboard.general.string = message.text
    showToast("已复制")
}
```

##### d. 撤回

```swift
private func handleRecall(_ message: ChatMessage) {
    let alert = UIAlertController(title: "撤回消息", message: "确定撤回这条消息吗？", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "取消", style: .cancel))
    alert.addAction(UIAlertAction(title: "撤回", style: .default) { [weak self] _ in
        self?.performRecall(message)
    })
    present(alert, animated: true)
}

private func performRecall(_ message: ChatMessage) {
    guard let msgId = Int(message.id) else { return }
    Task {
        let success = await IMService.shared.recallMessage(msgId)
        await MainActor.run {
            if success {
                // 本地替换为撤回样式
                if let idx = messages.firstIndex(where: { $0.id == message.id }) {
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
                        extra: nil, reply: nil
                    )
                    messages[idx] = recalMsg
                    tableView.reloadRows(at: [IndexPath(row: idx, section: 0)], with: .fade)
                }
                showToast("已撤回")
            } else {
                showToast("撤回失败，请重试")
            }
        }
    }
}
```

> **注意**：撤回成功后融云也会下发 `RC:RcNtf`，收到后 `fromRongCloud` 会再次转换为 `.recall`。由于本地已经替换过，`reloadRows` 是幂等的。如果不想重复刷新，可以在收到 `RC:RcNtf` 时判断 `messages` 中是否已经存在 `.recall` 类型的同 ID 消息。

##### e. 引用回复

```swift
private func handleQuote(_ message: ChatMessage) {
    quotedMessage = message
    showQuotePreview(for: ReplyMessage.from(message))
}

private func showQuotePreview(for reply: ReplyMessage) {
    quotePreviewBar?.removeFromSuperview()
    let bar = QuotePreviewBar()
    bar.configure(with: reply)
    bar.onDismiss = { [weak self] in
        self?.dismissQuote()
    }
    // 插入到 inputBar 上方
    view.insertSubview(bar, belowSubview: inputBar)
    bar.snp.makeConstraints { make in
        make.leading.trailing.equalToSuperview()
        make.bottom.equalTo(inputBar.snp.top)
        make.height.equalTo(52)
    }
    quotePreviewBar = bar
}

private func dismissQuote() {
    quotedMessage = nil
    quotePreviewBar?.removeFromSuperview()
}
```

##### f. 发送时带上引用

修改 `send(text:)`、`sendImage(_:)` 等所有发送入口：

```swift
private func send(text: String) {
    let reply = quotedMessage.flatMap { ReplyMessage.from($0) }
    // ... 乐观展示本地消息 ...
    Task {
        let sentMsg = await IMService.shared.sendMessage(
            text, 
            conversationId: conversationId,
            replyMessage: reply  // ← 传入引用
        )
        // ...
        await MainActor.run {
            self.dismissQuote()  // 发送成功后清除引用
        }
    }
}
```

##### g. 点击空白关闭菜单

```swift
// 在 viewDidLoad 或 setupUI 中添加 tap gesture
let tap = UITapGestureRecognizer(target: self, action: #selector(dismissActionMenu))
tap.cancelsTouchesInView = false
tableView.addGestureRecognizer(tap)
// 或重写 touchesBegan
```

Scroll 时关闭菜单：

```swift
func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    actionMenu?.dismiss()
}
```

---

### 3.5 Cell 改动

#### TextBubbleCell（及其他 Cell）

每个有 bubble 的 Cell 需要：
1. 添加 `weak var delegate: ChatCellDelegate?`
2. 在 `bubbleView` 上添加 `UILongPressGestureRecognizer`
3. 在手势回调中调用 `delegate?.cellDidLongPress(self, message: currentMessage)`

```swift
// 以 TextBubbleCell 为例
private var currentMessage: ChatMessage?
private var longPressGesture: UILongPressGestureRecognizer!

// 在 init 中添加手势
longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
bubbleView.addGestureRecognizer(longPressGesture)

@objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
    guard gesture.state == .began, let msg = currentMessage else { return }
    delegate?.cellDidLongPress(self, message: msg)
}

// 在 configure 中缓存 message
func configure(...) {
    self.currentMessage = msg
    // ...
}
```

**需要修改的 Cell 清单：**
- `TextBubbleCell` ✅
- `ImageBubbleCell` ✅
- `VoiceBubbleCell` ✅
- `FileBubbleCell` ✅
- `VideoBubbleCell` ✅
- `SysNotifyCell` ✅
- `ServiceCardCell` — 无 bubble 概念，暂不加
- `MealAnalysisCell` — 无 bubble 概念，暂不加
- `AIWeeklyReportCell` — 无 bubble 概念，暂不加

---

## 7. 远端消息加载 — 重构

> **2026-07-02 重构**：融云官方回复，拉取历史消息应使用 `getMessages` + `RCHistoryMessageOption`，而非 `getRemoteHistoryMessages` + `RCRemoteHistoryMsgOption`。

### 7.1 当前问题

`getRemoteHistoryMessages` 返回的消息 `messageId` 可能为 `-1`（未入库），导致依赖 `messageId` 的操作全部失效：
- 语音下载播放 ❌
- 撤回消息 ❌
- 已读回执 ❌

### 7.2 融云推荐 API

```objc
// RCCoreClient.h:1745
- (void)getMessages:(RCConversationType)conversationType
           targetId:(NSString *)targetId
             option:(RCHistoryMessageOption *)option
           complete:(nullable void (^)(NSArray<RCMessage *> *_Nullable messages,
                                        long long timestamp,
                                        BOOL isRemaining,
                                        RCErrorCode code))complete
              error:(nullable void (^)(RCErrorCode status))errorBlock;
```

**`RCHistoryMessageOption`**：

```objc
@interface RCHistoryMessageOption : NSObject
@property (nonatomic, assign) long long recordTime;        // 起始时间戳（毫秒），首次传 0
@property (nonatomic, assign) NSInteger count;              // 1 < count <= 100
@property (nonatomic, assign) RCHistoryMessageOrder order; // Desc（降序）/ Asc（升序），默认降序
@end
```

### 7.3 翻页规则

```
首次进入 → getMessages(recordTime: 0, count: 20)
    → 回调返回 (messages, timestamp, isRemaining, code)
    → 消息正常入库，messageId > 0 ✅

下拉加载更多 → getMessages(recordTime: timestamp, count: 20)
    → timestamp 是上次回调返回的服务端游标
    → isRemaining == false → 没有更多了
```

### 7.4 DAL — RongCloudManager 改动

#### 7.4.1 删除旧方法

- ❌ `getRemoteMessages(targetId:recordTime:count:order:includeLocal:)` — **删除**
- ❌ `RCRemoteHistoryMsgOption` — **不再使用**

#### 7.4.2 新增方法

```swift
/// 拉取历史消息（融云推荐 API，使用 RCHistoryMessageOption）
/// - Parameters:
///   - targetId: 会话 ID
///   - recordTime: 起始时间戳（毫秒），首次传 0
///   - count: 拉取数量
///   - order: 拉取顺序，默认降序
/// - Returns: (消息列表, 下次翻页用的 timestamp, 是否还有更多)
func getHistoryMessages(
    targetId: String,
    recordTime: Int64 = 0,
    count: Int = 20,
    order: RCHistoryMessageOrder = .desc
) async -> (messages: [RCMessage], timestamp: Int64, isRemaining: Bool)
```

内部调用 `client.getMessages(.ConversationType_GROUP, targetId: targetId, option: option, complete: ..., error: ...)`。

### 7.5 BLL — IMService 改动

#### 7.5.1 `loadMessages` — 直接调用新 API

```swift
func loadMessages(conversationId: String) async -> (messages: [ChatMessage], timestamp: Int64, isRemaining: Bool) {
    let (rcMessages, timestamp, isRemaining) = await RongCloudManager.shared.getHistoryMessages(
        targetId: conversationId,
        recordTime: 0,
        count: 20
    )
    sendReadReceiptsIfNeeded(rcMessages)
    let chatMessages = rcMessages.map { ChatMessage.fromRongCloud(rcMessage: $0) }.reversed()
    messagesStore[conversationId] = Array(chatMessages)
    return (Array(chatMessages), timestamp, isRemaining)
}
```

#### 7.5.2 `loadOlderMessages` — 用 timestamp 翻页

```swift
func loadOlderMessages(conversationId: String, timestamp: Int64) async -> (messages: [ChatMessage], timestamp: Int64, isRemaining: Bool) {
    let (rcMessages, newTimestamp, isRemaining) = await RongCloudManager.shared.getHistoryMessages(
        targetId: conversationId,
        recordTime: timestamp,
        count: 20
    )
    sendReadReceiptsIfNeeded(rcMessages)
    let older = rcMessages.map { ChatMessage.fromRongCloud(rcMessage: $0) }.reversed()
    messagesStore[conversationId] = Array(older) + (messagesStore[conversationId] ?? [])
    return (Array(older), newTimestamp, isRemaining)
}
```

> **参数变更**：`beforeSentTime: Int64` → `timestamp: Int64`，语义从"消息时间戳"变为"服务端翻页游标"。

### 7.6 PL — ChatViewController 改动

#### 7.6.1 新增 `lastTimestamp` 状态

```swift
private var lastTimestamp: Int64 = 0
```

#### 7.6.2 `loadMessages` 保存 timestamp

```swift
private func loadMessages() {
    Task {
        let (msgs, timestamp, isRemaining) = await IMService.shared.loadMessages(conversationId: conversationId)
        await MainActor.run {
            lastTimestamp = timestamp
            hasMoreMessages = isRemaining
            // ... 其余不变
        }
    }
}
```

#### 7.6.3 `handleRefresh` 用 timestamp 翻页

```swift
@objc private func handleRefresh() {
    guard !isLoadingMore, hasMoreMessages else { ... }
    isLoadingMore = true
    Task {
        let (olderMessages, newTimestamp, isRemaining) = await IMService.shared.loadOlderMessages(
            conversationId: conversationId,
            timestamp: lastTimestamp
        )
        await MainActor.run {
            lastTimestamp = newTimestamp
            if !isRemaining { hasMoreMessages = false }
            // 去重 + insertTimeMarkers + reloadData
            // ... 其余不变（去掉 beforeSentTime 相关逻辑）
        }
    }
}
```

### 7.7 副作用：修复 messageId = -1 问题

新 API 返回的消息正常存入本地 DB，`rcMessage.messageId > 0` 可靠，以下操作自然修复：
- `VoiceBubbleCell` 语音下载（`downloadMediaMessage`）
- `sendReadReceiptRequest` 已读回执
- `recallMessage` 撤回消息

### 7.8 改动文件清单

```
修改文件：
  DAL/IM/RongCloudManager.swift     ← 删除 getRemoteMessages()，新增 getHistoryMessages()
  BLL/Message/IMService.swift       ← loadMessages / loadOlderMessages 适配新签名（timestamp 代替 beforeSentTime）
  PL/Message/Chat/ChatViewController.swift ← loadMessages / handleRefresh 适配
```

### 7.9 边界情况

| 场景 | 处理 |
|------|------|
| 远端返回空 + isRemaining=false | 会话无历史消息，`hasMoreMessages=false` |
| 首次加载 20 条，isRemaining=true | 保存 `timestamp`，允许下拉翻页 |
| 翻页返回 0 条，isRemaining=false | `hasMoreMessages=false`，下拉不再触发 |
| 网络断开拉远端失败 | error 回调返回 `([], 0, false)`，保留当前列表 |
| `messageId` 为 -1 | 不再出现（新 API 消息正常入库） |

---

## 4. 改动文件清单（含远端加载）

```
新增文件：
  PL/Message/Chat/MessageActionMenu.swift     ← 长按操作菜单 UI 组件
  PL/Message/Chat/QuotePreviewBar.swift       ← 引用预览条 UI 组件

修改文件：
  DAL/IM/RongCloudManager.swift               ← 新增 recallMessage()，所有 sendXxx 加 extra 参数
  DAL/IM/Message.swift                        ← ChatMessage 加 canRecall/canCopy/canQuote/quoteObjectName/quotePreviewText；
                                                  ReplyMessage 加 from(ChatMessage)/toExtraJSON；
                                                  ExtraPayload 改为 internal
  BLL/Message/IMService.swift                 ← 新增 recallMessage()，所有 sendXxx 加 replyMessage 参数
  PL/Message/Chat/ChatViewController.swift    ← 长按回调、菜单交互、撤回/引用逻辑、引用预览、发送带引用
  PL/Message/Chat/Cells/TextBubbleCell.swift  ← 添加 delegate + 长按手势（已有 replyView）
  PL/Message/Chat/Cells/ImageBubbleCell.swift ← 同上
  PL/Message/Chat/Cells/VoiceBubbleCell.swift ← 同上
  PL/Message/Chat/Cells/FileBubbleCell.swift  ← 同上
  PL/Message/Chat/Cells/VideoBubbleCell.swift ← 同上
  PL/Message/Chat/Cells/SysNotifyCell.swift   ← 同上
```

---

## 5. 边界情况检查

| 场景 | 处理 |
|------|------|
| 用户快速连续长按两条消息 | `actionMenu?.dismiss()` 先关闭旧菜单再展示新的 |
| 正在展示菜单时收到新消息滚到底部 | `scrollViewWillBeginDragging` 关闭菜单 |
| 撤回消息时网络断开 | `recallMessage` 回调 `false`，Toast 提示 |
| 消息没有 `sentTime`（mock 数据） | `canRecall` 返回 `false` |
| message.id 不是纯数字（本地乐观消息） | `Int(message.id)` 返回 `nil`，不允许撤回 |
| 引用消息后切换键盘模式 | 引用预览保持显示 |
| 引用消息后点击另一个引用 | 替换 `quotedMessage`，更新预览 |
| 撤回后融云又下发 `RC:RcNtf` | `fromRongCloud` 已处理，`reloadRows` 幂等 |
| 引用消息时被引用消息已被撤回 | 发送前检查即可，极端情况允许发送（显示"已撤回"占位） |

---

## 6. 测试要点

- [ ] 长按文本消息 → 弹出菜单，三个按钮可见
- [ ] 长按图片消息 → 弹出菜单，仅"引用"可见
- [ ] 长按自己 5 分钟前发的消息 → "撤回"可见
- [ ] 长按 mock 数据（无 sentTime）→ "撤回"不可见
- [ ] 点击"复制" → Toast "已复制"，粘贴板有内容
- [ ] 点击"撤回" → 确认弹窗 → 成功后消息变为"你撤回了一条消息"
- [ ] 点击"引用" → 输入栏上方出现引用预览
- [ ] 引用预览中发送消息 → 消息带引用信息
- [ ] 接收端看到引用消息 → 气泡下方显示被引用内容
- [ ] 点击引用预览关闭按钮 → 预览消失
- [ ] 滚动列表 → 菜单消失
- [ ] 点击空白区域 → 菜单消失
