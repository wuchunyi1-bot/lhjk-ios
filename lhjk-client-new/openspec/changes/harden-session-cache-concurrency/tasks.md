## 1. Hub / 健康 / 零售缓存 actor 化

- [x] 1.1 将 `ServiceHubCacheService` 改为 `actor`；网络 Task 不弱引用写回；`clear` / `invalidatePackages` 内 `await RetailCategoryService.invalidate`
- [x] 1.2 将 `HealthPageCacheService` 改为 `actor`（同文件或保持位置）
- [x] 1.3 将 `RetailCategoryService` 改为 `actor`
- [x] 1.4 更新调用方：`RootTabBarController`、`ServiceViewModel`、`HealthViewModel`、`MetricCardEditViewModel`、登出 / 会话失效 / 注销、`ServiceCatalogService.packageDetail` → async 及详情 VM

## 2. IM 集合隔离

- [x] 2.1 `IMService` 为 `messagesStore` / `conversations` / `notifications` / `hasLoadedConversations` 加 `NSLock`（锁内不做网络 await）
- [x] 2.2 确认实时消息、load/send、`clear` 均走加锁路径

## 3. 清理

- [x] 3.1 删除未入工程的根目录 `ServiceHubCacheService.swift`
- [x] 3.2 编译相关文件确认无同步调用 actor 遗漏
