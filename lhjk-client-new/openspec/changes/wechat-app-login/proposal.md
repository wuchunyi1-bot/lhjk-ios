## Why

后端已提供 iOS 微信一键登录契约（`grant_type=WE_CHAT_APP_LOGIN`，未绑定返回 `AU0001` 后复用同一微信 `code` 绑手机）。客户端仍为 Mock（假 code / `wechatTempToken`），无法真机登录。

## What Changes

- **BREAKING（BLL 微信登录模型）**：去掉 Mock 的 `wechatTempToken` / `confirmRebind` 主路径；改为微信 `code` → token；`AU0001` 携带原 `code` 进入绑定。
- `LoginService` 对接真实 `POST /auth/oauth2/token`（`WE_CHAT_APP_LOGIN`）与绑定二次请求（`code` + `mobile` + `smsCode`）。
- 登录页：`WeChatSDKManager.sendAuth` 取真 `code`，校验 `state`；成功走现有 `handleLoginSuccess`（含 `archiveComplete` 门禁）。
- 绑定页发码走既有 `sendVerificationCode(type: .login)`；取消时清除内存中的微信 `code`。
- 忽略 token 响应中的 `userInfo`（与 `onboarding-archive-complete` 一致）。

## Capabilities

### New Capabilities

- `wechat-app-login`：微信 App 授权登录与未绑定手机号绑定流程。

### Modified Capabilities

- （无独立归档的 `register-login` 主 spec；行为以本 change 的 delta 与现有登录编排为准。）

## Impact

- `BLL/RegisterLogin/LoginService*`、`LoginModels`
- `PL/RegisterLogin/LoginViewModel`、`LoginViewController`、`PhoneBindingView`
- `DAL/WeChat/WeChatSDKManager`（`state` 校验）
- `docs/api-inventory.md`
- 依赖：已有微信 OpenSDK、`client_id=funde-app` 与现有短信登录一致
