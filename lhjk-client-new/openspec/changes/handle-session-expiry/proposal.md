## Why

服务端在登录失效时返回 **HTTP 200 + 业务码 `A0230`（msg「登录已失效!」）**，而非 HTTP 401。当前 `AuthenticationInterceptor` 只认 401，且 `requiresRefresh` 恒为 false，业务层也无统一过期处理，导致 App 继续停留在已登录态。需对齐 funde 原型 / PRD AUTH-11：全局弹窗 → 重新登录。

## What Changes

- 在认证请求响应链路统一识别会话失效业务码（至少 `A0230`，以及 msg 含「登录已失效」等）
- 识别后立即清理本地登录态与会话相关缓存，并在当前页展示**不可点遮罩关闭**的全局弹窗
- 弹窗文案对齐原型：标题「登录状态已过期」、说明「为保护您的健康数据安全，登录状态已过期，请重新登录」、按钮「重新登录」
- 点击「重新登录」进入登录页，并设置 `fd_session_expired_hint` 以便登录页展示失效提示条
- 并发多请求同时返回失效码时只弹一次
- **本期不做**：密码变更专属文案、多端踢下线文案、登录成功后 redirect 回跳（仍可后续扩展）

## Capabilities

### New Capabilities

- `session-expiry`: 登录态失效检测、清理、全局弹窗与进入登录页

### Modified Capabilities

- `networking`: 认证请求响应需识别业务层会话失效码并触发会话失效处理（不仅限 HTTP 401）

## Impact

- DAL：`APIManager` / `APIManager+Async` 响应钩子
- BLL：`LoginService` 会话清理编排（可选协调器）
- PL：全局 `SessionExpirySheet`、登录页已有 `fd_session_expired_hint`
- 参考：funde-client `MobileApp.vue`（`fd-auth-expired`）、PRD「登录过期」EXPIRED-F001/F002 / MSG-22 / AUTH-11
