## ADDED Requirements

### Requirement: 消息与会话内存集合线程安全

`IMService` SHALL 对 `messagesStore`、`conversations`、`notifications` 以及 `hasLoadedConversations` 的读写使用锁或等价串行机制。来自融云 SDK 回调线程的实时消息入库 MUST 与异步加载/发送路径互斥访问同一集合，MUST NOT 因数据竞争导致进程崩溃。

同步只读 API（`getConversations` / `getMessages` / `getNotifications` 等）MAY 保持同步签名，但 MUST 在隔离保护下返回快照。

#### Scenario: SDK 回调与 Chat 加载并发写

- **WHEN** `RongCloudManager.messageReceivedPublisher` 在非主线程触发 `onMessageReceived`，同时 Chat 正在写入 `messagesStore`
- **THEN** 两次写操作 MUST 串行化；系统 MUST NOT 因 `Dictionary` 数据竞争出现 `EXC_BAD_ACCESS`

#### Scenario: 登出 clear 与实时消息

- **WHEN** 用户登出调用 `IMService.clear()` 同时仍有实时消息回调
- **THEN** `clear` 与消息入库 MUST 互斥；清空后内存集合 MUST 为空或仅含 clear 之后到达且已同步写入的消息（不得损坏集合结构）
