## ADDED Requirements

### Requirement: 微信 Open SDK 单一封装

系统 SHALL 在 DAL 层通过 `WeChatSDKManager` 统一封装微信开放平台 Open SDK，供登录、分享、支付复用；**同一 SDK 包**覆盖上述三类能力（推荐含支付的 `WechatOpenSDK-XCFramework`）。

#### Scenario: SDK 能力边界

- **WHEN** 查阅本规格
- **THEN** 明确登录（`SendAuthReq`）、分享（`SendMessageToWXReq`，含小程序）、支付（`PayReq`）均来自同一 Open SDK
- **AND** **禁止**为三类能力分别引入三套微信 SDK
- **AND** 须选用**含支付**的 SDK 变体；无支付变体不得用于本 App

#### Scenario: 注册

- **WHEN** App 启动 `configureThirdPartySDKs`
- **THEN** 调用 `WeChatSDKManager.register`，传入开放平台 AppID 与 Universal Link
- **AND** AppID 或 Universal Link 未配置时跳过注册并记日志，后续能力调用返回未配置错误

#### Scenario: 安装与回调

- **WHEN** 业务需判断能否调起微信
- **THEN** 通过 Manager 查询是否安装微信 / 是否支持 Open API
- **WHEN** 系统通过 URL Scheme 或 Universal Link 回跳 App
- **THEN** `SceneDelegate`（及必要的 AppDelegate）将 URL / UserActivity 交给 Manager `handleOpen*`，由唯一 `WXApiDelegate` 分发分享 / 登录 / 支付结果

#### Scenario: 分享

- **WHEN** 业务请求分享小程序卡片给微信好友
- **THEN** Manager 组装小程序分享对象，`scene` 为会话，异步回调成功 / 取消 / 失败
- **WHEN** 业务请求分享网页
- **THEN** Manager 提供网页分享能力（同会话场景）
- **AND** 未安装微信或 SDK 未链入时返回明确错误，**禁止**静默成功

#### Scenario: 登录

- **WHEN** 业务发起微信授权登录
- **THEN** Manager 发送 `SendAuthReq`（默认 `snsapi_userinfo`），在回调中返回 `code`（及 state）
- **AND** **禁止**在 DAL 用 `code` 换 access_token；换票与绑定手机属于 BLL / 服务端

#### Scenario: 支付

- **WHEN** `WechatPayChannel` 或 BLL 发起微信支付
- **THEN** 使用服务端预下单字段组装 `WeChatPayRequest`，经 Manager 调起 `PayReq`
- **AND** 支付结果经同一 Delegate 回调；客户端成功**不得**视为最终到账，须 BLL 服务端二次校验（见 `payment` spec）

#### Scenario: 分层与编译

- **WHEN** 未通过 CocoaPods 集成 Open SDK
- **THEN** Manager 以条件编译降级，调用返回「SDK 未集成」，工程仍可编译
- **AND** PL / BLL **不得**直接依赖 `WXApi` 类型；仅通过 Manager 与 `WeChatModels` 交互

#### Scenario: 工程配置（开发者）

- **WHEN** 正式启用微信能力
- **THEN** 开发者手动：启用含支付的 Open SDK Pod、配置 URL Scheme / Queries Schemes / Associated Domains、将 `DAL/WeChat` 源文件加入 Target、填入 `WeChatConfig`
- **AND** AI **不得**修改 Podfile / Info.plist / pbxproj
