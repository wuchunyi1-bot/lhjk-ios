# Me / 我的模块 Hub — ViewModel

## Purpose

为 `MyViewController` 引入 `MyViewModel`，将用户信息、mock 统计数据、服务列表、功能菜单从 ViewController 移至 ViewModel。

> **Reference**: `PL/My/Home/MyViewController.swift`、`BLL/User/UserManager.swift`

---

## Requirements

### Requirement: MyViewModel Data Ownership

#### Scenario: Published 状态
- **WHEN** ViewModel 初始化
- **THEN** 包含以下 `@Published` 属性：
  - `userName: String` — 用户姓名（默认"加载中…"）
  - `avatarChar: String` — 头像文字（取姓名首字）
  - `avatarURL: String?` — 头像远程 URL
  - `stats: [StatItem]` — 统计条数据（积分/家庭成员/保单/健康等级）
  - `fulfillmentStats: [FulfillmentStat]` — 订单履约统计
  - `services: [ServiceItem]` — 服务卡片数据
  - `functionGroups: [FuncGroup]` — 功能菜单分组

#### Scenario: 数据加载
- **WHEN** ViewModel 初始化或 `loadUserProfile()` 被调用
- **THEN** 从 `UserManager.shared.currentUser` 读取用户信息
- **AND** 更新 `userName`、`avatarChar`、`avatarURL`
- **AND** Mock 数据（stats/services/functionGroups）在 init 时从静态默认值加载

### Requirement: Notification 监听

#### Scenario: 用户信息更新
- **WHEN** `Notification.Name.userDidUpdate` 通知发出
- **THEN** ViewModel 自动调用 `loadUserProfile()`
- **AND** `@Published` 属性变化驱动 UI 刷新
- **AND** ViewController 不再需要直接监听此通知

### Requirement: MyViewController 重构

#### Scenario: 移除的代码
- **WHEN** 完成重构
- **THEN** 从 VC 移除：
  - `private var userName/avatarChar/avatarURL` 状态变量
  - `private let stats/fulfillmentStats/services/functionGroups` mock 数据数组
  - `loadUserProfile()` / `onUserUpdated()` 方法
  - `refreshHeader()` 中的手动 tag 查找逻辑（改为 sink 驱动）
  - `NotificationCenter` 用户更新监听注册

#### Scenario: 保留的代码
- **WHEN** 完成重构
- **THEN** 保留在 VC：
  - `buildTableHeader()` — 全部 UI 构建（渐变、头像、会员卡、统计条）
  - `UITableViewDataSource/Delegate` 方法
  - `refreshForSeniorMode()` — 重建 header
  - 导航 action（pushSettings、pushProfile 等）

#### Scenario: ViewModel 绑定
- **WHEN** `bindViewModel()` 被调用
- **THEN** 订阅 `$userName` → 触发 `refreshHeader()` 更新 UI
- **AND** `refreshHeader()` 从 `viewModel.avatarChar`、`viewModel.avatarURL`、`viewModel.userName` 读取数据

## Acceptance Checklist

- [ ] `PL/My/Home/ViewModels/MyViewModel.swift` 创建
- [ ] Mock 数据从 VC 移至 ViewModel 静态属性
- [ ] 用户信息加载和 `userDidUpdate` 监听在 ViewModel 中
- [ ] Header 刷新由 `$userName` 驱动
- [ ] 所有 UI 行为与重构前一致
