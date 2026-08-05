## Context

- 任务「去完成」经 `DailyHealthTask.actionRoute` → `Router.push` → `HealthRoutes` → `H5Config.authenticatedMetricURL`
- 现状：`UserTodayMonitorTask.displayMeta` 使用 `/health/metrics/{key}`（无 suffix）→ H5 指标首页
- 目标：进入 H5 `#/{key}/add`（体重/血压/血糖等手动录入）

## Goals / Non-Goals

**Goals:**

- 未完成任务「去完成」打开对应 H5 **add** 页
- type 与 skipUrl（指标首页）均落到 add

**Non-Goals:**

- 改任务列表 UI、打卡回传、运动任务另一接口
- 服药/补剂等无 H5 add 文档的类型（仍按既有兜底）

## Decisions

1. **原生路径统一用 `…/add`**（对齐 Vue `monitor-reminder-routes`），不用仅内部的 `manual`；同时保留 `manual` 兼容。
2. **H5 映射**：`nativeSuffix "add" | "manual"` → H5 `"add"`。
3. **type 表**：

| type | actionRoute | H5 |
|------|-------------|-----|
| 1 血糖 | `/health/metrics/blood-sugar/add` | `#/blood-sugar/add` |
| 2 血压 | `/health/metrics/blood-pressure/add` | `#/blood-pressure/add` |
| 3 体重 | `/health/metrics/weight/add` | `#/weight/add` |
| 4 心率 | `/health/metrics/heart-rate/add` | `#/heart-rate/add`（若 H5 未上线则空态由 H5 处理） |
| 其它 | `/health/metrics` | 指标 Hub 原生 |

4. **skipUrl**：以 `/` 开头时，若等于 `/health/metrics/{key}`（无后续段）则改写为 `…/add`；已含 `/add` 或 `/manual` 不改。

## Risks / Trade-offs

- [心率等无宿主文档 add] → 仍推 `/add`，与其它指标一致；H5 未实现时由 H5 处理。
