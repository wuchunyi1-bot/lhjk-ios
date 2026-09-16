## Context

- API：`GET /v1/scheme/getUserToDayMonitorTask?userId=`（Apifox `UserMonitorTaskObject` / 472330787）
- 响应：`ResultListUserMonitorTaskObject`，`data` 为 `UserMonitorTaskObject[]`
- UI：已实现的 `HomeTaskCardCell` / `DailyTasksViewController`（`home-daily-health-tasks`）
- 模块归属：**Home**

## Goals / Non-Goals

**Goals:**

- 登录用户拉取今日监测任务列表并驱动首页摘要 + 详情页
- 完整解码 Apifox `UserMonitorTaskObject` 字段（含积分、进度、监测说明等）
- `type` → 图标 / 短标题 / `actionRoute`：**以字典 `monitorType` 为准**（`value` 编号 + `name` 文案）；Apifox 文档中的 type 枚举仅作接口字段说明，不作客户端映射依据
- `isComplete == 1` → 已完成
- **会话内缓存**：避免首页 / 详情每次 `viewWillAppear` 都打接口

**Non-Goals:**

- 不改首页任务区视觉布局
- 不实现 `updateUserMonitorTask` 完成回传（体征录入页后续处理）
- 不接 `getUserToDaySportTask`（运动任务另接口）
- 不解码 `details`（Apifox schema 未展开子字段）

## Decisions

1. **userId**：优先 `loginUserInfo.id`，否则 `currentUser.id`；缺失则空列表不请求。
2. **data**：`APIResponse<[UserTodayMonitorTask]>` 数组。
3. **字段映射（Apifox `UserMonitorTaskObject`）**：

| API 字段 | 类型 | UI `DailyHealthTask` / 展示 |
|----------|------|------------------------------|
| `get_id` / `id` | string | `id`（优先 `id`，否则 `get_id`） |
| `taskId` | int64 | 备用 `id` |
| `taskName` | string | `title` / `shortTitle` |
| `isComplete` | int32 (0/1) | `done` |
| `monitorTime` | string | `planTime` + detailRows「计划时间」 |
| `monitorValue` | string | 已完成时 detailRows「监测值」 |
| `type` | int32 | 字典 `monitorType.value`；`name` → shortTitle / 跳转；详情列表类型胶囊固定「监测任务」 |
| `mealType` | int32 | detailRows「餐次」+ 首页 `extraTags` |
| `mealTypeName` | string | 详情页「计划时段」**直接展示**该字段；空则不展示该行 |
| `userId` | int64 | 解码保留，展示不用 |
| `schemeId` | int64 | 解码保留 |
| `doctorId` / `sessionId` / `hospitalId` | int64 | 解码保留 |
| `createTime` | string | 已完成时 `completedAt` |
| `timeStamp` | int64 | 解码保留 |
| `skipUrl` | string | 若为 App 内 path（以 `/` 开头）优先作 `actionRoute` |
| `completeTaskNumber` / `taskNumber` | int32 | `taskNumber > 1` 时 detailRows「今日进度」+ 首页 tag |
| `remindSwitch` | int32 | 解码保留 |
| `monitorSpecification` | string | 详情「监测说明」（优先于本地默认文案） |
| `quantity` | int32 | 完成**单条**任务可获得的积分（任务行 `home_task_goal` 角标） |
| `pointsEarned` | int32 | **该 `type` 当天已获得积分**（同 type 多条相同，已含日上限；不是单条完成分） |
| `pointsTotal` | int32 | **该 `type` 当天积分上限**；`> 0` 时 detailRows「今日积分」+ 首页 tag |

首页进度「+N分」= 按 `type` 去重后的 `pointsEarned` 之和，禁止 `Σ quantity`（已完成）或 `Σ 每条 pointsEarned`。见 spec「首页完成积分按监测类型汇总」。

4. **type 映射（字典 `monitorType`，非 Apifox 文档枚举）**：

客户端以 `getDictionaryByParentId2` 拉取的 **监测类型** 字典为准：`value` 为任务 `type` 整型值，`name` 为展示文案。

路由解析顺序：

1. 用任务 `type` 在字典 `monitorType` 中找 `value`，取 `name`
2. **按 name 关键字** 映射 App 路由（编号会变：线上 `11` 是「营养补充剂」，不是 CMS 体征卡 `cardType=11` 用药）
3. 字典未同步时，再按历史编号 `2…7` 兜底

| 字典 name 含 | actionRoute |
|--------------|-------------|
| 营养补 / 补充剂 / 补剂 | `/supplement/add?taskId=` |
| 用药 / 药物 | `/medication` |
| 血压 | `/health/metrics/blood-pressure/add` |
| 血糖 | `/health/metrics/blood-sugar/add` |
| 体重 | `/health/metrics/weight/add` |
| 体温 | `/health/metrics/temperature/add` |
| 血氧 | `/health/metrics/spo2/add` |
| 心率 | `/health/metrics/heart-rate/add` |
| 血脂 | `/health/metrics/blood-lipid` |
| 运动 | `/exercise-food/check-in?taskId=` |
| 饮食 | `/health/metrics/exercise/home` |
| 睡眠 | 不跳转 |

`shortTitle` 优先字典 `name`。详情列表「任务类型」胶囊固定为「监测任务」，不按血糖 / 体重等区分。

5. **mealType**（Apifox）：1 空腹 / 2 早餐前 / 3 午餐前 / 4 午餐后 / 5 晚餐前 / 6 晚餐后1小时 / 7 晚餐后2小时 / 8 睡前；优先字典 `glucosePeriod`，否则 `mealType`，再回落硬编码表。用于「餐次」标签，**不**再用于「计划时段」。
   **mealTypeName**（Apifox 时段名称）：详情页「计划时段」直接展示接口返回文案，不经字典映射、不以 `monitorValue` 兜底。

6. **空态 / 失败**：清空任务列表，UI 展示「今日暂无健康任务」；不回落 mock。

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

- 睡眠（字典 value `1`）评审通过后：在 `monitorTaskRoutes` 补路由并放开跳转。
- 「完成」信号目前是否已有统一出口（原生 / H5）：实现时需确认挂点；文档先预留通知。
