## MODIFIED Requirements

### Requirement: 确认订单立即支付

确认订单页点击「立即支付」或待支付「去支付」SHALL 调用支付统一接口并调起所选渠道。

#### Scenario: 微信支付

- **WHEN** 用户选择微信支付并点击支付
- **THEN** 调用 `POST /v1/orderPay/orderPay`（JSON body：`orderId`、`payType=1`、`amountVersion`、`expectedPayableAmount`）
- **AND** `amountVersion`、`expectedPayableAmount` 必须来自当前页最近一次 `getOrderSettlement`（缺省可取同屏 `getAppOrderDetail`），**原样带回**，禁止用本地重算应付替换
- **AND** 用返回预支付参数调起微信 Open SDK
- **AND** 用户取消支付时停留当前页并提示；成功后刷新订单列表并进入订单列表

#### Scenario: 支付宝

- **WHEN** 用户选择支付宝并点击支付
- **THEN** 调用 `POST /v1/orderPay/orderPay`（JSON body：`orderId`、`payType=2`、`amountVersion`、`expectedPayableAmount`），带回规则同微信
- **AND** 用返回 `data.aliBody`（支付宝 `orderStr`）调起支付宝 SDK
- **AND** 用户取消支付时停留当前页并提示；成功后刷新订单列表并进入订单列表

#### Scenario: 结算金额已变化

- **WHEN** 点击支付后服务端发现优惠券/权益卡过期、改运费等导致应付或结算版本与提交值不一致
- **THEN** **不**调起第三方支付
- **AND** 用接口 `msg` 提醒用户金额已变化
- **AND** 重新请求 `getOrderSettlement` 刷新确认页金额后停留当前页

## ADDED Requirements

### Requirement: 结算金额契约字段

确认订单结算响应 SHALL 携带支付校验字段，供支付接口原样带回。

#### Scenario: 解码与展示

- **WHEN** `getOrderSettlement` 成功
- **THEN** 解码根级 `amountVersion`（结算版本）与 `expectedPayableAmount`（期望应付）
- **AND** 页面应付金额优先展示 `expectedPayableAmount`（与支付提交值一致）
- **AND** 换券 / 换卡 / 改运费后刷新结算，使用最新契约字段再支付
