# Vouchers / 我的卡券 — ViewModel

## Purpose

为 `VoucherListViewController` 引入 `VoucherListViewModel`，将卡券数据、Tab 筛选、过滤逻辑从 ViewController 移至 ViewModel。

> **Reference**: `PL/My/Vouchers/VoucherListViewController.swift`、`BLL/My/VoucherService.swift`

---

## Requirements

### Requirement: VoucherListViewModel Data Ownership

#### Scenario: Published 状态
- **WHEN** ViewModel 初始化
- **THEN** 包含以下 `@Published` 属性：
  - `filteredVouchers: [MVoucher]` — 当前筛选后的卡券
  - `isEmpty: Bool` — 筛选结果为空
  - `activeTab: Int` — 当前选中的 Tab（0=全部, 1=未使用, 2=已激活, 3=已过期）

### Requirement: Tab 筛选

#### Scenario: 加载数据
- **WHEN** `loadData()` 被调用
- **THEN** 从 `VoucherService.shared.getVouchers()` 获取全部卡券
- **AND** 调用 `filterVouchers()` 按当前 `activeTab` 筛选

#### Scenario: 切换 Tab
- **WHEN** `selectTab(_ index:)` 被调用
- **THEN** 更新 `activeTab`，重新执行筛选：
  - 0 → 全部
  - 1 → `.unused`
  - 2 → `.activated`
  - 3 → `.expired`
- **AND** 更新 `isEmpty`

### Requirement: VoucherListViewController 重构

#### Scenario: 移除的代码
- **WHEN** 完成重构
- **THEN** 从 VC 移除：
  - `private var allVouchers: [MVoucher]`
  - `private var filteredVouchers: [MVoucher]`
  - `private var activeTab: Int`
  - `loadData()` / `filterVouchers()` / `updateDisplay()` 方法
  - `tabChanged(_:)` 中的过滤逻辑

#### Scenario: 保留的代码
- **WHEN** 完成重构
- **THEN** 保留在 VC：
  - 所有 UI 布局（segmentControl、tableView、emptyView、getMoreView）
  - 导航（Router.push）
  - `activateVoucher` 导航操作

#### Scenario: ViewModel 绑定
- **WHEN** `bindViewModel()` 被调用
- **THEN** 订阅 `$isEmpty` → 控制 tableView/emptyView 切换
- **AND** 订阅 `$filteredVouchers` → 触发 `tableView.reloadData()`

## Acceptance Checklist

- [ ] `PL/My/Vouchers/ViewModels/VoucherListViewModel.swift` 创建
- [ ] Tab 筛选逻辑在 ViewModel 中
- [ ] Empty 状态由 `@Published` 驱动
- [ ] 所有 UI 行为与重构前一致
