## Why

后端已在 `GET /v1/archive/getOArchiveByUserId` 增加 `archiveComplete`，并在档案接口返回姓名、出生日期等资料字段；首次注册无正式档案时也会返回 `archiveComplete=false`。现行 `/onboarding` 门禁依赖登录 token 的 `userInfo` 四字段本地判断，与后端权威状态不一致，且与档案接口重复。

## What Changes

- **BREAKING（门禁）**：`/onboarding` 是否展示 **只** 依据 `getOArchiveByUserId` 返回的 `archiveComplete`；不再用 `loginUserInfo` 的 `chineseName` / `sex` / `birthday` / `hospitalId`。
- `OArchive` 解码补充 `archiveComplete`，以及资料回填所需的 `sex` / `birthday`（与已有 `chineseName`、`hospitalId` 等一并使用）。
- 登录成功与冷启动：先拿到 `userId` → 拉取默认档案 → 再按 `archiveComplete` 决定是否进 `/onboarding`（门禁变为依赖网络，不再纯本地）。
- **移除** `/auth/oauth2/token` 响应中的 `userInfo` 解码与 `LoginUserInfo` / `applyLoginUserInfo` / `patchLoginUserInfo` / `loginUserInfo` 持久化；原依赖 `loginUserInfo.id` / `hospitalId` 的调用点改走 `currentUser` / `defaultArchive` / 机构选择 store。
- 完善资料提交成功后：刷新默认档案，以服务端 `archiveComplete` 作为后续门禁依据（不再本地 patch 四字段）。

## Capabilities

### New Capabilities

- `onboarding-gate`：Onboarding 门禁以档案 `archiveComplete` 为唯一判定。

### Modified Capabilities

- `register-login`：登录/冷启动流程与 token 模型（去掉 `userInfo`）；完善页回填与提交后刷新档案。

## Impact

- `DAL/Networking/OAuthCredential.swift`：删除 `LoginUserInfo`、`OAuthTokenResponse.userInfo`
- `BLL/User/UserManager.swift`、`UserModels.swift`（`OArchive`）
- `BLL/RegisterLogin/LoginService.swift`
- `PL/RegisterLogin/ViewModels/LoginViewModel.swift`、`Onboarding/OnboardingViewController.swift`
- `Other/SceneDelegate.swift`
- 仍读 `loginUserInfo` 的业务：`HomeViewModel`、`DailyTasksViewModel`、`HealthPageService`、`ServiceListViewModel` 等
- Apifox 分享站当前 `OArchiveVO` **尚未**列出 `archiveComplete` / `sex` / `birthday`（文档滞后）；实现以本变更 + 联调为准，文档补齐后核对清单
- 相关旧提案将被本变更覆盖：`onboarding-login-userinfo` 的门禁约定
