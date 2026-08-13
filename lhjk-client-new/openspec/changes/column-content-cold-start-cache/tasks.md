## 1. Cache BLL

- [x] 1.1 新增 `ColumnContentCacheService`：按 code 缓存、`preloadColdStart`、`banners(for:)`、in-flight 去重、`clear()`
- [x] 1.2 `AppContainer` 注册；登出 / SessionExpiry / 我的退出调用 `clear()`

## 2. 接入

- [x] 2.1 `RootTabBarController` 冷启动先 `preloadColdStart` 再 Hub 静态预拉
- [x] 2.2 `HomeViewModel` 改走缓存
- [x] 2.3 `ServiceHubCacheService.fetchBanners` 改走缓存

## 3. 文档

- [x] 3.1 `docs/api-inventory` 注明 getByCode 冷启动缓存策略
- [x] 3.2 勾选 tasks；提示 Xcode 加入新文件
