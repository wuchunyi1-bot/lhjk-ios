## Context

对齐 funde-client：

- PRD / page-spec：`docs/page-specs/home-daily-tasks.page.yaml`、`home.page.yaml`（daily-tasks）
- Vue：`HomeView.vue`（首页摘要）、`DailyTasksView.vue`（二级页）
- Mock：`daily-health-tasks.ts` ← 监测提醒卡片同源

模块归属：**Home**。

## Goals / Non-Goals

**Goals:**

- 首页任务区与二级详情页 UI/交互对齐 Vue
- 路由 `/home/tasks`；去完成跳转业务路由
- Design Token；触摸目标 ≥ 44pt

**Non-Goals:**

- 任务打卡提交与服务端同步
- 积分奖励展示
- 历史任务日历 / 自定义排序
- 本页直接录入体征（仅跳转）

## Decisions

1. **路由** `/home/tasks`（与 Vue / page-spec 一致，不用旧 `/tasks`）。
2. **首页只展示前 3 条**；进度分母为全日任务总数；多余时卡片底部「查看全部 N 项」。
3. **数据** 本期本地 mock，字段对齐 `DailyHealthTask`；后续可换真实 API。
4. **去完成** `Router.push(actionRoute)`；已完成不可点。
5. **去掉积分** 首页标题右侧改为「查看全部 ›」；卡片内不再显示 `+N` 分。

## Risks / Trade-offs

- [部分 actionRoute 尚未有原生页] → 走已有 Health H5 路由；缺失时落 `/health/metrics`。
