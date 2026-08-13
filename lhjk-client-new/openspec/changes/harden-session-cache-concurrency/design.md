## Context

`ColumnContentCacheService` 已改为 `actor`，因并行 `TaskGroup` 踩坏 `Dictionary` 导致 `EXC_BAD_ACCESS`。同进程内仍有：

| 服务 | 形态 | 风险点 |
|------|------|--------|
| `ServiceHubCacheService` | `final class` | `packageTasks` / `packagesByCategoryId` 多 key 并行写 |
| `HealthPageCacheService` | `final class` | preload / refresh 双 Task 写 `cached` |
| `RetailCategoryService` | `final class` | 单字段，随 Hub 并发解析 |
| `IMService` | `final class` | `messagesStore` 等在融云 SDK 回调线程与 async Task 间交叉写 |

业务语义（无 TTL、冷启动预拉、in-flight 去重、登出 clear）保持不变；本变更只加并发隔离。

## Goals / Non-Goals

**Goals:**

- Hub / 健康 / 零售类目缓存与 ColumnContent 一致：状态变更串行化（优先 `actor`）
- IM 消息 / 会话可变集合跨线程安全
- 调用方补齐 `await`；登出 / 会话失效清空语义不变
- 删除未编入工程的根目录旧 `ServiceHubCacheService.swift`

**Non-Goals:**

- 不引入 TTL、磁盘缓存、新接口
- 不改 `UserManager` / 券计数 / UserDefaults Store（风险低，本轮不做）
- 不把 `IMService` 整体改成 `actor`（Combine Publisher 与大量同步读 API）；消息集合用锁或等价串行即可
- 不修改 `.xcodeproj` / Podfile

## Decisions

### 1. Hub 系缓存统一 `actor`

`ServiceHubCacheService`、`HealthPageCacheService`、`RetailCategoryService` → `actor`，对齐 `ColumnContentCacheService`。

- **Why**: 与已验证修复同构；`await` 时自动让出 actor，网络可并行、状态写串行。
- **Alternative**: 专用 `DispatchQueue` — 可同步读，但与现有 async 风格不一致，且易漏包。

### 2. Actor 内网络 Task 不捕获 `[weak self]` 写状态

网络 `Task` 只捕获依赖 Service；写回在 `await task.value` 之后的 actor 方法内完成（同 ColumnContent）。

### 3. `ServiceCatalogService.packageDetail` 改为 `async`

Hub 缓存读变为 `await` 后，详情本地回落须异步；`ServicePackageDetailViewModel` 调用处 `await`。

### 4. `IMService` 用 `NSLock`（或等价串行队列）保护集合

对 `messagesStore`、`conversations`、`notifications` 及 `hasLoadedConversations` 的读写在同一把锁内完成；`onMessageReceived` / `clear` / load / send 写路径均加锁。

- **Why**: 保留同步 `getConversations` / `getMessages` / Publisher，改动面小。
- **Alternative**: 内部 `actor` + 全面 async API — 更干净但 Chat/会话 VM 改动大，可后续再做。

### 5. 孤儿文件

删除 `lhjk-client-new/ServiceHubCacheService.swift`（未在 pbxproj）；权威实现仅 `BLL/Service/ServiceHubCacheService.swift`。

## Risks / Trade-offs

- [Risk] actor 化后漏改同步调用 → 编译失败 → Mitigation：全仓搜 `hasLoadedStatic` / `getCached` / `clear()` / `invalidate` 并补 `await`
- [Risk] `NSLock` 内做网络 await 会死锁 → Mitigation：锁只包内存读写，网络在锁外
- [Risk] IM 锁粒度过大影响吞吐 → Mitigation：当前消息量级可接受；热点再拆分
- [Trade-off] IM 未全 actor，风格与 Hub 不完全一致 → 以安全与改动面优先

## Migration Plan

1. 落地 OpenSpec change 产物
2. 改 BLL actor / 锁 → 改 PL/BLL 调用方 → 删孤儿文件
3. 编译验证；登出 / 冷启动预拉 / 进服务与健康 Tab / 收消息冒烟

## Open Questions

无（按上表优先级实现即可）。
