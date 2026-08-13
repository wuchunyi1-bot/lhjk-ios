# 微信 Open SDK (WeChat)

## Purpose

DAL 统一封装微信开放平台 **Open SDK**（登录 / 分享 / 支付同一套库），供 BLL、支付渠道与业务页调用。

## SDK 选型

| 项 | 约定 |
|----|------|
| 能力 | 登录 + 分享（含小程序）+ 支付 |
| Pod | `WechatOpenSDK-XCFramework`（**含支付**） |
| 入口 | `DAL/WeChat/WeChatSDKManager` |
| 配置 | `WeChatConfig`（AppID、Universal Link、默认小程序原始 id） |

官方说明：Open SDK 同时支持分享与收藏、微信登录、微信支付。无支付变体本项目不使用。

## 分层

```
PL / BLL → WeChatSDKManager（DAL）→ WXApi
WechatPayChannel → WeChatSDKManager.pay
```

## Requirements

见变更 `openspec/changes/wechat-opensdk-dal/specs/wechat/spec.md`（已实现 DAL 骨架；Pod / 证书配置由开发者完成）。

## 相关

- 支付二次校验：`openspec/specs/payment/`
- 权益卡赠送：`giftBenefit` 成功后 `WeChatSDKManager.shareMiniProgram`（见 `openspec/specs/vouchers/`）
- 登录换票：`LoginService` 后续接 `sendAuth` 返回的 `code`
