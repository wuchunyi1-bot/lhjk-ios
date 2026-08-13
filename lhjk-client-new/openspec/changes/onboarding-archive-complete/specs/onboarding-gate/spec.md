## ADDED Requirements

### Requirement: Onboarding 门禁仅依据 archiveComplete

系统 SHALL 仅根据 `GET /v1/archive/getOArchiveByUserId` 写入本地的 `defaultArchive.archiveComplete` 决定是否展示 `/onboarding`。MUST NOT 使用登录 token `userInfo`、本地四字段完整性或 `getCurrentUserBaseInfo` 作为门禁条件。

#### Scenario: 档案未完成

- **WHEN** 默认档案拉取成功且 `archiveComplete` 为 `false` 或缺失（非 `true`）
- **THEN** 系统 MUST 展示 `/onboarding`

#### Scenario: 档案已完成

- **WHEN** 默认档案拉取成功且 `archiveComplete == true`
- **THEN** 系统 MUST NOT 展示 `/onboarding`，进入主流程

#### Scenario: 首次注册无正式档案

- **WHEN** 服务端对无正式档案用户仍返回 `data` 且 `archiveComplete == false`
- **THEN** 系统 MUST 展示 `/onboarding`

#### Scenario: 档案拉取失败且无未完成缓存

- **WHEN** `getOArchiveByUserId` 失败，且本地无 `archiveComplete == false` 的缓存档案
- **THEN** 系统 MUST NOT 因门禁阻塞进入主页（可稍后重试拉取）

#### Scenario: 档案拉取失败但缓存未完成

- **WHEN** 拉取失败且本地缓存 `archiveComplete != true`
- **THEN** 系统 MUST 展示 `/onboarding`

### Requirement: 门禁前必须先拉取默认档案

在登录成功导航与冷启动已登录分支中，系统 SHALL 在判定 onboarding 之前完成：解析 `userId`（来自 `currentUser` / `getCurrentUserBaseInfo`）→ 调用 `getOArchiveByUserId` → 再读 `archiveComplete`。MUST NOT 在未尝试拉取档案的情况下仅凭本地登录摘要做门禁。

#### Scenario: 登录成功

- **WHEN** 用户登录成功
- **THEN** 系统 MUST 先 `fetchUserInfo`（或已有有效 `currentUser.id`），再 `fetchDefaultArchive`，再按 `archiveComplete` 决定 `/onboarding` 或主页

#### Scenario: 冷启动已登录

- **WHEN** App 冷启动且本地凭证有效
- **THEN** 系统 MUST 同样在拉档后按 `archiveComplete` 决定是否 present `/onboarding`

### Requirement: OArchive 解码 archiveComplete 与资料字段

`OArchive` SHALL 解码 `archiveComplete`（Bool），以及用于完善页回填的 `sex`、`birthday`（与既有 `chineseName`、`hospitalId` 等一并可用）。字段缺失时 MUST 不导致整包解码失败。

#### Scenario: 含新字段的响应

- **WHEN** 响应 JSON 含 `archiveComplete`、`sex`、`birthday`
- **THEN** `OArchive` MUST 正确映射到对应属性
