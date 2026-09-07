## ADDED Requirements

### Requirement: 支付结果页

第三方支付结束（成功或失败）后，系统 SHALL 展示独立支付结果页，而不是仅 Toast 后离开确认订单。

路由：`/orders/pay-result`。视觉对齐 Figma `3506:9196`。

#### Scenario: 支付成功进入结果页

- **WHEN** 确认订单页 `payMallOrder` 成功（含 0 元单、未调起 SDK 但接口成功）
- **THEN** 进入支付结果页成功态
- **AND** 标题为「支付结果」
- **AND** 展示切图 `pay_success`、主文案「支付成功」、本次应付金额（¥0.00 亦展示）
- **AND** 请求 `GET /v1/order/getAppOrderDetail`，在 `pay_info_bg` 信息卡展示订单号、下单时间、支付方式、订单状态
- **AND** **不**展示支付时间
- **AND** 底栏展示「完成」
- **AND** 刷新订单列表通知 `.orderListNeedsRefresh`
- **AND** 不得 Toast「支付成功」后直接进入订单列表

#### Scenario: 支付失败进入结果页

- **WHEN** 已发起支付后出现 `PaymentError`（用户取消除外）或其它无法完成支付的错误
- **THEN** 进入支付结果页失败态
- **AND** 展示切图 `pay_failed`、主文案「支付失败」与失败原因
- **AND** 同样请求 `getAppOrderDetail` 展示信息卡（不含支付时间）
- **AND** 底栏展示「完成」
- **AND** 不展示应付金额

#### Scenario: 支付结束跨 Tab 重建栈

- **WHEN** 支付成功或失败进入结果页（含选择套餐、购物车、订单列表待支付）
- **THEN** 调用 `OrderNavigationCoordinator.presentPayResultOnMyOrders`
- **AND** 服务 Tab（及来源 Tab）`popToRoot`，切到「我的」Tab
- **AND** 我的导航栈变为 `[我的, 订单列表全部, 支付结果]`
- **AND** 不得把结果页压在选择套餐 / 套餐详情 / 确认订单之上

#### Scenario: 完成与返回均进入订单列表

- **WHEN** 用户在支付结果页点击「完成」或导航栏返回
- **THEN** 调用 `leavePayResultToOrderList`
- **AND** 落到「我的 → 我的订单 → 全部」，栈为 `[我的, 订单列表全部]`
- **AND** 不得返回确认订单页或选择套餐页
- **AND** 禁用侧滑 pop，避免回到确认页重复提交

#### Scenario: 查看订单进入详情

- **WHEN** 用户在支付结果页点击「查看订单」
- **THEN** 调用 `leavePayResultToOrderDetail`
- **AND** 我的导航栈变为 `[我的, 订单列表全部, 订单详情]`

## MODIFIED Requirements

### Requirement: Third-party Payment

#### Scenario: 微信支付

- **WHEN** 用户选择微信支付
- **THEN** BLL 层向服务端 `POST /v1/orderPay/orderPay` 请求预支付信息（prepay_id 等），经 DAL `WeChatSDKManager.pay` / `WechatPayChannel.pay(order:prepay:)` 调起微信 SDK
- **AND** 成功或失败由 PL 层展示支付结果页（见「支付结果页」）
- **AND** 请求携带结算/详情下发的 `amountVersion`、`expectedPayableAmount`（原样带回）
- **AND** 微信 Open SDK 与登录、分享共用同一注册与回调入口（见 `openspec/specs/wechat/`）

#### Scenario: 支付宝支付

- **WHEN** 用户选择支付宝支付
- **THEN** BLL 层向服务端 `POST /v1/orderPay/orderPay` 请求 `aliBody`（orderStr），调起支付宝 SDK
- **AND** 成功或失败由 PL 层展示支付结果页（见「支付结果页」）
- **AND** 请求携带结算/详情下发的 `amountVersion`、`expectedPayableAmount`（原样带回）
