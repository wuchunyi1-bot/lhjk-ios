# Change: adapt-fundee-order-list-pay-entry

## Why

「我的 → 我的订单 → 待支付」列表缺少去支付入口：点卡片与「去支付」按钮当前分别进订单详情 / Toast 占位，无法回到确认订单页完成支付。需打通待支付订单 → `/orders/confirm`（按 `orderId` 拉结算）。

## What Changes

- 待支付订单卡片点击 → `/orders/confirm?orderId=`
- 待支付订单「去支付」按钮 → `/orders/confirm?orderId=`
- 其它状态卡片点击仍进 `/orders/detail`；其它按钮维持现状

## Impact

- `OrderTabViewController`（`handleAction` / `didSelectRowAt`）
- Spec：`order-list` delta
