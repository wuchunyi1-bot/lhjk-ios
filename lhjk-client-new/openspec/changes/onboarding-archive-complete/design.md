## Context

现行 Onboarding 门禁（`onboarding-login-userinfo`）以 token `userInfo` → `loginUserInfo` 四字段本地判断。后端改为在 `GET /v1/archive/getOArchiveByUserId` 返回 `archiveComplete`，并在同一接口带回姓名、出生日期等；无档案的新用户也会得到 `archiveComplete=false`。

Apifox 分享站（486441727e0）当前 `OArchiveVO` **尚未**同步 `archiveComplete` / `sex` / `birthday`（仍止于既有档案字段）；实现以产品说明与联调为准，文档更新后核对。

`loginUserInfo` 除门禁外仍被 `id` / `hospitalId` 多处业务读取，清理 token `userInfo` 时必须一并迁移这些读取点。

## Goals / Non-Goals

**Goals:**

- `/onboarding` 唯一条件：`archiveComplete != true`（在成功拿到档案响应后判定）。
- 登录 / 冷启动：先有 `userId`，再拉默认档案，再门禁。
- 彻底停止解码与持久化 token `userInfo`。
- 完善页回填优先用档案（及 `currentUser`）；提交成功后刷新档案。

**Non-Goals:**

- 不改完善页 UI / Figma 布局。
- 不改 `saveArchiveHospital` 请求体约定（仍按现有 DTO）。
- 不在本变更改写 Apifox 文档。
- 不把 `archiveComplete` 再镜像写回 UserDefaults 作为第二套门禁源（以内存 `defaultArchive` + 每次登录/冷启动拉取为准）。

## Decisions

### 1. 门禁唯一字段

`needsOnboarding = (defaultArchive?.archiveComplete != true)`，在 **本次** `getOArchiveByUserId` 成功并写入 `defaultArchive` 之后计算。

| `archiveComplete` | 行为 |
|-------------------|------|
| `true` | 不进 `/onboarding` |
| `false` / 缺省 / `nil` data 被服务端约定为未完成 | 进 `/onboarding` |

首次无档案：服务端仍返回带 `archiveComplete=false` 的 data（产品约定）；客户端按 `false` 拦截。

**备选（否决）**：继续本地四字段 — 与后端权威状态脱节。  
**备选（否决）**：`data == null` 才拦截 — 与「无档案也返回 archiveComplete=false」不符。

### 2. 编排顺序（串行关键路径）

```
登录成功 / 冷启动已登录
  → fetchUserInfo()                    // getCurrentUserBaseInfo → currentUser.id
  → fetchDefaultArchive(userId)        // getOArchiveByUserId → defaultArchive
  → if archiveComplete != true → /onboarding
  → else → 主页
```

`userId` **不再**来自 token `userInfo`；必须先有 `currentUser.id`（或既有缓存的 `currentUser`）再请求档案。冷启动若已有 `currentUser` 缓存可直接拉档案，但仍应刷新用户与档案。

### 3. 彻底移除 token `userInfo`

结论：**对客户端已无必要保留**。

| 原用途 | 迁移 |
|--------|------|
| Onboarding 门禁 | `defaultArchive.archiveComplete` |
| `loginUserInfo.id` | `currentUser.id`（`UserManager.resolvedUserId` 只保留此路径） |
| `loginUserInfo.hospitalId` | `defaultArchive.hospitalId` → 再降级 `InstitutionSelectionStore` / 服务模块已选机构 |
| 完善页回填 / `patchLoginUserInfo` | 回填：`defaultArchive` → `currentUser`；成功后 `refreshDefaultArchive`，删除 patch |

删除：`LoginUserInfo`、`OAuthTokenResponse.userInfo`、`applyLoginUserInfo`、`patchLoginUserInfo`、`loginUserInfo` 及 UserDefaults key。  
登录成功路径：只应用 token 凭证，**不读** `userInfo`。

### 4. `OArchive` 模型增量

新增（Optional，兼容文档滞后）：

- `archiveComplete: Bool?`
- `sex: String?`
- `birthday: String?`（已有 `chineseName` / `hospitalId`）

解码策略与现有雪花 ID / 灵活数值一致。

### 5. 拉取失败时的门禁

- 档案接口失败：不强制弹出 onboarding（避免网络抖动锁死）；可 Toast / 静默，保留上次 `defaultArchive` 若有；若缓存 `archiveComplete == true` 则进主页，若无缓存或缓存未完成则 **仍进入 onboarding** 或进主页？  
  **选定**：失败且无可用缓存 → **不**挡主页（与旧「无 loginUserInfo 则 skip gate」类似），避免无法使用 App；下次成功拉取再门禁。  
  失败但缓存 `archiveComplete == false` → 仍进 onboarding。  
  失败但缓存 `archiveComplete == true` → 主页。

### 6. 完善提交后

`saveArchiveHospital`（及现有资料更新）成功 → `fetchDefaultArchive` → 期望 `archiveComplete == true` → dismiss；不再写 `loginUserInfo`。

## Risks / Trade-offs

- [Apifox 文档未列新字段] → 联调确认 JSON key（`archiveComplete` / `archive_complete`）；Decoder 用 convertFromSnakeCase。
- [门禁需网络] → 首登/冷启动多一次串行等待；可接受。
- [userId 依赖详情接口] → 详情失败则无法拉档案；按 Decision 5 降级。
- [hospitalId 迁移遗漏] → 实现前 grep `loginUserInfo` 清零。

## Migration Plan

1. 合入模型 + 门禁 + 编排。
2. 迁移所有 `loginUserInfo` 引用后删除类型与持久化。
3. 安装后旧 `cached_login_user_info` 可忽略并在登出/启动时 remove。
4. 回滚：恢复四字段门禁需同时恢复 token `userInfo`（不推荐）。

## Open Questions

- Apifox 补齐后核对：`sex` / `birthday` 类型与示例是否与完善页一致（`"1"`/`"2"`、日期格式）。
- `data == null` 是否仍可能出现；若出现，按「未完成」还是「失败」处理 — 当前按产品「总会带 archiveComplete=false」实现；若联调见 null，按 Decision 5「无缓存」处理并记入 spec 修正。
