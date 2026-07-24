# Change: adapt-fundee-order-after-sale-detail

## Why

「我的订单 → 退款/售后」Tab 点击卡片进入详情页后出现**空白**，无法查看售后进度与申请信息。需对齐 funde PRD 5.7：复用原订单详情壳 +「退款/售后信息卡」，并修复售后订单详情解码与加载态问题。

## What Changes

- `AppOrderDetailBO` 补充售后字段（`refundId`、`refundReasons`、`refundApplyTime`、`applyRefund`、`refuseReasons` 等）
- 商品明细解码容错，避免售后订单 `shoppingCartPackageDetailList` 字段类型不一致导致整单解析失败
- 详情页新增「退款/售后信息」卡片（申请时间、退款单号、申请原因、退款金额）
- 修复详情 loading 结束后 `scrollView` 未恢复显示的问题
- 售后态（status=6/9）底部无操作按钮，只读查看

## Impact

- `BLL/Service/OrderDetailModels.swift`
- `PL/My/Order/Detail/OrderDetailViewController.swift`
- `PL/My/Order/Detail/Components/OrderDetailComponents.swift`

## Reference

- funde PRD `05_用户_我的订单_v1.0.md` §5.7
- funde `OrderAfterSaleInfoCard.vue`
- Apifox `GET /v1/order/getAppOrderDetail` — `AppOrderDetailBO`
