## MODIFIED Requirements

### Requirement: 确认订单立即支付

确认订单页点击「立即支付」或待支付「去支付」SHALL 调用支付统一接口并调起所选渠道。

#### Scenario: 微信支付

- **WHEN** 用户选择微信支付并点击支付
- **THEN** 调用 `GET /v1/orderPay/orderPay?orderId=&payType=1`
- **AND** 用返回预支付参数调起微信 Open SDK
- **AND** 用户取消支付时停留当前页并提示；成功后刷新订单列表并进入订单列表

#### Scenario: 支付宝

- **WHEN** 用户选择支付宝并点击支付
- **THEN** 调用 `GET /v1/orderPay/orderPay?orderId=&payType=2`
- **AND** 用返回 `data.aliBody`（支付宝 `orderStr`）调起支付宝 SDK
- **AND** 用户取消支付时停留当前页并提示；成功后刷新订单列表并进入订单列表
