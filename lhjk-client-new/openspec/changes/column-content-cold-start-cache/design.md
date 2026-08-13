## Context

- `ColumnContentService`：纯网络 `GET /v1/columnContent/getByCode`
- 首页：`HomeViewModel.loadBanners` 直连网络
- 服务：`ServiceHubCacheService` 静态层内拉 `mall_advertisement`，与首页未共享

## Goals / Non-Goals

**Goals:**

- 每次**进程冷启动进主界面**后，对已知 code 从服务端拉取并写入内存缓存
- 界面：`code` 已缓存 → 直接用；未缓存 → 拉取并写入后再返回
- in-flight 按 code 去重；登出清空
- 已知预拉 code：`home_banner_code`、`mall_advertisement`

**Non-Goals:**

- 不做磁盘持久化 / TTL
- 不改 `getByCode` 请求参数与 DTO 映射
- 不把 matrix/categories 并入本缓存

## Decisions

### 1. 独立 `ColumnContentCacheService`（actor）

与 `ServiceHubCacheService` 解耦：按 **code** 索引缓存，供 Home / Service 共用。  
**必须用 `actor`（或等价串行队列）隔离可变状态**：`preloadColdStart` 的 `TaskGroup` 会并行进入 `fetchAndStore`；若用普通 `class` 并发读写 `Dictionary`/`Set`，会数据竞争并表现为 `EXC_BAD_ACCESS`（常见 address 如 `0x10`）。

### 2. 加载标记

对每个 code：

| 状态 | 行为 |
|------|------|
| 已成功写入（含空数组） | `banners(for:)` 直接返回，不再请求 |
| 未写入 / 仅失败 | `banners(for:)` 发网；成功则写入 |
| 冷启动 `preloadColdStart` | **强制**对已知 code 发网并覆盖缓存（进程内首次预拉） |

失败不写入「已加载」，以便界面稍后重试。

### 3. 冷启动时机

`RootTabBarController.scheduleHubPreloadIfNeeded` 中，在现有 delay 后：

1. `columnContentCache.preloadColdStart()`
2. 再 `serviceHubCache.preloadStatic()`（banners 从 column cache 取）
3. health hub 预拉不变

### 4. 调用方

- Home：`columnContentCache.banners(for: homeBannerCode)`
- ServiceHub：`fetchBanners` → `columnContentCache.banners(for: hospitalBannerCode)`

### 5. clear

与 Hub 缓存一并在 logout / `SessionExpiryCoordinator` / 我的退出中 `clear()`。

## Risks

- [预拉未完成用户已进首页] → `banners(for:)` 与预拉共用 in-flight Task，不会双发
- [某 code 预拉失败] → 该 code 未标记加载；进页再拉
