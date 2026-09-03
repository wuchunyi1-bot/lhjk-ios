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
- **AND** 默认按字典 `monitorType.value` 映射（**非** Apifox 文档枚举）：
  - `2` → `/health/metrics/blood-pressure/add`
  - `3` → `/health/metrics/exercise/home`
  - `4` → `/health/metrics/weight/add`
  - `5` → `/health/metrics/blood-sugar/add`
  - `6` → `/health/metrics/temperature/add`
  - `7` → `/health/metrics/spo2/add`
  - `1`（睡眠）及其它未配置路由的 value → 不跳转
- **AND** 若 `skipUrl` 以 `/` 开头且 type 可跳转：优先使用；若其为指标首页路径（`/health/metrics/{key}` 无子路径），SHALL 改写为同指标的 `/add` 路径后再跳转

#### Scenario: 扩展字段展示

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
