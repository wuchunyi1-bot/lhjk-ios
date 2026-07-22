# Change: adapt-fundee-order-settlement

## Why

确认订单页需以 `getOrderSettlement` 为唯一主数据；立即购买 `saveShoppingCartOrPurchase` 成功后 `data` 即为订单 id，须传入结算接口。此前误用草稿且把 `data` 当空对象，导致结算接口未调用。

## What Changes

- `saveShoppingCartOrPurchase` 解析 `data` 为订单 id（Int64）
- 立即下单 / 购物车去结算 → `/orders/confirm?orderId=`
- 确认页进入必调 `getOrderSettlement`，展示不依赖上一页草稿
- 收货方式默认自提；`orderExpress==1` 才支持快递；自提地址 `hospital/getById`

## Impact

- ShoppingCartService / 套餐详情立即下单 / 购物车结算 / OrderConfirm VM+路由
- Spec：`order-confirm` delta
