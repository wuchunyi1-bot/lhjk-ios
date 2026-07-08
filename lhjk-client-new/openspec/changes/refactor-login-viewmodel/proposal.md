## Why

`LoginViewController` 当前 1058 行，是项目中最臃肿的 VC。它承载了：

- 双模式登录状态机（验证码/密码）
- 5+ API 调用（隐私版本、验证码、短信登录、密码登录、微信绑定）
- 拼图验证流程
- 隐私弹窗 + 通知权限引导
- 登录后流程编排（token 存储 → IM 连接 → onboarding 检查）
- 表单验证（手机号、验证码、密码）
- 所有 UI 布局 + 键盘 + Toast

同时也是 `.shared` 直调最多的 VC——`LoginService.shared`、`UserManager.shared`、`RongCloudManager.shared`、`APIManager.shared` 到处散落。

## What Changes

1. 新建 `PL/RegisterLogin/ViewModels/LoginViewModel.swift`
2. 重构 `PL/RegisterLogin/LoginViewController.swift` — 移出所有业务逻辑和 `.shared` 直调
3. VC 只保留 UI 布局、键盘处理、弹窗展示/隐藏、Toast

## Capabilities

- `register-login`: LoginViewModel 定义与 LoginViewController 重构

## Impact

- **PL/RegisterLogin/ViewModels/LoginViewModel.swift**: 新增（预计 ~300 行）
- **PL/RegisterLogin/LoginViewController.swift**: 瘦身（1058 → 预计 ~650 行）
- **无工程配置变更**
