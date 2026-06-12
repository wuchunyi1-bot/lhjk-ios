## Why

当前 iOS 项目的注册/登录页面 (`LoginViewController.swift`) 仅有一个最简骨架——手机号 + 验证码 + 蓝色登录按钮，缺少品牌标识、多登录方式切换、微信登录入口、老年模式适配、协议提示等核心功能。而平行项目 funde-client（Vue.js 原型）已经产出了一套完整的注册登录页面设计规范和布局实现，包括：

- 双模式登录切换（验证码 / 密码）
- 品牌标识展示（Logo + 名称 + Slogan）
- 微信第三方登录入口 + 授权弹层
- 倒计时获取验证码
- 用户协议展示
- 老年模式字号自动放大（data-senior）
- 完整的颜色/字号/间距 Token 体系

本变更的目标是**将 funde-client 的注册登录页面设计沉淀为 iOS 项目的 OpenSpec 规范**，并评估其在 iOS UIKit 项目中的适配方案。

## What Changes

- 新增 `register-login` spec：参考 funde-client 的 LoginView.vue + tokens.css + design-system.md，产出 iOS 项目的注册登录页面规格
- 适配分析：对照 funde-client 的 Web 布局和 iOS 项目约束（UIKit + SnapKit + iOS 15.0），识别可复用与需改造的部分
- 不涉及代码实现——仅产出 spec 文档，代码实现在后续变更中完成

## Capabilities

### New Capabilities
- `register-login`: 注册/登录页面 UI 规范 — 布局结构、品牌区、表单区（验证码/密码双模式）、微信登录入口、老年模式适配、Token 映射

### Modified Capabilities
<!-- 无已有规范需要修改 -->

## Impact

- **PL/RegisterLogin/**: 后续代码实现将重写 `LoginViewController.swift`
- **BLL/RegisterLogin/**: 需新增登录业务逻辑 Service（验证码发送、登录验证、微信授权）
- **DAL/Networking/**: 需新增登录相关 API 端点
- **Other/Common/**: 需新增设计 Token（颜色、字号）的 UIColor/UIFont 扩展
- **无工程配置变更**：不涉及 Podfile、.xcodeproj、Info.plist 修改
