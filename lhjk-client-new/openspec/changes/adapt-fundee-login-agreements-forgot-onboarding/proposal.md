## Why

对齐 PRD《01_用户_用户注册与登录》与 funde `LoginView.vue` / `ProfileSetupView.vue`：登录侧仍为双协议 + Toast、忘记密码为独立页、完善资料缺「所属机构/`hospitalId`」，门禁与 UI 不一致。

## What Changes

- 三协议勾选（用户协议、隐私政策、健康管理服务知情同意书）+ 未勾选时「知情同意」弹窗（同意并继续 / 稍后再看）
- 前置隐私弹窗补知情同意书入口
- 忘记密码改为登录页内步骤（找回验证码 → 设置新密码 → 回密码登录预填手机号）
- 完善资料：所属机构选择写入 `hospitalId`，提交后写入 `loginUserInfo`

## Capabilities

### New Capabilities

- （无独立新 capability；以 delta 修改既有 `register-login`）

### Modified Capabilities

- `register-login`: 三协议与知情同意弹窗、忘记密码页内步骤、Onboarding 所属机构/`hospitalId`

## Impact

- PL：`AgreementCheckboxView`、`PrivacyPromptView`、知情同意弹窗、`LoginViewController`/`LoginViewModel`、`OnboardingViewController`、机构选择页
- BLL：`LoginService.resetPassword` 接线；Onboarding 提交写 `hospitalId`
- 路由：弱化独立 `/forgot-password` 入口（可保留兼容）
