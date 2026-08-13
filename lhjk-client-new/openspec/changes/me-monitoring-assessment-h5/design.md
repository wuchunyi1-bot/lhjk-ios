## Context

体检报告已通过 `H5Config.authenticatedPageURL` + `MyRoutes` → `WebViewController` 接入。监测方案 / 健康评估采用同一模式。

| 入口文案 | 原生深链 | H5 hash |
|----------|----------|---------|
| 监测方案 | `/me/monitoring-plan` | `#/monitoring-plan` |
| 健康评估 | `/me/health-assessment` | `#/health-assessment` |

「健康测评」`/me/health-evaluations` 不在本期范围。

## Goals / Non-Goals

**Goals:**

- 两项入口打开带 `token` + `platform=ios` 的 H5
- 保留 `/me/*` 深链；增加无前缀别名便于与文档对齐

**Non-Goals:**

- 不改 H5 业务内容、不新增 Query 业务参数
- 不迁移「健康测评」或饮食方案等其它行
- 不强制删除原生 VC 源文件

## Decisions

### 1. URL 经 `H5Config.authenticatedPageURL`

与 medical-reports / health record 一致：`{origin}/#/{path}?token&platform=ios`。

### 2. 原生入口仍用 `/me/*`

Hub `MyViewModel` 已指向 `/me/monitoring-plan`、`/me/health-assessment`；仅改注册目标为 WebView。

### 3. 别名 `/monitoring-plan`、`/health-assessment`

与 H5 文档路径字面量一致，供外部/调试直达。

## Risks / Trade-offs

- [Risk] H5 未部署该路由 → 白屏 → Mitigation：与 H5 环境对齐；开发环境可切 `H5Config.environment`
- [Trade-off] 原生监测方案原型页不再走入口 → 可保留源码备查

## Migration Plan

1. OpenSpec 产物
2. `H5Config` + `MyRoutes`
3. 真机/模拟器从「我的」点两项冒烟

## Open Questions

无。
