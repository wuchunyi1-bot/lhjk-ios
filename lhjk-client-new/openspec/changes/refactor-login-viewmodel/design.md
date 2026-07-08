## Context

`LoginViewController` 是项目中最复杂的 VC，1058 行囊括了完整登录流程的所有逻辑。本次抽取 `LoginViewModel` 遵循已有的 ViewModel 模式（`ObservableObject` + `@Published` + `PassthroughSubject`），同时执行"VC 不再直接调 `.shared`"的要求。

> **Related**: `openspec/changes/extract-viewmodels/`、`openspec/changes/introduce-appcontainer/`

## Decisions

### 1. LoginViewModel 职责边界

| 移到 LoginViewModel | 留在 LoginViewController |
|---|---|
| `loginMode`, `isLoggingIn`, `smsRequestId` 状态 | UI 布局（所有 SnapKit 约束） |
| `needsPrivacyConsent` 隐私状态 | 键盘处理 |
| 所有 `loginService.*` API 调用 | 弹窗展示/隐藏（PrivacyPromptView、CaptchaVerifyView 等） |
| `validatePhone(_:)` 验证逻辑 | 模式切换 UI 动画（`updateModeUI`） |
| 登录成功后的流程编排 | Toast 展示 |
| 通知权限上报 | 文本字段读取（`getCurrentPhone`） |
| 隐私版本检查 + 同意 | WeChat Sheet 动画 |

### 2. 一次性事件用 PassthroughSubject

登录成功后的导航、Toast 消息等一次性事件通过 Publisher 发出：

```swift
let toastPublisher = PassthroughSubject<String, Never>()
let navigateToHomePublisher = PassthroughSubject<Void, Never>()
let presentOnboardingPublisher = PassthroughSubject<Void, Never>()
let dismissKeyboardPublisher = PassthroughSubject<Void, Never>()
```

### 3. 流程步骤用 enum 建模

```swift
enum LoginFlowStep {
    case privacyCheck          // 检查隐私版本
    case privacyPrompt(PrivacyVersionInfo)  // 展示隐私弹窗
    case loginForm             // 登录表单
    case captchaVerify         // 拼图验证
    case notificationGuide     // 通知权限引导
    case complete              // 登录完成，等待导航
}
```

### 4. 去掉所有 `.shared` 直调

VC 中所有的 `LoginService.shared`、`UserManager.shared`、`RongCloudManager.shared`、`APIManager.shared` 全部移除。VC 只通过以下方式获取数据：

- 调用 `viewModel.xxx()` 方法触发操作
- 订阅 `viewModel.$xxx` 响应状态变化
- 订阅 `viewModel.xxxPublisher` 响应一次性事件

### 5. 依赖注入

```swift
init(loginService: LoginService = AppContainer.shared.loginService,
     userManager: UserManager = AppContainer.shared.userManager,
     rongCloudManager: RongCloudManager = AppContainer.shared.rongCloudManager)
```

### 6. VC 保留的 UIKit 特有逻辑

以下逻辑不属于 ViewModel，留在 VC：
- 键盘通知监听 + ScrollView contentInset 调整
- `UILongPressGestureRecognizer`（语音按钮预留）
- `UIAlertController`（Toast）
- 弹窗视图的 add/remove + 动画
- 文本字段文字提取（`getCurrentPhone`、密码/验证码字段值）
- `UIView.animate` 模式切换动画
