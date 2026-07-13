## Why

funde-client `MeView.vue` 已重构「我的」Hub：隐藏四格统计、去掉服务履约列表、新增「常用功能」宫格、会员卡按开通状态展示、健康管理精简、底部「设置与支持」+ 退出登录。iOS `MyViewController` 仍停留在旧布局，需对齐原型（本变更仅改 Hub 首页）。

## What Changes

- 对齐 Vue `MeView.vue` + `me.json` 的 Hub 信息架构
- Hero：「编辑资料」→「个人信息」；健康档案跳 `/me/health-profile`
- 会员卡：支持 `not_opened` / `active` / `expiring` / `expired` 文案与主按钮（不做原型「注销演示」）
- **移除** 四格统计条、服务履约（我的订单）区块
- **新增**「常用功能」4 列宫格（8 入口）
- 健康管理改为 6 项（预约/卡券迁入常用功能）
- **新增**「设置与支持」分组 + Hub 底部退出登录
- 不改设置子页、订单详情等其它「我的」子模块

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `me`: 「我的」Hub 首页布局与交互（相对 `adapt-fundee-me` / 当前实现）

## Impact

- `PL/My/Home/MyViewController.swift`、`MyViewModel.swift`
- 可能新增 `MeCommonActionsCell` / 更新 `MeMembershipCardCell`
- 路由：常用功能用已有 `/orders`、`/me/appointments`、`/me/vouchers`、`/services/cart`、`/me/devices`、`/me/address`、`/me/family`、`/me/policy`；开通会员可用 `/me/membership` 或注册 `/me/membership/open` 占位
- 登出复用 Settings 同等清理链
