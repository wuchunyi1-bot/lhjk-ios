# Order Confirm Delta — 订单列表待支付展示

## MODIFIED Requirements

### Requirement: 确认订单页结构

#### Scenario: 默认确认订单（购物车 / 套餐下单）

- **WHEN** `entry` 缺省或为 `cart`
- **THEN** 导航标题为「确认订单」
- **AND** **不展示**顶部状态头与底部订单信息卡

#### Scenario: 我的订单待支付进入

- **WHEN** 用户从「我的订单」全部/待支付 Tab 点击待支付订单或「去支付」
- **THEN** 进入 `/orders/confirm?orderId=&entry=order_pay`
- **AND** 导航标题为「**订单详情**」
- **AND** 顶部展示待支付状态卡（主文案「待支付」+ primary 图标样式，**无**卡片内副文案）
- **AND** 中间区域与默认确认页一致（履约、地址/自提、套餐、备注、优惠、费用、支付方式）
- **AND** 底部展示「订单信息」卡（订单号、下单时间、订单备注；展开见支付状态）
- **AND** 并行请求 `getAppOrderDetail` 填充订单信息；结算仍用 `getOrderSettlement`

#### Scenario: 优惠券行文案

- **WHEN** 已绑定优惠券且抵扣金额 > 0
- **THEN** 展示 `已使用一张，共优惠¥{amount}`
- **WHEN** 有可用券未选
- **THEN** 展示 `有{n}张可用`
- **WHEN** 无可用券
- **THEN** 展示 `暂无可用`

#### Scenario: 订单列表待支付导航

- **WHEN** `entry=order_pay` 用户点击返回
- **THEN** `pop` 回订单列表（**不得**跨 Tab）
- **WHEN** 支付成功
- **THEN** 与 `default` 相同，当前 Nav 替换为订单列表「全部」
