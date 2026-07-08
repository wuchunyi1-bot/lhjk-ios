## Context

当前 `CancelAccountViewController.performCancellation()` 是 mock 实现：在 0.8s 延迟后调用 `LoginService.shared.logout()` + `clearSession()`，然后直接展示成功。实际上应该调用 `POST /v1/users/cancelCurrentUser` API，只在服务端确认注销成功后才清除本地状态。

> **Related**: `openspec/changes/extract-viewmodels/`、`openspec/changes/introduce-appcontainer/`、`openspec/specs/cancel-account/`（如存在）

## Decisions

### 1. API 层：UserService 新增方法

**选择**: 在已有的 `UserService` 中新增 `cancelCurrentUser()` 方法。

```swift
func cancelCurrentUser() async throws {
    let response: APIResponse<EmptyResponse> = try await APIManager.shared
        .postAsync(path: "/v1/users/cancelCurrentUser", ...)
    guard response.isSuccess else { throw UserServiceError.cancelFailed(response.msg ?? "") }
}
```

### 2. ViewModel 职责

| 移到 CancelAccountViewModel | 留在 CancelAccountViewController |
|---|---|
| 注销提交状态 (`isSubmitting`) | UI 布局（notice + result 两个 step） |
| API 调用 (`cancelCurrentUser`) | 确认弹窗（UIAlertController） |
| 成功后清理（logout + clearSession + clearUserManager） | Step 切换动画 |
| 未完成订单检查逻辑 | 跳转 `/orders`、`/login`（Router） |

### 3. 流程

```
用户点击"申请注销"
  → 检查未完成订单（V1.0: 默认无）
  → 确认弹窗
  → 用户确认
  → viewModel.cancelAccount()
    → POST /v1/users/cancelCurrentUser
    → 成功: 调 logout API → clearSession → clearUser
    → 失败: 通过 toastPublisher 提示错误
  → VC 订阅 isSubmitting/result
    → 成功: 展示 result view → 2s 后跳转 /login
    → 失败: 恢复按钮状态
```

### 4. 清理顺序

注销成功后按以下顺序清理：
1. `APIManager.shared.clearCredential()` — 清除 Token
2. `LoginService.shared.clearSession()` — 清除登录态
3. `UserManager.shared.clear()` — 清除用户缓存
4. `IMService.shared.clear()` — 清除 IM 数据

### 5. 依赖注入

```swift
init(userService: UserService = AppContainer.shared.userService,
     loginService: LoginService = AppContainer.shared.loginService,
     userManager: UserManager = AppContainer.shared.userManager,
     imService: IMService = AppContainer.shared.imService)
```

### 6. 未完成订单检查（V1.0）

当前 `hasUnfinishedOrders()` 默认返回 `false`（无订单服务）。保留此逻辑在 ViewModel 中，后续接入订单服务后改为真实检查。
