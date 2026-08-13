## Context

- 生产样例：`title` / `content` / `urlKey` / `imageUrl` + 嵌套 `extra`（字符串 JSON）含 `type:realTime`、`monitorType`、`rows`、`completed`
- UI 参考：用户截图；funde-client `chat-monitor-reminders.ts` + `ConversationDetailView.vue` chat-card
- 现有 C-monitor：录入成功，不读 content，无 CTA

## Goals / Non-Goals

**Goals:** 识别 realTime、按提醒卡样式渲染、去完成跳转、与 C-monitor 互斥。

**Non-Goals:** 不改 Vip/Comment/CheckUser；不实现 AngelDoctor 原生 scheme 全量兼容表以外的未知 urlKey（可 toast）。

## Decisions

### 1. 判定顺序（AD:SysNotify）

```
extra.type == "realTime"  → monitorReminder
extra.rows 非空           → monitor（录入成功）
否则                      → sysNotify
```

### 2. UI

| 元素 | 来源 |
|------|------|
| 标题 | `title` |
| 说明 | `content` |
| tag | `dataSourceTag`，空则默认「监测任务」 |
| 主题色/图标 | `monitorType`（同 C-monitor iconMeta；兼容 `glucose`→sugar） |
| KV | `extra.rows` |
| CTA | 未完成「去完成 ›」；`completed` 为 1/true →「已完成」禁用 |

### 3. 跳转

`IMMonitorReminderRoute.entryPath(urlKey:monitorType:title:)` → `Router.push` / 健康 H5 add。

优先 `monitorType`，其次解析 `urlKey`（推荐 `FundeH5:`，兼容 `AngelDoctor://…`），再标题关键字。

### 推荐 urlKey（后端下发）

| monitorType | urlKey |
|-------------|--------|
| pressure | `FundeH5:/blood-pressure/add` |
| sugar / glucose | `FundeH5:/blood-sugar/add` |
| weight | `FundeH5:/weight/add` |
| temperature | `FundeH5:/temperature/add` |
| diet | `FundeH5:/exercise-food/add?meal=breakfast` |
| sport / exercise | `FundeH5:/exercise-food/check-in` |

### 4. clickable

仅 `monitorReminder` 且未完成时 `clickable=true`；整卡或按钮触发 `cellDidTapIMCard`。

## Risks

- [未知 urlKey + 未知 monitorType] → toast / 进 `/health/metrics`
- [imageUrl 与本地图标] → 优先 SF + monitorType；imageUrl 可选增强（本期可不加载封面）
