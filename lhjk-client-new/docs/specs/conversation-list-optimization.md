# ConversationListViewController 刷新优化方案

## 背景

每次进入 `ConversationListViewController` 页面都会走完整刷新链路：

```
GET /mobile/v1/session/getGroup → 提取 groupId → 融云批量查 → 合并排序
```

涉及 HTTP 请求 + 融云批量查询，耗时较长。需要优化为首次全量加载 + 后续订阅通知局部更新。

## 方案设计

### 生命周期调整

| 生命周期 | 改前 | 改后 |
|----------|------|------|
| `viewDidLoad` | 只搭建 UI + 订阅 | 搭建 UI + 订阅 + **首次 loadData()** |
| `viewWillAppear` | 每次 `loadData()` | 无操作 |
| `IMService.init()` | 仅订阅 `messageReceivedPublisher` | 追加订阅 `connectionStatusPublisher`：IM 连接后主动 `loadConversations()` |
| `IMService.onMessageReceived` | 仅缓存到 `messagesStore` | 追加：若 `conversations` 已加载则 `updateConversation(id:)` 刷新未读 |

### 会话加载时机（核心变更）

| 触发者 | 时机 | 方法 |
|--------|------|------|
| `IMService` | IM 连接成功 (`.connected`) | `loadConversations()` — 首次主动加载 |
| `ConversationListVC.loadData()` | `viewDidLoad` | 检查 `hasLoadedConversations`：命中缓存直接返回，未命中走 `forceReload()` |
| `ConversationListVC.forceReload()` | 远端同步完成 / 收到未知会话消息 | `loadConversations()` — 全量 HTTP + 融云 |

### 三类通知处理

```
收到通知 (conversationId)
  │
  ├─ conversations 里匹配到 id
  │    └─ B方案：查单条 RCConversation → 更新 lastMessage/lastTime/unread → 置顶
  │
  └─ 匹配不到
       └─ 全量 loadData()
```

### 订阅分工

| Publisher | 触发场景 | 刷新策略 |
|-----------|---------|---------|
| `messageReceivedPublisher` | 收到新消息 | 单条局部更新（匹配不到则全量） |
| `messageSentPublisher` | 自己发送消息成功 | 单条局部更新（融云不回调自发送） |
| `conversationDidSyncPublisher` | 多端同步（已读/新消息） | 批量局部更新 unread/lastMessage |
| `remoteConversationListDidSyncPublisher` | 远端会话列表同步 | 保持全量刷新（涉及新会话） |

## 改动清单

### 1. Conversation 模型 (`DAL/IM/Conversation.swift`)

- `lastMessage`: `let` → `var`
- `lastTime`: `let` → `var`
- `lastMessageText(from:)`: `private` → internal
- `formatRCTime(_:)`: `private` → internal

### 2. RongCloudManager (`DAL/IM/RongCloudManager.swift`)

- 新增 `conversationDidSyncPublisher: PassthroughSubject<Void, Never>`
- `RongCloudConversationDelegateBridge.conversationDidSync()` 中发送事件

### 3. IMService (`BLL/Message/IMService.swift`)

- `markAsRead(_:)` 补充 `RongCloudManager.shared.clearGroupUnreadCount(for:)` 调用
- 新增 `updateConversation(id:) async -> Conversation?` 方法（B方案核心）
- 新增 `totalUnreadCountDidChangePublisher: PassthroughSubject<Int, Never>` — 底部消息 Tab 角标数据源
- 新增 `notifyUnreadCountChanged()` 私有方法，在以下时机触发：`loadConversations` / `updateConversation` / `markAsRead` / `deleteConversation` / `clear`
- **新增** `connectionStatusPublisher` 订阅：IM 连接成功后主动加载会话列表
- **新增** `onMessageReceived` 内主动调用 `updateConversation(id:)`：即使用户在其他 Tab 也能刷新未读
- **新增** `hasLoadedConversations: Bool` 标记：`loadConversations()` 完成后置 `true`，`clear()` 重置为 `false`

### 4. ConversationListViewController (`PL/Message/ConversationListViewController.swift`)

- `viewDidLoad`: 增加首次 `loadData()`（内部检查 `hasLoadedConversations` 决定是否走缓存）
- `viewWillAppear`: 删除 `loadData()`
- `messageReceivedPublisher` 订阅: 改为 `handleConversationUpdate(conversationId:)`
- 新增 `conversationDidSyncPublisher` 订阅: 批量局部更新
- `remoteConversationListDidSyncPublisher` 订阅: 改为 `forceReload()`（始终全量）
- 新增辅助方法: `handleConversationUpdate` / `handleBatchConversationUpdate`
- **新增** `forceReload()`：始终走完整 `loadConversations()`，用于远端同步 / 未知会话兜底
- **重构** `loadData()`：先检查 `IMService.hasLoadedConversations`，命中缓存直接 `getConversations()`，零网络请求

## 不变更范围

- 不处理新群发现（无消息的新群需要后端轮询或远端同步兜底）
- 局部更新不覆盖后端元数据字段（name/title/role/status/serviceScope）
- `remoteConversationListDidSyncPublisher` 保持全量刷新（远端同步可能涉及新会话）

## 后续扩展：底部消息角标

已于 `IMService` 新增 `totalUnreadCountDidChangePublisher`，由 `RootTabBarController` 订阅并更新消息 Tab 的 `badgeValue`。角标 = 所有团队对话 `unread` 之和，通过上述 publisher 机制在每次会话数据变更时自动重算。详见 `openspec/specs/im/spec.md` » Message Tab Bar Badge。
