# Change: wire-order-pay-api

## Why

确认订单「立即支付 / 去支付」仍为占位 Toast；Apifox 已有 `GET /v1/orderPay/orderPay`，需在支付时真实调用并调起微信。

## What Changes

- `OrderService.orderPay` → `GET /v1/orderPay/orderPay`（`orderId` + `payType`：1 微信 / 2 支付宝）
- `PaymentService.payMallOrder`：预下单后 `WechatPayChannel.pay(order:prepay:)`
- `OrderConfirmViewModel.submitPay` 接入上述链路；支付宝暂提示改用微信
- `docs/api-inventory` 增补 33a
- Apifox `data` schema 为空：客户端宽松解码微信 APP 字段；缺字段时明确报错（0 元单接口成功可完成）

## Impact

- BLL：`OrderService` / `OrderModels` / `PaymentService`
- PL：`OrderConfirmViewModel`
- DAL：`WechatPayChannel.payAsync`
