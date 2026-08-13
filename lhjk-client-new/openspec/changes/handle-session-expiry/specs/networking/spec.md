## ADDED Requirements

### Requirement: Business session-invalid codes on authenticated responses
系统 SHALL 在已认证请求的成功 HTTP 响应（2xx）中检查业务 `code`/`msg`；若判定为会话失效，则通知上层会话失效处理器。此检查独立于 Alamofire `AuthenticationInterceptor` 的 HTTP 401 刷新路径。

#### Scenario: Inspect raw body after decode success
- **WHEN** 已认证请求 HTTP 2xx 且 body 可解析出业务 `code`
- **THEN** DAL 在将结果返回 BLL 之前检查会话失效条件；若命中则触发会话失效回调

#### Scenario: Unauthenticated session skipped
- **WHEN** 请求经由 `publicSession` 发出
- **THEN** DAL 不触发会话失效回调

## MODIFIED Requirements

### Requirement: Authentication & Token Management
系统 SHALL 使用 Alamofire 的 `AuthenticationInterceptor` 配合自定义 `Authenticator` 实现 Token 的自动注入、过期刷新和并发请求控制。

**架构设计**:
```
┌──────────────────────────────────────────────────┐
│              APIManager (Session)                 │
│  ┌────────────────────────────────────────────┐  │
│  │        AuthenticationInterceptor            │  │
│  │  ┌──────────────────────────────────────┐  │  │
│  │  │         OAuthAuthenticator            │  │  │
│  │  │  • apply(credential, to: &request)   │  │  │
│  │  │  • refresh(credential, completion)    │  │  │
│  │  │  • didRequest(failDueToAuthError:)    │  │  │
│  │  │  • isRequest(authenticatedWith:)      │  │  │
│  │  │  └──────────────────────────────────────┘  │  │
│  │  ┌──────────────────────────────────────┐  │  │
│  │  │         OAuthCredential               │  │  │
│  │  │  • accessToken / refreshToken         │  │  │
│  │  │  • expiration (requiresRefresh)       │  │  │
│  │  └──────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
```

- `OAuthCredential`: 实现 `AuthenticationCredential` 协议，存储 accessToken、refreshToken 和过期时间
- `OAuthAuthenticator`: 实现 `Authenticator` 协议，负责四个核心职责
- `AuthenticationInterceptor`: Alamofire 内置拦截器，协调 Authenticator 和 Credential，自动处理并发 Token 刷新的锁和队列
- 当服务端以 **业务码**（如 `A0230`）而非 HTTP 401 宣告登录失效时，由响应层会话失效检测接管（见 session-expiry），不依赖 `requiresRefresh`

#### Scenario: Token 自动注入
- **WHEN** 发起任何网络请求
- **THEN** `OAuthAuthenticator.apply(_:to:)` 自动将 Bearer Token 注入请求头的 Authorization 字段

#### Scenario: Token 过期自动刷新
- **WHEN** `OAuthCredential.requiresRefresh` 返回 true（当前时间超过 expiration）
- **THEN** `OAuthAuthenticator.refresh(_:for:completion:)` 自动调用刷新接口获取新 Token，刷新成功后更新 Credential 并自动重放原请求

#### Scenario: 并发刷新控制
- **WHEN** 多个请求同时触发 Token 刷新（如页面加载时同时发起 3 个请求，Token 均已过期）
- **THEN** `AuthenticationInterceptor` 内部自动排队：仅第一个请求触发实际刷新，其余请求挂起等待刷新结果，无需手动管理锁或队列

#### Scenario: 401 触发刷新
- **WHEN** 服务端返回 HTTP 401 且 `OAuthAuthenticator.didRequest(_:with:failDueToAuthenticationError:)` 返回 true
- **THEN** `AuthenticationInterceptor` 自动触发 Token 刷新流程，成功后重放原请求

#### Scenario: Token 刷新失败
- **WHEN** Token 刷新接口也返回错误（如 refreshToken 过期），或当前无法刷新
- **THEN** 系统触发会话失效处理：若业务侧仍有会话则再尝试一次协调器刷新；最终失败则清理登录态并展示全局过期弹窗

#### Scenario: 请求认证状态判断
- **WHEN** 需要判断某个请求是否已携带有效认证信息
- **THEN** `OAuthAuthenticator.isRequest(_:authenticatedWith:)` 检查请求头的 Authorization 是否匹配当前 Credential

#### Scenario: 业务码宣告登录失效后优先刷新
- **WHEN** 已认证请求 HTTP 2xx 但业务 `code` 为 `A0230`（或等价会话失效 msg）
- **THEN** 系统先调用 `refresh_token` 续期；成功则更新 Credential 且不弹过期窗；失败再走强制重新登录
