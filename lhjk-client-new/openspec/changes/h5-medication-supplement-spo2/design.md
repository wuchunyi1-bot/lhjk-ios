## Context

体检报告、监测方案、健康评估已通过 `H5Config.authenticatedPageURL` + 原生路由 → `WebViewController` 接入。用药 / 营养补剂 / 血氧采用同一模式。

血氧体征首页已存在：`H5Config.metricKeys` 含 `spo2`，路由 `/health/metrics/spo2` → `#/spo2`。本期补文档对齐别名 `/spo2`。

| 入口文案 | 原生深链 | H5 hash |
|----------|----------|---------|
| 用药 | `/medication` | `#/medication` |
| 营养补剂 | `/supplement` | `#/supplement` |
| 血氧 | `/spo2`（别名） | `#/spo2`（与 `/health/metrics/spo2` 相同） |

## Goals / Non-Goals

**Goals:**

- 三条路径打开带 `token` + `platform=ios` 的 H5
- 路由落在健康模块 `HealthRoutes`
- 更新 `h5-host` 路由表

**Non-Goals:**

- 不改 H5 业务内容、不新增业务 Query
- 不把用药 / 营养补剂加入体征 `metricKeys`（非监测卡片）
- 不改「我的」Hub 硬编码入口；CMS `quickEntryList` / `FundeH5:` 已可直达
- 不改体征卡 `cardType` → `/health/metrics/{key}` 逻辑

## Decisions

### 1. URL 经 `H5Config.authenticatedPageURL`

与 medical-reports / monitoring-plan 一致。血氧别名可用 `authenticatedPageURL(path: "spo2")` 或 `authenticatedMetricURL(metricKey: "spo2")`，二者 hash 相同。

### 2. 文档路径即原生 path

注册 `/medication`、`/supplement`、`/spo2`，与 H5 hash 字面量一致，供 `FundeApp:`、`Router.push`、IM 深链使用。

### 3. 模块归属：健康

用药 / 营养补剂 / 血氧属健康 Tab 能力，路由写入 `HealthRoutes`，不写入 `MyRoutes`。

## Risks / Trade-offs

- [Risk] H5 未部署该路由 → 白屏 → 与 H5 环境对齐；开发可切 `H5Config.environment`
- [Trade-off] `/spo2` 与 `/health/metrics/spo2` 双路径 → 有意兼容文档短链与体征卡深链

## Migration Plan

1. OpenSpec 产物 + 主 spec 路由表
2. `H5Config` + `HealthRoutes`
3. 用 `Router.push` / `FundeApp:` 冒烟

## Open Questions

无。
