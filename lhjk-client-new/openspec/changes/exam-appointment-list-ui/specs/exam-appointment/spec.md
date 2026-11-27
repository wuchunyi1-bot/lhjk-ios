## ADDED Requirements

### Requirement: 预约体检与就医协助落地页已移除

系统 SHALL NOT 注册 `/appointments/exams`、`/services/medical-assist` 以及两边的使用记录页。我的权益列表 SHALL 请求 `GET /v1/cabin/entitlementList`，SHALL NOT 调用 `GET /v1/cabin/medicalConfigList`。体检和就医协助的权益卡片进入项目预约 SHALL 请求 `GET /v1/cabin/bookDetail`，SHALL NOT 请求 `GET /v1/serviceItem/detail`。这两类的「去预约」SHALL 先确认消耗，确认后调用 `POST /v1/cabin/book`（`sourceType = 2`），再用返回的姓名、电话和二维码展示工作人员联系方式。`businessType = 1` 的卡片 SHALL 与「去预约」相同，进入康养小屋选择页。

#### Scenario: 权益列表使用新接口

- **WHEN** 用户打开我的权益
- **THEN** 列表来自 `GET /v1/cabin/entitlementList`
- **AND** 列表为空时展示「暂无权益」
- **AND** 康养小屋的列表、预约和取消保持原逻辑

#### Scenario: 点击权益卡片

- **WHEN** 用户点击 `businessType = 1` 的权益卡片
- **THEN** 与点击「去预约」相同，进入康养小屋选择页 `/wellness-cabins`
- **AND** `GET /v1/cabin/list` 另传该条的 `projectId`
- **WHEN** 用户点击体检或就医协助的权益卡片
- **THEN** 进入项目预约页 `/wellness-cabins/book`，并带上该条的 `businessType`
- **AND** 详情请求 `GET /v1/cabin/bookDetail`，Query 使用该条返回的 `configId`
- **AND** 不展示选择预约日期和选择预约时段
- **AND** 次数大于 0 时，底部预约与列表「去预约」相同：确认消耗后调用 `POST /v1/cabin/book`
- **AND** 不请求 `GET /v1/serviceItem/detail`

#### Scenario: 体检和就医协助去预约

- **WHEN** 用户点击 `businessType = 2` 或 `3` 的「去预约」
- **THEN** 弹出「确认消耗权益」。体检文案为「本次预约将消耗 1 次体检权益。确认后为您展示工作人员企业微信和联系电话。」就医协助把「体检」换成「就医协助」
- **AND** 点「再想想」留在当前页
- **AND** 点「确认消耗」调用 `POST /v1/cabin/book`，JSON 为该条 `configId`、`sourceType = 2`、`quantity = 1`，不传日期和时段
- **AND** 成功后弹出「添加工作人员」，姓名、电话和二维码使用这次返回的数据
- **AND** 「我知道了」或点击遮罩关闭后仍留在当前页
- **AND** 接口成功返回后刷新我的权益列表；若项目预约详情已打开，同时刷新该页的可用次数

#### Scenario: 体检和就医协助详情里预约

- **WHEN** 用户在体检或就医协助的项目预约详情点击底部预约，且可用次数大于 0
- **THEN** 与列表「去预约」相同，先确认消耗，再调用 `POST /v1/cabin/book`
- **AND** 成功后刷新我的权益列表和当前详情的可用次数
- **AND** 康养小屋的日期、时段和提交逻辑保持不变

#### Scenario: 小屋去预约进入选择页

- **WHEN** 用户点击 `businessType = 1` 的「去预约」
- **THEN** 进入康养小屋选择页 `/wellness-cabins`
- **AND** `GET /v1/cabin/list` 另传该条的 `projectId`
- **AND** 首页金刚区进入康养小屋时不传 `projectId`

#### Scenario: 落地页不再存在

- **WHEN** 用户从首页或服务入口查找预约体检、就医协助
- **THEN** 没有这两个落地页
- **AND** 康养小屋的列表、预约和取消保持原逻辑

### Requirement: 预约记录只请求一次

预约记录页 SHALL 用一次 `GET /v1/cabin/appointments` 拉取记录，SHALL NOT 传 `businessType`。状态筛选仍传 `status`。小屋列表和首页待服务仍传 `businessType = 1`。

#### Scenario: 预约记录不拆类型

- **WHEN** 用户从我的权益进入预约记录
- **THEN** 只请求一次 `GET /v1/cabin/appointments`
- **AND** 请求不包含 `businessType`
- **AND** 不再提供体检、就医协助各自的使用记录页

#### Scenario: 体检和就医协助的记录操作

- **WHEN** 预约记录里是体检或就医协助
- **THEN** 待安排没有按钮，点卡片不进入详情
- **AND** 待确认只显示「去确定」，点按钮进入 `/appointments/usage-records/confirm?id=`，只带预约 id，点卡片不进入详情
- **AND** 待服务、服务中、已完成、已取消、已过期显示「查看详情」，点按钮进入对应详情，点卡片不进入详情
- **AND** 详情调用 `GET /v1/cabin/reservationDetail`，页面模板按这次返回的 `businessType` 决定，不按预约列表有没有该字段猜测。1 展示康养小屋详情，2 和 3 展示体检或就医协助详情
- **AND** 体检和就医协助详情展示服务名称、时间、机构或医院、地址和导航、服务人员与电话、服务说明；`businessType` 为 3 时另展示科室和医生
- **AND** 服务说明按 `description` 原文展示。带 HTML 时用富文本渲染，纯文本仍按正文显示。待确认和待服务共用这一块
- **AND** 待确认详情底部为「确认安排」，调用 `POST /v1/cabin/confirm`，成功后回到预约记录并刷新
- **AND** 待服务详情底部为「取消服务」，确认文案说明安排不再保留且消耗本次权益，调用 `POST /v1/cabin/cancel`，成功后回到预约记录并刷新
- **AND** 康养小屋记录仍使用原来的按钮和小屋预约详情
