# Change: order-pay-amount-version

## Why

支付统一接口改为 POST，并增加结算版本校验：优惠券/权益卡过期或改运费后，服务端应付可能已变。客户端必须把结算/详情下发的 `amountVersion`、`expectedPayableAmount` 原样带回，否则后端拒绝拉起支付并提示金额变化。

## What Changes

- `POST /v1/orderPay/orderPay`（JSON body，禁止 query）
- Body：`orderId` / `payType` / `description` / `code`，以及必带回的 `amountVersion`、`expectedPayableAmount`
- `getOrderSettlement`、`getAppOrderDetail` 解码并缓存上述两字段
- 支付失败（金额/版本不一致）展示后端 `msg`，刷新结算后停留当前页

## Impact

- BLL：`OrderService` / `OrderSettlementModels` / `OrderDetailModels` / `PaymentService`
- PL：`OrderConfirmViewModel`
- Spec：`payment`、确认订单立即支付
- `docs/api-inventory.md` 33a Method 改为 POST
