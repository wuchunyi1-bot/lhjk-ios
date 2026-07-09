## Context

服务首页 `ServiceViewModel.load()` 在每次 `viewWillAppear` 并行请求 banners、matrix、categories，再串行拉当前类目 packages。消息模块则在 `IMService` 内缓存会话列表，连接成功后预拉，VC 优先读缓存。

约束（产品确认）：
- **不做 TTL**，不按时间过期
- **每次冷启动**重新拉取静态层
- 同一次 App 生命周期内复用内存缓存
- 热启动（回前台）不自动重拉

## Goals / Non-Goals

**Goals:**

- BLL 单例缓存静态层 + 按类目 packages，对标 `IMService.hasLoadedConversations`
- 冷启动进主界面后延迟预拉 L1+L2（banners / matrix / categories）
- 进服务 Tab：有缓存立刻渲染；packages 按需拉并缓存
- 下拉刷新 / `forceReload` 绕过缓存全量重拉
- 登出 `clear()`

**Non-Goals:**

- TTL、定时刷新、回前台自动刷新
- 冷启动预拉 packages
- UI 预挂载 / 预创建 Service VC
- 搜索页、商城列表、订单角标预加载（本变更不覆盖）

## Decisions

### 1. 新建 `ServiceHubCacheService`，不塞进 `ServiceCatalogService`

- **Why**: Catalog 负责快照组装；缓存生命周期（预拉 / clear / in-flight）与消息 `IMService` 同级，独立更清晰。
- **Alternative**: 扩展 Catalog — 职责混杂，否决。

### 2. 无 TTL，仅 `hasLoadedStatic` + packages 字典

- **Why**: 产品明确不要时间过期；冷启动进程内存清空或显式 `clear` 后再预拉即可。
- **Alternative**: TTL — 否决。

### 3. 冷启动 / 登录后延迟 1~2s 预拉静态层

- **Why**: 避免与 Home 首屏抢带宽；对齐「连接成功后再拉会话」的错峰思路。
- **Where**: `RootTabBarController.viewDidLoad` 首次调度（覆盖冷启动进主界面与登录后 `setRoot("/")`）。

### 4. Packages 不预拉，按类目缓存

- **Why**: 依赖选中类目与 `hospitalId`；启动预拉浪费且易错。
- 切回已缓存类目不重复请求；换机构（未来）应 `invalidatePackages()`。

### 5. `ServiceViewModel` 缓存优先

```
load():
  若有静态缓存 → applyPartial
  若 !hasLoadedStatic → await preloadStatic
  await ensurePackages(currentCategory)
  applyFull snapshot
```

`viewWillAppear` 仍调 `load()`，但会话内多为读缓存，无网络。

### 6. In-flight 去重

`preloadStatic` / `ensurePackages(categoryId)` 各持有可选 `Task`，并发调用共享同一 Task。

### 7. 登出清理

在现有 `IMService.shared.clear()` 旁调用 `ServiceHubCacheService.shared.clear()`（Settings 登出路径）。

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| 冷启动预拉失败，进 Tab 仍空白 | Tab 侧 `load()` 在 `!hasLoadedStatic` 时现场重试 |
| 运营改 banner 同会话不更新 | 下拉刷新 `forceReload`；冷启动必拉 |
| 预拉与 Tab 同时触发双请求 | in-flight 去重 |
| 延迟预拉用户极快点服务 Tab | Tab `load()` 与预拉共享 Task，不重复 |

## Migration Plan

1. 加 CacheService + AppContainer
2. SceneDelegate 预拉 + 登出 clear
3. 改 ViewModel / VC
4. 无数据迁移；回滚即删预拉与缓存层，恢复每次 reload

## Open Questions

- 无。下拉刷新 UI 若尚未接入，先暴露 `forceReload()` API，VC 可后续接 UIRefreshControl。
