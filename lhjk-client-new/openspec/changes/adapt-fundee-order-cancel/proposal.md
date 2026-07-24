# Change: adapt-fundee-order-cancel

## Why

「我的 → 我的订单」列表与详情页已展示「取消订单」按钮，但当前仅 Toast 占位。需对接 `POST /v1/order/insertOrEdit`，对齐 funde PRD 05 的待支付直接取消与待发货退款申请流程。

## What Changes

- `OrderService.insertOrEditOrder` 对接 Apifox `insertOrEdit` 接口
- 待支付（status=1）：二次确认 → `status=8`（已取消）
- 待发货（status=2）：二次确认 → 退款原因弹层 → `status=9`（退款审核）+ `remark`
- 列表 `OrderTabViewController`、详情 `OrderDetailViewController` 接入取消流程
- 成功后刷新订单列表并 Toast；详情页取消成功后返回上一页

## Impact

- `BLL/Service/OrderService.swift`、`OrderModels.swift`（取消请求模型）
- `PL/My/Order/Components/OrderCancelFlow.swift`、`OrderCancelRefundSheet.swift`（新增）
- `PL/My/Order/OrderTabViewController.swift`、`OrderListViewController.swift`
- `PL/My/Order/Detail/OrderDetailViewController.swift`、`OrderDetailViewModel.swift`

## API

- [新增或编辑订单](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330734e0.md) — `POST /v1/order/insertOrEdit`（JSON `MOrder`）

## Reference

- funde PRD：`05_用户_我的订单_v1.0.md` §5.2.4、§5.3.3
- funde 原型：`OrderListView.vue` `cancelOrder`、`PendingDeliveryOrderDetailView.vue`
