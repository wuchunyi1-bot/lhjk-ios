# Change: wechat-opensdk-dal

## Why

权益卡赠送需拉起微信「小程序卡片」分享；登录与支付也需同一微信开放平台能力。工程内仅有 `WechatPayChannel` / 登录 Mock 占位，Podfile 中 `WechatOpenSDK` 仍注释，缺少统一 DAL 封装与回调入口。

## What Changes

- 明确：**一个微信 Open SDK 同时覆盖登录、分享、支付**（推荐 CocoaPods `WechatOpenSDK-XCFramework`，含支付；另有无支付变体勿选）
- 新增 `DAL/WeChat/WeChatSDKManager`：注册、安装检测、URL/Universal Link 回调、分享（网页/小程序）、授权登录、调起支付
- `AppDelegate` / `SceneDelegate` 接入注册与回调转发
- `WechatPayChannel` 改为委托 Manager 调起支付与处理回调（业务预下单仍在 BLL）
- **AI 不改** Podfile / Info.plist / pbxproj；开发者手动启用 Pod 与工程配置

## Impact

- DAL：`WeChat/*`；Payment 微信支付渠道；App 启动与 Scene URL
- Spec：`openspec/specs/wechat/`；变更目录本 change
- 后续：权益卡赠送页、登录授权、真实预支付参数对接
