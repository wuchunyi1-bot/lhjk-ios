## Why

当前 iOS 项目的「我的」模块仅有一个最简骨架 (`MyViewController.swift`) —— 头像 emoji + 用户名 + 红色退出按钮，缺少品牌 Hero、积分/家庭成员/保单统计、会员卡入口、服务履约概览、功能列表分组等核心内容。平行项目 funde-client 已完成完整的「我的」Hub 页设计，包含 20 个子页面。

本变更将 funde-client 的 MeView 及其核心子页面设计沉淀为 iOS OpenSpec，并实现 Hub 主页面的 UI。

## What Changes

- 新增 `me` spec：参考 funde-client `MeView.vue` + `me.json` + 子页面，产出 iOS 项目「我的」模块规格
- 重写 `MyViewController.swift` 为完整 Hub 布局
- 新增子页面 ViewController（Settings 等）
- 不涉及 BLL/网络层 —— 纯 UI 实现，数据暂用 mock

## Capabilities

### New Capabilities
- `me`: 我的模块 UI 规范 — Hub 布局（Hero + 会员卡 + 统计条 + 服务履约 + 功能列表分组 + 退出登录）、子页面结构

## Impact

- **PL/My/**: `MyViewController.swift` 重写，新增 Settings 等子页面
- **BLL/My/**: 暂无，数据暂用 mock
- **Other/Common/Extensions/**: 复用已有的 `UIColor+Theme.swift`
