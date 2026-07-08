## Why

当前项目中 PL 层 ViewController 承载了过多职责：数据持有、数据转换、Mock 数据、API 调用、Combine 订阅、UI 布局等都耦合在同一个文件中。这导致：(1) 无法对业务逻辑做单元测试；(2) ViewController 复用困难；(3) 数据流不清晰，难以追踪状态变更。

## What Changes

### PL 层目录规范

在 `project-architecture` spec 中新增 `ViewModels/` 子目录，与 `Cells/`、`Components/` 并列。

### 已重构的 ViewController（6 个）

| VC | 重构前 | 重构后 | ViewModel（新增） | 提取内容 |
|----|--------|--------|-------------------|---------|
| HomeVC | 279 | 195 (-30%) | 161 | 用户数据、mock 数据、Snapshot 构建、Notification 监听 |
| ChatVC | 1175 | 875 (-26%) | 398 | 消息管理、发送/撤回/引用、实时订阅、时间标记、乐观更新 |
| ConversationListVC | 270 | 160 (-41%) | 129 | 5 路 Combine 订阅、增量/批量/全量刷新、缓存策略 |
| AddressListVC | 252 | 225 (-11%) | 55 | 地址数组、异步加载/删除、loading/empty 状态 |
| VoucherListVC | 269 | 230 (-15%) | 52 | 卡券数据、Tab 筛选、过滤逻辑 |
| MyVC | 499 | 384 (-23%) | 120 | 用户信息、mock 数据（stats/服务/功能列表）、Notification 监听 |

### 待处理

- **LoginViewController（1058 行）**：最高优先级但复杂度也最高。含双模式登录状态机、5+ API 调用、拼图验证、隐私弹窗、通知权限引导、微信绑定等。建议作为独立变更处理。

### 跳过（不需要 ViewModel）

- MessagesViewController (118)、NotificationListViewController (64) — 太简单
- OrderListViewController (287) — 容器型 VC，无数据逻辑
- HealthViewController (206)、ServiceViewController (423) — 纯静态 mock 数据，接入 API 时再处理

## Capabilities

- `project-architecture`: PL 层目录规范新增 ViewModels/
- `home`: HomeViewModel 定义
- `im`: ChatViewModel 定义 + ConversationListViewModel 定义
- `shipping-address`: AddressListViewModel 定义
- `vouchers`: VoucherListViewModel 定义
- `me`: MyViewModel 定义

## Impact

**新增文件**（6 个 ViewModel）：
- `PL/Home/ViewModels/HomeViewModel.swift`
- `PL/Message/Chat/ViewModels/ChatViewModel.swift`
- `PL/Message/ViewModels/ConversationListViewModel.swift`
- `PL/My/Address/ViewModels/AddressListViewModel.swift`
- `PL/My/Vouchers/ViewModels/VoucherListViewModel.swift`
- `PL/My/Home/ViewModels/MyViewModel.swift`

**修改文件**（6 个 ViewController）：
- `PL/Home/HomeViewController.swift`
- `PL/Message/Chat/ChatViewController.swift`
- `PL/Message/ConversationListViewController.swift`
- `PL/My/Address/AddressListViewController.swift`
- `PL/My/Vouchers/VoucherListViewController.swift`
- `PL/My/Home/MyViewController.swift`

**Spec 文件**（1 个修改 + 4 个新增 delta）：
- `openspec/specs/project-architecture/spec.md`（更新 PL 层目录规范）
- 本次 change 的 delta spec 文件
