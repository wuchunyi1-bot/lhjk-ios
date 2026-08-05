## Why

首页「今日健康任务」仍按旧原型展示积分、勾选行，且无二级详情页；funde-client 现行 Vue（`HomeView.vue` / `DailyTasksView.vue`）与 page-spec 已改为进度条 + 去完成/已完成 + `/home/tasks` 详情（含监测说明），需对齐 UI 逻辑。

## What Changes

- 首页任务区对齐 Vue：进度摘要条、最多 3 条任务行（图标/短标题/计划时间/分类标签/去完成）、「查看全部 ›」进详情；**不展示积分**
- 新增二级页 `/home/tasks`：橙色进度 Hero、完整任务卡片（说明、字段行、监测说明）、温馨提示
- 「去完成」跳转对应体征录入路由（本地 mock 映射，本期不做打卡提交）
- 任务数据模型对齐监测提醒字段（category / planTime / instructions / actionRoute）

## Capabilities

### New Capabilities

- `home-daily-health-tasks`: 首页今日任务区 + `/home/tasks` 详情页 UI 与交互

### Modified Capabilities

- （无归档主规格；`sync-home-to-funde-vue` 中任务区积分文案由本变更覆盖）

## Impact

- `PL/Home/`（HomeTaskCardCell、HomeViewController、HomeViewModel）
- 新建 `PL/Home/DailyTasks/`
- `BLL/Home/HomeRoutes.swift` 注册 `/home/tasks`
