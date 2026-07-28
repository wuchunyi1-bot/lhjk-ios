## Context

参考 funde-client：
- `prototype/src/views/auth/LoginView.vue` — 三协议、知情同意 sheet、`step: login|forgot|reset-password`
- `prototype/src/views/auth/ProfileSetupView.vue` — 所属机构
- `MobileApp.vue` — 前置隐私三协议

现有 iOS：`AgreementCheckboxView`（两协议）、`ForgotPasswordViewController`（独立页）、`OnboardingViewController`（城市字段）。

## Goals / Non-Goals

**Goals:**
- 三协议 + 知情同意弹窗对齐 PRD AUTH-06
- 忘记密码页内步骤对齐 PRD AUTH-08 / funde LoginView
- Onboarding 所属机构绑定真实 `hospitalId`（无假 id）

**Non-Goals:**
- 微信登录、单设备、登录过期全局弹窗（本期不做）
- 业务经理选填（可后续）

## Decisions

1. **知情同意弹窗**：`AgreementConsentSheet`（底部或居中卡片），存 `pendingAction`；同意后勾选并重放原提交。获取验证码不强制勾选（对齐 PRD）。
2. **忘记密码**：`LoginViewModel.Step` = `login | forgot | resetPassword`；拼图复用 `CaptchaVerifyView`；提交调 `LoginService.resetPassword`；成功切回密码登录并预填手机号。独立 `ForgotPasswordViewController` 可保留但登录入口改为页内步骤。
3. **所属机构**：完善页第四项改为机构选择行 → push 机构列表（复用 HospitalService / 已有选机构能力）；选中回写名称 + `hospitalId`；提交 `patchLoginUserInfo(hospitalId:)` + 资料 API（若 API 支持则传，否则至少本地门禁字段写入）。禁止硬编码假 hospitalId。

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| 机构列表接口参数不明 | 复用现有 `HospitalService` / 机构切换已用接口 |
| 资料 API 无 hospitalId 字段 | 先写 loginUserInfo 满足门禁；API 字段以文档为准 |
| 协议正式 URL 未定 | 沿用现有 Router WebView 占位路径，三协议均可点 |

## Open Questions

- 知情同意书正式 URL / 版本号（产品确认前用占位路由）
