## Why

当前 iOS 项目的注册/登录页面 (`LoginViewController.swift`) 仅有一个最简骨架——手机号 + 验证码 + 蓝色登录按钮，缺少品牌标识、多登录方式切换、微信登录入口、隐私授权、拼图验证、忘记密码、通知权限引导、登录态管理等核心功能。

平行项目 funde-client 已产出一套完整的注册登录 PRD（`用户注册与登录_v1.0.md`），经多角色评审（SPACE-prd-writer + deepseek），覆盖了：

- 隐私保护提示（首次打开/协议更新）
- 本机手机号一键识别 + 手动输入降级
- 拼图滑块真人验证（防短信滥用）
- 双模式登录（验证码 / 密码）+ 忘记密码
- 协议主动勾选（合规要求）
- 微信授权登录 + 手机号绑定 + 换绑冲突处理
- 推送通知权限预引导
- 登录后 redirect/deeplink 目标页还原
- 登录过期、账号冻结、注销中等异常状态
- 30 条详细错误提示文案与触发规则
- 多设备登录 + 新设备安全提醒
- 完整的适老化交互规则

本变更的目标是**将 funde-client PRD 的注册登录完整需求沉淀为 iOS 项目的 OpenSpec 规范**，并评估其在 iOS UIKit 项目中的适配方案。

## What Changes

- 更新 `register-login` spec：参考 funde-client PRD + LoginView.vue + tokens.css + design-system.md，大幅扩充 iOS 项目注册登录页面规格，新增 10+ 个 Requirement
- 更新 design.md：新增隐私授权流程、本机号识别策略、拼图验证集成、协议主动勾选、通知权限预引导、redirect/deeplink 处理等设计决策
- 更新 tasks.md：新增 10 个大类、40+ 个子任务，覆盖完整实现路径
- 不涉及代码实现——仅产出/更新 spec 文档，代码实现在后续变更中完成

## Capabilities

### New Capabilities
（在已有 `register-login` spec 基础上大幅扩充，新增以下 Requirement）
- 隐私保护提示（PrivacyPromptView）
- 本机手机号检测与脱敏展示
- 拼图滑块真人验证（CaptchaVerifyView）
- 协议主动勾选（AgreementCheckboxView）
- 忘记密码完整流程（ForgotPasswordView）
- 微信绑定手机号 + 换绑冲突处理（PhoneBindingView）
- 推送通知权限预引导（NotificationGuideView）
- 登录后 redirect/deeplink 处理
- 登录过期 / 账号冻结 / 注销中状态管理
- 多设备登录 + 新设备安全提醒
- 全局异常处理 + 30 条错误提示触发规则

### Modified Capabilities
- `register-login`: spec 从 ~400 行扩充至 ~550 行，新增 10 个 Requirement，更新已有 10 个 Requirement

## Impact

- **PL/RegisterLogin/**: 后续代码实现将重写 `LoginViewController.swift`，并新增 10+ 个组件
- **BLL/RegisterLogin/**: 需新增完整登录业务逻辑 Service（隐私版本、本机号、验证码发送与校验、密码登录、微信授权与绑定、重置密码、会话状态、通知权限）
- **DAL/Networking/**: 需新增登录相关 API 端点（接口名称以真实后端为准，PRD 中接口名称为自动生成仅供参考）
- **Other/Common/**: 需新增设计 Token（颜色、字号）的 UIColor/UIFont 扩展
- **无工程配置变更**：不涉及 Podfile、.xcodeproj、Info.plist 修改
