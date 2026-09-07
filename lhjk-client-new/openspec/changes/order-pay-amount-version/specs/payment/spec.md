## MODIFIED Requirements

### Requirement: Third-party Payment

系统 SHALL 集成微信支付和支付宝 SDK。

#### Scenario: 微信支付

- **WHEN** 用户选择微信支付
- **THEN** BLL 层 `POST /v1/orderPay/orderPay`（`payType=1`）请求预支付信息，经 DAL `WeChatSDKManager.pay` / `WechatPayChannel.pay(order:prepay:)` 调起微信 SDK，PL 层展示支付结果
- **AND** 请求必须携带结算/详情下发的 `amountVersion`、`expectedPayableAmount`
- **AND** 微信 Open SDK 与登录、分享共用同一注册与回调入口（见 `openspec/specs/wechat/`）

#### Scenario: 支付宝支付

- **WHEN** 用户选择支付宝支付
- **THEN** BLL 层 `POST /v1/orderPay/orderPay`（`payType=2`）请求 `aliBody`（orderStr），调起支付宝 SDK 完成支付，PL 层展示支付结果
- **AND** 请求必须携带结算/详情下发的 `amountVersion`、`expectedPayableAmount`

## ADDED Requirements

### Requirement: 支付金额版本校验

发起支付前客户端 SHALL 把用户当前看到的结算契约提交给服务端，防止券/卡失效后仍按旧金额拉起支付。

#### Scenario: 原样带回

- **WHEN** 用户在确认订单或订单详情（待支付走确认页）点击支付
- **THEN** `POST /v1/orderPay/orderPay` JSON body 携带该页最近一次接口返回的 `amountVersion` 与 `expectedPayableAmount`
- **AND** **禁止**用客户端本地加减优惠/权益后的金额替换 `expectedPayableAmount`

#### Scenario: 服务端拒绝

- **WHEN** 服务端判定版本或应付与最新结算不一致
- **THEN** 不调起微信/支付宝
- **AND** 向用户展示后端提醒文案，并刷新结算/详情金额
