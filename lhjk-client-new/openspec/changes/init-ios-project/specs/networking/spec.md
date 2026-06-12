## ADDED Requirements

### Requirement: HTTP Client
系统 SHALL 提供统一的 HTTP 客户端（`APIManager`），基于 Alamofire `Session` 封装网络请求的构建、发送和响应处理。

#### Scenario: 发送 GET 请求
- **WHEN** BLL 层需要获取数据
- **THEN** DAL 层的 `APIManager` 构建 GET 请求并发送，返回解析后的响应数据或错误

#### Scenario: 发送 POST 请求
- **WHEN** BLL 层需要提交数据
- **THEN** DAL 层将请求体序列化为 JSON 格式，发送 POST 请求，并返回解析后的响应

#### Scenario: 文件上传
- **WHEN** BLL 层需要上传文件（图片、音频等）
- **THEN** 网络客户端构建 multipart/form-data 请求，支持上传进度回调

#### Scenario: 文件下载
- **WHEN** BLL 层需要下载文件
- **THEN** 网络客户端支持流式下载，提供下载进度回调，支持断点续传

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
│  │  └──────────────────────────────────────┘  │  │
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
- **WHEN** Token 刷新接口也返回错误（如 refreshToken 过期）
- **THEN** `AuthenticationInterceptor` 将该错误向上抛出，BLL 层捕获后通知 PL 层跳转登录页

#### Scenario: 请求认证状态判断
- **WHEN** 需要判断某个请求是否已携带有效认证信息
- **THEN** `OAuthAuthenticator.isRequest(_:authenticatedWith:)` 检查请求头的 Authorization 是否匹配当前 Credential

### Requirement: Request & Response Interceptor
系统 SHALL 支持请求和响应的拦截器链，用于统一添加请求头、日志记录和错误预处理。

#### Scenario: 请求拦截
- **WHEN** 发起网络请求前
- **THEN** Alamofire `RequestInterceptor` 协议的方法依次执行，可添加通用 Header（如 Content-Type）、记录请求日志

#### Scenario: 响应日志
- **WHEN** 收到网络响应后
- **THEN** Alamofire `EventMonitor` 协议的方法记录响应状态码、响应体和错误信息

### Requirement: Error Handling
系统 SHALL 提供统一的错误处理机制，支持网络错误、服务端错误和业务错误的分类处理。

#### Scenario: 网络不可达
- **WHEN** 发起请求时网络不可达
- **THEN** 返回明确的网络错误信息，PL 层展示"网络连接不可用"提示

#### Scenario: 请求超时
- **WHEN** 请求超过设定超时时间（默认 30 秒）
- **THEN** 返回超时错误，BLL 层根据业务决定是否重试

#### Scenario: 服务端错误
- **WHEN** HTTP 状态码为 5xx
- **THEN** 返回服务端错误，附带状态码和响应体中的错误信息

#### Scenario: 业务错误
- **WHEN** HTTP 状态码为 2xx 但响应体中包含业务错误码
- **THEN** 解析业务错误码和错误消息，传递给 BLL 层处理

### Requirement: Network Status Monitoring
系统 SHALL 监控设备的网络连接状态变化。

#### Scenario: 网络状态变化
- **WHEN** 设备的网络连接状态发生变化（Wi-Fi ↔ 蜂窝网络 ↔ 无网络）
- **THEN** 通过 Combine `@Published` 属性告知 BLL 层当前网络状态和连接类型

#### Scenario: 网络恢复
- **WHEN** 网络从不可用恢复到可用状态
- **THEN** 自动重试之前失败的可重试请求（如消息发送）

### Requirement: API Base Configuration
系统 SHALL 支持多环境配置（开发、测试、生产），支持切换 API 的 Base URL。

#### Scenario: 环境切换
- **WHEN** 切换开发/测试/生产环境
- **THEN** 网络客户端使用对应环境的 Base URL 和配置

#### Scenario: 请求路径拼接
- **WHEN** BLL 层传入 API 路径（如 `/user/profile`）
- **THEN** 网络客户端自动拼接完整 URL：`{Base URL}/user/profile`
