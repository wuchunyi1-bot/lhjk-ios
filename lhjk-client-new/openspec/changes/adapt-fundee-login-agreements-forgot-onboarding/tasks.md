# Tasks: adapt-fundee-login-agreements-forgot-onboarding

## 1. Spec

- [x] 1.1 proposal / design / register-login delta

## 2. 三协议 + 知情同意

- [x] 2.1 `AgreementCheckboxView` 三协议文案与第三链接回调
- [x] 2.2 `PrivacyPromptView` 补知情同意书
- [x] 2.3 新增 `AgreementConsentSheet`；`LoginViewController` 最终提交未勾选时弹出并重放动作
- [x] 2.4 获取验证码不再强制协议勾选

## 3. 忘记密码页内步骤

- [x] 3.1 `LoginViewModel` 增加 `forgot` / `resetPassword` 步骤与字段
- [x] 3.2 `LoginViewController` 页内 UI（对齐 LoginView.vue）
- [x] 3.3 拼图 → 发重置验证码；提交 `resetPassword`；成功回密码登录预填手机号
- [x] 3.4 登录入口改为页内步骤（独立 ForgotPassword VC 保留兼容）

## 4. 完善资料所属机构

- [x] 4.1 Onboarding UI：城市 → 所属机构行
- [x] 4.2 机构选择子页 + 回写名称/`hospitalId`
- [x] 4.3 提交写入 `patchLoginUserInfo(hospitalId:)`（资料 API 无 hospitalId 字段时仅本地门禁）
