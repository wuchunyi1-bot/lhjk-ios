## 1. BLL 缓存服务

- [x] 1.1 新增 `BLL/Service/ServiceHubCacheService.swift`：静态缓存（banners/matrix/categories）、`hasLoadedStatic`、按类目 packages 字典、`preloadStatic()` / `ensurePackages(category:hospitalId:)` / `forceReload(selectedCategory:hospitalId:)` / `clear()`、in-flight Task 去重
- [x] 1.2 在 `AppContainer` 注册 `serviceHubCacheService`
- [x] 1.3 静态拉取复用 `ColumnContentService` / `DictionaryService`；packages 复用 `HospitalPackageService.fetchPackageItems`

## 2. 冷启动预拉与登出清理

- [x] 2.1 `RootTabBarController` 进主界面后延迟 1～2s 调用 `preloadStatic()`（覆盖冷启动与登录 `setRoot("/")`；未登录不创建 TabBar）
- [x] 2.2 登出路径（`SettingsViewController` 等与 `IMService.clear()` 同处）调用 `ServiceHubCacheService.clear()`

## 3. ViewModel / VC

- [x] 3.1 重构 `ServiceViewModel`：注入 cache；`load()` 缓存优先；`selectCategory` 走 `ensurePackages`；保留激活 Banner 本地态与通知
- [x] 3.2 `ServiceViewController`：`viewWillAppear` 仍调 `load()`（行为变为缓存优先）；`forceReload()` API 已暴露，下拉刷新 UI 可后续接入

## 4. 校验

- [x] 4.1 确认无 TTL 字段；热启动路径无自动重拉
- [x] 4.2 提示开发者将新 Swift 文件加入 Xcode target
