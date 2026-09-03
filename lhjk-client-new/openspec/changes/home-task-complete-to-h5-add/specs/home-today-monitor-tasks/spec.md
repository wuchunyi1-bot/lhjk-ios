## MODIFIED Requirements

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
- **AND** 默认按字典 `monitorType.value` 映射：
  - `2` → `/health/metrics/blood-pressure/add`（`#/blood-pressure/add`）
  - `3` → `/health/metrics/exercise/home`
  - `4` → `/health/metrics/weight/add`（`#/weight/add`）
  - `5` → `/health/metrics/blood-sugar/add`（`#/blood-sugar/add`）
  - `6` → `/health/metrics/temperature/add`
  - `7` → `/health/metrics/spo2/add`
  - `1`（睡眠）及其它 → 不跳转
- **AND** 若 `skipUrl` 以 `/` 开头：优先使用；若其为指标首页路径（`/health/metrics/{key}` 无子路径），SHALL 改写为同指标的 `/add` 路径后再跳转

#### Scenario: 失败与空数据

- **WHEN** 请求失败或 `data` 为空数组 / null
- **THEN** 若无可用缓存：任务列表为空并展示空态文案
- **AND** **不得**使用本地 mock 假数据顶替

#### Scenario: 删除 mock

- **WHEN** 本能力落地
- **THEN** 移除 `DailyHealthTaskMock` 及默认 mock 注入路径
