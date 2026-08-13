## ADDED Requirements

### Requirement: Detect session invalidation on authenticated responses
系统 SHALL 在**已认证**网络请求的响应中识别会话失效信号。识别条件至少包括：业务码 `A0230`；或响应 `msg` 明确表示登录已失效/登录状态已过期；或 HTTP 状态码 401。未认证的 `publicSession` 请求 MUST NOT 触发本流程。

#### Scenario: Business code A0230 on HTTP 200
- **WHEN** 已认证请求返回 HTTP 200 且 body `code` 为 `A0230`（如 msg「登录已失效!」）
- **THEN** 系统触发会话失效处理流水线（先尝试 refresh，失败再弹窗），不得仅将该响应当作普通业务失败而忽略

#### Scenario: Public login APIs do not trigger
- **WHEN** 未登录用户调用登录/发码等 `publicSession` 接口且返回含 `A0230` 或其他业务错误
- **THEN** 系统不展示登录过期全局弹窗，也不清理（本不存在的）登录态

#### Scenario: HTTP 401 on authenticated request
- **WHEN** 已认证请求因认证失败返回 HTTP 401，且 Token 自动刷新失败
- **THEN** 系统触发同一会话失效处理流水线

---

### Requirement: Prefer refresh_token before forcing re-login
系统 SHALL 在识别到会话失效信号后，**优先**使用本地 `refresh_token` 调用 `POST /auth/oauth2/token`（`grant_type=refresh_token`）静默续期；仅当无 refresh_token、刷新接口失败或业务拒绝时，才清理本地态并展示过期弹窗。

#### Scenario: A0230 then refresh succeeds
- **WHEN** 已认证请求返回 `A0230`，且本地存在可用 `refresh_token`，且刷新接口成功返回新 access_token
- **THEN** 系统 SHALL 更新 Credential / 重建认证 Session，MUST NOT 展示登录过期弹窗，MUST NOT 清理 IM 等业务缓存

#### Scenario: A0230 then refresh fails
- **WHEN** 刷新失败（无 refresh_token、网络错误或服务端拒绝）
- **THEN** 系统 SHALL 清理本地登录态并展示全局登录过期弹窗

#### Scenario: Concurrent A0230 during refresh
- **WHEN** 同一时刻多个已认证请求均返回会话失效
- **THEN** 系统 MUST 只发起一次刷新 / 只展示一次弹窗

---

### Requirement: Clear local session on expiry
系统 SHALL 在**刷新失败、强制重新登录**时清理本地登录态与会话相关缓存，且 MUST NOT 阻塞于服务端 logout 接口。

#### Scenario: Immediate local cleanup after refresh failure
- **WHEN** refresh 失败进入强制重新登录
- **THEN** 清除 access/refresh token 与 API Credential，清空 IM 会话缓存、服务 Hub 缓存、健康 Hub 缓存、机构选择，断开融云，并 `UserManager.clear`

#### Scenario: No logout API call
- **WHEN** 会话因服务端判定失效且刷新失败而清理
- **THEN** 系统不调用 `DELETE /oauth2/logout`（token 已失效）

---

### Requirement: Global session-expired sheet
系统 SHALL 在刷新失败后于当前界面展示全局登录过期弹窗；遮罩不可关闭；文案对齐 funde 原型。

#### Scenario: Present sheet once
- **WHEN** 刷新失败且当前尚未展示该弹窗
- **THEN** 展示弹窗：标题「登录状态已过期」、说明默认「为保护您的健康数据安全，登录状态已过期，请重新登录」、主按钮「重新登录」；点击遮罩不得关闭

#### Scenario: Relogin action
- **WHEN** 用户点击「重新登录」
- **THEN** 设置 `fd_session_expired_hint` 为真，并将根控制器切换为登录页

#### Scenario: Login page hint
- **WHEN** 用户因会话失效进入登录页且 `fd_session_expired_hint` 为真
- **THEN** 登录页展示已有失效提示条，并在展示后清除该标记
