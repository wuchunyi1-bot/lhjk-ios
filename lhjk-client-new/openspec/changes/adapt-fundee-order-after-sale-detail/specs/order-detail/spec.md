# Order Detail Delta — 退款/售后

## MODIFIED Requirements

### Requirement: 退款/售后 Tab 进入详情

#### Scenario: 点击退款/售后列表卡片

- **WHEN** 用户在「退款/售后」Tab 点击订单卡片
- **THEN** 进入 `/orders/detail?id={orderId}`
- **AND** 调用 `GET /v1/order/getAppOrderDetail`
- **AND** 页面展示完整详情内容，不得空白

### Requirement: 售后信息展示

#### Scenario: 退款/售后态详情

- **WHEN** 详情 `status=6` 或 `status=9`
- **THEN** 状态头展示对应售后状态与提示文案
- **AND** 展示「退款/售后信息」卡片，含申请时间、退款单号、申请退款原因（接口有值时）
- **AND** 底部不展示业务操作按钮（只读）

#### Scenario: 已出款金额

- **WHEN** 接口返回 `applyRefund` 且金额 > 0
- **THEN** 在售后信息卡展示「退款金额」并高亮

#### Scenario: 退款驳回

- **WHEN** 存在 `refuseReasons` 且订单已回到非售后主状态
- **THEN** 状态区展示「退款未通过：{原因}」
- **AND** 不展示售后信息卡

### Requirement: 解码容错

#### Scenario: 商品明细字段类型不一致

- **WHEN** `shoppingCartPackageDetailList` 中数值字段为字符串或浮点
- **THEN** 仍能成功解析订单详情并展示其它区块
