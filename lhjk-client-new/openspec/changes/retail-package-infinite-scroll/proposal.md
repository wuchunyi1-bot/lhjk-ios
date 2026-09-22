## Why

服务模块首页「富德优选」需对接零售套包分页接口，并支持上拉无限加载，直至无更多数据，对齐 funde-client 完整商品浏览体验。

**接口文档**：https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/487882770e0

## What Changes

- 对接 `GET /v1/hospitalPackage/getEnabledRetailHospitalPackagePage`
- Hub 富德优选：最多 6 条（`pageSize = 6`），不上拉加载
- 空态 Section 隐藏
- Tab 切回复用会话缓存

## Capabilities

### New Capabilities

- `service`：富德优选分页与无限加载（delta spec）

### Modified Capabilities

- 无（Hub 布局仍遵循 `sync-funde-service-module`，本变更仅扩展富德优选数据与交互）

## Impact

| 层 | 文件 |
|----|------|
| BLL Models | `ServiceRecommendModels.swift` — `PaginatedRetailHospitalPackageData` |
| BLL Service | `HospitalPackageService.swift` — `fetchRetailPackages` |
| BLL Cache | `ServiceHubCacheService.swift` — 首屏预览 `pageSize = 6` |
| PL VM | `ServiceViewModel.swift` — 预览最多 6 条 |
| PL VC | `ServiceViewController.swift` — 网格展示，无分页 Footer |
