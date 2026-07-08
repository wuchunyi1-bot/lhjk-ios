# Shipping Address / 收货地址 — ViewModel

## Purpose

为 `AddressListViewController` 引入 `AddressListViewModel`，将地址数据、异步加载/删除 API 调用、loading/empty 状态管理从 ViewController 移至 ViewModel。

> **Reference**: `PL/My/Address/AddressListViewController.swift`、`BLL/My/AddressService.swift`

---

## Requirements

### Requirement: AddressListViewModel Data Ownership

#### Scenario: Published 状态
- **WHEN** ViewModel 初始化
- **THEN** 包含以下 `@Published` 属性：
  - `addresses: [MAddress]` — 地址列表（默认地址置顶）
  - `isLoading: Bool` — 加载中（默认 true）
  - `isEmpty: Bool` — 列表为空（默认 true）

### Requirement: 异步数据加载

#### Scenario: 加载地址列表
- **WHEN** `loadAddresses()` 被调用
- **THEN** 设置 `isLoading = true`，调用 `AddressService.shared.getAddressList()`
- **AND** 成功后将 `data.records` 赋值给 `addresses`，默认地址 (`isDefault == 1`) 排序置顶
- **AND** 设置 `isLoading = false`，`isEmpty = addresses.isEmpty`

#### Scenario: 加载失败
- **WHEN** API 请求抛出错误
- **THEN** 设置 `isLoading = false`，`isEmpty = true`
- **AND** 不修改 `addresses`（保留旧数据或空数组）

### Requirement: 删除地址

#### Scenario: 删除成功
- **WHEN** `deleteAddress(id:)` 被调用
- **THEN** 调用 `AddressService.shared.deleteAddress(id:)`
- **AND** 成功后从 `addresses` 中移除 `id` 匹配的条目
- **AND** 更新 `isEmpty`

#### Scenario: 删除失败
- **WHEN** API 请求抛出错误
- **THEN** 抛出错误给调用方处理（Toast 展示在 VC 中）

### Requirement: AddressListViewController 重构

#### Scenario: 移除的代码
- **WHEN** 完成重构
- **THEN** 从 VC 移除：
  - `private var addresses: [MAddress]`
  - `private var isLoading: Bool`
  - `loadAddresses()` 方法
  - `performDelete(id:at:)` 方法中的删除 API 调用
  - `updateDisplay()` 方法

#### Scenario: 保留的代码
- **WHEN** 完成重构
- **THEN** 保留在 VC：
  - 所有 UI 布局（tableView、emptyView、loadingIndicator）
  - UIAlertController 确认弹窗
  - Toast 展示
  - 导航（Router.push）

#### Scenario: ViewModel 绑定
- **WHEN** `bindViewModel()` 被调用
- **THEN** 订阅 `$isLoading` → 控制 loadingIndicator 和 tableView/emptyView 显隐
- **AND** 订阅 `$isEmpty` → 控制 tableView/emptyView 切换
- **AND** 订阅 `$addresses` → 触发 `tableView.reloadData()`

## Acceptance Checklist

- [ ] `PL/My/Address/ViewModels/AddressListViewModel.swift` 创建
- [ ] 地址列表加载、删除通过 ViewModel
- [ ] loading/empty 状态由 `@Published` 驱动
- [ ] 所有 UI 行为与重构前一致
