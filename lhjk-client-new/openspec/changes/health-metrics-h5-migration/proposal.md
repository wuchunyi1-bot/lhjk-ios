## Why

健康模块「体征监测」由 H5 SPA 承载。宿主接入文档要求打开 H5 时携带 `token` + `platform=ios`，且部分指标 H5 路径与 App `metric key` 不一致（如 `exercise` → `exercise-food`）。当前实现仅加载裸 hash URL，无法满足登录态与子页面深链。

## What Changes

- **H5 鉴权 Query**：健康体征相关 WebView URL 统一追加 `token`（`access_token`）与 `platform=ios`
- **环境 Base URL**：development 对齐文档 `http://h5-dev.lianhaojiankang.com`
- **App key → H5 path 映射**：`exercise` → `exercise-food`；子路由 `manual/history/detail` 映射为 H5 `add/records/detail`
- **子页面深链**：原生路由携带的 `monitorId`、`sugarId`、`meal` 等参数拼入 H5 query
- **范围**：仅健康模块体征 H5；其他 WebView（协议页等）暂不改动

## Supersedes / Related

- 延续 `health-metrics-h5-migration`（Hub + WebView 骨架已完成）
- 作废原生体征实现（已完成）

## Capabilities

### Modified Capabilities

- `health-metrics`: H5 URL 构建、鉴权参数、路径与子路由映射

## Impact

- `Other/Common/H5Config.swift`
- `BLL/Health/HealthRoutes.swift`
- `openspec/changes/health-metrics-h5-migration/specs/health-metrics/spec.md`

## Reference

- 宿主文档：`h5接入文档.docx`
- Hash 形态：`{baseURL}#/{path}?token=...&platform=ios&...`
