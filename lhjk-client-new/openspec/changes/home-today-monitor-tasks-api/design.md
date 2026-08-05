## Context

- API：`GET /v1/scheme/getUserToDayMonitorTask?userId=`（Apifox 472330787）
- Apifox 响应 `data` 未展开；以旧客户端 `tasks` 字段为准
- UI：已实现的 `HomeTaskCardCell` / `DailyTasksViewController`（`home-daily-health-tasks`）
- 模块归属：**Home**

## Goals / Non-Goals

**Goals:**

- 登录用户拉取今日监测任务列表并驱动首页摘要 + 详情页
- `type` → 图标 / 短标题 / `actionRoute` 映射
- `isComplete == 1` → 已完成
- **会话内缓存**：避免首页 / 详情每次 `viewWillAppear` 都打接口

**Non-Goals:**

- 不改首页任务区视觉布局
- 不实现 `updateUserMonitorTask` 完成回传（体征录入页后续处理）
- 不接 `getUserToDaySportTask`（运动任务另接口）
- 不做跨进程永久磁盘缓存（登出清空即可；不必 UserDefaults 持久化列表）

## Decisions

1. **userId**：优先 `loginUserInfo.id`，否则 `currentUser.id`；缺失则空列表不请求。
2. **data**：`APIResponse<[UserTodayMonitorTask]>` 数组。
3. **字段映射（旧端 tasks）**：

| API | UI `DailyHealthTask` |
|-----|----------------------|
| `id` / `taskId` | `id` |
| `taskName` | `title` / `shortTitle` |
| `isComplete` (0/1) | `done` |
| `monitorTime` | `planTime` + detailRows「计划时间」 |
| `monitorValue` | 已完成时 detailRows「监测值」 |
| `type` | iconKey / category / actionRoute |
| `skipUrl` | 若为 App 内 path（以 `/` 开头）优先作 `actionRoute` |

4. **type 映射**：

| type | 含义 | iconKey | actionRoute |
|------|------|---------|-------------|
| 1 | 血糖 | glucose | `/health/metrics/blood-sugar/add` → `#/blood-sugar/add` |
| 2 | 血压 | pressure | `/health/metrics/blood-pressure/add` → `#/blood-pressure/add` |
| 3 | 体重 | weight | `/health/metrics/weight/add` → `#/weight/add` |
| 4 | 心率/胎心兼容 | heart-rate | `/health/metrics/heart-rate/add` → `#/heart-rate/add` |
| 其它 | 通用 | checklist | `/health/metrics` |

`skipUrl` 若为指标首页（`/health/metrics/{key}`）须改写为同指标 `/add`；已是 `/add` 或 `/manual` 则保留。

5. **空态 / 失败**：清空任务列表，UI 展示「今日暂无健康任务」；不回落 mock。

6. **为何现在每次都打接口（现状问题）**

| 触发点 | 位置 | 行为 |
|--------|------|------|
| 首页每次出现 | `HomeViewController.viewWillAppear` → `loadTodayTasks()` | **强制请求** |
| 用户资料更新 | `HomeViewModel` 订阅 `.userDidUpdate` → `loadTodayTasks()` | 再次请求 |
| 详情每次出现 | `DailyTasksViewController.viewWillAppear` → `load()` | **强制请求** |

因此：切 Tab 回首页、从二级页返回、反复进详情，都会重复调用同一接口。

7. **缓存与刷新策略（待实现，本次仅定稿；暂不改代码）**

### 7.1 缓存载体

- 在 **BLL 层** 增加会话级缓存（建议 `HomeService` 内或独立 `TodayMonitorTaskStore`，单例）：
  - `cachedTasks: [UserTodayMonitorTask]`
  - `cachedUserId: String`
  - `cachedCalendarDay: String`（本地日历日，`yyyy-MM-dd`，设备时区）
  - `hasFetchedOnce: Bool`（本进程是否已成功拉过）
- 首页 / 详情 **共用同一份缓存**，映射为 `DailyHealthTask` 后展示。
- **登出**（`UserManager.clear` / `LoginService.logout`）时清空缓存。
- **不强制** UserDefaults 持久化列表：冷启动重新拉一次即可满足「冷启动刷新」。

### 7.2 读取路径（`load` / `loadTodayTasks`）

```
进入首页或详情
  → 若缓存有效（userId 一致 + 日历日未变 + 已有成功缓存）
      → 直接用缓存刷新 UI，不发网络
  → 否则
      → 发 GET getUserToDayMonitorTask
      → 成功则写入缓存并刷新 UI
      → 失败则：有旧缓存则保留展示；无缓存则空态
```

首页 / 详情 `viewWillAppear` **只走上述逻辑**，不再无条件请求。

### 7.3 强制刷新时机（仅以下场景打接口）

| 场景 | 触发方式 | 说明 |
|------|----------|------|
| **冷启动** | App 进程首次进入首页（Store 未 `hasFetchedOnce`） | 无有效内存缓存，必然请求一次 |
| **日期变化** | load 前比较 `cachedCalendarDay` 与「今天」；回前台 / `significantTimeChange` 时校验跨日 | 跨自然日后缓存失效并请求 |
| **任务完成状态变化** | 监测完成后发 `.todayMonitorTaskShouldRefresh` | 缓存作废并重新拉取，保证「已完成」回显 |

明确 **不** 因以下原因刷新：

- 仅切换 Tab / `viewWillAppear`
- 仅 `.userDidUpdate`（资料变更与今日任务无关；除非 userId 变化）
- 详情页与首页互相进入（共享缓存）

### 7.4 「状态完成」落地约定

当前体征 H5 / 原生录入成功后 **尚未** 回调首页任务。实现缓存时需约定：

1. App 内完成监测并确认后，`NotificationCenter.post(.todayMonitorTaskShouldRefresh)`
2. H5 若能通过 JSBridge 回传完成，宿主同样 post 该通知
3. Store 收到后：`invalidate()` → 立即或下次 load 时打接口

Bridge 未就绪前：先保证「冷启动 + 跨日」；完成态先留通知钩子，体征成功点逐步挂上。

### 7.5 并发

- 同一时刻只允许一个 in-flight 请求（合并重复 `load`）
- 强制刷新进行中时，后来的 `load` 等待同一次结果

## Open Questions

- type=4 在富德侧是否仍为胎心：暂映射心率 H5；若产品确认另改。
- 「完成」信号目前是否已有统一出口（原生 / H5）：实现时需确认挂点；文档先预留通知。
