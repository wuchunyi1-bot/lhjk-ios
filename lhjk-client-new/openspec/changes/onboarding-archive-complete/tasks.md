## 1. 模型与门禁

- [x] 1.1 `OArchive` 增加 `archiveComplete`、`sex`、`birthday` 解码
- [x] 1.2 `UserManager.checkNeedOnboarding` 改为只读 `defaultArchive?.archiveComplete != true`（含失败/缓存策略，见 design）
- [x] 1.3 `resolvedUserId` 去掉 `loginUserInfo` 分支，仅 `currentUser.id`

## 2. 登录 / 冷启动编排

- [x] 2.1 `LoginViewModel.handleLoginSuccess`：先 `fetchUserInfo` → `fetchDefaultArchive` → 再门禁导航
- [x] 2.2 `SceneDelegate` 冷启动：去掉「先本地四字段门禁」；拉档后再决定 present `/onboarding`
- [x] 2.3 `LoginService` 去掉 `applyLoginUserInfo(token.userInfo)`

## 3. 清理 token userInfo

- [x] 3.1 删除 `LoginUserInfo`、`OAuthTokenResponse.userInfo` 及相关注释
- [x] 3.2 删除 `UserManager` 的 `loginUserInfo` 持久化 / `apply` / `patch` / UserDefaults key
- [x] 3.3 迁移 `HomeViewModel`、`DailyTasksViewModel`、`HealthPageService`、`ServiceListViewModel` 等对 `loginUserInfo` 的引用
- [x] 3.4 全仓 grep 确认无 `loginUserInfo` / `LoginUserInfo` / `applyLoginUserInfo` / `patchLoginUserInfo`

## 4. Onboarding 页

- [x] 4.1 回填改为 `defaultArchive` → `currentUser`（去掉 loginUserInfo）
- [x] 4.2 提交成功后刷新默认档案，删除 `patchLoginUserInfo`

## 5. 文档核对

- [x] 5.1 联调确认 JSON 字段；若 Apifox 分享站补齐 `archiveComplete`/`sex`/`birthday`，在 `docs/api-inventory` 或本 change 备注「文档已对齐」
- [x] 5.2 本 change 全部 tasks 完成后，再进入代码合入评审（本文件勾选）
