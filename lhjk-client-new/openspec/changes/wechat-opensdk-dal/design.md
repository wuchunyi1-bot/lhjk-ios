# Design: 微信 Open SDK DAL 封装

## SDK 能力结论（开放平台）

微信开放平台 **Mobile App Open SDK** 官方说明：同一套 SDK 提供：

| 能力 | API 入口 | 说明 |
|------|----------|------|
| 分享 / 收藏 | `SendMessageToWXReq` | 文本、图片、网页、**小程序**等 |
| 登录 | `SendAuthReq` | 拿 `code`，换票在服务端 |
| 支付 | `PayReq` | 需服务端预下单参数 |

CocoaPods 推荐：

```ruby
pod 'WechatOpenSDK-XCFramework'
```

- **含支付**的 XCFramework / `.a` 与 **不含支付**变体需选对；本项目要支付 → **必须用含支付版本**。
- 旧注释 `pod 'WechatOpenSDK'` 亦可，但以官网当前推荐 XCFramework 为准。
- **不是**三个独立 SDK；登录 / 分享 / 支付共用 `WXApi.registerApp` + 同一 `WXApiDelegate`。

开放平台控制台还需：开通对应权限、配置 Universal Link、App 关联小程序（分享小程序卡片）、商户号与支付目录（支付）。

## Goals

1. DAL 单一入口 `WeChatSDKManager`，PL/BLL **禁止**直接 `import` 微信头文件（除 bridged Manager 内部）。
2. 未安装 Pod 时工程仍可编译（`#if canImport(WechatOpenSDK)` 降级为明确错误）。
3. 支付 / 分享 / 登录回调统一分发，避免多处实现 `WXApiDelegate`。

## Non-Goals

- 本期不接真实登录换票 API、不接权益卡赠送 UI、不接预支付下单接口。
- 不修改 Podfile / Info.plist / pbxproj（由开发者按清单操作）。

## 架构

```text
AppDelegate.configureThirdPartySDKs
  → WeChatSDKManager.register(config)

SceneDelegate openURL / Universal Link
  → WeChatSDKManager.handleOpenURL / handleUniversalLink

BLL / PL
  → WeChatSDKManager.shareMiniProgram / sendAuth / pay
  → completion(Result)

WechatPayChannel.pay
  → 组装 WeChatPayRequest → Manager.pay
```

## 配置

`WeChatConfig`（占位，上线前填齐）：

- `appId`：开放平台移动应用 AppID（亦为 URL Scheme）
- `universalLink`：与苹果 / 微信后台一致的 Universal Link 前缀
- `miniProgramUserName`：关联小程序原始 id（`gh_`），供权益卡等分享默认使用

未配置 `appId` 时：`register` 打日志并跳过，调用能力返回 `.notConfigured`。

## 开发者手动步骤（AI 不做）

1. Podfile 启用 `WechatOpenSDK-XCFramework`，`pod install`
2. Info.plist：URL Types = AppID；`LSApplicationQueriesSchemes` = `weixin` / `weixinULAPI` / `weixinURLParamsAPI`（靠前）
3. Associated Domains：`applinks:你的域名`
4. 将 `DAL/WeChat/*.swift` 加入 Xcode Target
5. 填入 `WeChatConfig` 真实值

## 文件

| 文件 | 职责 |
|------|------|
| `WeChatConfig.swift` | AppID / UL / 小程序原始 id |
| `WeChatModels.swift` | 分享/登录/支付请求与错误枚举 |
| `WeChatSDKManager.swift` | 注册、检测、分享、授权、支付、回调 |
