# Cancel Account / 注销用户

## Purpose

实现注销用户功能：接入 `POST /v1/users/cancelCurrentUser` API，抽取 `CancelAccountViewModel` 管理注销流程。

> **API Reference**: `POST /v1/users/cancelCurrentUser` — 返回 `ResultVoid`，Auth: Bearer access_token

---

## Requirements

### Requirement: UserService API

`UserService` SHALL 新增 `cancelCurrentUser()` 方法。

#### Scenario: API 调用
- **WHEN** `cancelCurrentUser()` 被调用
- **THEN** 发起 `POST /v1/users/cancelCurrentUser`（需认证）
- **AND** 解析响应为 `APIResponse<EmptyResponse>`
- **AND** `response.isSuccess == true` 时成功返回
- **AND** 失败时抛出 `UserServiceError.cancelFailed(msg)`

### Requirement: CancelAccountViewModel

#### Scenario: Published 状态
- **WHEN** ViewModel 初始化
- **THEN** `@Published var isSubmitting: Bool = false`
- **AND** `@Published var isSuccess: Bool = false`
- **AND** `let toastPublisher = PassthroughSubject<String, Never>()`

#### Scenario: 未完成订单检查
- **WHEN** `hasUnfinishedOrders()` 被调用
- **THEN** V1.0 默认返回 `false`
- **AND** 后续接入订单服务后改为真实检查（`status ∈ {pending_use, in_progress, pending_review}`）

#### Scenario: 注销提交
- **WHEN** `cancelAccount()` 被调用
- **THEN** 设置 `isSubmitting = true`
- **AND** 调用 `userService.cancelCurrentUser()`
- **AND** 成功后依次执行清理：
  1. `APIManager.shared.clearCredential()`
  2. `loginService.clearSession()`
  3. `userManager.clear()`
  4. `imService.clear()`
- **AND** 设置 `isSuccess = true`，`isSubmitting = false`
- **AND** 失败时设置 `isSubmitting = false`，通过 `toastPublisher` 发出错误

### Requirement: CancelAccountViewController 重构

#### Scenario: 移除的代码
- **WHEN** 完成重构
- **THEN** 从 VC 移除：
  - `private var isSubmitting = false`
  - `performCancellation()` 中的 mock 延迟 + `.shared` 直调
  - `LoginService.shared.logout()` / `.clearSession()` / `UserManager.shared.clear()` 调用

#### Scenario: 新增绑定
- **WHEN** `bindViewModel()` 被调用
- **THEN** 订阅 `$isSubmitting` → 更新按钮状态
- **AND** 订阅 `$isSuccess` → 切换 notice/result step，标题清空
- **AND** 订阅 `toastPublisher` → 展示错误 Toast

#### Scenario: 零 .shared 直调
- **WHEN** 完成重构
- **THEN** VC 中不出现 `LoginService.shared` / `UserManager.shared` / `IMService.shared` / `APIManager.shared`
- **AND** `Router.shared.push/setRoot` 可保留（框架级服务）

## Acceptance Checklist

- [ ] `BLL/User/UserService.swift` 新增 `cancelCurrentUser()` 方法
- [ ] `PL/My/Settings/Security/ViewModels/CancelAccountViewModel.swift` 创建
- [ ] VC 中无业务 `.shared` 直调
- [ ] 注销流程：确认弹窗 → API 调用 → 成功展示 → 跳转登录页
- [ ] 注销失败时恢复按钮状态，展示错误提示
