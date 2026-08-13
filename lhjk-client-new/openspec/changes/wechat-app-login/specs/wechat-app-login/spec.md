## ADDED Requirements

### Requirement: 微信授权登录走 WE_CHAT_APP_LOGIN

系统 SHALL 使用微信 OpenSDK 取得临时 `code` 后，以表单编码调用 `POST /auth/oauth2/token`，参数包含 `client_id`、`client_secret`、`grant_type=WE_CHAT_APP_LOGIN`、`code`。App MUST NOT 使用 `appSecret` 自行换 openid。成功（业务码 `200`/`0`）后 MUST 持久化 access/refresh token，并进入与短信/密码登录相同的登录成功编排（含默认档案 `archiveComplete` 门禁）。MUST NOT 依赖响应中的 `userInfo`。

#### Scenario: 已绑定用户直接登录

- **WHEN** 用户完成微信授权且服务端返回成功 Token
- **THEN** 系统 MUST 保存凭证并执行登录成功后续流程

#### Scenario: 业务失败

- **WHEN** Token 接口返回非成功且非 `AU0001` 的业务码
- **THEN** 系统 MUST 向用户展示服务端 `msg`（或映射后的 `LoginError`），并允许重试

### Requirement: 未绑定手机号 AU0001

当 Token 接口返回业务码 `AU0001` 时，系统 SHALL 进入手机号绑定流程，并 MUST 保留本次微信 `code`（内存）。绑定阶段 MUST NOT 立即重新拉起微信授权。

#### Scenario: 进入绑定页

- **WHEN** 首次微信登录返回 `AU0001`
- **THEN** 系统 MUST 展示绑定手机号 UI，并保存原微信 `code`

#### Scenario: 绑定并登录

- **WHEN** 用户提交手机号与短信验证码
- **THEN** 系统 MUST 再次请求 `POST /auth/oauth2/token`，参数含同一 `grant_type`、原 `code`、`mobile`、`smsCode`
- **AND** 成功后 MUST 保存 Token 并走登录成功编排

#### Scenario: 绑定发码

- **WHEN** 绑定页请求验证码
- **THEN** 系统 MUST 调用既有发码接口，`type=1`（注册或登录），`clientId` 与登录客户端一致

#### Scenario: 取消绑定

- **WHEN** 用户关闭绑定页
- **THEN** 系统 MUST 清除内存中的微信 `code`

### Requirement: 微信 SDK 回调校验

发起授权时系统 SHALL 生成并保存 `state`；收到 `SendAuthResp` 时 MUST 校验 `state` 一致且 `code` 非空后才交给业务层。用户取消（errCode -2）MUST NOT 当作授权失败强提示（可静默或轻提示）。

#### Scenario: state 不匹配

- **WHEN** 回调 `state` 与发起时不一致或缺少 code
- **THEN** 系统 MUST 视为无效回调，不发起登录请求
