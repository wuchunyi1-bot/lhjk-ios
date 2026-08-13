## ADDED Requirements

### Requirement: 会话内存缓存状态 MUST 串行隔离

系统 SHALL 对下列会话级内存缓存的可变状态（含 `Dictionary` / `Set` / in-flight `Task` 句柄 / generation）使用 `actor` 隔离，禁止多个并发 Task 无同步地读写同一实例：

- `ColumnContentCacheService`（已满足）
- `ServiceHubCacheService`
- `HealthPageCacheService`
- `RetailCategoryService`

缓存业务语义 MUST 保持：无 TTL；冷启动 / `clear()` 后重拉；同 key in-flight 去重；`generation` 丢弃 clear 后迟到的写回。

#### Scenario: 多类目并行 ensurePackages

- **WHEN** 多个并发调用对 `ServiceHubCacheService` 以不同类目 id 执行 `ensurePackages`
- **THEN** 系统 MUST NOT 因数据竞争损坏 `packageTasks` 或 `packagesByCategoryId`（不得因此出现 `EXC_BAD_ACCESS`）

#### Scenario: 健康 Hub preload 与 refresh 重叠

- **WHEN** 冷启动 `preload` 与页面 `refresh`（或编辑卡片后的 invalidate+refresh）时间重叠
- **THEN** 对 `cached` / Task 句柄的读写 MUST 串行；迟到结果 MUST 被 generation 丢弃或与 clear 语义一致

#### Scenario: 登出清空仍可用

- **WHEN** 用户登出或会话失效清理本地态
- **THEN** 调用方 MUST `await`（或等价）清空上述 actor 缓存；清空后再次进入对应 Tab MUST 重新拉取

### Requirement: IM 消息与会话集合 MUST 跨线程安全

`IMService` 对 `messagesStore`、`conversations`、`notifications` 以及 `hasLoadedConversations` 的读写 MUST 通过锁或等价串行机制同步。融云 SDK 回调线程触发的实时消息入库 MUST NOT 在无同步情况下与异步加载/发送路径交叉写同一 `Dictionary`。

#### Scenario: 实时消息与历史加载并发

- **WHEN** 融云 `onReceived` 写入 `messagesStore` 的同时，Chat 正在 `loadMessages` / `loadOlderMessages` / `send*`
- **THEN** 系统 MUST NOT 因集合数据竞争崩溃；消息列表语义可保持既有追加/合并行为

#### Scenario: 同步读 API 仍可用

- **WHEN** UI 调用 `getConversations()` / `getMessages(conversationId:)` / `getNotifications()`
- **THEN** 系统 MUST 在同步隔离下返回当前快照（本轮不要求改为 async）
