# Instant Messaging (IM)

## Purpose

提供即时通讯能力，包括文本消息收发、图片/语音/视频消息、会话列表管理、消息状态同步、离线消息和推送通知。

## Requirements

### Requirement: Message Types
系统 SHALL 支持以下消息类型：文本、图片、语音、视频、文件、位置、系统通知。

#### Scenario: 发送文本消息
- **WHEN** 用户输入文本并发送
- **THEN** 消息以文本类型发送，包含发送者 ID、接收者 ID、消息内容、时间戳和唯一消息 ID

#### Scenario: 发送图片消息
- **WHEN** 用户选择相册图片或拍照后发送
- **THEN** 图片先上传至文件服务器，消息体包含图片 URL、缩略图 URL 和图片尺寸

#### Scenario: 发送语音消息
- **WHEN** 用户录制语音后发送
- **THEN** 语音文件上传至文件服务器，消息体包含语音 URL 和语音时长

---

### Requirement: Real-time Communication
系统 SHALL 使用融云（RongCloud）IM SDK 实现消息实时收发。融云 SDK 内置长连接、心跳保活、断线重连和消息路由功能。

#### Scenario: SDK 初始化
- **WHEN** 应用启动时
- **THEN** DAL 层调用融云 SDK 初始化接口 `RCIMClient.shared().initWithAppKey(_:)`，配置应用 Key

#### Scenario: 用户连接
- **WHEN** 用户登录成功并获取融云 Token
- **THEN** DAL 层调用 `RCIMClient.shared().connect(withToken:success:error:tokenIncorrect:)` 建立连接，融云 SDK 自动管理长连接生命周期

#### Scenario: 连接状态监听
- **WHEN** 融云连接状态发生变化
- **THEN** BLL 层通过 `RCIMClientConnectionStatusChangeNotification` 监听状态变化（已连接 / 连接中 / 未连接 / Token 错误），并通知 PL 层展示对应 UI

#### Scenario: 实时接收消息
- **WHEN** 融云 SDK 收到新消息回调
- **THEN** BLL 层通过 `RCIMClientReceiveMessageDelegate` 接收消息，解析后更新对应会话，PL 层实时展示新消息

---

### Requirement: Conversation Management
系统 SHALL 提供会话列表功能，支持会话排序、未读计数和会话操作。

#### Scenario: 会话列表
- **WHEN** 用户进入消息列表页
- **THEN** 展示所有会话，按最后消息时间倒序排列，显示每个会话的最后一条消息、未读数和时间

#### Scenario: 未读消息计数
- **WHEN** 收到新消息且用户不在该会话中
- **THEN** 对应会话的未读计数 +1，会话列表和 Tab 角标同步更新

#### Scenario: 会话删除
- **WHEN** 用户删除一个会话
- **THEN** 该会话从列表移除，本地消息记录可选择保留或清除

#### Scenario: 会话置顶
- **WHEN** 用户将某个会话置顶
- **THEN** 该会话始终展示在列表最上方，与普通会话以分隔线区分

---

### Requirement: Message Status
系统 SHALL 支持消息状态的追踪和同步：发送中 → 已发送 → 已送达 → 已读。

#### Scenario: 消息发送状态更新
- **WHEN** 消息发送后状态发生变化
- **THEN** PL 层实时更新消息气泡的状态标识（发送中显示转轮、已送达显示单勾、已读显示双勾）

#### Scenario: 已读回执
- **WHEN** 用户阅读了对方发来的消息
- **THEN** 客户端自动发送已读回执，将当前会话的所有未读消息标记为已读

---

### Requirement: Offline Messages
系统 SHALL 支持离线消息存储和同步。

#### Scenario: 消息本地存储
- **WHEN** 收发消息时
- **THEN** 消息内容持久化到本地数据库（SQLite），确保离线状态下可查看历史消息

#### Scenario: 离线消息拉取
- **WHEN** 用户重新上线后
- **THEN** 客户端拉取离线期间的消息，按时间戳去重后插入本地数据库并更新 UI

---

### Requirement: Push Notification
系统 SHALL 在应用处于后台或未启动时，通过 APNs 推送新消息通知。

#### Scenario: 后台推送
- **WHEN** 应用在后台且收到新消息
- **THEN** 系统横幅展示推送通知，包含发送者名称和消息摘要

#### Scenario: 点击推送
- **WHEN** 用户点击消息推送通知
- **THEN** 应用打开并跳转至对应会话页面
