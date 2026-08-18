## Why

宿主 H5 已提供用药、营养补剂、血氧页面（hash 分别为 `#/medication`、`#/supplement`、`#/spo2`），但 iOS 尚未注册与文档对齐的原生深链。CMS `FundeH5:` 虽可直开 H5，`FundeApp:` / `Router.push` / IM 等仍无法落到这三条路径。

## What Changes

- `H5Config` 增加用药、营养补剂鉴权 URL（`token` + `platform=ios`）；血氧复用已有体征 H5 路径 `#/spo2`
- 注册原生路由 `/medication`、`/supplement`、`/spo2`，打开对应 `WebViewController`
- `/spo2` 为 `/health/metrics/spo2` 的文档路径别名，不改变既有体征卡跳转
- 更新 `h5-host` 路由表

## Capabilities

### New Capabilities

- `medication-supplement-spo2-h5`：用药 / 营养补剂 / 血氧 H5 宿主接入

### Modified Capabilities

- `h5-host`：路由表补充三条 H5 与 iOS 深链映射

## Impact

- `Other/Common/H5Config.swift`
- `BLL/Health/HealthRoutes.swift`（健康模块）
- `openspec/specs/h5-host/spec.md`
- CMS `FundeApp:/medication` 等可打开；`FundeH5:` 行为不变
