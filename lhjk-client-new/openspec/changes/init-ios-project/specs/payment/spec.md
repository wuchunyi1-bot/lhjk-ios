## ADDED Requirements

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

### Requirement: Third-party Payment
系统 SHALL 集成微信支付和支付宝 SDK。

#### Scenario: 微信支付
- **WHEN** 用户选择微信支付
- **THEN** BLL 层向服务端请求预支付信息（prepay_id），调起微信 SDK 完成支付，PL 层展示支付结果

#### Scenario: 支付宝支付
- **WHEN** 用户选择支付宝支付
- **THEN** BLL 层向服务端请求签名字符串（orderString），调起支付宝 SDK 完成支付，PL 层展示支付结果

#### Scenario: 支付回调
- **WHEN** 第三方支付完成后
- **THEN** 通过 URL Scheme 或 Universal Link 回调至应用，BLL 层处理支付结果并与服务端同步

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

### Requirement: Security
系统 SHALL 确保支付过程的安全性。

#### Scenario: 凭证验证
- **WHEN** 客户端收到支付成功回调
- **THEN** 必须将支付凭证发送至服务端进行二次验证，客户端不得直接信任支付结果

#### Scenario: 防重放
- **WHEN** 发起支付请求
- **THEN** 订单号全局唯一且一次性有效，防止重复支付

#### Scenario: 数据传输
- **WHEN** 支付相关数据传输
- **THEN** 所有支付接口必须使用 HTTPS，敏感参数不得以明文日志输出
