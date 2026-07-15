## 1. Spec

- [x] 1.1 创建 `health-metrics-h5-migration` proposal / design / spec

## 2. H5 配置与路由

- [x] 2.1 扩展 `H5Config`：`metricKeys`、`metricPageURL`、`metricTitle`
- [x] 2.2 `HealthRoutes` 全部体征路由改为 `WebViewController`
- [x] 2.3 `/health/metrics/add?key=*` 改为 H5

## 3. 清理原生代码

- [x] 3.1 删除 BLL 体征 Service / Models / BluetoothService
- [x] 3.2 删除 PL 体征原生页面（保留 `MetricsViewController`）
- [x] 3.3 `AppContainer` 移除体征 Service 注册

## 4. 配置（开发者手动）

- [ ] 4.1 Info.plist 放开 dev IP HTTP
- [ ] 4.2 Xcode 移除已删 `.swift` 文件引用；确认 `H5Config.swift` 在 target 内

## 5. 验证

- [ ] 5.1 Hub / 体征监测页 10 个卡片均可打开对应 H5
- [ ] 5.2 旧深链子路由（如 `/health/metrics/blood-pressure/manual`）仍可打开 H5 首页
