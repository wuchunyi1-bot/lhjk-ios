## ADDED Requirements

### Requirement: 订单操作 insertOrEdit 矩阵

`POST /v1/order/insertOrEdit` SHALL 按下列映射组装 Body；`id`、`hospitalId` 均为字符串。

#### Scenario: 待支付取消

- **WHEN** 用户取消待支付订单
- **THEN** `{ "status": 8, "hospitalId", "id", "remark"? }`

#### Scenario: 待发货确认发货

- **WHEN** 用户点击「确认发货」
- **THEN** `{ "status": 3, "hospitalId", "id", "shipmentTime" }`
- **AND** `shipmentTime` 为当前时间，格式 `yyyy-M-d H:m:s`（不补零）

#### Scenario: 待发货取消

- **WHEN** 用户取消待发货订单并填写原因
- **THEN** `{ "status": 9, "hospitalId", "id", "remark" }`

#### Scenario: 待收货退款/售后

- **WHEN** 用户提交退款/售后申请
- **THEN** `{ "status": 9, "hospitalId", "id", "remark" }`

#### Scenario: 待收货确认收货

- **WHEN** 用户确认收货
- **THEN** `{ "status": 4, "hospitalId", "id" }`

#### Scenario: 使用中 / 已逾期结算

- **WHEN** 用户提交结算申请
- **THEN** `{ "status": 9, "hospitalId", "id", "remark" }`

---

### Requirement: 列表按钮可见性

#### Scenario: 待发货

- **THEN** 展示「确认发货」「取消订单」

#### Scenario: 待收货

- **THEN** 展示「退款/售后」「确认收货」
