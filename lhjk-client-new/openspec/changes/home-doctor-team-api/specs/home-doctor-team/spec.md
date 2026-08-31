## ADDED Requirements

### Requirement: 拉取用户参与的健康管家团队

系统 SHALL 通过 `GET /v1/session/getUserParticipateAllTeam` 获取当前用户参与的团队成员，并驱动首页「我的富德联好健康管家团队」卡片列表。

文档：[获取用户所参与的所有团队](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/495580451e0.md)

#### Scenario: 请求参数

- **WHEN** 本地存在有效 `userId`（`loginUserInfo.id` 或 `currentUser.id`）
- **THEN** 发起 GET，Query：`userId`（必填）
- **AND** 使用已登录 Bearer 鉴权（`APIManager` 拦截器）

#### Scenario: 无 userId

- **WHEN** 无法解析 userId
- **THEN** 不发起请求，团队成员列表为空，不展示团队 Section

#### Scenario: 成功解析嵌套数组

- **WHEN** 响应成功且 `data` 为 `MyDoctorTeamVO[][]`
- **THEN** 取第一个非空内层数组作为展示团队
- **AND** 排除 `userId` 与当前用户相同的成员
- **AND** 映射为团队卡片并刷新 UI

#### Scenario: 成员字段映射

- **WHEN** 渲染单条成员
- **THEN**：
  - `userName` → 姓名；首字 → 文字头像
  - `imageUrl` 非空 → Kingfisher 加载头像，失败回落文字头像
  - `position` → 职称（空则按角色默认文案）
  - `openBusinessName`（可截断）→ 专长标签
  - 角色色：doctor / nutrition / manager（见 design 映射表）
  - 接口无在线态时 **不** 展示「在线」点与虚假 status badge

#### Scenario: 发消息进入聊天详情

- **WHEN** 用户点击成员「发消息」且该成员 `groupId` 非空
- **THEN** 直接 push 聊天详情页，路由为 `/conversations/:id`
- **AND** 路由参数 `id` = 该成员的 `groupId`（融云群会话 targetId / 会话 id）
- **AND** **不得**先进入消息 Tab 列表再点进会话

#### Scenario: 发消息无 groupId

- **WHEN** 用户点击「发消息」但 `groupId` 为空或缺失
- **THEN** 不跳转聊天详情
- **AND** 可 Toast 提示无法发起会话（可选）

#### Scenario: 失败与空数据

- **WHEN** 请求失败，或 `data` 为 null / 空数组 / 过滤后无成员
- **THEN** 团队列表为空，不展示团队 Section
- **AND** **不得**使用本地 mock 假数据顶替

### Requirement: 展示居家服务剩余天数

系统 SHALL 通过 `GET /v1/schemeArchive/getRemainServiceTime` 获取当前用户居家服务剩余时间，并在团队卡片标题右侧展示。

#### Scenario: 请求与并行加载

- **WHEN** 首页拉取管家团队且用户已登录
- **THEN** 与 `getUserParticipateAllTeam` 并行发起 GET `/v1/schemeArchive/getRemainServiceTime`
- **AND** 无 Query 参数，使用 Bearer 鉴权

#### Scenario: 展示剩余天数

- **WHEN** 响应成功且 `data.remainDays > 0`
- **THEN** 团队卡片标题右侧展示「服务剩余 N 天 ›」（N = `remainDays`）
- **WHEN** `remainDays` 为 null、`0` 或负数
- **THEN** 隐藏标题右侧文案

#### Scenario: 剩余时间失败

- **WHEN** `getRemainServiceTime` 失败
- **THEN** 静默处理，仅隐藏右侧文案
- **AND** 团队成员列表仍按团队接口结果展示（若有）

#### Scenario: 点击剩余天数

- **WHEN** 用户点击「服务剩余 N 天 ›」
- **THEN** 跳转 `/orders`，`tab=in_progress`（使用中订单 Tab）

#### Scenario: 删除 mock

- **WHEN** 本能力落地
- **THEN** 移除 `HomeViewModel.defaultTeamMembers` 及默认 mock 注入路径
