# Conversation List / 会话列表 — ViewModel

## Purpose

为 `ConversationListViewController` 引入 `ConversationListViewModel`，将 5 路 Combine 订阅、会话数据管理、增量/批量/全量刷新策略从 ViewController 移至 ViewModel。

> **Reference**: `PL/Message/ConversationListViewController.swift`、`BLL/Message/IMService.swift`、`DAL/IM/RongCloudManager.swift`

---

## Requirements

### Requirement: ConversationListViewModel Data Ownership

`ConversationListViewModel` SHALL 作为会话列表的单一数据源。

#### Scenario: Published 状态
- **WHEN** ViewModel 初始化
- **THEN** 包含 `@Published var conversations: [Conversation]`
- **AND** 包含 `var totalUnread: Int` 计算属性（遍历 conversations 累加 unread）

### Requirement: Combine 订阅管理

ViewModel SHALL 在 `init` 中自动订阅以下 5 路数据源，无需外部触发：

#### Scenario: 消息接收 → 局部更新
- **WHEN** `RongCloudManager.messageReceivedPublisher` 发出新消息
- **THEN** 调用内部 `handleConversationUpdate(conversationId:)` 局部刷新该会话

#### Scenario: 远端同步完成 → 全量刷新
- **WHEN** `RongCloudManager.remoteConversationListDidSyncPublisher` 发出
- **THEN** 调用 `forceReload()` 全量重新加载

#### Scenario: 多端同步 → 批量更新
- **WHEN** `RongCloudManager.conversationDidSyncPublisher` 发出
- **THEN** 遍历本地 conversations，逐条调用 `IMService.updateConversation(id:)` 更新

#### Scenario: 发送成功 → 局部更新
- **WHEN** `RongCloudManager.messageSentPublisher` 发出
- **THEN** 局部刷新该会话

#### Scenario: 已读标记 → 局部更新
- **WHEN** `IMService.conversationMarkedReadPublisher` 发出
- **THEN** 局部刷新该会话

### Requirement: 缓存优先加载

#### Scenario: 首次加载 — 缓存命中
- **WHEN** `loadData()` 调用且 `IMService.hasLoadedConversations == true`
- **THEN** 直接从 `IMService.getConversations()` 取缓存数据赋值到 `conversations`
- **AND** 不发起 HTTP 请求

#### Scenario: 首次加载 — 缓存未命中
- **WHEN** `loadData()` 调用且 `hasLoadedConversations == false`
- **THEN** 调用 `forceReload()` → `IMService.loadConversations()` 完整加载

### Requirement: 局部更新策略

#### Scenario: 匹配成功
- **WHEN** `handleConversationUpdate` 查到对应 conversationId 的会话
- **THEN** 从本地 conversations 移除旧条目，将更新后的会话插入到 index 0（置顶）
- **AND** 更新 `conversations` 触发 UI 刷新

#### Scenario: 匹配失败
- **WHEN** conversationId 在本地 conversations 中未找到
- **THEN** 降级为 `forceReload()` 全量刷新

### Requirement: ConversationListViewController 重构

#### Scenario: 移除的代码
- **WHEN** 完成重构
- **THEN** 以下代码从 VC 移除：
  - `private var conversations: [Conversation]`
  - `setupSubscriptions()` 方法
  - `loadData()` / `forceReload()` 逻辑
  - `handleConversationUpdate(conversationId:)` / `handleBatchConversationUpdate()` 方法
  - Combine imports 中的订阅管理代码

#### Scenario: 保留的代码
- **WHEN** 完成重构
- **THEN** 保留在 VC：
  - `TeamBannerCell`（UI 组件）
  - `UITableViewDataSource/Delegate` 方法
  - 导航逻辑（`ChatViewController` push）
  - `onDataChanged` 回调
  - `forceReload()` 作为 public 方法委托给 ViewModel

## Acceptance Checklist

- [ ] `PL/Message/ViewModels/ConversationListViewModel.swift` 创建
- [ ] 5 路 Combine 订阅在 ViewModel.init 中自动启动
- [ ] VC 通过 `viewModel.$conversations` 驱动 TableView
- [ ] 缓存优先加载策略工作正常
- [ ] 局部/批量/全量刷新逻辑与重构前行为一致
- [ ] Tab Bar 角标更新正常（通过 `totalUnread`）
