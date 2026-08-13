## Context

后端文档：`ios-wechat-login-integration.md`。工程已有 `WeChatSDKManager.sendAuth`、短信/密码走 `POST /auth/oauth2/token`，微信登录仍为 Mock。

## Goals / Non-Goals

**Goals:**

- 真机：拉微信 → `code` → `WE_CHAT_APP_LOGIN` → Token 或 `AU0001` 绑手机。
- 绑定复用原 `code` + `smsCode`；发码 `type=1`。
- 登录成功复用 `handleLoginSuccess`（IM + 档案门禁）。

**Non-Goals:**

- 不新建独立 `WeChatLoginManager`（继续用 `WeChatSDKManager`）。
- 不改 Keychain 存储策略（沿用现有 Credential / UserDefaults 兼容路径）。
- 不实现文档未约定的「换绑 confirmRebind」专用接口（若服务端返回冲突文案，用 `serverMessage` 展示）。
- 不消费 token `userInfo`。

## Decisions

### 1. BLL 结果模型

```swift
enum WeChatLoginStep {
  case loggedIn(LoginResult)
  case needBindMobile(wechatCode: String)
}
```

- `loginByWeChat(code:)` → 上两者之一，或抛 `LoginError`
- `loginByWeChatBinding(code:mobile:smsCode:)` → `LoginResult`
- 删除 Mock：`WechatAuthResult.wechatTempToken`、`wechatBindPhone(..., confirmRebind:)`

命名避免与 DAL `WeChatAuthResult`（SDK code）冲突。

### 2. 编排位置

`LoginViewModel.startWeChatLogin()`：

1. `WeChatSDKManager.sendAuth`（async 包装）
2. `loginService.loginByWeChat(code:)`
3. `.loggedIn` → `handleLoginSuccess`
4. `.needBindMobile` → `PassthroughSubject` / 回调让 VC 展示 `PhoneBindingView`，内存持有 `pendingWeChatCode`
5. 用户取消绑定 → 清空 `pendingWeChatCode`

### 3. 业务码

| code | 处理 |
|------|------|
| `200` / `0` | 存 Token，登录成功 |
| `AU0001` | 不抛致命错，返回 `needBindMobile` |
| 其它 | `LoginError(from:msg:)` |

`AU0001` 时 `data` 可为 null，解码须成功。

### 4. SDK `state`

`sendAuth` 时保存 `expectedState`，`SendAuthResp` 校验一致后再交 `code`。

### 5. 绑定发码

`PhoneBindingView` 通过 `onRequestCode: (phone) async throws -> Void`（或 VC 注入）调用 `sendVerificationCode(..., .login)`，去掉本地假倒计时成功。

## Risks / Trade-offs

- [微信 code 600s 过期] → Toast 提示重新点微信登录；清除 pending code
- [AppID / UL 配置错误] → 与支付/分享同一 `WeChatConfig`，联调清单核对
- [去掉 rebind Mock] → UI 保留亦可，但微信主路径不再进入

## Open Questions

- 无：以服务端文档为准。
