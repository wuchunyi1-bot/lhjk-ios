# Change: adapt-fundee-cart-checkout-insert-or-edit

## Why

购物车「去结算」当前直接进入确认订单页，未调用 `POST /v1/order/insertOrEdit` 将购物车关联订单置为待支付（`status=1`）。同时需禁止点击卡片主体触发结算，仅「去结算」按钮可操作。

## What Changes

- 购物车「去结算」：先 `insertOrEditOrder`，Body `{ id, status: 1, serialNumber? }`，成功后进入 `/orders/confirm`
- 点击卡片主体无响应（不跳转）
- `OrderInsertOrEditRequest.checkoutFromCart` + `OrderService.checkoutCartOrder`

## API

- [新增或编辑订单](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330734e0.md) — `status=1` 表示待支付
