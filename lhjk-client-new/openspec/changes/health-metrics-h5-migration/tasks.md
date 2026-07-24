## 1. Spec

- [x] 1.1 创建 `health-metrics-h5-migration` proposal / design / spec
- [x] 1.2 补充 H5 鉴权、路径映射、子路由 query 规格

## 2. H5 配置与路由

- [x] 2.1 扩展 `H5Config`：`metricKeys`、`metricPageURL`、`metricTitle`
- [x] 2.2 `HealthRoutes` 全部体征路由改为 `WebViewController`
- [x] 2.3 `/health/metrics/add?key=*` 改为 H5
- [x] 2.4 `H5Config.authenticatedMetricURL`：`token` + `platform=ios`
- [x] 2.5 `exercise` → `exercise-food`；子路由 suffix 映射与业务 query
- [x] 2.6 development base URL → `h5-dev.lianhaojiankang.com`
- [x] 2.7 `HealthRoutes` 向 URL 构建传递 `routeParams`
- [x] 2.8 `WebViewController` H5 内返回优先（`canGoBack` → `goBack`，否则 pop/dismiss）

## 3. 清理原生代码

- [x] 3.1 删除 BLL 体征 Service / Models / BluetoothService
- [x] 3.2 删除 PL 体征原生页面（保留 `MetricsViewController`）
- [x] 3.3 `AppContainer` 移除体征 Service 注册

## 4. 配置（开发者手动）

- [ ] 4.1 Info.plist 放开 dev H5 HTTP（`h5-dev.lianhaojiankang.com` 或 IP）
- [ ] 4.2 Xcode 确认 `H5Config.swift` 在 target 内

## 5. 验证

- [ ] 5.1 Hub / 体征监测页卡片打开 H5，URL 含 `platform=ios` 与 `token`（已登录）
- [ ] 5.2 体重/血压/血糖 `detail` 深链携带 `monitorId`
- [ ] 5.3 饮食运动打开 `#/exercise-food`
- [ ] 5.4 H5 子页返回走 WebView 历史，无历史时回到原生 Hub
