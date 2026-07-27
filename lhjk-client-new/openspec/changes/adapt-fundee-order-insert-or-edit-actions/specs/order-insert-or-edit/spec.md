## ADDED Requirements

### Requirement: PRD 3.4 用户侧操作矩阵（App）

用户侧订单列表 / 详情底栏 SHALL 按套餐类型与状态展示操作；**不得**把后台履约能力（如确认发货）暴露给用户。

> **确认收货目标状态**：客户端按接口约定提交确认收货；订单最终是否进入「已完成」由**后端状态机**处理，App **不**在客户端改写目标 status 规则。

#### Scenario: 待支付

- **WHEN** `status=1`
- **THEN** 列表展示「取消订单」+「去支付」
- **AND** 待支付详情（`entry=order_pay`）底栏展示「取消订单」+「去支付」（主按钮文案为「去支付」，非「立即支付」）

#### Scenario: 待发货

- **WHEN** `status=2`
- **THEN** **仅**展示「取消订单」
- **AND** **不得**展示「确认发货」

#### Scenario: 待收货

- **WHEN** `status=3`
- **THEN** 展示「确认收货」；电商零售（`packageType=2`）且未退款过时额外展示「退款/售后」

#### Scenario: 使用中

- **WHEN** `status=4` 且 `packageType=1`（租赁/综合服务）
- **THEN** 展示「结算订单」；满足续费资格时额外展示「续费订单」
- **WHEN** `status=4` 且 `packageType=4`（体验）
- **THEN** 未退款过时仅展示「退款/售后」

#### Scenario: 已逾期

- **WHEN** `status=7` 且 `packageType=1`
- **THEN** 展示「结算订单」
- **AND** 仅当 `renewed==1` 且由 `endTime` 推算逾期天数 ∈ [0, 5] 时展示「续费订单」
- **WHEN** 逾期第 6 天起
- **THEN** **不得**展示「续费订单」

#### Scenario: 已完成

- **WHEN** `status=5` 且 `packageType` 为 2 或 4，且无退款历史
- **THEN** 展示「退款/售后」
- **WHEN** `packageType` 为 1 或 3，或已有退款历史
- **THEN** 无业务变更按钮

---

## MODIFIED Requirements

### Requirement: 订单操作 insertOrEdit 矩阵

`POST /v1/order/insertOrEdit` SHALL 按下列映射组装 Body；`id`、`hospitalId` 均为字符串。

#### Scenario: 待支付取消

- **WHEN** 用户取消待支付订单
- **THEN** `{ "status": 8, "hospitalId", "id", "remark"? }`

#### Scenario: 待发货取消

- **WHEN** 用户取消待发货订单并填写原因
- **THEN** `{ "status": 9, "hospitalId", "id", "remark" }`

#### Scenario: 待收货退款/售后

- **WHEN** 用户提交退款/售后申请
- **THEN** `{ "status": 9, "hospitalId", "id", "remark" }`

#### Scenario: 待收货确认收货

- **WHEN** 用户确认收货
- **THEN** 按接口约定提交确认收货 Body（含 `id`、`hospitalId`）
- **AND** 客户端 **不**负责将主状态推导为「已完成」；流转结果以服务端返回 / 列表刷新为准

#### Scenario: 使用中 / 已逾期结算

- **WHEN** 用户提交结算申请
- **THEN** `{ "status": 9, "hospitalId", "id", "remark" }`

#### Scenario: 确认发货非用户入口

- **WHEN** 用户查看待发货订单
- **THEN** App **不得**提供「确认发货」按钮
- **AND** 发货为后台履约能力，不在用户操作矩阵内

---

### Requirement: 列表按钮可见性

#### Scenario: 待发货

- **THEN** 仅展示「取消订单」

#### Scenario: 待收货

- **THEN** 展示「退款/售后」（符合类型与未退款条件时）、「确认收货」
