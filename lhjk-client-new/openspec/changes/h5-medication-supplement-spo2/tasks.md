## 1. Spec 路由表

- [x] 1.1 更新 `openspec/specs/h5-host/spec.md` 路由表：用药 / 营养补剂 / 血氧

## 2. H5Config

- [x] 2.1 增加 `medicationPageURL`（`#/medication`）
- [x] 2.2 增加 `supplementPageURL`（`#/supplement`）
- [x] 2.3 增加 `spo2PageURL`（`#/spo2`，与体征 `authenticatedMetricURL` 等价）

## 3. 路由

- [x] 3.1 `HealthRoutes` 注册 `/medication`、`/supplement`、`/spo2` → WebView
