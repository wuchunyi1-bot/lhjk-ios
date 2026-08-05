## 1. 路由与 H5 映射

- [x] 1.1 `H5Config`：指标 `add` suffix → H5 `add`（与 manual 并列）
- [x] 1.2 `HealthRoutes`：注册 `/health/metrics/{key}/add`

## 2. 任务 actionRoute

- [x] 2.1 `UserTodayMonitorTask` type 默认路由改为 `…/add`
- [x] 2.2 `skipUrl` 为指标首页时改写为 `…/add`
