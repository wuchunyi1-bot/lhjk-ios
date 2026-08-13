## ADDED Requirements

### Requirement: Token 响应不再使用 userInfo

`POST /auth/oauth2/token` 的客户端解码 SHALL 只取凭证字段（`accessToken`、`refreshToken`、`expiresIn` 等）。MUST NOT 定义或持久化 `userInfo` / `LoginUserInfo`。登录成功后 MUST NOT 调用 `applyLoginUserInfo`。

#### Scenario: 登录成功应用凭证

- **WHEN** token 接口返回成功
- **THEN** 系统 MUST 仅将 access/refresh/过期时间写入 `OAuthCredential` / Token 存储
- **AND** MUST NOT 将响应中的 `userInfo`（若后端仍下发）写入任何本地用户摘要

#### Scenario: 业务取 userId / hospitalId

- **WHEN** 首页任务、健康 CMS、服务列表等需要 `userId` 或 `hospitalId`
- **THEN** `userId` MUST 来自 `currentUser.id`（或等价 resolved 路径，且不得再读登录摘要）
- **AND** `hospitalId` MUST 优先来自 `defaultArchive.hospitalId`，再降级机构选择 / 服务模块已选机构逻辑

### Requirement: 完善资料成功后刷新档案

Onboarding 提交成功后，系统 SHALL 刷新 `getOArchiveByUserId` 结果；MUST NOT 再通过 `patchLoginUserInfo` 写本地四字段以满足门禁。完善页表单回填 SHALL 优先使用 `defaultArchive`（姓名 / 性别 / 生日 / 机构），其次 `currentUser`。

#### Scenario: 提交成功

- **WHEN** `saveArchiveHospital`（及既有资料更新）成功
- **THEN** 系统 MUST 重新拉取默认档案
- **AND** 在随后门禁中以新的 `archiveComplete` 为准

#### Scenario: 打开完善页回填

- **WHEN** 用户进入 `/onboarding` 且本地已有默认档案或部分资料
- **THEN** 表单 MUST 优先用档案字段回填，MUST NOT 依赖已删除的 `loginUserInfo`

## REMOVED Requirements

### Requirement: Onboarding 门禁以登录 userInfo 四字段为准

**Reason:** 后端以档案接口 `archiveComplete` 为权威；token `userInfo` 对客户端不再需要。

**Migration:** 见 capability `onboarding-gate`；删除 `LoginUserInfo`、`checkNeedOnboarding` 对四字段的本地判断，以及 `onboarding-login-userinfo` 变更中的对应约定。
