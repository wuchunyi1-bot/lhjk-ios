## ADDED Requirements

### Requirement: 拉取今日监测任务

系统 SHALL 通过 `GET /v1/scheme/getUserToDayMonitorTask` 获取当前用户今日监测任务，并驱动首页「今日健康任务」与 `/home/tasks` 详情页。

#### Scenario: 请求参数

- **WHEN** 本地存在有效 `userId`（`loginUserInfo.id` 或 `currentUser.id`）
- **THEN** 发起 GET，Query：`userId`（必填）
- **AND** 使用已登录 Bearer 鉴权（`APIManager` 拦截器）

#### Scenario: 无 userId

- **WHEN** 无法解析 userId
- **THEN** 不发起请求，任务列表为空，展示空态

#### Scenario: 成功解析

- **WHEN** 响应 `success`/`code` 成功且 `data` 为任务数组
- **THEN** 映射为 `DailyHealthTask` 列表并刷新 UI
- **AND** 首页最多展示前 3 条；进度分母为全日任务数；详情页展示全部

#### Scenario: 完成态

- **WHEN** `isComplete == 1`
- **THEN** 任务标记已完成；「去完成」不可点；展示「已完成」
- **WHEN** `isComplete == 0` 或缺失
- **THEN** 未完成，可跳转 `actionRoute`

#### Scenario: 类型跳转（录入页）

- **WHEN** 用户点击未完成任务「去完成」
- **THEN** 打开对应体征 **H5 录入（add）** 页，而非指标展示首页
- **AND** 优先按字典 `monitorType.name` 解析路由（**value 编号会随运营配置变化，不得把 CMS cardType 11=用药 当成监测类型 11**）：
  - 名称含「营养补 / 补充剂 / 补剂」→ `/supplement/add?taskId={taskId}`（优先接口 `taskId`，否则实例 `id`）
  - 名称含「用药 / 药物」→ `/medication`
  - 名称含「运动」→ `/exercise-food/check-in?taskId={taskId}`（优先接口 `taskId`，否则实例 `id`）
  - 血压 / 血糖 / 体重 / 体温 / 血氧 / 心率 / 血脂 / 饮食 → 对应体征 H5
  - 名称含「睡眠」→ 不跳转
- **AND** 字典未同步时，再按常见 value 编号兜底：`2` 血压、`3` 运动、`4` 体重、`5` 血糖、`6` 体温、`7` 血氧
- **AND** 若 `skipUrl` 以 `/` 开头且 type 可跳转：优先使用；若其为指标首页路径（`/health/metrics/{key}` 无子路径），SHALL 改写为同指标的 `/add` 路径后再跳转

#### Scenario: 扩展字段展示

- **WHEN** 任务含非空 `mealTypeName`
- **THEN** 详情页展示「计划时段」，值为接口原文，不经字典映射
- **WHEN** `mealTypeName` 为空或缺失
- **THEN** 不展示「计划时段」行
- **WHEN** 任务含 `mealType`
- **THEN** 详情页 detailRows 展示「餐次」；首页任务行 `extraTags` 含餐次文案
- **WHEN** `taskNumber > 1`
- **THEN** 展示「今日进度」`completeTaskNumber/taskNumber`
- **WHEN** `pointsTotal > 0`
- **THEN** 展示「今日积分」`pointsEarned/pointsTotal`
- **WHEN** `monitorSpecification` 非空
- **THEN** 详情「监测说明」优先使用该字段，否则使用本地 type 默认文案

#### Scenario: 失败与空数据

- **WHEN** 请求失败或 `data` 为空数组 / null
- **THEN** 若无可用缓存：任务列表为空并展示空态文案
- **AND** **不得**使用本地 mock 假数据顶替

#### Scenario: 删除 mock

- **WHEN** 本能力落地
- **THEN** 移除 `DailyHealthTaskMock` 及默认 mock 注入路径

---

### Requirement: 首页完成积分按监测类型汇总

系统 SHALL 将首页「今日健康任务」进度摘要中的已得积分，按监测 `type` 汇总 `pointsEarned`，不得把每条任务的单次分或同 type 多条 `pointsEarned` 重复相加。

**字段语义（`GET /v1/scheme/getUserToDayMonitorTask`）**：

| 字段 | 含义 |
|------|------|
| `quantity` | 完成**这一条**任务可获得的积分（任务行角标仍可用） |
| `pointsEarned` | **该 `type` 当天已经获得的积分**（同 type 多条任务值相同；受该类型日上限约束） |
| `pointsTotal` | **该 `type` 当天可获得的积分上限**（同 type 多条任务值相同） |

同 type 每天总分有上限。例如 type=11 有 5 条营养补充剂任务，`quantity=5`、`pointsTotal=15`：完成第 4 条后单次相加会变成 20，但类型上限是 15，接口在每条上返回的 `pointsEarned` 已是该类型当天实得（≤ `pointsTotal`）。

#### Scenario: 按 type 去重后相加

- **WHEN** 计算首页进度摘要「+N分」（`taskEarnedPoints`）
- **THEN** 将任务列表按 `type` 分组
- **AND** 每个 `type` 只取一条 `pointsEarned`（同 type 各条应相同；若不一致取较大值）
- **AND** 将各 type 的 `pointsEarned` 相加，得到今日已得总分
- **AND** **不得**再对已完成任务的 `quantity` 求和
- **AND** **不得**把同 type 多条任务的 `pointsEarned` 按条数累加（会重复计算该类型当天已得分）

#### Scenario: 示例

- **WHEN** 今日任务含 type=11 三条（`pointsEarned=10`）与 type=5 两条（`pointsEarned=3`）
- **THEN** 首页已得积分 = `10 + 3` = 13
- **AND** 不是 `10+10+10+3+3`，也不是已完成条数 × `quantity`

#### Scenario: 缺 type

- **WHEN** 某条任务 `type` 为空
- **THEN** 将所有无 `type` 的任务视为一组，取该组 `pointsEarned` 最大值计入总分（不按条数相加）

---

### Requirement: 今日任务会话缓存与条件刷新

系统 SHALL 对今日监测任务做会话级缓存，避免因页面反复出现而重复请求；仅在冷启动、自然日变化、任务完成态需同步时刷新网络。

#### Scenario: 缓存命中不请求

- **WHEN** 首页或详情 `viewWillAppear` / `load`
- **AND** 已有同一 `userId`、同一本地日历日（`yyyy-MM-dd`）的成功缓存
- **THEN** 使用缓存渲染 UI
- **AND** **不**发起 `getUserToDayMonitorTask`

#### Scenario: 冷启动刷新

- **WHEN** 进程内尚无成功缓存（含冷启动后首次进入首页）
- **THEN** 发起网络请求并写入缓存

#### Scenario: 日期变化刷新

- **WHEN** 当前本地日历日与缓存日不一致（含跨日回前台校验）
- **THEN** 使缓存失效并重新请求
- **AND** 用新结果覆盖缓存与 UI

#### Scenario: 任务完成刷新

- **WHEN** 收到任务完成/需同步通知（如监测提交成功后的 `.todayMonitorTaskShouldRefresh`）
- **THEN** 使缓存失效并重新请求
- **AND** 首页与详情共用刷新后的数据

#### Scenario: 非刷新场景

- **WHEN** 用户仅切换 Tab、从子页返回、或反复进入详情且缓存仍有效
- **THEN** 不发起网络请求

#### Scenario: 登出清空

- **WHEN** 用户登出
- **THEN** 清空今日任务会话缓存
