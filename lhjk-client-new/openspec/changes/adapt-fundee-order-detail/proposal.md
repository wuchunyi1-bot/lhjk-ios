# Change: adapt-fundee-order-detail

## Why

「我的 → 我的订单」中，除**待支付**外点击订单卡片当前进入占位页，无法查看真实订单详情。需对接 `GET /v1/order/getAppOrderDetail`，首版对齐 funde 订单详情在**待发货**场景的展示与信息结构。

## What Changes

- 新增订单详情页 `OrderDetailViewController`（PL）+ `OrderDetailViewModel`
- `OrderService.getAppOrderDetail(orderId:)` 对接 Apifox 文档
- `/orders/detail` 路由替换占位页；列表**待支付**仍进 `/orders/confirm`
- 详情页按 `status` 展示状态头、套餐/明细、履约地址、费用与订单信息；**待发货**展示取消订单按钮（点击本期 Toast，后续接 API）

## Impact

- `BLL/Service/OrderService.swift`、`OrderDetailModels.swift`（新增）
- `PL/My/Order/Detail/`（新增）
- `BLL/My/MyRoutes.swift`
- `openspec/specs/order-list` delta（详情跳转说明）

## API

- [根据订单id查询订单详情](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330739e0.md) — `GET /v1/order/getAppOrderDetail?orderId=`
