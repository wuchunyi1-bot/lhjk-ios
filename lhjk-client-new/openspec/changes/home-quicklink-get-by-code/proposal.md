## Why

首页金刚区（快捷入口）仍使用 `HomeViewModel.defaultQuickActions` 本地写死的 SF Symbol + 路由。运营需与 Banner 一样通过栏位内容接口配置；约定 code 为 `home_quickLink_code`，需对齐 `home_banner_code` 的拉取、缓存与空态策略。

## What Changes

- `ColumnContentService` 增加常量 `homeQuickLinkCode = "home_quickLink_code"`（复用同一 `GET /v1/columnContent/getByCode`）。
- `ColumnContentCacheService.knownPreloadCodes` 纳入该 code；冷启动与 Banner 一并预拉。
- `HomeViewModel` 经缓存 `banners(for: home_quickLink_code)`（或等价封装）加载金刚区；**删除** `defaultQuickActions` mock；空/失败隐藏金刚区 section。
- `HomeQuickActionsCell` 支持远程 `imageUrl`（Kingfisher），不再依赖本地 SF Symbol 作为已接 API 后的主数据源。
- `docs/api-inventory.md` 注明 getByCode 的 `home_quickLink_code`。

## Capabilities

### New Capabilities

- `home-quicklink`：首页金刚区通过 `getByCode` + `home_quickLink_code` 加载。

### Modified Capabilities

- （无归档主 spec；缓存行为对齐既有 `column-content-cold-start-cache` / `home-banner` change。）

## Impact

- `BLL/Service/ColumnContentService.swift`
- `BLL/Service/ColumnContentCacheService.swift`
- `PL/Home/ViewModels/HomeViewModel.swift`
- `PL/Home/Cells/HomeQuickActionsCell.swift`
- `docs/api-inventory.md`
