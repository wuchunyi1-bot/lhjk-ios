## Why

服务首页每次 `viewWillAppear` 都全量请求 banners / matrix / categories / packages，切 Tab 反复进入会重复打网、首屏等待明显。消息模块已通过 `IMService` 内存缓存 + 冷启动预拉实现「先进缓存、会话内复用」；服务模块应对齐同一模式，且**不做 TTL**——每次冷启动重新拉取，同一次进程内复用。

## What Changes

- 新增 BLL `ServiceHubCacheService`：内存缓存静态层（banners / matrix / categories）与按类目的 packages；`hasLoadedStatic`、in-flight 去重、`clear()`、`forceReload()`
- 冷启动进入主界面后延迟预拉静态层（L1+L2）；**不**预拉 packages
- `ServiceViewModel` 改为缓存优先：有缓存先上屏，缺什么补什么；不再每次 `viewWillAppear` 全量 `reload()`
- 登出链路调用 `ServiceHubCacheService.clear()`（对齐 `IMService.clear()`）
- **不做 TTL**、不做热启动自动刷新、不做 UI 预挂载

## Capabilities

### New Capabilities

- `service-hub-preload`: 服务首页 Hub 数据预加载与会话内内存缓存（无 TTL）

### Modified Capabilities

- （无）主规格目录尚无独立 `service` 归档；本变更以新 capability 承载需求

## Impact

- BLL：`BLL/Service/ServiceHubCacheService.swift`（新建）
- PL：`ServiceViewModel`、`ServiceViewController`（加载时机）
- 启动：`RootTabBarController` 延迟预拉（覆盖冷启动与登录 `setRoot`）
- 登出：`SettingsViewController` / 注销账号路径调用 `clear()`
- `AppContainer` 注册新服务
- 依赖现有 `ColumnContentService` / `DictionaryService` / `HospitalPackageService` / `ServiceCatalogService` / `VoucherService`
