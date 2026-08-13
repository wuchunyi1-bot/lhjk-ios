## Why

`ColumnContentCacheService` 已因并行 Task 踩坏 `Dictionary`/`Set` 出现 `EXC_BAD_ACCESS`，并改为 `actor`。同构的会话内存缓存（`ServiceHubCacheService`、`HealthPageCacheService`、`RetailCategoryService`）以及融云回调线程写入的 `IMService.messagesStore` 仍是普通 `class`，存在同类数据竞争。需在崩溃复现前统一隔离。

## What Changes

- 将 `ServiceHubCacheService`、`HealthPageCacheService`、`RetailCategoryService` 改为 **`actor`**（或等价串行隔离），保证缓存字典 / Task 句柄的读写串行。
- 将 `IMService` 对 `messagesStore` / `conversations` 等可变集合的访问隔离到 **`actor` 或专用串行队列**，融云 `messageReceivedPublisher` 回调不得直接跨线程写 Dictionary。
- 同步更新所有 call site：`await` 读缓存 / `clear`；登出与会话失效路径保持清空语义不变。
- 删除仓库根目录未编入工程的旧副本 `ServiceHubCacheService.swift`，避免与 `BLL/Service/` 混淆。
- **不改变**缓存业务语义：无 TTL、冷启动预拉、in-flight 去重、`generation` 丢弃迟到结果、登出清空。

## Capabilities

### New Capabilities

- `session-cache-concurrency`：会话级内存缓存与 IM 消息字典的并发隔离约定（actor / 串行访问、禁止跨线程写集合）

### Modified Capabilities

- `im`：明确 `messagesStore` / 会话列表的线程安全要求（delta）

## Impact

- BLL：`ServiceHubCacheService`、`HealthPageCacheService`、`RetailCategoryService`、`IMService`
- 调用方：`RootTabBarController`、`ServiceViewModel` / `ServiceListViewModel`、`HealthViewModel`、`MetricCardEditViewModel`、`ServiceCatalogService`、`SessionExpiryCoordinator`、`MyViewController`、注销账号、Chat / Conversation ViewModel 等
- `AppContainer` 注入类型仍为 shared 单例；对外 API 多为 `async`
- 不改 Apifox、不改 pbxproj / Podfile
