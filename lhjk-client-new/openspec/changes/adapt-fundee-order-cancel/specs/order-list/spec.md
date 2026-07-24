# Order List Delta — 取消订单

## MODIFIED Requirements

### Requirement: 订单列表操作

#### Scenario: 列表卡片取消待支付订单

- **WHEN** 用户在待支付 Tab 点击卡片「取消订单」
- **THEN** 走 `order-cancel` spec 待支付取消流程（不进入详情页）

#### Scenario: 列表卡片取消待发货订单

- **WHEN** 用户在待发货 Tab 或全部 Tab 点击「取消订单」
- **THEN** 走 `order-cancel` spec 待发货退款申请流程

#### Scenario: 取消后刷新

- **WHEN** 取消或退款申请成功
- **THEN** 所有订单 Tab 子列表刷新数据
