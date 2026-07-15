## Why

健康模块「体征监测」10 个指标（血压、血糖、体重、心率、睡眠、心电、鹰瞳眼底、饮食运动、血氧、消化道）已确定全部由 H5 SPA 承载。App 仅保留 Hub / 指标网格入口，点击后打开 `WebViewController`，不再维护原生详情、录入、历史等页面，也不再调用 Angel 体征 API。

## What Changes

- 所有 `/health/metrics/{key}` 及历史子路由统一跳转 H5 hash 页 `#/{key}`
- `/health/metrics/add?key={key}` 同样跳转对应 H5 页
- 扩展 `H5Config`：集中管理指标 key、标题、URL
- **删除** 体征监测相关原生 PL（ViewController / ViewModel / Cell / Component）与 BLL（Service / Models / BluetoothService）
- 从 `AppContainer` 移除 `bloodPressureService`、`bloodSugarService`、`weightService`、`exerciseFoodService`
- **保留** `HealthViewController`（Hub）、`MetricsViewController`（指标网格）、`MetricCardCell` 等入口 UI

## Supersedes

- `weight-h5-migration`（体重 H5 为本次变更子集）
- `implement-blood-pressure` / `implement-blood-sugar` / `implement-weight` / `implement-exercise-food`（原生实现作废）
- `funde-metrics-with-angel-api`（App 侧不再直连 Angel 体征 API）

## Capabilities

### Modified Capabilities

- `health-metrics`: 体征监测入口与路由改为 H5 WebView

## Impact

- `BLL/Health/HealthRoutes.swift`
- `Other/Common/H5Config.swift`
- `DAL/AppContainer.swift`
- 删除 `PL/Health/Metrics/` 下除 `MetricsViewController.swift` 外的原生实现
- 删除 `BLL/Health/*Service.swift`、`*Models.swift`、`BluetoothService.swift`
- `Info.plist` ATS（开发者手动，见 design）

## Reference

- H5 dev base：`http://192.168.15.249:5181`
- Hash 约定：`#/{metric-key}`，如 `#/blood-pressure`、`#/weight`
