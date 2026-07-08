## 1. Spec 文档

- [x] 1.1 创建 `openspec/changes/refactor-login-viewmodel/` 目录及 `.openspec.yaml`
- [x] 1.2 编写 `proposal.md` — 变更提案
- [x] 1.3 编写 `design.md` — 设计决策
- [x] 1.4 编写 `specs/register-login/spec.md` — LoginViewModel 定义与重构要求

## 2. LoginViewModel 实现

- [ ] 2.1 创建 `PL/RegisterLogin/ViewModels/LoginViewModel.swift`
- [ ] 2.2 实现状态管理（loginMode, isLoggingIn, flowStep, phoneNumber）
- [ ] 2.3 实现 API 封装（隐私检查、验证码、短信登录、密码登录）
- [ ] 2.4 实现登录成功编排（token 存储、IM 连接、onboarding 检查）
- [ ] 2.5 实现表单验证（手机号、验证码、密码）

## 3. LoginViewController 重构

- [ ] 3.1 移除所有业务逻辑方法
- [ ] 3.2 移除所有 `.shared` 直调
- [ ] 3.3 添加 `bindViewModel()` 订阅
- [ ] 3.4 保留 UI 布局、键盘处理、弹窗动画

## 4. 验证

- [ ] 4.1 编译验证：确保无编译错误
- [ ] 4.2 运行 `ruby generate_project.rb` 将新文件纳入 Xcode 项目
- [ ] 4.3 功能验证：短信登录、密码登录、隐私弹窗、通知引导流程完整
