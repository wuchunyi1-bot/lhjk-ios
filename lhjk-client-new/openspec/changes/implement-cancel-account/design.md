## Context

当前 `CancelAccountViewController.performCancellation()` 是 mock 实现：在 0.8s 延迟后调用 `LoginService.shared.logout()` + `clearSession()`，然后直接展示成功。实际上应该调用 `POST /v1/users/cancelCurrentUser` API，只在服务端确认注销成功后才清除本地状态。

> **Related**: `openspec/changes/extract-viewmodels/`、`openspec/changes/introduce-appcontainer/`、`openspec/specs/cancel-account/`（如存在）

## Decisions

### 1. API 层：UserService 新增方法

**选择**: 在已有的 `UserService` 中新增 `cancelCurrentUser()` 方法。

```swift
func cancelCurrentUser() async throws {
    let response: APIResponse<APIDataID> = try await APIManager.shared
        .postAsync(path: "/v1/users/cancelCurrentUser", ...)
    if response.code == "O0012" { throw UserServiceError.unfinishedOrders(...) }
    guard response.isSuccess else { throw UserServiceError.cancelFailed(response.msg ?? "") }
}
```

### 2. ViewModel 职责

| 移到 CancelAccountViewModel | 留在 CancelAccountViewController |
|---|---|
| 注销提交状态 (`isSubmitting`) | UI 布局（notice + result 两个 step） |
| API 调用 (`cancelCurrentUser`) | 确认弹窗（UIAlertController） |
| 成功后清理（logout + clearSession + clearUserManager） | Step 切换动画 |
| 未完成订单检查逻辑（`O0012`） | 跳转 `/orders`、`/login`（Router） |

### 3. 流程

```
用户点击"申请注销"
  → 确认弹窗
  → 用户确认
  → viewModel.cancelAccount()
    → POST /v1/users/cancelCurrentUser
    → 成功: 清会话 → isSuccess
    → code O0012: unfinishedOrderPublisher（不清理会话）
    → 其它失败: toastPublisher
  → VC 订阅
    → 成功: 展示 result view → 2s 后跳转 /login
    → O0012: Alert「暂无法注销账户」→「查看订单」push /orders
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

### 6. 未完成订单检查（业务码 O0012）

注销接口 `POST /v1/users/cancelCurrentUser` 在存在未完成订单、待发货商品或使用中的服务时返回：

```json
{ "code": "O0012", "msg": "您当前还有未完成的订单、待发货商品或使用中的服务，请处理完成后再申请注销。", "data": 12345 }
```

- `data` 为命中的订单 id（int64），客户端用 `APIDataID` 解码
- **不得**按客户端本地订单列表预检拦截；以服务端 `O0012` 为准
- Alert：「暂无法注销账户」+ 服务端 `msg`；「我知道了」关闭；「查看订单」`Router.push("/orders")`
