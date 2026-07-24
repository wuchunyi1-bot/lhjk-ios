# Change: adapt-fundee-completed-order-detail

## Why

已完成等非待支付订单详情需对齐 funde-client `PaidOrderDetailView`：在套餐信息之外独立展示**收货地址 / 服务机构**、**物流信息**（按商品行发货状态）、**退款/售后信息**，与待支付确认页的信息分区一致，避免履约信息挤在单一卡片内。

## What Changes

- `OrderDetailPackageLineBO` 新增 `shipmentStatus`、`presetDeliveryTime`
- 详情页区块重排：状态 → 提示 → 售后信息 → 套餐 → 商品明细 → 收货地址 → 物流信息 → 服务机构 → 费用 → 订单信息
- 新增 `OrderDetailAddressView`、`OrderDetailInstitutionView`、`OrderDetailLogisticsView`
- 退款/售后信息卡样式对齐 funde `OrderAfterSaleInfoCard`（行高、字体、退款金额高亮）
- 移除原合并式 `OrderDetailFulfillmentView` 在详情页的使用

## Impact

- `BLL/Service/OrderDetailModels.swift`
- `PL/My/Order/Detail/OrderDetailViewController.swift`
- `PL/My/Order/Detail/Components/OrderDetailComponents.swift`

## Reference

- funde `PaidOrderDetailView.vue`、`OrderLogisticsInfoSection.vue`、`OrderAfterSaleInfoCard.vue`
- funde `order-detail-shared.css`、`mobile.css`（`order-fee-total`、shipment-task-card）
- Apifox `GET /v1/order/getAppOrderDetail` — `ShoppingCartPackageDetailBO`
