## Why

首页「今日健康任务」仍使用本地 mock；需接入 `GET /v1/scheme/getUserToDayMonitorTask`，在保持现有 UI（进度 + 最多 3 条 + `/home/tasks` 详情）的前提下替换数据源。

## What Changes

- 新增 Home 模块 BLL：拉取今日监测任务并映射为现有 `DailyHealthTask` 展示模型
- 首页 / 详情页加载真实数据；失败或无数据展示空态
- **删除** `DailyHealthTaskMock`（模块已接真实接口，禁止 mock 顶替）
- UI 布局交互沿用 `home-daily-health-tasks`（不改版式）

## Capabilities

### New Capabilities

- `home-today-monitor-tasks`: 今日监测任务 API 接入与首页/详情数据绑定

### Modified Capabilities

- （无已归档主规格；延续 `home-daily-health-tasks` UI 要求）

## Impact

- `BLL/Home/`：`HomeService`、`UserTodayMonitorTask`
- `PL/Home/ViewModels/HomeViewModel.swift`
- `PL/Home/DailyTasks/*`
- Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330787e0.md
- 字段对照：旧端 `AngelDoctor` `tasks` 模型（Apifox `data` schema 为空）
