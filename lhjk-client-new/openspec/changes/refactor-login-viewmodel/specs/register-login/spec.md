# RegisterLogin / 注册登录 — ViewModel

## Purpose

为 `LoginViewController` 引入 `LoginViewModel`，将登录状态机、API 调用、表单验证、流程编排从 ViewController 移至 ViewModel。同时移除 VC 中所有 `.shared` 直调。

> **Reference**: `PL/RegisterLogin/LoginViewController.swift`、`BLL/RegisterLogin/LoginService.swift`、`BLL/User/UserManager.swift`

---

## Requirements

### Requirement: LoginViewModel State Ownership

`LoginViewModel` SHALL 作为登录流程的**唯一状态持有者**。

#### Scenario: @Published 状态
- **WHEN** ViewModel 初始化
- **THEN** 包含以下 `@Published` 属性：
  - `loginMode: LoginMode` — `.sms` / `.password`（默认 `.sms`）
  - `isLoggingIn: Bool` — 是否正在请求中（防重复提交）
  - `needsPrivacyConsent: Bool` — 是否需要隐私弹窗（默认 true）
  - `phoneNumber: String` — 当前手机号（两个模式共享）
  - `flowStep: LoginFlowStep` — 流程步骤

### Requirement: LoginFlowStep 流程建模

#### Scenario: 流程步骤
- **WHEN** `LoginFlowStep` 被定义
- **THEN** 包含以下 case：
  - `.privacyCheck` — 正在检查隐私版本
  - `.privacyPrompt(PrivacyVersionInfo)` — 需要展示隐私弹窗
  - `.loginForm` — 登录表单就绪
  - `.captchaVerify(String)` — 正在拼图验证（关联手机号）
  - `.notificationGuide` — 通知权限引导
  - `.complete` — 登录完成

### Requirement: API 调用封装

ViewModel SHALL 封装所有 LoginService API 调用，VC 不直接访问任何 Service。

#### Scenario: 隐私检查
- **WHEN** `checkPrivacyConsent()` 被调用
- **THEN** 调用 `loginService.getPrivacyVersion()`
- **AND** 若最新版本 > 本地版本 → `flowStep = .privacyPrompt(info)`
- **AND** 若已同意 → `flowStep = .loginForm`

#### Scenario: 同意隐私
- **WHEN** `agreePrivacy(version:)` 被调用
- **THEN** 调用 `loginService.agreePrivacy(version:)`
- **AND** 持久化版本号到 UserDefaults
- **AND** `flowStep = .loginForm`

#### Scenario: 发送验证码
- **WHEN** `sendVerificationCode(phone:captchaToken:)` 被调用
- **THEN** 验证手机号格式（`^1[3-9]\d{9}$`）
- **AND** 调用 `loginService.sendVerificationCode(to:phone, type:.login)`
- **AND** 成功后更新 `smsRequestId`，通过 `toastPublisher` 发出"验证码已发送"

#### Scenario: 短信登录
- **WHEN** `loginBySMS(phone:code:)` 被调用
- **THEN** 验证手机号格式 + 验证码 6 位
- **AND** 设置 `isLoggingIn = true`
- **AND** 调用 `loginService.loginByPhone(phone, code:)`
- **AND** 成功后执行 `handleLoginSuccess(phone:result:)`

#### Scenario: 密码登录
- **WHEN** `loginByPassword(phone:password:)` 被调用
- **THEN** 验证手机号格式 + 密码 ≥ 6 位
- **AND** 设置 `isLoggingIn = true`
- **AND** 调用 `loginService.loginByPassword(phone, password:)`
- **AND** 成功后执行 `handleLoginSuccess(phone:result:)`

#### Scenario: 登录成功编排
- **WHEN** `handleLoginSuccess` 被调用
- **THEN** 执行以下操作：
  1. 持久化 Token：`APIManager.shared.setCredential(credential)`
  2. 存储手机号：`UserDefaults.standard.set(phone, forKey:)`
  3. 连接 IM：`rongCloudManager.fetchTokenAndConnect()`
  4. 检查 onboarding：`userManager.checkNeedOnboarding()`
  5. 若需要 onboarding → `presentOnboardingPublisher` 发出
  6. `navigateToHomePublisher` 发出
  7. `flowStep = .complete`

### Requirement: 表单验证

#### Scenario: 手机号验证
- **WHEN** `validatePhone(_:)` 被调用
- **THEN** 正则匹配 `^1[3-9]\d{9}$`
- **AND** 失败时通过 `toastPublisher` 发出"请输入正确的手机号"

#### Scenario: 验证码验证
- **WHEN** 短信登录提交
- **THEN** 验证码必须为 6 位数字
- **AND** 失败时发出"请输入 6 位验证码"

#### Scenario: 密码验证
- **WHEN** 密码登录提交
- **THEN** 密码至少 6 位
- **AND** 失败时发出"密码至少 6 位"

### Requirement: ViewController 零 .shared 直调

`LoginViewController` SHALL NOT 直接调用任何 Service 的 `.shared`。

#### Scenario: 移除的直调
- **WHEN** 完成重构
- **THEN** VC 中不出现以下代码：
  - `LoginService.shared.xxx`
  - `UserManager.shared.xxx`
  - `RongCloudManager.shared.xxx`
  - `APIManager.shared.xxx`

#### Scenario: 允许保留
- **WHEN** VC 需要导航
- **THEN** `Router.shared.push/present/setRoot` 可保留（Router 是框架级服务，非业务 Service）
- **WHEN** VC 需要读取 UserDefaults
- **THEN** `UserDefaults.standard.integer(forKey:)` 可保留（系统 API）

### Requirement: LoginViewController 重构

#### Scenario: 移除的代码
- **WHEN** 完成重构
- **THEN** 从 VC 移除：
  - `private let loginService = LoginService.shared`
  - `private var loginMode/isLoggingIn/smsRequestId/needsPrivacyConsent` 状态
  - `checkPrivacyConsent()` / `handlePrivacyAgree()` 方法
  - `handleRequestCode()` / `sendCode(phone:captchaToken:)` 方法
  - `submitBySMS()` / `submitByPassword()` 方法
  - `handleLoginSuccess()` / `navigateAfterLogin()` 方法
  - `validatePhone(_:)` 方法
  - `setLoggingIn(_:)` 方法
  - `handleWechatBinding()` / `showPhoneBindingRebind()` 方法
  - `requestNotificationPermission()` 中的 `loginService.reportNotificationPermission()` 调用

#### Scenario: 保留的代码
- **WHEN** 完成重构
- **THEN** 保留在 VC：
  - 所有 UI 布局（`setupUI()`，~300 行）
  - 键盘通知处理
  - `toggleMode()` + `updateModeUI(animated:)` 动画
  - `showCaptchaVerify` / `dismissCaptcha`
  - `showNotificationGuide` / `dismissNotificationGuide`
  - `showPrivacyPrompt` / `dismissPrivacyPrompt`
  - `showWechatSheet` / `dismissWechatSheet`
  - `showPhoneBinding` / `dismissPhoneBinding`
  - `showToast` + `openURL`
  - `getCurrentPhone()` — 从 UI 控件读值

#### Scenario: ViewModel 绑定
- **WHEN** `bindViewModel()` 被调用
- **THEN** 订阅 `$flowStep` → 根据步骤展示/隐藏对应弹窗
- **AND** 订阅 `$isLoggingIn` → 更新提交按钮状态
- **AND** 订阅 `toastPublisher` → 展示 Toast
- **AND** 订阅 `navigateToHomePublisher` → `Router.shared.setRoot("/")`
- **AND** 订阅 `presentOnboardingPublisher` → `Router.shared.present("/onboarding")`

## Acceptance Checklist

- [ ] `PL/RegisterLogin/ViewModels/LoginViewModel.swift` 创建
- [ ] VC 中无 `LoginService.shared` / `UserManager.shared` / `RongCloudManager.shared` / `APIManager.shared` 直调
- [ ] 隐私检查 → 同意 → 登录 → 导航流程完整可用
- [ ] 短信登录和密码登录均可正常工作
- [ ] 表单验证错误 Toast 正常展示
- [ ] VC 代码量从 ~1058 行降到 ~650 行
