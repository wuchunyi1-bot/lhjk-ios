# lhjk-client-new 项目约定

## 线程安全：UI 必须在主线程

**规则**：所有 UIKit / SwiftUI 操作必须在主线程执行。

### NotificationCenter 通知 → UI 刷新

```
❌ 错误:
NotificationCenter.default.post(name: .xxx, object: nil)

✅ 正确:
await MainActor.run {
    NotificationCenter.default.post(name: .xxx, object: nil)
}
// 或
DispatchQueue.main.async {
    NotificationCenter.default.post(name: .xxx, object: nil)
}
```

**原因**：`NotificationCenter` 在 post 的线程**同步**投递回调。如果 post 在后台线程（如 `UserManager.refreshUserInfo()` 的 `Task` 上下文），所有 observer 的回调也在后台线程执行，此时调 UIKit → 崩溃。

### async/await 中的 UI 操作

```swift
Task {
    let result = try await someAsyncAPI()
    // ← 这里可能在任意线程
    await MainActor.run {
        // ✅ UI 操作放这里
        self.label.text = result.name
        self.tableView.reloadData()
    }
}
```

### Timer

```
❌ Timer.scheduledTimer(...)  // 默认 RunLoop mode，滚动时暂停

✅ RunLoop.main.add(timer, forMode: .common)  // 滚动不暂停，确保主线程
```

### 新增/修改代码检查清单

- [ ] `NotificationCenter.post` 是否包了 `MainActor.run` / `DispatchQueue.main.async`？
- [ ] `Task { }` 内的 UI 操作是否在 `await MainActor.run { }` 内？
- [ ] `Timer` 是否用了 `RunLoop.main.add(_:forMode:.common)`？
- [ ] observer 回调是否需要 `queue: .main`？

## 布局：避免 _UITemporaryLayoutWidth 约束冲突

**规则**：水平方向的 `equalToSuperview().inset()` 约束优先级不应为 `.required(1000)`，应降为 `750`。

```swift
// ❌ 可能在 _UITemporaryLayoutWidth == 0 时冲突
make.leading.trailing.equalToSuperview().inset(16)

// ✅ 静默容忍临时零宽测量
make.leading.trailing.equalToSuperview().inset(16).priority(750)
```

适用场景：
- 自定义 UIView 子类（直接 add 到 VC 的 view）
- `tableHeaderView` 的子视图
- 任何在 `systemLayoutSizeFitting` 中被测量的视图

## 用户数据：全局单例缓存

- `UserManager.shared.currentUser` — 读用户信息，不要在各页面重复调 API
- `UserManager.shared.fetchUserInfo()` — App 启动 / 登录成功后调用一次
- `UserManager.shared.refreshUserInfo()` — 用户修改个人信息后调用，会发 `.userDidUpdate` 通知

## 分层依赖：DAL 不依赖 BLL

**规则**：DAL（Data Access Layer）不能引用 BLL（Business Logic Layer）的类型或单例。依赖方向必须是 PL → BLL → DAL，不可反向。

```
✅ 正确:
PL (ChatViewController) → BLL (IMService) → DAL (RongCloudManager)
                         ↑ UserManager 只能在这层用

❌ 错误:
DAL (RongCloudManager) → BLL (UserManager)  // 下层依赖上层，方向反了
```

**做法**：如果 DAL 需要用户信息等 BLL 数据，由 BLL 作为参数传入 DAL 方法。
- DAL 方法加 `senderUserInfo: RCUserInfo? = nil` 参数
- BLL 从 `UserManager` 取值，调用时传入

### 检查清单

- [ ] DAL 文件（`DAL/` 目录）是否 import 或引用了 BLL 类型（`UserManager`、`IMService` 等）？
- [ ] DAL 方法的业务数据是否通过参数传入而非内部获取？

## 消息收发：senderUserInfo 解析与展示

**规则**：`fromRongCloud` 转换时必须从 `rcMessage.content.senderUserInfo` 提取发送者信息，填充到 `ChatMessage` 的 `senderName` / `avatar` 字段。

### 发送端（已就绪）

发送时由 BLL（`IMService.makeSenderUserInfo()`）构建 `RCUserInfo` 传入 DAL，融云带在消息中送达对端。

### 接收端（fromRongCloud 转换）

```
rcMessage.content?.senderUserInfo  →  ChatMessage
    .name                           →  senderName
    .name.prefix(1)                 →  avatar（首字符，UI 用作文本头像）
    .portraitUri                    →  （预留，当前 UI 为文字头像，暂不映射）
    .userId                         →  （预留）
```

**注意**：
- `avatar` 字段当前 UI 用作文本首字母（非图片），因此取 `name` 首字符而非 `portrait` URL
- 后续如需支持头像图片，可新增 `portraitUrl` 字段并在 Cell 中用 Kingfisher 加载
- `senderUserInfo` 对自己发的消息（`MessageDirection_SEND`）也有值，转换时一并填充
- `RCUserInfo` 无 role 字段，`senderRole` 不从该字段推导
- 文本消息和图片消息的 `senderUserInfo` 统一通过 `rcMessage.content?.senderUserInfo` 获取

### UI 展示

#### 头像 & 昵称

- `TextBubbleCell` — 读取 `msg.avatar`（头像文字）、`msg.senderName`（昵称行）
- `ImageBubbleCell` — 同上，`msg.avatar` → 头像，`msg.senderName` → 昵称行
- 自己发的消息（`.user`）头像固定显示 "我"，不受 senderUserInfo 影响

#### 消息时间位置

| 消息方向 | 时间位置 | 示例 |
|---|---|---|
| `.staff`（对方） | metaLabel 内，senderName 之后 | `"张三 · 医生 · 14:30"` |
| `.user`（自己） | 气泡下方独立 timeLabel | `"14:30"` |

- 对方消息时间跟在发送者信息后面，格式：`senderName · senderRole · time`（nil 值自动 compactMap 过滤）
- 自己发的消息时间保持在气泡下方，位置不变
- `ImageBubbleCell` 已按此规则实现；`TextBubbleCell` 需对齐

#### 自定义消息类型

融云 SDK 支持通过 `objectName` 区分的自定义消息类型。`fromRongCloud` 转换时需按 `objectName` 分派：

| objectName | MessageType | 解析方式 | text 取值 |
|---|---|---|---|
| `RC:TxtMsg` | `.text` | `RCTextMessage` | `textContent.content` |
| `RC:ImgMsg` | `.image` | `RCImageMessage` | `"[图片]"` |
| `AD:FileMsg` | `.file` | `RCMessageContent` | `content.extra` |
| `AD:VideoMsg` | `.video` | `RCMessageContent` | `content.extra` |
| `AD:SysNotify` | `.sysNotify` | `RCMessageContent` | `content.extra` |
| 其他 | `.text` | `RCMessageContent` | `""` |

**规则**：
- 不管哪种类型，统一通过 `rcMessage.content?.senderUserInfo` 提取发送者信息
- 自定义类型通过基类 `RCMessageContent` 的 `.extra` 字段拿附加数据
- 新增 `MessageType` 时同步更新 `ChatViewController` 的 cell 注册和 `cellForRow` 分发

### 检查清单

- [ ] `fromRongCloud` 是否从 `rcMessage.content?.senderUserInfo` 提取了 name → senderName, name.prefix(1) → avatar？
- [ ] 新增消息类型时，是否同样提取 senderUserInfo？
- [ ] 对方消息时间是否在 metaLabel 中（senderName 后面），而非独立 timeLabel？
- [ ] 新 objectName 是否在 `fromRongCloud` 的 else 分支中处理了类型分派？

## IM 消息适配：Web 端规范对标

> 参考文档：`/Users/chunyi/Desktop/lhjk/message-send.md`（Vue 3 + 融云 imlib-next 5.40）
> iOS 当前 SDK：RongIMLibCore 5.x

### 1. 整体架构对比

| 维度 | Web | iOS 现状 | 差距 |
|------|-----|---------|------|
| 会话类型 | 固定 `ConversationType.GROUP` | ✅ 已固定 | 无 |
| 文本消息 `RC:TxtMsg` | `{ content, user, extra?, mention? }` | ✅ 已实现 send/receive | 缺 @ 提及、引用回复 |
| 图片消息 `RC:ImgMsg` | `{ imageUri, content, user }` | ✅ 已实现 send/receive | 缺 OSS 上传流程 |
| 文件消息 `AD:FileMsg` | `{ fileUrl, fileName, fileSize, fileSuffix, user }` | ⚠️ 仅解析 else 分支 | **需完整实现** |
| 视频消息 `AD:VideoMsg` | `{ videoUrl, videoCoverImg, videoName, videoTime, user }` | ⚠️ 仅解析 else 分支 | **需完整实现** |
| 系统通知 `AD:SysNotify` | `{ businessData, title, content, imageUrl, urlKey, user }` | ⚠️ 仅解析 else 分支 | **需完整实现** |
| 群发 | 后端 `POST /im/v1/groupSend/sendGroupMessage` | ❌ 无 | 后续需求 |
| 撤回 | 融云 recall + 60min 窗口 | ❌ 无 | 后续需求 |
| @ 提及 | `MentionedInfo` + `sendOptions` | ❌ 无 | 后续需求 |
| 引用回复 | `content.extra.replyMessage` | ❌ 无 | 后续需求 |

### 2. 消息体公共结构（Web 端规则）

每种消息都携带 `user` 字段作为发送者信息：

```js
// user 字段 = senderUserInfo
{
  id: string,          // userId
  name: string,        // 显示名
  portrait: string,    // 头像 URL
  extra: JSON.stringify({ departmentName }),  // 附加（部门名等）
}
```

**iOS 对照**：`RCUserInfo` 有 `userId` / `name` / `portraitUri`，**但无法直接存储 `extra`（部门名）**。需评估是否通过 `RCUserInfo.extra` 传递，或从 `Conversation` 模型补充。

### 3. 自定义消息类型字段详解

#### 3.1 `AD:FileMsg` — 文件 / 音频 / 团队知识

| 字段 | 类型 | 说明 | 文件 | 音频 | 团队知识 |
|------|------|------|------|------|----------|
| `fileUrl` | String | OSS 文件地址 | ✅ | ✅ (contentUrl) | ✅ |
| `fileName` | String | 文件名 | ✅ | ✅ (audioName) | ✅ |
| `fileSize` | String | 格式化大小 "1.23MB" | ✅ | `""` | `""` |
| `fileSuffix` | String | 后缀 pdf/doc/mp3/richText | ✅ | `"mp3"` | `"richText"` |
| `fileTime` | Int? | 音频时长（秒） | ❌ | ✅ | ❌ |
| `imageUrl` | String? | 团队知识封面 | ❌ | ❌ | ✅ |
| `lastMsgDisplayContent` | String | 会话列表摘要 | `"[文件]"` | `"[音频]"` | `"[团队知识]"` |
| `user` | Object | 发送者 + `extra: { familySkip }` | ✅ | ✅ | ✅ |

#### 3.2 `AD:VideoMsg` — 视频

| 字段 | 类型 | 说明 |
|------|------|------|
| `videoUrl` | String | 视频地址 |
| `videoCoverImg` | String | 封面图 |
| `videoName` | String | 视频名 |
| `videoTime` | Int | 时长（秒） |
| `videoSuffix` | String | 后缀，固定 `"mp4"` |
| `lastMsgDisplayContent` | String | `"[视频]"` |
| `user` | Object | 发送者（含 `icon` 字段） |
| `extra` | JSON | `{ width, height }` |

#### 3.3 `AD:SysNotify` — 套餐

| 字段 | 类型 | 说明 |
|------|------|------|
| `businessData` | JSON string | `{ id, categoryServiceId, hospitalId, name, description, imageUrl }` |
| `title` | String | 套餐名 |
| `content` | String | 描述 |
| `isShowUser` | Bool | 是否展示发送者 |
| `imageUrl` | String | 套餐图片 |
| `urlKey` | String | 固定 `"SET_MEAL"` |
| `lastMsgDisplayContent` | String | `"[套餐]"` |
| `user` | Object | 发送者 |

### 4. iOS 适配范围（按优先级排序）

#### 🔴 P0 — 自定义消息注册与模型（发消息前提）

**4.1 注册自定义消息类型**
- 在 `RongCloudManager.initialize()` 后调用 `client.registerMessageType()` 注册 `AD:FileMsg`、`AD:VideoMsg`、`AD:SysNotify`
- 参考 Web 端 `src/im/messageTypes.js`

**4.2 创建自定义消息模型类（DAL）**
- 新建 `DAL/IM/CustomMessages/` 目录
- `FileMessage` — 继承 `RCMessageContent`，实现 `RCMessageCoding`，字段对应 `AD:FileMsg`
- `VideoMessage` — 同上，对应 `AD:VideoMsg`
- `SysNotifyMessage` — 同上，对应 `AD:SysNotify`
- 每个类实现 `encode()` / `decodeWithData()` / `getObjectName()`

**4.3 ChatMessage 模型扩展**
- 新增 `fileMessage: FileMessage?`、`videoMessage: VideoMessage?`、`sysNotify: SysNotifyMessage?` 可选字段（类似 `card` / `meal` / `report` 模式）

#### 🟡 P1 — 发送 & 接收打通

**4.4 发送方法（DAL → BLL → PL）**
- `RongCloudManager.sendFileMessage()` — 构建 `FileMessage`，调 `client.sendMessage()`
- `RongCloudManager.sendVideoMessage()` — 构建 `VideoMessage`
- `RongCloudManager.sendSysNotifyMessage()` — 构建 `SysNotifyMessage`
- `IMService` 对应封装
- `ChatViewController` 入口（先做 UI 占位，文件选择后续对接）

**4.5 接收解析（fromRongCloud）**
- 完善 else 分支：`as? FileMessage` / `as? VideoMessage` / `as? SysNotifyMessage` 强转解析
- 提取各字段填充到 `ChatMessage`

**4.6 自定义消息 Cell（PL）**
- `FileBubbleCell` — 文件卡片：图标 + 文件名 + 大小
- `VideoBubbleCell` — 视频卡片：封面 + 时长
- `SysNotifyCell` — 套餐卡片：图片 + 标题 + 描述
- `ChatViewController` 注册新 Cell

#### 🟢 P2 — 后续功能

- OSS 上传（文件 / 视频 / 图片）
- @ 提及（`MentionedInfo`，`sendOptions`）
- 引用回复（`content.extra.replyMessage`）
- 消息撤回（融云 recall API + 60min 窗口）
- 群发（后端 API，不走融云 SDK）
- 发送中互斥 / 进度回调

### 5. 当前已就绪 vs 待开发

| 功能 | 状态 |
|------|------|
| 文本收发 + senderUserInfo | ✅ 完成 |
| 图片收发 + senderUserInfo | ✅ 完成 |
| 自定义类型 else 分支占位 | ✅ 完成（按 `RCMessageContent` 基类解析 extra） |
| 自定义消息模型类 | ✅ 3/3 (FileMessage / VideoMessage / SysNotifyMessage) |
| 自定义消息注册 | ✅ registerCustomMessageTypes() |
| 文件/视频/套餐发送 | ✅ RongCloudManager + IMService |
| 文件/视频/套餐 Cell | ✅ 3/3 (FileBubbleCell / VideoBubbleCell / SysNotifyCell) |
| OSS 上传 | ❌ |
| @ 提及 / 引用 / 撤回 | ❌ |

### 6. 改动的文件范围预估

```
新增文件：
  DAL/IM/CustomMessages/FileMessage.swift       ← RCMessageContent 子类
  DAL/IM/CustomMessages/VideoMessage.swift       ← RCMessageContent 子类
  DAL/IM/CustomMessages/SysNotifyMessage.swift   ← RCMessageContent 子类
  PL/Message/Chat/Cells/FileBubbleCell.swift     ← 文件 Cell
  PL/Message/Chat/Cells/VideoBubbleCell.swift    ← 视频 Cell
  PL/Message/Chat/Cells/SysNotifyCell.swift      ← 套餐 Cell

修改文件：
  DAL/IM/RongCloudManager.swift     ← registerMessageType + sendXxxMessage
  DAL/IM/Message.swift              ← ChatMessage 加可选字段 + MessageType 已加
  DAL/IM/RongCloudMessageDelegate.swift ← fromRongCloud 完善解析
  BLL/Message/IMService.swift       ← sendFile / sendVideo / sendSysNotify
  PL/Message/Chat/ChatViewController.swift ← cell 注册 + 入口 + cellForRow
```
