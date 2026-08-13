# IM 消息卡片 — iOS 实现

> 监测上传：`monitor-im-card-frontend-handoff.md`（v0.4）  
> UI 对齐：funde-client `ConversationDetailView.vue` chat-card  
> 实时提醒：`openspec/changes/im-sysnotify-realtime-reminder/`  
> 代码：`IMCardResolver` / `SysNotifyCell`

---

## AD:SysNotify 三态

| 识别 | variant | UI |
|------|---------|-----|
| `extra.type == "realTime"` | **`monitorReminder`** | 实时提醒：圆标 + title + tag「监测任务」+ **content** + rows + **去完成 ›** |
| `extra.rows` 非空（且非 realTime） | `monitor` | 录入成功卡：圆标 + title + tag + 分隔线 + KV/结果胶囊/表格；**不读 content**；无 CTA |
| 其它 | `sysNotify` | 旧 C-sys：title + content；可选封面 |

判定顺序：**先 realTime，再 rows，再兜底 sysNotify**。

已移除：meal / detection / fetal / appointment（不再按 urlKey 拆）。

---

## C-monitorReminder（实时提醒）

对齐截图 + funde-client `monitor-reminder` / `chat-monitor-reminders.ts`。

```
┌─────────────────────────────────┐
│ (●icon)  title       [监测任务]  │
│ content 说明文案                  │
│ ─────────────────────────────── │
│ 计划时段：…                      │
│ 计划时间：…                      │
│ ┌──────── 去完成 › ──────────┐ │
└─────────────────────────────────┘
```

| 元素 | 数据 | 渲染 |
|------|------|------|
| 标题 | `title` | 15pt bold |
| 说明 | `content` | 正文，必展示（可多行） |
| 类型图标 | `extra.monitorType` | SF Symbol + 主题色圆底（同 C-monitor） |
| tag | `dataSourceTag`，空则 **「监测任务」** | 灰底胶囊 |
| KV | `extra.rows` | label：value |
| CTA | `completed` | `"0"`/空 →「去完成 ›」可点；`"1"` →「已完成」禁用 |
| 跳转 | `urlKey` + `monitorType` | 优先 `urlKey`（`FundeH5:`）；否则按 `monitorType` 兜底 |

`imageUrl` 可选；主题色 **不** 依赖封面。

会话摘要：`lastMsgDisplayContent`。

### realTime 跳转 · `urlKey` 约定（`FundeH5:`）

下发 `AD:SysNotify` 实时提醒时，**推荐**将 `urlKey` 写成 `FundeH5:` + H5 hash 路径（与 `FundePageURL` / `H5Config` 一致）。客户端去掉前缀后打开 `#/{path}?token&platform=ios`。

| `extra.monitorType` | 含义 | 推荐 `urlKey` | 实际 H5 |
|---------------------|------|---------------|---------|
| `pressure` | 血压录入 | `FundeH5:/blood-pressure/add` | `#/blood-pressure/add` |
| `sugar` / `glucose` | 血糖录入 | `FundeH5:/blood-sugar/add` | `#/blood-sugar/add` |
| `weight` | 体重录入 | `FundeH5:/weight/add` | `#/weight/add` |
| `temperature` | 体温录入 | `FundeH5:/temperature/add` | `#/temperature/add` |
| `diet` | 饮食录入 | `FundeH5:/exercise-food/add?meal=breakfast` | `#/exercise-food/add?meal=breakfast` |
| `sport` / `exercise` | 运动打卡 | `FundeH5:/exercise-food/check-in` | `#/exercise-food/check-in` |
| （未知） | 体征 Hub | `FundeH5:/blood-pressure`（或由客户端兜底 Hub） | 指标首页 |

说明：

- `meal` 可按餐次改为 `lunch` / `dinner` / `snack`；缺省 `breakfast`。
- 饮食运动 H5 根路径为 **`exercise-food`**（不是 `exercise`）。
- 历史兼容：生产仍可能下发 `AngelDoctor://tizhong` 等；iOS `IMMonitorReminderRoute` 仍按关键字映射。**新消息请用上表 `FundeH5:`**。

---

## C-monitor（录入成功）

```
┌─────────────────────────────────┐
│ (●icon)  title          [tag]   │  ← 28 圆图标主题色；tag=dataSourceTag
│ ─────────────────────────────── │
│ 标签：值                         │
│ 测量结果： [偏高]                │
│ ┌ 食物 │ 克数 │ 热量 ┐          │
└─────────────────────────────────┘
```

| 元素 | 数据 | 渲染 |
|------|------|------|
| 标题 | `title` | 15pt bold |
| 类型图标 | `extra.monitorType` | SF Symbol；圆底色仅按 monitorType |
| 来源 tag | `extra.dataSourceTag` | 空则隐藏 |
| KV / 结果 / 表 | `rows[]` | 不读 `content`；无 CTA；`clickable=false` |

### monitorType → 图标 / accent（funde iconMeta）

| monitorType | Symbol | accent |
|-------------|--------|--------|
| pressure | `waveform.path.ecg` | `#B47300` |
| sugar / glucose | `drop.fill` | `#E5564B` |
| weight | `chart.bar.fill` | `#1F9A6B` |
| temperature | `thermometer.medium` | `#2DB983` |
| diet | `fork.knife` | `#3D6FB8` |
| sport | `figure.walk` | `#FF7A50` |

---

## 其它 ObjectName（未改）

`AD:Vip` / `AD:ServiceComment` / `AD:CheckUserMsg` 仍走各自 variant。
