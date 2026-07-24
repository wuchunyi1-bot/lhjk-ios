# Order List Delta — 待支付跳转参数

## MODIFIED Requirements

### Requirement: 待支付去支付入口

#### Scenario: 待支付卡片与去支付按钮

- **WHEN** 用户在全部或待支付 Tab 操作待支付订单
- **THEN** 进入 `/orders/confirm`，参数包含 `orderId` 与 **`entry=order_pay`**
