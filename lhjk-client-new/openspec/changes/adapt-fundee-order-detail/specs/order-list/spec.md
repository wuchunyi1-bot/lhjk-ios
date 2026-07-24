# Order List Delta — 详情跳转

## MODIFIED Requirements

### Requirement: 订单列表展示

#### Scenario: 非待支付订单进入详情

- **WHEN** 用户点击 `status != 1` 的订单卡片
- **THEN** 进入 `/orders/detail?id={orderId}`
- **AND** 详情页调用 `GET /v1/order/getAppOrderDetail`（见 `order-detail` spec）

#### Scenario: 待支付订单进入确认页

- **WHEN** 用户点击 `status = 1` 的订单卡片或「去支付」
- **THEN** 进入 `/orders/confirm?orderId=`，不进入详情页
