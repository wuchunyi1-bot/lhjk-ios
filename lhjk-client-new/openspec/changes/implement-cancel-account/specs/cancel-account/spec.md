# Cancel Account / 注销用户

## Purpose

实现注销用户功能：接入 `POST /v1/users/cancelCurrentUser` API，抽取 `CancelAccountViewModel` 管理注销流程。

> **API Reference**: `POST /v1/users/cancelCurrentUser` — 成功返回 `ResultVoid`；存在未完成订单时业务码 `O0012`，`data` 为命中的订单 id（int64），Auth: Bearer access_token

---

## Requirements

### Requirement: UserService API

`UserService` SHALL 新增 `cancelCurrentUser()` 方法。

#### Scenario: API 调用
- **WHEN** `cancelCurrentUser()` 被调用
- **THEN** 发起 `POST /v1/users/cancelCurrentUser`（需认证）
- **AND** 解析响应为 `APIResponse<APIDataID>`（`data` 可为标量订单 id）
- **AND** `response.isSuccess == true` 时成功返回
- **AND** `code == "O0012"` 时抛出 `UserServiceError.unfinishedOrders(orderId:message:)`，`orderId` 取 `data`，`message` 取服务端 `msg`（空则用默认文案）
- **AND** 其余失败抛出 `UserServiceError.cancelFailed(msg)`

### Requirement: CancelAccountViewModel

#### Scenario: Published 状态
- **WHEN** ViewModel 初始化
- **THEN** `@Published var isSubmitting: Bool = false`
- **AND** `@Published var isSuccess: Bool = false`
- **AND** `let toastPublisher = PassthroughSubject<String, Never>()`
- **AND** `let unfinishedOrderPublisher = PassthroughSubject<UnfinishedOrderBlock, Never>()`

#### Scenario: 未完成订单（业务码 O0012）
- **WHEN** `cancelCurrentUser()` 返回 `code == "O0012"`
- **THEN** 不得清理本地会话
- **AND** 通过 `unfinishedOrderPublisher` 发出 `UnfinishedOrderBlock`（含可选 `orderId` 与提示文案）

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
- **AND** 一般失败时设置 `isSubmitting = false`，通过 `toastPublisher` 发出错误

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
- **AND** 订阅 `unfinishedOrderPublisher` → 弹出「暂无法注销账户」Alert

#### Scenario: 暂无法注销账户弹窗
- **WHEN** 收到未完成订单拦截
- **THEN** Alert 标题为「暂无法注销账户」
- **AND** 正文优先使用服务端 `msg`；缺省为「您当前还有未完成的订单、待发货商品或使用中的服务，请处理完成后再申请注销。」
- **AND** 按钮为「我知道了」（关闭）与「查看订单」
- **AND** 点击「查看订单」跳转 `/orders`（订单列表）
- **AND** 点击「我知道了」关闭弹窗，留在注销页

#### Scenario: 零 .shared 直调
- **WHEN** 完成重构
- **THEN** VC 中不出现 `LoginService.shared` / `UserManager.shared` / `IMService.shared` / `APIManager.shared`
- **AND** `Router.shared.push/setRoot` 可保留（框架级服务）

## Acceptance Checklist

- [x] `BLL/User/UserService.swift` 新增 `cancelCurrentUser()` 方法
- [x] `PL/My/Settings/Security/ViewModels/CancelAccountViewModel.swift` 创建
- [x] VC 中无业务 `.shared` 直调
- [x] 注销流程：确认弹窗 → API 调用 → 成功展示 → 跳转登录页
- [x] 注销失败时恢复按钮状态，展示错误提示
- [x] `O0012` 弹出「暂无法注销账户」，「查看订单」进入订单列表

