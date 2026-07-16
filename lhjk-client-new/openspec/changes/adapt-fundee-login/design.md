## Context

funde-client（富德健康）是一个 Vue.js 移动端原型项目，已完成完整的设计系统（tokens.css + mobile.css）和注册登录 PRD（`用户注册与登录_v1.0.md`）。当前 iOS 项目（lhjk-client）仅有最简 `LoginViewController.swift` 骨架，缺少隐私授权、本机号识别、拼图验证、忘记密码、通知权限引导、登录态管理等完整登录体验。本设计文档分析如何将 funde-client 的注册登录完整链路适配到 iOS UIKit + SnapKit 项目。

## Reference Source Analysis

### funde-client PRD 核心流程

```
┌─────────────────────────────────────────────────────────────┐
│                     注册登录完整链路                           │
│                                                              │
│  打开 App ─→ 隐私弹窗 ─→ 登录页                                │
│                            │                                 │
│              ┌─────────────┼─────────────┐                   │
│              ▼             ▼             ▼                   │
│         验证码登录      密码登录      微信登录                   │
│              │             │             │                   │
│         本机号识别      手机号+密码    微信授权                  │
│              │             │             │                   │
│         拼图验证        协议勾选      绑定手机号?               │
│              │             │             │                   │
│         发送验证码      提交登录      冲突处理                  │
│              │             │             │                   │
│         验证码校验       ──┴──          ──┴──                  │
│              │                                               │
│         登录成功 ──→ 通知权限预引导 ──→ redirect?/home         │
│                                                              │
│  分支流程: 忘记密码、登录过期、账号冻结、注销中                    │
└─────────────────────────────────────────────────────────────┘
```

### funde-client LoginView.vue 布局结构

```
┌──────────────────────────────────────────┐
│              登录页 (full-screen)          │
│  ┌──────────────────────────────────────┐│
│  │  Brand 区 (padding-top: 80px)        ││
│  │  ┌──────┐                            ││
│  │  │ 富德 │  72×72 渐变圆角方块          ││
│  │  └──────┘                            ││
│  │  富德健康     (22px bold)              ││
│  │  全生命周期... (13px muted)            ││
│  └──────────────────────────────────────┘│
│  ┌──────────────────────────────────────┐│
│  │  Form 区                              ││
│  │  ┌──────────────────────────────┐    ││
│  │  │ 脱敏本机号: 156****8923       │    ││
│  │  │ [使用其他手机号]              │    ││
│  │  └──────────────────────────────┘    ││
│  │  ┌──────────────────┬───────────┐    ││
│  │  │ 🛡 验证码         │ 获取验证码  │    ││
│  │  └──────────────────┴───────────┘    ││
│  │  ┌──────────────────────────────┐    ││
│  │  │ ☐ 同意《用户协议》与《隐私政策》 │    ││
│  │  └──────────────────────────────┘    ││
│  │  ┌──────────────────────────────┐    ││
│  │  │      登录 / 注册              │    ││
│  │  └──────────────────────────────┘    ││
│  │  使用账号密码登录 / 返回验证码登录      ││
│  │  忘记密码                             ││
│  └──────────────────────────────────────┘│
│  ┌──────────────────────────────────────┐│
│  │  WeChat 区                            ││
│  │       ┌────┐                          ││
│  │       │ 💬 │  (Floating circle btn)   ││
│  │       └────┘                          ││
│  └──────────────────────────────────────┘│
└──────────────────────────────────────────┘
```

### funde-client Design Tokens 关键值

| 类别 | Token | Web 值 | iOS 等价 |
|------|-------|--------|---------|
| 主色 | `--fd-color-primary` | `#FF7A50` | `UIColor(hex: "#FF7A50")` |
| 主色深 | `--fd-color-primary-deep` | `#E55A2E` | 按下态 |
| 主色浅 | `--fd-color-primary-soft` | `#FFF3EE` | 浅橙背景 |
| 背景 | `--fd-color-bg` | `#FDF6F3` | view.backgroundColor |
| 卡片面 | `--fd-color-surface` | `#FFFFFF` | 输入框背景 |
| 文字主 | `--fd-color-text` | `#1F2430` | 标题/正文 |
| 文字辅 | `--fd-color-subtext` | `#6B7280` | 标签 |
| 文字弱 | `--fd-color-muted` | `#9AA0AC` | 提示/协议 |
| 边框 | `--fd-color-border` | `#ECE4DD` | 输入框边框 |
| 大标题 | `--fd-h1` | 28px → 34px (senior) | ~28pt → 34pt |
| 标题 | `--fd-h2` | 22px → 26px (senior) | ~22pt → 26pt |
| 正文 | `--fd-body` | 15px → 19px (senior) | ~15pt → 19pt |
| 说明 | `--fd-caption` | 13px → 16px (senior) | ~13pt → 16pt |
| 最小 | `--fd-micro` | 11px → 14px (senior) | ~11pt → 14pt |
| 圆角小 | `--fd-radius-sm` | 12px | 12pt |
| 圆角中 | `--fd-radius-md` | 18px | 18pt |
| WeChat 绿 | — | `#07C160` | 微信品牌色 |

## Adaptation Analysis

### 可直接适配的部分 ✅

| funde-client 元素 | iOS 适配方案 | 置信度 |
|-------------------|-------------|--------|
| 全屏布局 (无 tabbar) | `LoginViewController` 以 modal 或 root 方式 present，无需 `fd-screen` 的 tabbar 高度计算 | 高 |
| Brand 区（Logo + 名称 + Slogan） | 垂直 UIStackView → SnapKit 约束，直接用 UILable + UIView 实现品牌色方块 | 高 |
| 输入框结构（label + icon + input） | 自定义 `LoginFieldView`（UIView 子类），内含 icon UIImageView + UITextField | 高 |
| 验证码按钮（60s 倒计时） | UIButton + Timer，可用 `.primary-soft` 背景色 | 高 |
| 双模式切换 | 自定义 toggle（参考 fd-segment 样式），控制两个 form stack 的 `isHidden` | 高 |
| 登录按钮（全宽、圆角、阴影） | UIButton + SnapKit，设置 backgroundColor / cornerRadius / shadow | 高 |
| 协议勾选框 + 链接文字 | UIView 包裹 UIButton(checkbox) + UILabel(attributedText 带链接) | 高 |
| 微信登录入口 + 授权弹层 | UIButton (floating) + 自定义 Modal VC | 高 |
| 隐私保护提示弹窗 | 自定义 Modal VC，含协议链接和双按钮 | 高 |
| 通知权限预引导弹窗 | 自定义 Modal VC，含引导文案和双按钮 | 高 |
| 忘记密码页面 | 独立 VC / 在登录页内切换，含手机号 → 拼图 → 验证码 → 新密码流程 | 高 |

### 需要改造的部分 ⚠️

| funde-client 实现 | iOS 差异 | 适配方案 |
|-------------------|---------|---------|
| `min-height: 100vh` + flex column | iOS 无 vh 概念 | 使用 `view.safeAreaLayoutGuide` + scrollView 包裹 |
| CSS `:focus-within` 边框变色 | iOS 无 focus 伪类 | 使用 `UITextFieldDelegate` 的 `textFieldDidBeginEditing` 切换边框色 |
| `padding-top: 80px` 硬编码 | iOS 需适配刘海屏 | Brand 区 top 约束到 `view.safeAreaLayoutGuide.topAnchor` + 适当 offset |
| `van-icon` 图标 | iOS 无 Vant 组件库 | 使用 SF Symbols（系统）或 icon font / 自定义 icon 图片 |
| `van-action-sheet` (WeChat 弹层) | iOS 无 Vant UI | 自定义 Modal ViewController |
| `van-dialog` (隐私弹窗) | iOS 无 Vant UI | 自定义 Modal ViewController 或 UIAlertController |
| CSS box-shadow 多层阴影 | iOS layer.shadow 不支持多层 | 简化为单层阴影，保持视觉接近即可 |
| `var(--fd-*)` CSS 变量自动切换 | iOS 无法运行时切换全局 token | 通过 `TraitCollection` 或自定义 `AppearanceManager` 管理 |
| 微信 SDK 集成 | funde-client 是 mock 演示 | iOS 需集成微信 OpenSDK，在 BLL 层封装 |
| 运营商本机号获取 | funde-client 是 mock 演示 | V1.0 使用 mock，V1.1 接入真实运营商 SDK |
| 拼图验证服务 | funde-client 是 mock 演示 | V1.0 使用 mock captcha_token，V1.1 接入真实服务 |

### 不可直接适配的部分 ❌

| funde-client 元素 | 原因 | 替代方案 |
|-------------------|------|---------|
| `data-senior="true"` CSS 变量联动 | iOS 不基于 CSS | 使用 `UIContentSizeCategory` + `UIAppearance` 或自定义 Theme 管理器 |
| `linear-gradient` 渐变背景 (Brand mark) | iOS 需用 CAGradientLayer | 创建 `GradientView` 自定义 UIView |
| `scrollbar-width: none` | iOS UIScrollView 原生隐藏滚动条（默认不显示） | 无需处理 |
| Vue `v-if` 条件渲染 | iOS 用 `isHidden` / `removeFromSuperview` | 直接对应 |
| 后端接口契约 | PRD 中接口名称为自动生成 | 忽略 PRD 中的接口名称，iOS BLL 层自行定义协议，后续对接真实后端接口 |

## Decisions

### 1. 布局方案：UIScrollView + UIStackView

**选择**: 使用 `UIScrollView` 作为根容器，内含垂直 `UIStackView` 分多段（Privacy / Brand / Form / WeChat / Notification）。

**理由**: 键盘弹出时需要内容可滚动避免遮挡；StackView 自动处理子视图间距，减少手动约束代码。

### 2. 颜色 Token 管理：UIColor 扩展

**选择**: 创建 `UIColor+Theme.swift` 扩展，定义所有 funde-client 颜色 Token 为静态属性。

```swift
extension UIColor {
    static let fdPrimary = UIColor(hex: "#FF7A50")
    static let fdBg = UIColor(hex: "#FDF6F3")
    // ...
}
```

**理由**: 统一管理颜色，后续可扩展深色模式 / 老年模式自适应。

### 3. 老年模式方案：UIContentSizeCategory 联动

**选择**: 字号使用 `UIFont.preferredFont(forTextStyle:)` 配合 Dynamic Type，老年模式通过覆盖 `traitCollection.preferredContentSizeCategory` 实现全局放大。

**理由**: 利用 iOS 原生 Dynamic Type 机制，比手动管理字号映射更健壮；系统设置中的「辅助功能→更大字体」直接联动。

### 4. 组件化拆分

**选择**: 页面拆分为以下可复用组件（PL 层）：
- `PrivacyPromptView`: 隐私保护提示弹窗（新增）
- `BrandHeaderView`: Logo mark + 名称 + Slogan
- `LoginFieldView`: label + icon + textField（可配置为密码模式）
- `VerifyCodeButton`: 倒计时按钮
- `CaptchaVerifyView`: 拼图滑块验证弹窗（新增）
- `AgreementCheckboxView`: 协议勾选框 + 富文本链接（新增）
- `ForgotPasswordView`: 忘记密码页（新增）
- `NotificationGuideView`: 通知权限预引导弹窗（新增）
- `PhoneBindingView`: 微信手机号绑定弹层（新增）
- `WechatLoginButton`: 微信登录浮动按钮
- `WechatAuthSheetView`: 微信授权底部弹层

**理由**: 模块化组件便于后续复用，也便于单独测试。

### 5. 图标方案：SF Symbols

**选择**: 优先使用 Apple SF Symbols 系统图标替代 funde-client 的 mingcute / van-icon。

| funde icon | SF Symbol |
|-----------|-----------|
| `phone-o` | `phone` |
| `shield-o` | `shield` |
| `contact-o` | `person.crop.circle` |
| `lock` | `lock` |
| `eye-o` / `closed-eye` | `eye` / `eye.slash` |
| `wechat` | 自定义 icon（微信品牌色 #07C160 的圆角图） |

**理由**: SF Symbols 随系统安装，无需额外依赖；支持 Dynamic Type 字号自适应。

### 6. 隐私授权流程

**选择**: 登录页展示前先检查本地隐私协议版本号，与后端最新版本比较。未同意或版本过期则展示隐私弹窗，不同意则展示不可用状态页。

**理由**: 合规要求（《个人信息保护法》），必须在收集手机号前取得用户对隐私政策的明确同意。

### 7. 本机号识别策略

**选择**: V1.0 使用 mock 本机号数据（预设测试手机号）；V1.1 接入真实运营商 SDK。本机号获取失败时静默降级为手动输入模式，不阻塞登录流程。

**理由**: 运营商 SDK 有覆盖率限制（无 SIM、双卡、网络异常等），需要优雅降级。Mock 模式确保原型可完整演示。

### 8. 拼图验证集成

**选择**: 发送验证码前弹出拼图滑块验证，通过后获取一次性 `captcha_token` 随验证码请求发送后端二次校验。

**理由**: 防止短信接口被恶意滥用，降低短信成本。`captcha_token` 一次性消费、有效期 2 分钟。

### 9. 协议勾选改为主动勾选

**选择**: PRD 要求协议勾选为主动复选框（而非文案中隐含同意），所有登录/绑定提交前校验勾选状态。

**理由**: 合规要求，用户需主动明示同意。PRD 中明确未勾选协议不能获取验证码或提交任何登录。

### 10. 通知权限预引导

**选择**: 登录成功后先展示 App 内预引导弹窗（说明通知价值），用户点击「去开启」后再调用系统权限弹窗；「暂不开启」则跳过。允许/拒绝均不阻塞进入首页。

**理由**: iOS 系统权限弹窗只弹一次，预引导可显著提高通知允许率（PRD 目标 ≥ 50%）。不阻塞首页是 PRD 明确要求。

### 11. 登录后 redirect/deeplink 处理

**选择**: 登录成功后检查 redirect/deeplink 参数，仅允许 App 内白名单路径。非法目标回退 `/home`。登录过期时自动携带当前页面路径为 redirect。

**理由**: PRD 明确要求支持推送/短信深链跳转和登录过期回跳。白名单机制防止 open redirect 安全漏洞。

## Risks / Trade-offs

- **微信 SDK 依赖**: funde-client 是 mock 演示，实际 iOS 微信登录需集成微信 OpenSDK（需开发者在 Podfile 中添加 `WechatOpenSDK`）→ 本 spec 仅定义 UI 层，微信 SDK 集成在后续变更中处理
- **运营商 SDK 依赖**: 本机号获取需运营商能力，V1.0 使用 mock → V1.1 接入真实 SDK 时需评估覆盖率
- **拼图验证服务依赖**: V1.0 使用 mock captcha_token → V1.1 接入真实验证服务
- **老年模式与 Dynamic Type**: iOS Dynamic Type 的放大系数与 funde-client 的 `data-senior` 放大比例不完全一致 → 可以接受微小差异，优先使用 iOS 原生方案
- **渐变 Logo Mark**: CAGradientLayer 需代码绘制，不能像 CSS 直接用 `linear-gradient` → 使用 `GradientView` 封装，复杂度可控
- **多设备登录**: V1.0 允许多设备不踢出，可能增加客服咨询量（账号共享）→ 后续版本可增加设备管理和踢出策略
- **接口契约**: PRD 中的接口名称为自动生成，不可直接使用。iOS BLL 层自行定义协议，与后端协商后确定真实接口

## Open Questions

- 是否需要在登录页增加「注册」入口独立页面？funde-client PRD 设计是「登录即注册」（验证码登录自动创建账号），iOS 保持一致
- 微信登录是否需要「首次绑定手机号」流程？PRD 中有完整绑定 + 换绑冲突处理流程
- 是否需要 Apple Sign In (Sign in with Apple) 作为额外登录方式？PRD 未提及，可后续评估
- 登录态有效期和"长时间未登录"的具体天数？PRD 标注 [待确认]，由后端安全策略定义
- 账号冻结/注销中是否需要展示客服入口或申诉入口？PRD 标注 [待确认]
- 新设备登录提醒的推送通道？PRD 标注 [待确认：提醒通道]

## Onboarding (新增 2026-06-16, 重写 2026-06-25)

### 12. Onboarding 架构：单页表单

**选择 (2026-06-25 更新)**: 对齐 funde-client PRD §5.10 和实际 `OnboardingView.vue` 实现，改为单页表单。4 个字段（姓名 / 出生日期 / 性别 / 所在城市）垂直排列在 UIScrollView 中，固定底部「保存并继续」按钮。

**理由**: PRD §5.10 明确说明「该引导页不等同于健康档案，不采集身份证、详细地址、疾病史、保单等重信息」。原 4 步向导（健康史 / 生活习惯 / 团队见面）属于健康档案范畴，应拆到我的 / 健康档案中单独承接。单页表单减少步骤间的认知负担，更符合 50-70 岁目标用户。

**旧设计 (已废弃)**: 使用单个 `OnboardingViewController`，内部通过 `currentStep` 状态变量控制 4 个步骤的 UI 切换。

### 13. 展示判断：checkNeedOnboarding()

**选择 (2026-07-16 修订)**: 门禁主体为登录 token 返回的 `userInfo`（持久化 `loginUserInfo`），检查 `chineseName`、`sex`、`birthday`、`hospitalId`。**不再**调用 `getCurrentUserBaseInfo`。详见 `onboarding-login-userinfo`。

**理由**: 本地 flag 无法应对服务端数据被清空/回滚的场景。API 数据是真实的用户状态，比本地缓存更可靠。`fd_onboarded` 已从代码中完全移除。

### 14. Chip 组件：OptionChipView

**选择**: 复用 `OptionChipView` + `OptionChipGroup`（单选模式），用于性别选择。

**理由**: 组件已存在，单选模式下直接满足需求。旧设计中 4 组 chip 的需求已随步骤简化而减少。

### 15. Onboarding 完成后的导航

**选择**: Onboarding 完成后 `dismiss(animated: true)`，回到已有的 TabBarController。

**理由**: OnboardingViewController 是 fullScreen present 在 TabBar 之上的。引导完成后 dismiss，用户自然回到已有 TabBar 的主页 Tab。不需要也不应该替换 root VC，否则会销毁 TabBar 结构。
