# Design: adapt-fundee-order-list-pay-entry

## Context

- 待支付订单 `status=1`，卡片按钮为「取消订单」+「去支付」
- 确认订单页已改为以 `orderId` 拉 `getOrderSettlement`，路由 `/orders/confirm?orderId=`

## Decisions

1. 待支付（`pendingPayment`）卡片整体点击 → `/orders/confirm?orderId=<id>`，不再进订单详情
2. `OrderListCardAction.pay` → `/orders/confirm?orderId=<id>`
3. 无有效 `id` 时 Toast「订单信息缺失」
4. 其它状态行为不变

## Risks

| Risk | Mitigation |
|------|-----------|
| 订单 id 缺失 | Toast 提示，不跳转 |
