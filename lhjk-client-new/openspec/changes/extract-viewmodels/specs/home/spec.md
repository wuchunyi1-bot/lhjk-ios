# Home / 首页 — ViewModel

## Purpose

为 `HomeViewController` 引入 `HomeViewModel`，将数据持有、用户信息读取、Snapshot 构建逻辑从 ViewController 移至 ViewModel。

> **Reference**: 现有 `PL/Home/HomeViewController.swift`、`openspec/specs/design-tokens/spec.md`

---

## Requirements

### Requirement: HomeViewModel Data Ownership

`HomeViewModel` SHALL 作为首页所有展示数据的 **单一数据源**，`HomeViewController` 只负责 UI 绑定和导航。

#### Scenario: ViewModel 数据结构
- **WHEN** `HomeViewModel` 被初始化
- **THEN** 它包含以下 `@Published` 属性：
  - `userName: String` — 用户姓名（默认 "加载中…"）
  - `advisor: String` — 健管师姓名
  - `daysLeft: Int` — 服务剩余天数
  - `riskScore: Int` — 健康风险评分
  - `riskLevel: String` — 风险等级文案
  - `riskHint: String` — 风险提示
  - `metrics: [HomeHeroCell.Metric]` — 体征指标列表
  - `quickActions: [HomeQuickActionsCell.Action]` — 快捷入口
  - `teamMembers: [HomeTeamCardCell.Member]` — 健管团队
  - `tasks: [HomeTaskCardCell.Task]` — 今日健康任务
  - `articles: [HomeArticleCell.Article]` — 健康文章
  - `snapshot: NSDiffableDataSourceSnapshot<HomeSection, HomeItem>` — TableView 数据源快照

#### Scenario: 数据加载
- **WHEN** ViewController 调用 `viewModel.loadUserProfile()`
- **THEN** ViewModel 从 `UserManager.shared.currentUser` 读取用户信息，更新 `userName` 等属性
- **AND** 同步更新 `snapshot`（调用内部 `applySnapshot()`）

#### Scenario: Mock 数据管理
- **WHEN** ViewModel 初始化
- **THEN** Mock 数据（metrics、quickActions、teamMembers、tasks、articles）定义在 ViewModel 中
- **AND** 后续接入真实 API 时只需修改 ViewModel，ViewController 无需变更

### Requirement: HomeViewModel BLL Integration

`HomeViewModel` SHALL 通过 `init` 参数接收 BLL Service，默认值使用 `.shared`。

#### Scenario: 依赖注入
- **WHEN** `HomeViewModel` 被创建
- **THEN** 接受 `userManager: UserManager = .shared` 参数
- **AND** 测试时可注入 mock UserManager

### Requirement: HomeViewController Refactor

`HomeViewController` SHALL 只保留 UI 职责：布局、TableView 配置、导航、生命周期。

#### Scenario: 移除的代码
- **WHEN** 完成重构
- **THEN** 以下代码从 `HomeViewController` 移除：
  - 所有 `private let` mock 数据数组（metrics、quickActions、teamMembers、tasks、articles）
  - `private var userName/avatarChar/advisor/daysLeft/riskScore/riskLevel/riskHint` 状态变量
  - `loadUserProfile()` 方法
  - `applySnapshot()` 方法
  - `onUserUpdated()` 方法中的手动数据更新

#### Scenario: 新增的绑定
- **WHEN** ViewController 的 `bindViewModel()` 被调用
- **THEN** 订阅 `viewModel.$snapshot` → 调用 `dataSource.apply(snapshot, animatingDifferences: false)`
- **AND** 订阅 `viewModel.$userName` → 局部刷新 Hero 区域（或依赖 snapshot 统一刷新）

#### Scenario: 导航保留在 VC
- **WHEN** 用户点击快捷入口或文章
- **THEN** ViewController 的闭包回调（onActionTapped、onMessageTapped 等）继续通过 `Router.shared` 处理导航
- **AND** ViewModel 不持有 Router 引用

---

## States

| State | 表现 |
|-------|------|
| **默认** | ViewModel 加载 mock 数据 + 用户信息，ViewController 展示 6 个区域 |
| **用户信息更新** | `userDidUpdate` 通知 → ViewModel 重新读取 UserManager → snapshot 更新 → UI 自动刷新 |

## Acceptance Checklist

- [ ] `PL/Home/ViewModels/HomeViewModel.swift` 文件存在
- [ ] `HomeViewModel` 为 `struct`，包含上述全部 `@Published` 属性
- [ ] `HomeViewController` 通过 `viewModel.$snapshot` 驱动 TableView
- [ ] `HomeViewController` 中不再包含硬编码 mock 数据数组
- [ ] 所有 UI 行为与重构前一致（Hero、Quick Actions、Team、Tasks、Service Banner、Articles）
- [ ] 用户信息更新通知 (`userDidUpdate`) 仍能正确刷新首页数据
