# 结算订单弹窗与提交流程

## Why

funde「我的订单」结算订单需底部抽屉采集申请退款原因；iOS 当前仅用 Alert 确认且未传 `refundReasons`，与 PRD 5.6.4 / `OrderSettlementDialog.vue` 不一致。

## What

- 对齐 funde 结算交互：套餐简卡 + 申请退款原因 +「再想想」/「确认结算」
- `insertOrEdit` 结算提交携带 `refundReasons`
- 列表与详情共用 `OrderSettlementSheet`

## 参考

- `funde-client/prototype/src/views/orders/components/OrderSettlementDialog.vue`
- `funde-client/prototype/src/views/orders/OrderListView.vue` → `settleOrder`
- PRD `05_用户_我的订单_v1.0.md` §5.6.4
