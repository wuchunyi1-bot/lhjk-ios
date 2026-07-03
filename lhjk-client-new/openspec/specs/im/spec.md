# Instant Messaging (IM)

## Purpose

提供即时通讯能力，作为健康管理服务的沟通枢纽。健管师/医生与客户在聊天中完成服务触达、健康数据推送和咨询回复。参考 funde-im `prototype/src/` 全部 Vue 组件及 `conversations.json` / `messages.json` mock 数据模型。

> **Reference**: funde-im `prototype/src/components/ConvoList.vue`、`ConvoItem.vue`、`MessageList.vue`、`MessageBubble.vue`、`Composer.vue`、`docs/v0.1/`

---

## Data Model

> 参考 funde-client `prototype/src/mock/conversations.json` 完整数据模型

### Conversation (会话)

| Field | Type | 说明 |
|-------|------|------|
| `id` | String | 会话唯一 ID，如 `conv-001`、`conv-ai-xd`、`conv-team` |
| `role` | Enum | 角色类型：`ai` / `team` / `manager` / `doctor` / `nutrition` / `service` / `case` / `psychology` |
| `roleLabel` | String | 角色标签文案，如"健管师 · 专属"、"主任医师 · 内科" |
| `name` | String | 会话对象显示名称 |
| `title` | String | 会话标题/职称，如"健康管理专家" |
| `avatar` | String | 头像文字（取姓名首字） |
| `status` | String | 在线状态文案，如"在线"、"今日可咨询"、"AI 在线" |
| `serviceScope` | String | 服务范围描述，如"慢病逆转 · 日常随访" |
| `lastMessage` | String | 最近一条消息的文本摘要 |
| `lastTime` | String | 最近消息时间（友好格式：今天 HH:mm / 昨天 / 周几） |
| `unread` | Int | 未读消息数 |
| `important` | Bool | 是否重要会话，决定左侧高亮竖条 |

### Message / ChatMessage (消息)

| Field | Type | 说明 |
|-------|------|------|
| `id` | String | 消息唯一 ID |
| `type` | Enum | `text` / `system` / `metric-card` / `report-card` / `diet-card` / `appointment-card` / `case-card` / `plan-card` / `meal-analysis` / `ai-weekly-report` |
| `role` | Enum | 发送方：`user`（用户） / `staff`（健管团队） |
| `senderName` | String? | 发送者姓名（staff 侧显示） |
| `senderRole` | String? | 发送者角色（群消息中区分多人） |
| `avatar` | String? | 发送者头像文字 |
| `text` | String | 文本内容（type=text 或 system 时使用） |
| `time` | String | 消息时间（友好格式：刚刚 / HH:mm / 今天 HH:mm） |
| `card` | ServiceCard? | 结构化卡片数据（type 为 *-card 时使用） |

### ServiceCard (结构化服务卡片)

| Field | Type | 说明 |
|-------|------|------|
| `title` | String | 卡片标题（如"血压趋势提醒"） |
| `icon` | String | SF Symbol 图标名 |
| `accent` | String | 主题色 hex（由角色 roleTone 决定） |
| `summary` | String | 卡片摘要描述 |
| `rows` | [CardRow] | 键值对数据行 |
| `footnote` | String? | 底部建议/备注文本 |
| `action` | String? | 行动按钮文案（存在时渲染按钮） |

### CardRow

| Field | Type | 说明 |
|-------|------|------|
| `label` | String | 指标名称（如"收缩压"） |
| `value` | String | 指标值（如"138 mmHg"） |
| `status` | String? | 状态文字（如"偏高"、"需关注"），有值时显示 status badge |

### MealAnalysis (餐食分析，type=meal-analysis)

| Field | Type | 说明 |
|-------|------|------|
| `label` | String | 餐食标签（如"昨日 晚餐"） |
| `annotations` | [MealAnnotation] | 食材标注列表 |
| `comment` | String | 营养师点评文案 |
| `from` | String | 点评人署名 |

| MealAnnotation | Type | 说明 |
|-------|------|------|
| `text` | String | 食材名（如"红烧肉"） |
| `tag` | Enum | 分类：`danger`（红） / `success`（绿） / `warning`（黄） |
| `tip` | String | 标注提示（如"饱和脂肪较高"） |

### AIWeeklyReport (AI 周报，type=ai-weekly-report)

| Field | Type | 说明 |
|-------|------|------|
| `weekNo` | Int | 周次编号 |
| `scoreBefore` | Int | 上周评分 |
| `scoreAfter` | Int | 本周评分 |
| `highlights` | [AIHighlight] | 本周亮点（icon + text） |
| `medal` | AIMedal? | 勋章（有则渲染，无则隐藏） |
| `nextGoal` | String | 下周目标文案 |

| AIHighlight | Type | 说明 |
|-------|------|------|
| `icon` | String | SF Symbol 图标名 |
| `text` | String | 亮点描述 |

| AIMedal | Type | 说明 |
|-------|------|------|
| `icon` | String | 勋章图标 |
| `name` | String | 勋章名称 |

### Notification (系统通知)

| Field | Type | 说明 |
|-------|------|------|
| `id` | String | 通知唯一 ID，如 `n1` |
| `icon` | String | SF Symbol 图标名 |
| `iconBg` | String | 图标背景色 hex |
| `iconColor` | String | 图标前景色 hex |
| `title` | String | 通知标题（加粗展示） |
| `tag` | String | 分类标签文案（"预约提醒" / "保单" / "设备" / "报告"） |
| `body` | String | 通知正文摘要（2 行截断） |
| `time` | String | 发送时间（友好格式） |
| `unread` | Bool | 是否未读 |

### 角色主色调 (roleTone)

| role | 主色 | 说明 |
|------|------|------|
| `ai` | `#FF7A50` (fdPrimary) | AI 健康顾问 |
| `team` | `#FF7A50` (fdPrimary) | 三好共管服务群 |
| `manager` | `#FF7A50` (fdPrimary) | 健管师 |
| `doctor` | `#3D6FB8` | 医生 |
| `nutrition` | `#1F9A6B` (fdSuccess) | 营养师 |
| `case` | `#7B5E9F` | 个案管理师 |
| `psychology` | `#5C8DC9` | 心理咨询师 |
| `service` | `#B47300` (fdWarning) | 家庭服务台 |

### 通知类型颜色映射

| 类型 | 主色 | 背景色 |
|------|------|--------|
| 预约提醒 | `#3D6FB8` | `#EAF3FF` |
| 保单 | `#B47300` | `#FFF3DC` |
| 设备/指标 | `#FF7A50` | `#FFE9DF` |
| 报告 | `#1F9A6B` | `#E6F7EF` |

---

## SDK Setup

### Requirement: RongCloud SDK Initialization
App 启动时 SHALL 初始化融云 IM SDK 并注册消息接收代理。

#### Scenario: SDK 初始化
- **WHEN** `AppDelegate.application(_:didFinishLaunchingWithOptions:)` 调用 `configureThirdPartySDKs()`
- **THEN** `RongCloudManager.shared.initialize(appKey: "k51hidwqkor2b")` 调用 `RCIMClient.shared().initWithAppKey()`
- **AND** `RongCloudMessageDelegate.shared.register()` 将自身设为 `RCIMClient.receiveMessageDelegate`

### Requirement: IM Account Registration & Connection
系统 SHALL 在用户登录后注册融云 IM 账号并建立长连接，冷启动时恢复连接，登出时断开。
连接建立后由融云 SDK 内部负责自动重连，App 侧无需额外重连逻辑。

#### Scenario: 登录后获取 Token 并连接
- **WHEN** 用户通过短信或密码登录成功
- **THEN** 调用 `RongCloudManager.shared.fetchTokenAndConnect()`
- **AND** 该方法调用 `POST /v1/account/addRongImAccount`（Bearer Token 鉴权）
- **AND** 解析响应中的 `token` 字段
- **AND** 将 token 持久化到 `UserDefaults`（key: `rc_im_token`）
- **AND** 调用 `connect(with: token)` 建立融云长连接
- **AND** IM 连接成功/失败均不阻塞页面跳转和 App 正常使用

#### Scenario: Token 接口重试
- **WHEN** `POST /v1/account/addRongImAccount` 请求失败
- **THEN** 等待 2 秒后重试 1 次
- **AND** 重试仍失败则放弃，打印日志

#### Scenario: 冷启动恢复连接
- **WHEN** App 冷启动且用户已登录（`auth_access_token` 存在）
- **THEN** `SceneDelegate.willConnectTo` 中调用 `restoreIMConnection()`
- **AND** 若 `UserDefaults` 中有已存储 token → 调用 `reconnect()` 直接连接
- **AND** 若 token 不存在（从未获取或已清除）→ 调用 `fetchTokenAndConnect()` 重新获取并连接
- **AND** 热启动（`sceneWillEnterForeground`）不额外处理，由融云 SDK 内部维持/恢复长连接

#### Scenario: 登出断开
- **WHEN** 用户确认退出登录
- **THEN** 调用 `RongCloudManager.shared.disconnect()`
- **AND** `disconnect()` 调用 `RCIMClient.shared().disconnect()` 断开长连接
- **AND** 清除内存中的 `currentUserId` 和 `connectionStatus`
- **AND** 清除 `UserDefaults` 中存储的 token（key: `rc_im_token`）

#### Scenario: 连接成功
- **WHEN** 融云 SDK 回调 `connect` 成功
- **THEN** `connectionStatus = .connected`，保存 `currentUserId`
- **AND** 调用 `getRemoteConversationList(success:error:)` 将会话列表从服务端同步到本地数据库（融云批量查询 API 依赖本地数据）
- **AND** 通过 `connectionStatusPublisher` 发布状态变化

#### Scenario: 连接失败 / Token 错误
- **WHEN** 融云 SDK 回调 `connect` 错误
- **THEN** Token 错误（`RC_CONN_TOKEN_INCORRECT` / `RC_CONN_TOKEN_EXPIRE`）→ `connectionStatus = .tokenIncorrect`
- **AND** 其他错误 → `connectionStatus = .disconnected`
- **AND** 通过 `connectionStatusPublisher` 发布状态变化
- **AND** 不做 App 侧重连，由融云 SDK 内部自动重试

### Requirement: Message Reception
系统 SHALL 接收融云推送的消息并转发至 App 内部。

#### Scenario: 消息接收
- **WHEN** 融云 SDK 收到新消息
- **THEN** `RongCloudMessageDelegate.onReceived(_:left:object:)` 将 `RCMessage` 转为 `Message` 模型
- **AND** 通过 `RongCloudManager.messageReceivedPublisher` 发布

### Requirement: Remote Conversation Sync Delegate
系统 SHALL 通过 `RCConversationDelegate` 监听远端会话同步完成事件。

#### Scenario: Delegate 注册
- **WHEN** `RongCloudManager.initialize(appKey:)` 调用
- **THEN** 调用 `client.setRCConversationDelegate(self)` 注册 delegate
- **AND** `RongCloudManager` 遵循 `RCConversationDelegate` 协议

#### Scenario: 远端会话同步完成
- **WHEN** 融云 SDK 完成远端会话列表同步
- **THEN** `RCConversationDelegate.remoteConversationListDidSync(_:)` 被回调
- **AND** 通过 `remoteConversationListDidSyncPublisher` 发布同步结果（`PassthroughSubject<RCErrorCode, Never>`）

#### Scenario: 实时会话同步完成
- **WHEN** 融云 SDK 完成实时会话同步
- **THEN** `RCConversationDelegate.conversationDidSync()` 被回调
- **AND** 打印 `[RongCloud] conversationDidSync` 日志

### Requirement: Messages Root Page
系统 SHALL 提供消息模块根页面 `/messages`，聚合所有健管团队会话和系统通知入口。

**路由**: `/messages`，Tab Bar「消息」Tab
**数据源**: `GET /v1/session/getGroup`（获取我的群组）+ 融云 SDK `getConversationList()`（获取单聊实时数据），两者合并后展示

#### Scenario: 页面结构
- **WHEN** 用户进入消息页
- **THEN** 顶部导航栏展示标题"消息" + 副标题"您的健管团队 7×24 在线"
- **AND** 下方 FdSegment 分段控件，两个 Tab：「团队对话」（角标 = 所有会话 unread 之和）、「通知中心」（角标 = 未读通知数）
- **AND** 默认激活「团队对话」Tab
- **AND** 「团队对话」和「通知中心」是**两个独立的子 ViewController**（`ConversationListViewController` / `NotificationListViewController`），通过分段控件切换，各自管理自己的数据加载和刷新

#### Scenario: 三好共管服务群置顶横幅
- **WHEN** 「团队对话」Tab 激活
- **THEN** 会话列表顶部渲染品牌渐变卡片（#FFF7F1 → #FFEDDF，橙色边框）
- **AND** 展示心形图标 + "三好共管 · 您的专属团队"标签 + 在线人数 badge + 引导文案
- **AND** 点击跳转 `/conversations/conv-team`

#### Scenario: 会话行渲染
- **WHEN** 遍历 conversations 数组渲染
- **THEN** 每行展示：
  - 左侧 46×46pt `fd-avatar--{role}` 角色色圆形头像（首字），`cornerRadius = 23` 确保正圆
  - 头像右上角未读角标（unread > 0 时，红色圆形 badge）
  - 姓名（15pt bold）+ roleLabel 标签 pill（10pt，灰底灰字）
  - 消息预览单行截断（12pt `fdSubtext`）
  - 右侧时间戳（10pt `fdMuted`，固定宽度 44pt，始终展示不被挤压）
  - 底部分割线（0.5pt，`fdBorder` 色，左右对齐内容区）
- **AND** 水平压缩优先级：`nameLabel` = `.defaultLow`（仅群名可省略），`roleTag` / `timeLabel` = `.required`（必须完整展示）
- **AND** `timeLabel` 固定宽度 44pt + 固定 trailing 16pt，确保时间始终可见
- **AND** `roleTag.trailing ≤ timeLabel.leading - 8`，防止标签遮挡时间
- **AND** `nameLabel.trailing ≤ roleTag.leading - 6`，超长群名自动 `...` 截断
- **AND** `important == true` 时左侧渲染 3pt 品牌色竖条

#### Scenario: 通知中心 Tab 内联预览
- **WHEN** 切换到「通知中心」Tab
- **THEN** 平铺展示通知行列表（与 `/notifications` 同一数据源）
- **AND** 每行：[圆角色图标（iconBg + iconColor）] + [标题 + 未读红点 + 时间] + [body 摘要] + [tag badge]
- **AND** 点击单条通知暂静默（后续接入精确路由跳转）

#### Scenario: 空状态
- **WHEN** 会话列表为空
- **THEN** 展示插图 + "您的健管团队正在为您分配，将在 24 小时内主动联系您"
- **WHEN** 通知列表为空
- **THEN** 展示"暂无通知"

#### Scenario: 会话列表数据源（两步合并）
- **WHEN** `ConversationListViewController` 加载会话列表
- **THEN** 前提：融云连接成功后已执行 `getRemoteConversationList` 将服务端会话同步到本地，确保本地数据库包含所有服务端会话
- **AND** 第一步：调用 `GET /v1/session/getGroup` 获取我的群组列表，返回 `[GroupVO]`
- **AND** 第二步：用所有 `groupId` 调用融云 `getConversations` 批量查询本地会话详情（按 ID 分批，每批 100 个）
- **AND** 合并逻辑：**匹配上融云的在前展示，未匹配的在后展示**
  - 先遍历融云返回的 `[RCConversation]`，按 `sentTime` 倒序排列
  - 对每个 `RCConversation`，用 `targetId` 查找匹配的 `GroupVO`
  - 匹配成功 → `Conversation.fromGroupVO(group, rc: rc)`，记录为已匹配
  - 匹配失败（融云有会话但群组 API 未返回）→ `Conversation.fromRongCloud(rc)` fallback
  - 再遍历 `GroupVO` 中未被匹配的项 → `Conversation.fromGroupVO(group, rc: nil)` 追加到末尾
- **AND** 最终顺序：匹配的（按 sentTime 倒序）+ 未匹配的 GroupVO
- **AND** `GroupVO` + `RCConversation` → `Conversation` 字段映射：
  - 实时数据优先融云：`unreadMessageCount` → `unread`，`sentTime` → `lastTime`，`latestMessage` → `lastMessage`
  - 展示元数据优先 `GroupVO`：`principalName ?? groupName` → `name`，`serviceName` → `title` / `roleLabel`
  - `groupImg` 取首字 → `avatar`，`numbers` → `status`（"N 人在线"）
  - `labelType == 1` → `important = true`，`serviceId` → `role`
  - rc 为 nil 时：`unread = 0`，`lastTime = ""`，`lastMessage` fallback 到 GroupVO.lastContent
- **AND** 若 API 请求失败或融云未连接，fallback 到 mock 数据

#### Scenario: 测试方法 — 全量会话打印
- **WHEN** `ConversationListViewController.loadData()` 执行
- **THEN** 并行调用 `IMService.testFetchAllConversations()` 获取全量会话列表（通过 `getConversationList` 而非按 ID 批量查询）
- **AND** 打印每个会话的 ID、会话类型（单聊/群聊/其他）、未读数
- **AND** 该方法是临时测试用途，不影响正式数据流和 UI 渲染
- **AND** 使用 `async let` 与 `loadConversations()` 并行执行，不阻塞主流程

#### Scenario: 离线状态
- **WHEN** 网络断开
- **THEN** 展示本地缓存数据，顶部提示条"当前离线，消息可能不是最新"
- **AND** 恢复连接后自动刷新

---

### Requirement: Proactive Conversation Loading
`IMService` SHALL 在 IM 连接成功后主动加载会话列表，不依赖 `ConversationListViewController` 的 UI 生命周期触发。

**动机**：`UITabBarController` 懒加载子 VC 的 view，用户停留在首页时 `ConversationListViewController.viewDidLoad` 不会执行。如果等到用户首次点击消息 Tab 才加载会话，此前的所有新消息都无法驱动角标更新。

#### Scenario: IM 连接成功后自动加载
- **WHEN** `RongCloudManager.connectionStatusPublisher` 发出 `.connected`
- **THEN** `IMService` 检查 `conversations.isEmpty`，若为空则调用 `loadConversations()`
- **AND** `loadConversations()` 执行完整两步合并流程：`GET /mobile/v1/session/getGroup` → 融云 `getConversations(by:)` → 合并排序
- **AND** 加载完成后自动触发 `notifyUnreadCountChanged()` → 角标更新

#### Scenario: 避免重复加载
- **WHEN** IM 重连（如从后台恢复）
- **THEN** 若 `conversations` 非空（已加载过），跳过，不重复请求
- **WHEN** 用户登出后重新登录 → `clear()` 清空 `conversations`
- **THEN** 下次 IM 连接时 `conversations.isEmpty` 为 true → 重新加载

#### Scenario: 收到新消息时 IMService 自行更新未读数
- **WHEN** `IMService.onMessageReceived(_:)` 收到新消息
- **THEN** 除缓存到 `messagesStore` 外，若 `conversations` 已加载且包含该 `conversationId`，则调用 `updateConversation(id:)` 刷新 unread
- **AND** `updateConversation` 内部调用 `notifyUnreadCountChanged()` → 角标实时更新
- **AND** 此路径不依赖 `ConversationListViewController` 的订阅，即使用户在其他 Tab 角标也能刷新

---

### Requirement: Message Tab Bar Badge
系统 SHALL 在底部 Tab Bar「消息」Tab 上展示未读消息角标，角标数字 = 所有团队对话未读数之和。

**数据源**：`IMService.totalUnreadCount()`（遍历 `conversations` 累加 `unread` 字段）
**更新机制**：`IMService` 通过 Combine publisher `totalUnreadCountDidChangePublisher` 发布变更，`RootTabBarController` 订阅并更新 `messageNav.tabBarItem.badgeValue`

> **暂时只计算团队对话未读数**，待通知中心接入后将 `notiUnreadCount()` 也纳入角标计算。

#### Scenario: 显示规则
- **WHEN** 总未读数 > 0
- **THEN** 消息 Tab 显示角标数字（总未读数 > 99 显示 "99+"）
- **WHEN** 总未读数 == 0
- **THEN** 消息 Tab 隐藏角标（`badgeValue = nil`）

#### Scenario: 会话加载后更新角标
- **WHEN** `IMService.loadConversations()` 完成并设置 `conversations` 列表
- **THEN** 调用 `notifyUnreadCountChanged()` → 通过 `totalUnreadCountDidChangePublisher` 发布新的总未读数
- **AND** `RootTabBarController` 收到后更新消息 Tab 角标

#### Scenario: 收到新消息后更新角标
- **WHEN** 融云推送新消息 → `messageReceivedPublisher` 发出
- **THEN** 两条路径并行处理：
  - `IMService.onMessageReceived` → 会话已加载则 `updateConversation(id:)` → 角标更新（主力路径，不依赖 UI）
  - `ConversationListViewController` 订阅 → `handleConversationUpdate` → 更新列表 UI + 角标（UI 已加载时生效）

#### Scenario: 标记已读后更新角标
- **WHEN** 用户在会话详情页退出（`ChatViewController.viewDidDisappear`）或点击会话行
- **THEN** 调用 `IMService.markAsRead(_:)` → 将 `unread` 重置为 0
- **AND** 调用 `RongCloudManager.clearGroupUnreadCount(for:)` 清除融云侧未读
- **AND** 调用 `notifyUnreadCountChanged()` → 角标自动刷新

#### Scenario: 删除会话后更新角标
- **WHEN** `IMService.deleteConversation(_:)` 被调用
- **THEN** 从 `conversations` 移除该会话后调用 `notifyUnreadCountChanged()` → 角标自动刷新

#### Scenario: 登出后清除角标
- **WHEN** `IMService.clear()` 被调用（用户登出时）
- **THEN** 清空 `conversations` + 重置 `hasLoadedConversations = false` + 调用 `notifyUnreadCountChanged()` → 角标归零

#### Scenario: 初始状态
- **WHEN** App 冷启动后尚未加载会话列表
- **THEN** 消息 Tab 无角标（`conversations` 为空，`totalUnreadCount() = 0`）
- **AND** IM 连接成功后自动加载，角标随即更新

---

### Requirement: Conversation List Cache & Reload
`ConversationListViewController` SHALL 优先使用 `IMService` 已缓存的会话列表，避免重复 HTTP 请求。

**机制**：`IMService.hasLoadedConversations` 标记是否已完成首次加载。`loadData()` 检查此标记，已加载则直接用 `getConversations()` 缓存；需全量刷新时使用 `forceReload()`。

#### Scenario: 首次进入消息 Tab（缓存命中）
- **WHEN** 用户点击消息 Tab → `ConversationListViewController.viewDidLoad` → `loadData()`
- **AND** `IMService.hasLoadedConversations == true`（冷启动时 IM 连接后已加载）
- **THEN** 直接从 `IMService.getConversations()` 取缓存数据 → `tableView.reloadData()`
- **AND** 不发起 HTTP 请求，零网络开销

#### Scenario: 首次进入消息 Tab（缓存未命中，降级）
- **WHEN** `hasLoadedConversations == false`（极少见：IM 尚未连接或加载失败）
- **THEN** 调用 `forceReload()` → `loadConversations()` 完整加载

#### Scenario: 远端会话同步完成后强制刷新
- **WHEN** `remoteConversationListDidSyncPublisher` 发出（融云服务端会话同步完成）
- **THEN** 调用 `forceReload()` → 完整 HTTP + 融云查询 + 合并
- **AND** 因为可能涉及新增会话，不能只用缓存

#### Scenario: 收到未知会话消息时强制刷新
- **WHEN** `handleConversationUpdate` 在本地 `conversations` 中找不到该 `conversationId`
- **THEN** 调用 `forceReload()` → 全量加载（可能为新增群组）

### Publisher 数据流

```
App 冷启动
  SceneDelegate.restoreIMConnection()
    → RongCloudManager.connect()
      → connectionStatusPublisher(.connected)
        ├─ syncConversationsFromServer() (async)
        └─ IMService: conversations.isEmpty → loadConversations()  ← 提前加载
              → GET /mobile/v1/session/getGroup
              → 融云 getConversations(by: groupIds)
              → 合并排序 → hasLoadedConversations = true
                → notifyUnreadCountChanged()
                  → RootTabBarController.updateMessageBadge()
                    → 角标更新 ✅

新消息到达（用户在其他 Tab）
  融云 SDK → messageReceivedPublisher
    ├─ IMService.onMessageReceived
    │   → conversations 非空 → updateConversation(id:)
    │     → notifyUnreadCountChanged() → 角标更新 ✅
    └─ ConversationListViewController (如 UI 已加载)
        → handleConversationUpdate → 列表刷新 + 角标

用户点击消息 Tab（首次）
  ConversationListViewController.viewDidLoad
    → loadData()
      → hasLoadedConversations = true → getConversations() 缓存
        → 零网络请求，秒开 ✅

远端同步完成
  remoteConversationListDidSyncPublisher
    → ConversationListViewController.forceReload() → 全量刷新
```

---

### Requirement: Conversation Detail / Chat
系统 SHALL 展示单个会话的完整 IM 聊天界面，支持多角色、多消息类型和快捷回复。

**路由**: `/conversations/:id`
**数据源**: 融云 SDK `getHistoryMessages`（历史消息拉取）+ `RCIMClientReceiveMessageDelegate`（实时消息接收）

#### Scenario: 导航栏
- **WHEN** 进入会话详情
- **THEN** 导航栏展示对方姓名（`name`，16pt bold）+ 角色和在线状态（`roleLabel · status`，11pt `fdSubtext`）
- **AND** 左侧返回箭头退回消息列表

#### Scenario: 会话上下文横幅
- **WHEN** 消息区顶部渲染
- **THEN** 展示服务范围描述（`serviceScope`）+ 在线状态徽章（背景色 = `roleTone` 12% 透明度，文字色 = `roleTone`）

#### Scenario: 文本气泡 — staff 侧
- **WHEN** `role == "staff"` 的文本消息
- **THEN** 左对齐：头像（34×34pt `fd-avatar--{role}`） + 气泡 + 时间
- **AND** 气泡上方显示发送者姓名 + 角色 + 时间标签（11pt `fdMuted`）
- **AND** 白色气泡（`fdSurface`），圆角 15pt（左上直角），阴影

#### Scenario: 文本气泡 — user 侧
- **WHEN** `role == "user"` 的文本消息
- **THEN** 右对齐：气泡 + "我"头像（品牌色渐变圆形）+ 时间
- **AND** 品牌色气泡（`fdPrimary`），白色文字，圆角 15pt（右上直角）

#### Scenario: 系统消息
- **WHEN** `type == "system"`
- **THEN** 居中灰色胶囊样式（padding 5×12pt，`fdMuted` 文字，灰底 6% 透明度），无头像

#### Scenario: 日期分割线
- **WHEN** 消息区渲染
- **THEN** 在消息顶部显示"今天"居中分割线（11pt `fdMuted`，灰色胶囊背景）

#### Scenario: 结构化服务卡片
- **WHEN** `type` 为 `metric-card` / `report-card` / `diet-card` / `appointment-card` / `case-card` / `plan-card`
- **THEN** 左对齐白色卡片（18pt 圆角，`--card-accent` 边框，阴影）：
  - 顶部 icon（46×46pt 圆角色方形，`card-accent-soft` 背景）+ 标题（15pt bold）+ 摘要（12pt）
  - 分隔线 + 数据行（label + value + status badge）
  - footnote 建议区（灰底 12pt）
  - action 行动按钮（`card-accent-soft` 背景，`card-accent` 文字，13pt bold）
- **AND** `card.accent` 不存在时使用 `roleTone` 作为 fallback

#### Scenario: 餐食分析卡片（营养师专属）
- **WHEN** `type == "meal-analysis"`
- **THEN** 左对齐白色卡片（16pt 圆角，左下直角）：
  - 顶部"餐食标签 · 营养师分析"头部
  - 餐食照片占位区（80pt 高，灰色占位）
  - 食材标注列表：每行 danger（红底）/ success（绿底）/ warning（黄底）圆角色标签 + 提示
  - 营养师点评文案（13pt，分隔线下方）
  - 右下角署名

#### Scenario: AI 健康周报卡片（小德专属）
- **WHEN** `type == "ai-weekly-report"`
- **THEN** 品牌渐变卡片（#fff8f5 → #fff3ee，橙色边框，16pt 圆角）：
  - 头部：小德圆形头像 + 第 N 周健康周报 + 时间
  - 评分对比行（上周/本周 26pt 数字 + 绿色增量 badge）
  - 本周亮点列表（icon + text 行）
  - 勋章区（有则渲染，无则隐藏，黄色背景）
  - 下周目标（白色底 + 品牌色左边框）

#### Scenario: 快捷回复
- **WHEN** 输入区上方渲染
- **THEN** 展示 3 个快捷回复按钮（按 `conv.role` 动态选取）：
  - AI: "查看本周周报" / "我的健康目标" / "今日健康建议"
  - 营养师: "今天早餐怎么吃？" / "帮我调整晚餐" / "查看饮食方案"
  - 医生: "帮我看下指标" / "用药需要调整吗" / "预约复诊"
  - 个案管理师: "查看个案进度" / "补充资料" / "联系家属"
  - 心理咨询师: "开始放松练习" / "记录睡眠" / "预约咨询"
  - 家庭服务台: "查看预约" / "改约时间" / "联系服务台"
  - 团队群: "同步今日指标" / "请团队看一下" / "查看本周目标"
  - 默认（健管师）: "上传血压" / "查看监测方案" / "联系健管师"
- **AND** 横向滚动，点击直接发送对应文本
- **AND** 圆角色白色按钮 + 灰色边框

#### Scenario: 富媒体工具栏
- **WHEN** 输入框左侧渲染
- **THEN** 展示 3 个工具按钮：发送报告（document-2-line）/ 发送指标（chart-line-line）/ 发送图片（pic-line）
- **AND** 32×32pt 圆角色灰底按钮，品牌色图标
- **AND** 点击按钮发送占位消息（原型阶段不接真实上传）

#### Scenario: 文本输入与发送
- **WHEN** 用户输入文本
- **THEN** 发送按钮有内容时激活（品牌色），空文本时禁用（灰色）
- **AND** 点击发送或键盘回车 → 本地追加 user 侧气泡 → 滚动至底
- **AND** 输入框圆角色 999pt，品牌色背景（#fff8f5），placeholder "发消息给{name}"

#### Scenario: 键盘适配
- **WHEN** 键盘弹出/收起
- **THEN** 输入栏跟随键盘上移/恢复，消息区 contentInset 同步调整
- **AND** 页面使用全屏高度，消息区 flex-grow + overflow scroll

#### Scenario: 滚动行为
- **WHEN** 进入聊天页或发送消息
- **THEN** 自动滚动到消息区最底部
- **WHEN** 新消息到达且已在底部
- **THEN** 平滑滚动至底；否则显示"新消息"提示按钮

#### Scenario: 消息收发（融云 API）
- **WHEN** 用户进入聊天页
- **THEN** 调用 `RongCloudManager.getMessages(conversationType:targetId:count:)` 拉取最近 20 条历史消息
- **AND** 将 `[RCMessage]` 通过 `ChatMessage.fromRongCloud(rcMessage:)` 转为 `[ChatMessage]` 展示
- **AND** 若融云返回空或失败，fallback 到 mock 数据确保页面可用

- **WHEN** 用户发送文本消息
- **THEN** 先乐观展示本地 `ChatMessage`（id 前缀 `local-`，time "刚刚"）
- **AND** 异步调用 `RongCloudManager.sendTextMessage(conversationType:targetId:content:)` 发送到融云
- **AND** 发送成功后用服务端返回的 `RCMessage` 替换本地消息（更新 id、time 等字段）

- **WHEN** 融云推送新消息到当前会话
- **THEN** `ChatViewController` 订阅 `RongCloudManager.messageReceivedPublisher`
- **AND** 过滤 `conversationId` 匹配的消息，去重后追加到 `messages` 末尾并插入行、滚动至底
- **AND** `IMService` 同步将实时消息缓存到 `messagesStore`

---

### Requirement: Notification Center
系统 SHALL 提供独立通知中心页面，按时间倒序展示所有系统推送通知。

**路由**: `/notifications`
**数据源**: `GET /api/notifications`

#### Scenario: 通知卡片渲染
- **WHEN** 进入通知中心
- **THEN** 导航栏标题"通知中心"，左侧返回箭头
- **AND** 每张通知以卡片形式渲染：[圆角色图标区（iconBg + iconColor，38×38pt 圆角色方形）] + [标题（14pt bold）+ 正文（12pt，2 行截断）+ tag badge + 时间（10pt）]
- **AND** 按时间倒序平铺，卡片间有间距

#### Scenario: 通知图标颜色
- **WHEN** 渲染通知图标区
- **THEN** 按 `tag` 类型映射颜色：预约提醒 → 蓝色 / 保险 → 黄色 / 设备指标 → 橙色 / 报告 → 绿色

#### Scenario: 已读行为
- **WHEN** 用户进入通知中心页面
- **THEN** 触发 `POST /api/notifications/read-all` 标记全部已读
- **AND** 消息列表「通知中心」Tab 角标归零

#### Scenario: 空状态
- **WHEN** 通知列表为空
- **THEN** 展示空状态插图 + "暂无通知"

---

### Requirement: Design Tokens
所有颜色 SHALL 通过 `UIColor.fd*` Token 或 roleTone 映射引用，不硬编码。

#### Scenario: 消息气泡色
| 角色 | 气泡背景 | 文字 |
|------|---------|------|
| User（右侧） | `fdPrimary` (#FF7A50) | white |
| Staff（左侧） | `fdSurface` (white) | `fdText` |

#### Scenario: 餐食标注色
| tag | 背景色 | 圆点色 |
|-----|--------|--------|
| `danger` | `#FFF0EE` | `#FF4D4F` |
| `success` | `#F0FAF4` | `#52B96A` |
| `warning` | `#FFFBE6` | `#B47300` |

---

## Component Inventory

| Component | Type | funde ref | 说明 |
|-----------|------|-----------|------|
| `RootTabBarController` | UITabBarController | — | 根 TabBar，订阅 `totalUnreadCountDidChangePublisher` 更新消息 Tab 角标 |
| `MessagesViewController` | UIViewController | `MessagesView.vue` | 消息根页（分段 Tab + 团队横幅 + 会话列表 + 通知内联） |
| `ConversationCell` | UITableViewCell | ChatRow | 会话行（角色色头像 + 姓名 + 角色标签 + 预览 + 未读角标） |
| `NotificationCell` | UITableViewCell | noti-row | 通知行（图标区 + 标题 + 摘要 + tag badge + 时间） |
| `TeamBannerView` | UIView | team-banner | 三好共管置顶横幅卡片 |
| `ChatViewController` | UIViewController | `ConversationDetailView.vue` | 会话详情页（消息流 + 输入栏 + 快捷回复） |
| `MessageBubbleCell` | UITableViewCell | chat-bubble | 文本气泡（staff 左 / user 右双样式） |
| `ServiceCardCell` | UITableViewCell | chat-card | 结构化服务卡片（指标/报告/饮食/预约/个案/计划） |
| `MealAnalysisCell` | UITableViewCell | meal-bubble | 餐食分析卡片 |
| `AIWeeklyReportCell` | UITableViewCell | xd-report-card | AI 小德健康周报卡片 |
| `SystemMessageCell` | UITableViewCell | system-pill | 系统消息胶囊 |
| `QuickReplyBar` | UIView | quick-replies | 横向滚动快捷回复按钮组 |
| `ComposerBar` | UIView | chat-composer | 底部输入栏（工具按钮 + 输入框 + 发送） |
| `NotificationsViewController` | UIViewController | `NotificationsView.vue` | 通知中心独立页 |

---

## States

| State | 表现 |
|-------|------|
| **消息列表 — 默认** | 团队横幅 + 8 个角色会话行，角标数字正确 |
| **消息列表 — 通知 Tab** | 4 条通知行内联预览 |
| **消息列表 — 空会话** | 新用户引导空状态（健管团队分配中） |
| **消息列表 — 无通知** | "暂无通知"空状态 |
| **聊天 — 默认** | 历史消息流（文本 + 卡片 + 系统消息），自动滚至底 |
| **聊天 — 发送中** | user 消息追加到列表，气泡正常显示 |
| **聊天 — 快捷回复** | 点击快捷回复 → 自动发送 → 追加消息 → 滚动至底 |
| **聊天 — 键盘弹起** | 输入栏上移，消息区 contentInset 同步 |
| **通知中心 — 默认** | 4 张通知卡片，按时间倒序 |

## Acceptance Checklist

### 消息列表页
- [ ] Segmented Tab「团队对话」默认激活，角标 = 所有会话 unread 之和
- [ ] 三好共管服务群置顶横幅始终可见，点击跳转 `/conversations/conv-team`
- [ ] 8 个会话行渲染：头像（fd-avatar--{role} 色）、姓名、roleLabel、预览单行截断、时间、未读角标
- [ ] important 会话左侧品牌色竖条
- [ ] 点击会话行跳转 `/conversations/:id`，并清除该会话未读数
- [ ] 切换到「通知中心」Tab 展示通知行内联预览
- [ ] 通知行图标颜色按类型正确区分（蓝/黄/橙/绿）

### 底部消息角标
- [ ] 消息 Tab 角标 = 所有团队对话 unread 之和（通知中心未读暂不纳入）
- [ ] IM 连接成功后自动加载会话列表，无需等待用户进入消息 Tab
- [ ] 冷启动停留在首页时收到新消息 → 角标实时更新（IMService 自行处理，不依赖 ConversationListVC）
- [ ] 首次进入消息 Tab → 命中 `hasLoadedConversations` 缓存，不重复 HTTP 请求
- [ ] 标记已读后角标数字递减，全部已读后角标消失（`badgeValue = nil`）
- [ ] 远端会话同步完成 → `forceReload()` 全量刷新
- [ ] 登出后角标归零 + `hasLoadedConversations` 重置，重登后重新加载

### 聊天页
- [ ] 导航栏：姓名 + roleLabel · status
- [ ] 上下文横幅：serviceScope + 在线状态徽章（roleTone 色）
- [ ] staff 文本气泡：左对齐白色气泡 + 头像 + 姓名/角色/时间
- [ ] user 文本气泡：右对齐品牌色气泡 + "我"头像 + 时间
- [ ] 系统消息：居中灰色胶囊
- [ ] 日期分割线："今天"
- [ ] 服务卡片渲染：icon + 标题 + 摘要 + 数据行 + footnote + action 按钮
- [ ] 餐食分析卡片：餐食标签 + 照片占位 + 食材标注（红/绿/黄）+ 点评
- [ ] AI 周报卡片：评分对比 + 亮点 + 勋章（如有）+ 下周目标
- [ ] 快捷回复横向滚动，按角色动态文案
- [ ] 空文本时发送按钮禁用，有内容时激活
- [ ] 键盘弹起输入栏跟随

### 通知中心
- [ ] 通知卡片图标颜色按类型区分
- [ ] 标题 + 正文（2 行截断）+ 时间渲染正确
- [ ] 空状态展示

### 通用
- [ ] 所有颜色通过 roleTone / design token 映射
- [ ] 可点击区域 ≥ 44pt
