# Register / Login — Onboarding Gate Delta

## MODIFIED Requirements

### Requirement: Dual User Info Sources

系统 SHALL 同时维护两套用户数据，职责严格分离。

| 来源 | 存储 | 用途 |
|------|------|------|
| 登录 token `userInfo` | `UserManager.loginUserInfo` | **仅** `checkNeedOnboarding()` |
| `GET /v1/users/getCurrentUserBaseInfo` | `UserManager.currentUser` | App 内首页/我的/档案等业务展示与逻辑 |

#### Scenario: 禁止混用
- **WHEN** 业务页需要展示姓名、头像等
- **THEN** MUST 使用 `currentUser`（详情接口），MUST NOT 使用 `loginUserInfo`
- **WHEN** 判断是否进入 Onboarding
- **THEN** MUST 使用 `loginUserInfo`，MUST NOT 调用 `getCurrentUserBaseInfo`

---

### Requirement: Onboarding Gate Decision

#### Scenario: 门禁纯本地
- **WHEN** 调用 `checkNeedOnboarding()`
- **THEN** 只读持久化的 `loginUserInfo`
- **AND** 检查 `chineseName`、`sex`、`birthday`、`hospitalId` 任一为空则返回 `true`
- **AND** MUST NOT 发起网络请求

#### Scenario: 登录写入门禁数据
- **WHEN** `POST /auth/oauth2/token` 成功且含 `userInfo`
- **THEN** `applyLoginUserInfo` 持久化，供后续冷启动门禁使用

#### Scenario: 无 loginUserInfo
- **WHEN** 本地无 `loginUserInfo`
- **THEN** 门禁返回 `false`（不阻塞）

---

### Requirement: Profile Fetch Independent Of Gate

冷启动与登录成功后 SHALL **并行**拉取用户详情，与门禁互不依赖。

#### Scenario: 冷启动
- **WHEN** 已登录用户打开 App
- **THEN** 本地执行 `checkNeedOnboarding()`（loginUserInfo）
- **AND** 同时 `fetchUserInfo()` → `getCurrentUserBaseInfo` 写入 `currentUser`
- **AND** 门禁结果不依赖详情接口成功与否

#### Scenario: 登录成功
- **WHEN** 登录流程完成
- **THEN** 同样并行：门禁（loginUserInfo）+ `fetchUserInfo()`（详情）
