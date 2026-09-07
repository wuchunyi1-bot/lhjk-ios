# Payment

## Purpose

提供应用内支付能力，支持第三方支付渠道，包括商品管理、下单、支付执行、回调验证和订单管理。

## Requirements

### Requirement: Payment Channels
系统 SHALL 支持以下支付渠道：
- 微信支付
- 支付宝

#### Scenario: 渠道选择
- **WHEN** 用户发起支付
- **THEN** PL 层展示可用的支付渠道列表，用户选择后 BLL 层调用对应渠道的支付流程

#### Scenario: 渠道可用性检测
- **WHEN** 进入支付页面
- **THEN** 系统检测各支付渠道的可用性（微信是否安装、支付宝是否可用），仅展示可用渠道

---

### Requirement: Third-party Payment
系统 SHALL 集成微信支付和支付宝 SDK。

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

#### Scenario: 支付回调
- **WHEN** 第三方支付完成后
- **THEN** 通过 URL Scheme 或 Universal Link 回调至应用，BLL 层处理支付结果并与服务端同步

---

### Requirement: Order Management
系统 SHALL 支持订单创建、状态查询和支付验证。

#### Scenario: 创建订单
- **WHEN** 用户发起支付前
- **THEN** BLL 层向服务端创建订单，获取订单号和支付参数

#### Scenario: 支付验证
- **WHEN** 客户端支付完成
- **THEN** 将支付凭证发送至服务端进行验证，防止伪造支付结果

#### Scenario: 订单状态同步
- **WHEN** 支付验证完成后
- **THEN** 服务端更新订单状态，并同步至客户端

#### Scenario: 订单列表
- **WHEN** 用户查看订单记录
- **THEN** PL 层展示历史订单列表，包含订单号、商品名称、金额、支付渠道、时间和状态

---

### Requirement: Security
系统 SHALL 确保支付过程的安全性。

#### Scenario: 凭证验证
- **WHEN** 客户端收到支付成功回调
- **THEN** 必须将支付凭证发送至服务端进行二次验证，客户端不得直接信任支付结果

#### Scenario: 防重放
- **WHEN** 发起支付请求
- **THEN** 订单号全局唯一且一次性有效，防止重复支付

#### Scenario: 结算金额版本
- **WHEN** 用户点击支付
- **THEN** 必须提交当前结算/详情的 `amountVersion` 与 `expectedPayableAmount`
- **AND** 若优惠券、权益卡过期或运费变化导致不一致，服务端拒绝拉起支付；客户端展示 `msg` 并刷新结算，不得调起第三方 SDK

#### Scenario: 数据传输
- **WHEN** 支付相关数据传输
- **THEN** 所有支付接口必须使用 HTTPS，敏感参数不得以明文日志输出

---

### Requirement: 支付结果页

第三方支付结束（成功或失败）后，系统 SHALL 展示独立支付结果页（Figma `3506:9196`，路由 `/orders/pay-result`），不得仅 Toast 后离开确认订单。

#### Scenario: 支付成功进入结果页
- **WHEN** 确认订单 `payMallOrder` 成功（含 0 元单）
- **THEN** 进入支付结果页成功态：标题「支付结果」、切图 `pay_success`、「支付成功」、本次应付金额、底栏「完成」
- **AND** 请求 `GET /v1/order/getAppOrderDetail`，信息卡背景为 `pay_info_bg`，展示订单号、下单时间、支付方式、订单状态，**不**展示支付时间
- **AND** 发送 `.orderListNeedsRefresh`
- **AND** 不得 Toast「支付成功」后直接进入订单列表

#### Scenario: 支付失败进入结果页
- **WHEN** 已发起支付后出现 `PaymentError`（用户取消除外）或其它无法完成支付的错误
- **THEN** 进入支付结果页失败态：切图 `pay_failed`、「支付失败」、失败原因、底栏「完成」
- **AND** 同样拉详情填信息卡，不展示应付金额与支付时间

#### Scenario: 用户取消与金额版本拒绝不进结果页
- **WHEN** 用户在第三方收银台取消支付
- **THEN** 停留确认订单页并提示「已取消支付」
- **WHEN** `orderPay` 因结算版本/应付不一致被拒绝（`payRejected`）
- **THEN** 停留确认订单页展示 `msg` 并刷新结算，不进入结果页、不调起 SDK

#### Scenario: 完成与返回均进入订单列表
- **WHEN** 用户在支付结果页点击「完成」或导航栏返回
- **THEN** 进入「我的订单」全部 Tab，不得返回确认订单页
- **AND** 禁用侧滑 pop
- **AND** 无论入口（选择套餐 / 购物车 / 订单列表待支付），支付成功或失败均调用 `presentPayResultOnMyOrders`：服务及来源 Tab `popToRoot`，我的栈为 `[我的, 订单列表全部, 支付结果]`
- **AND** 结果页完成/返回调用 `leavePayResultToOrderList`，落到 `[我的, 订单列表全部]`
