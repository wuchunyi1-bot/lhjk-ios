## Why

`CancelAccountViewController` 当前 293 行，UI 和流程已完整（notice → 确认弹窗 → result），但 `performCancellation()` 是 mock 实现——只调用 `LoginService.shared.logout()` + `clearSession()`，未调用真实的注销 API `POST /v1/users/cancelCurrentUser`。

同时 VC 中存在 `.shared` 直调（`LoginService.shared`、`UserManager.shared`），不符合项目已建立的 ViewModel + AppContainer 架构模式。

## What Changes

1. **BLL 层**: `UserService` 新增 `cancelCurrentUser()` 方法，对接 `POST /v1/users/cancelCurrentUser`
2. **PL 层**: 新建 `CancelAccountViewModel`，封装注销流程（检查 → 确认 → API 调用 → 结果）
3. **PL 层**: 重构 `CancelAccountViewController`，移除 `.shared` 直调，绑定 ViewModel

## API Reference

```
POST /v1/users/cancelCurrentUser
Auth: Bearer access_token
Response: ResultVoid { code, data, msg, success, failed }
Success: response.isSuccess == true
```

## Capabilities

- `cancel-account`: 注销用户功能 spec

## Impact

- **BLL/User/UserService.swift**: 新增 `cancelCurrentUser()` 方法
- **PL/My/Settings/Security/ViewModels/CancelAccountViewModel.swift**: 新增
- **PL/My/Settings/Security/CancelAccountViewController.swift**: 重构
- **无工程配置变更**
