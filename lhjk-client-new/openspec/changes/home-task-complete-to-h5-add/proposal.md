## Why

「今日健康任务」点击「去完成」当前跳到体征 **展示首页**（如 `/health/metrics/blood-pressure` → `#/blood-pressure`），用户无法直接录入。应按 H5 宿主文档进入对应 **add** 页（如 `#/blood-pressure/add`）。

## What Changes

- `type` / 默认 `actionRoute` 改为指标 **录入** 原生路径（`…/add`），经既有 HealthRoutes → H5 `#/{metric}/add`
- 规范化 `skipUrl`：若指向指标首页则改写为 add；已是 add/manual 则保留
- `HealthRoutes` / `H5Config` 补齐 `add` 后缀注册与映射（与 `manual` 同指向 H5 `add`）
- 更新 `home-today-monitor-tasks` 中 type→路由约定

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `home-today-monitor-tasks`: 「去完成」跳转目标改为 H5 录入页而非展示页

## Impact

- `BLL/Home/UserTodayMonitorTask.swift`
- `BLL/Health/HealthRoutes.swift`
- `Other/Common/H5Config.swift`
- OpenSpec：`home-today-monitor-tasks` / 本变更 delta
