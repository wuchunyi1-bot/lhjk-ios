## Context

funde-client（富德健康）是一个 Vue.js 移动端原型项目，已完成完整的设计系统（tokens.css + mobile.css）和注册登录页面（LoginView.vue）。当前 iOS 项目（lhjk-client）仅有最简 `LoginViewController.swift` 骨架，缺少品牌传递和完整登录体验。本设计文档分析如何将 funde-client 的注册登录布局适配到 iOS UIKit + SnapKit 项目。

## Reference Source Analysis

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
│  │  │ 手机号 / 账号                   │    ││
│  │  │ 📱 +86  | 请输入手机号         │    ││
│  │  └──────────────────────────────┘    ││
│  │  ┌──────────────────┬───────────┐    ││
│  │  │ 🛡 验证码 / 密码    │ 获取验证码  │    ││
│  │  └──────────────────┴───────────┘    ││
│  │  ┌──────────────────────────────┐    ││
│  │  │      登录 / 注册              │    ││
│  │  └──────────────────────────────┘    ││
│  │  使用账号密码登录 / 返回验证码登录      ││
│  │  登录即代表同意《用户协议》与《隐私政策》  ││
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
| Brand 区（Logo + 名称 + Slogan） | 垂直 UIStackView → SnapKit 约束，直接用 UILable + UIView 实现渐变方块 | 高 |
| 输入框结构（label + icon + input） | 自定义 `LoginFieldView`（UIView 子类），内含 icon UIImageView + UITextField | 高 |
| 验证码按钮（60s 倒计时） | UIButton + Timer，可用 `.primary-soft` 背景色 | 高 |
| 双模式切换 | UISegmentedControl 或自定义 toggle（参考 fd-segment 样式），控制两个 form stack 的 `isHidden` | 高 |
| 登录按钮（全宽、圆角、阴影） | UIButton + SnapKit，设置 backgroundColor / cornerRadius / shadow | 高 |
| 协议提示文字 | UILabel, attributedText 带链接（UITapGestureRecognizer） | 高 |
| 微信登录入口 + 授权弹层 | UIButton (floating) + UIAlertController / 自定义 Modal | 高 |

### 需要改造的部分 ⚠️

| funde-client 实现 | iOS 差异 | 适配方案 |
|-------------------|---------|---------|
| `min-height: 100vh` + flex column | iOS 无 vh 概念 | 使用 `view.safeAreaLayoutGuide` + scrollView 包裹 |
| CSS `:focus-within` 边框变色 | iOS 无 focus 伪类 | 使用 `UITextFieldDelegate` 的 `textFieldDidBeginEditing` 切换边框色 |
| `padding-top: 80px` 硬编码 | iOS 需适配刘海屏 | Brand 区 top 约束到 `view.safeAreaLayoutGuide.topAnchor` + 适当 offset |
| `van-icon` 图标 | iOS 无 Vant 组件库 | 使用 SF Symbols（系统）或 icon font / 自定义 icon 图片 |
| `van-action-sheet` (WeChat 弹层) | iOS 无 Vant UI | 自定义 Modal ViewController 或 UIAlertController |
| CSS box-shadow 多层阴影 | iOS layer.shadow 不支持多层 | 简化为单层阴影，保持视觉接近即可 |
| `var(--fd-*)` CSS 变量自动切换 | iOS 无法运行时切换全局 token | 通过 `TraitCollection` 或自定义 `AppearanceManager` 管理，监听 `UIContentSizeCategory` 变化联动老年模式 |
| 微信 SDK 集成 | funde-client 是 mock 演示 | iOS 需集成微信 OpenSDK，在 BLL 层封装 |

### 不可直接适配的部分 ❌

| funde-client 元素 | 原因 | 替代方案 |
|-------------------|------|---------|
| `data-senior="true"` CSS 变量联动 | iOS 不基于 CSS | 使用 `UIContentSizeCategory` + `UIAppearance` 或自定义 Theme 管理器 |
| `linear-gradient` 渐变背景 (Brand mark) | iOS 需用 CAGradientLayer | 创建 `GradientView` 自定义 UIView |
| `scrollbar-width: none` | iOS UIScrollView 原生隐藏滚动条（默认不显示） | 无需处理 |
| Vue `v-if` 条件渲染 | iOS 用 `isHidden` / `removeFromSuperview` | 直接对应 |

## Decisions

### 1. 布局方案：UIScrollView + UIStackView

**选择**: 使用 `UIScrollView` 作为根容器，内含垂直 `UIStackView` 分三段（Brand / Form / WeChat）。

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
- `BrandHeaderView`: Logo mark + 名称 + Slogan
- `LoginFieldView`: label + icon + textField（可配置为密码模式）
- `VerifyCodeButton`: 倒计时按钮
- `WechatLoginButton`: 微信登录浮动按钮
- `WechatAuthSheetView`: 微信授权底部弹层

**理由**: 模块化组件便于后续复用（如注册页复用 BrandHeaderView），也便于单独测试。

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

## Risks / Trade-offs

- **微信 SDK 依赖**: funde-client 是 mock 演示，实际 iOS 微信登录需集成微信 OpenSDK（需开发者在 Podfile 中添加 `WechatOpenSDK`）→ 本 spec 仅定义 UI 层，微信 SDK 集成在后续变更中处理
- **老年模式与 Dynamic Type**: iOS Dynamic Type 的放大系数与 funde-client 的 `data-senior` 放大比例不完全一致 → 可以接受微小差异，优先使用 iOS 原生方案
- **渐变 Logo Mark**: CAGradientLayer 需代码绘制，不能像 CSS 直接用 `linear-gradient` → 使用 `GradientView` 封装，复杂度可控

## Open Questions

- 是否需要在登录页增加「注册」入口独立页面？funde-client 当前设计是「登录即注册」（验证码登录自动创建账号），iOS 是否保持一致？
- 微信登录是否需要「首次绑定手机号」流程？（funde-client 流程中有实名认证环节）
- 是否需要 Apple Sign In (Sign in with Apple) 作为额外登录方式？
