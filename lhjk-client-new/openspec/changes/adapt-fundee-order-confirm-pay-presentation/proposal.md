# Change: adapt-fundee-order-confirm-pay-presentation

## Why

「我的订单」中待支付订单进入 `/orders/confirm` 时，页面语义是「待支付订单详情 + 继续支付」，与购物车/套餐「确认订单」不同：需展示待支付状态头、底部订单信息，导航标题为「订单详情」。

## What Changes

- 新增 `entry=order_pay`（`OrderConfirmEntry.orderListPay`）
- 订单列表待支付卡片 /「去支付」push 时携带 `entry=order_pay`
- 确认页在该模式下：标题「订单详情」、顶部待支付状态区、底部订单信息卡；中间履约/套餐/优惠/支付等与现网一致
- 购物车 `entry=cart`、套餐立即下单 `default` 不变

## Impact

- `OrderNavigationCoordinator.swift`（`OrderConfirmEntry`）
- `OrderConfirmViewController` / `OrderConfirmViewModel`
- `OrderTabViewController`、`MyRoutes`
- `PL/My/Order/Components/OrderDetailStatusPresentation.swift`（新增）
- `OrderDetailComponents.swift`、`OrderConfirmComponents.swift`
