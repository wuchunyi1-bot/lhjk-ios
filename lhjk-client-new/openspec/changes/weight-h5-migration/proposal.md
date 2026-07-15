## Why

体重模块已整体迁移至 H5（`http://192.168.15.249:5181/#/weight`）。App 不再承载体重的录入、展示、详情等原生页面，也不再调用 `WeightService` 相关接口。原生代码暂保留以便回退，仅路由切换至 WebView。

## What Changes

- `/health/metrics/weight` 及其子路由（`/manual` `/history` `/service` `/detail`）统一指向 H5 `#/weight`
- `/health/metrics/add?key=weight` 同样跳转 H5
- 新增 `H5Config` / `H5Environment`，按环境管理 H5 base URL
- `WeightService`、`WeightViewController` 等原生代码**保留不删**，仅不再被路由引用

## Capabilities

### Modified Capabilities

- `weight`: 入口由原生改为 H5 WebView

## Impact

- `BLL/Health/HealthRoutes.swift`
- `Other/Common/H5Config.swift`（新增）
- `Other/Resources/Info.plist`（需开发者手动放开 dev IP 的 HTTP 访问，见 design）

## Reference

- H5 地址：`http://192.168.15.249:5181/#/weight`（development）
