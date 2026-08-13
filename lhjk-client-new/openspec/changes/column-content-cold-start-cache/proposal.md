## Why

`getByCode` 已用于服务 Hub（`mall_advertisement`）与首页（`home_banner_code`），但首页每次出现直接打网，服务侧则嵌在 Hub 静态缓存中，两套路径不一致。需要统一：**冷启动从服务端拉取并写入内存缓存**；界面优先读缓存，未命中再拉。

## What Changes

- 新增 BLL `ColumnContentCacheService`：按 `code` 内存缓存 Banner 列表；无 TTL；冷启动预拉已知 code；`banners(for:)` 命中复用 / 未命中请求。
- 冷启动（`RootTabBarController`）预拉 `home_banner_code` 与 `mall_advertisement`。
- `HomeViewModel`、`ServiceHubCacheService` 改为走缓存，不再各自裸调网络（服务 Hub 其它静态层不变）。
- 登出 / 会话失效时 `clear()`。

## Capabilities

### New Capabilities

- `column-content-cache`：栏位 `getByCode` 冷启动缓存与按 code 读取。

### Modified Capabilities

- （首页 / 服务 Hub 读缓存行为见本 change specs。）

## Impact

- 新增 `BLL/Service/ColumnContentCacheService.swift`（需手动加入 Xcode）
- `RootTabBarController`、`AppContainer`、`HomeViewModel`、`ServiceHubCacheService`、登出清理路径
- `docs/api-inventory.md` 备注缓存策略
