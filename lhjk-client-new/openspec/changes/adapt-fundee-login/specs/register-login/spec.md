# Register & Login

## Purpose

定义注册/登录页面的 UI 布局、交互行为和适配规则。参考 funde-client（富德健康）`LoginView.vue` + `design-system.md` 的设计规范，通过 UIKit + SnapKit 将其适配到 iOS 项目。

页面提供**验证码登录**（默认）和**密码登录**两种方式，支持微信第三方登录入口，并适配老年模式（大字号）。

> **Reference**: funde-client `/prototype/src/views/auth/LoginView.vue`、`/prototype/src/styles/tokens.css`、`/docs/design/design-system.md`

---

## Layout Architecture

页面布局采用全屏滚动结构（无 Tab Bar），从上到下分为三个区域：

```
┌──────────────────────────────────────────┐
│            UIScrollView                   │
│  ┌──────────────────────────────────────┐│
│  │         BrandHeaderView              ││
│  │  ┌──────┐  Logo Mark (72×72)        ││
│  │  │ 品牌 │  渐变色方块 + 白色文字       ││
│  │  └──────┘                            ││
│  │  富德健康      (appName, 22pt bold)   ││
│  │  全生命周期... (tagline, 13pt muted)  ││
│  └──────────────────────────────────────┘│
│  ┌──────────────────────────────────────┐│
│  │          Form Area                   ││
│  │  ┌──────────────────────────────┐    ││
│  │  │ LoginFieldView (phone)       │    ││
│  │  │ label: "手机号"               │    ││
│  │  │ icon + TextField              │    ││
│  │  └──────────────────────────────┘    ││
│  │  ┌──────────────────┬───────────┐    ││
│  │  │ LoginFieldView   │ VerifyCode│    ││
│  │  │ label: "验证码"   │ Button    │    ││
│  │  │ icon + TextField  │ 获取验证码  │    ││
│  │  └──────────────────┴───────────┘    ││
│  │         ---  或 密码模式  ---          ││
│  │  ┌──────────────────────────────┐    ││
│  │  │ LoginFieldView (username)    │    ││
│  │  │ label: "账号"                │    ││
│  │  └──────────────────────────────┘    ││
│  │  ┌──────────────────────────────┐    ││
│  │  │ LoginFieldView (password)    │    ││
│  │  │ label: "密码"                │    ││
│  │  │ 含 show/hide toggle           │    ││
│  │  └──────────────────────────────┘    ││
│  │  ┌──────────────────────────────┐    ││
│  │  │     Submit Button            │    ││
│  │  │     "登录 / 注册" 或 "密码登录"  │    ││
│  │  └──────────────────────────────┘    ││
│  │  使用账号密码登录 / 返回验证码登录      ││
│  │  登录即代表同意《用户协议》与《隐私政策》  ││
│  └──────────────────────────────────────┘│
│  ┌──────────────────────────────────────┐│
│  │        WeChat Area                   ││
│  │        ┌────┐                        ││
│  │        │ 💬 │  (52×52 浮动圆形按钮)    ││
│  │        └────┘                        ││
│  │  → tap 弹出 WechatAuthSheet          ││
│  └──────────────────────────────────────┘│
└──────────────────────────────────────────┘
```

---

## Requirements

### Requirement: Full-Screen Layout
登录页 SHALL 以全屏方式展示，不显示底部 Tab Bar。

#### Scenario: 页面展示方式
- **WHEN** 用户未登录时访问需要登录的页面
- **THEN** 系统 `present` LoginViewController 为全屏 modal（`modalPresentationStyle = .fullScreen`），或通过 SceneDelegate 设置为 root ViewController

#### Scenario: 键盘弹起
- **WHEN** 用户点击输入框导致键盘弹出
- **THEN** UIScrollView 自动调整 contentInset，确保当前输入框不被键盘遮挡

#### Scenario: 背景色
- **WHEN** 登录页渲染
- **THEN** 页面背景色 SHALL 为 `UIColor.fdBg`（对应 funde-client `#FDF6F3` 暖米底色）

---

### Requirement: Brand Header
登录页顶部 SHALL 展示品牌标识区域，包含 Logo Mark、应用名称、Slogan。

#### Scenario: Logo Mark
- **WHEN** 页面渲染品牌区
- **THEN** 展示 72×72pt 的 Logo Mark（圆角 22pt），背景使用品牌渐变（`#FFB48A` → `#FF7A50` → `#F25E36`），居中显示品牌简称文字（白色、22pt、bold）

#### Scenario: App Name
- **WHEN** 页面渲染品牌区
- **THEN** Logo Mark 下方 16pt 处展示应用名称（22pt、bold、`UIColor.fdText`），对应 funde-client `LoginView.vue` 中的 `login-brand__name`

#### Scenario: Slogan
- **WHEN** 页面渲染品牌区
- **THEN** 应用名称下方 6pt 处展示 Slogan（13pt、`UIColor.fdSubtext`），对应 `login-brand__tagline`

#### Scenario: Brand 区顶部间距
- **WHEN** 页面渲染品牌区
- **THEN** Brand 区顶部与 safeAreaLayoutGuide.topAnchor 间距为 80pt（适配刘海屏后实际偏移 ≈ 36pt below safe area）

---

### Requirement: Login Mode Switching
登录页 SHALL 支持验证码登录和密码登录两种模式，默认展示验证码登录。

#### Scenario: 默认模式
- **WHEN** 用户首次进入登录页
- **THEN** 展示验证码登录模式（手机号 + 验证码 + 获取验证码按钮）

#### Scenario: 切换到密码登录
- **WHEN** 用户点击「使用账号密码登录」
- **THEN** 表单切换为密码模式（账号 + 密码），验证码相关输入框隐藏，密码相关输入框显示

#### Scenario: 切换回验证码登录
- **WHEN** 用户在密码模式下点击「返回验证码登录」
- **THEN** 表单切换回验证码模式

#### Scenario: 提交按钮文案
- **WHEN** 验证码模式下
- **THEN** 提交按钮显示「登录 / 注册」
- **WHEN** 密码模式下
- **THEN** 提交按钮显示「密码登录」

---

### Requirement: Phone Number Field (SMS Mode)
验证码模式下 SHALL 展示手机号输入框。

#### Scenario: 输入框结构
- **WHEN** 验证码模式激活
- **THEN** 展示 `LoginFieldView`，label 为「手机号」、左侧 icon 为 SF Symbol `phone`、placeholder 为「请输入手机号」、keyboardType 为 `.phonePad`、maxLength 为 11

#### Scenario: 输入框样式
- **WHEN** 输入框处于默认状态
- **THEN** 高度 48pt、背景色 `UIColor.fdSurface`（白色）、边框 1pt `UIColor.fdBorder`（`#ECE4DD`）、圆角 12pt

#### Scenario: 输入框聚焦态
- **WHEN** 输入框获得焦点 (becomeFirstResponder)
- **THEN** 边框色变为 `UIColor.fdPrimary`（`#FF7A50`），附带 3pt 宽度 brand color 弱阴影

---

### Requirement: Verification Code Field (SMS Mode)
验证码模式下 SHALL 展示验证码输入框及获取验证码按钮，两者水平并排。

#### Scenario: 输入框结构
- **WHEN** 验证码模式激活
- **THEN** 展示 `LoginFieldView`（flexible width），label 为「验证码」、左侧 icon 为 SF Symbol `shield`、placeholder 为「请输入验证码」、keyboardType 为 `.numberPad`、maxLength 为 6

#### Scenario: 获取验证码按钮（默认态）
- **WHEN** 用户尚未点击获取验证码
- **THEN** 按钮显示「获取验证码」、文字颜色 `UIColor.fdPrimary`（`#FF7A50`）、背景色 `UIColor.fdPrimarySoft`（`#FFF3EE`）、高度 48pt、圆角 12pt、字体 13pt semibold

#### Scenario: 获取验证码按钮（倒计时态）
- **WHEN** 用户点击获取验证码后
- **THEN** 按钮进入 60 秒倒计时，显示「{N}s 后重试」、文字颜色 `UIColor.fdMuted`、背景色 `UIColor.fdBg2`（`#F6ECE4`）、按钮不可交互

#### Scenario: 倒计时结束
- **WHEN** 60 秒倒计时归零
- **THEN** 按钮恢复为「获取验证码」可点击状态

#### Scenario: 手机号校验
- **WHEN** 用户点击获取验证码
- **THEN** 系统校验手机号格式（中国大陆手机号 1[3-9]xxxxxxxxx），格式错误时通过 toast 提示「请输入正确的手机号」

---

### Requirement: Password Fields (Password Mode)
密码模式下 SHALL 展示账号和密码两个输入框。

#### Scenario: 账号输入框
- **WHEN** 密码模式激活
- **THEN** 展示 `LoginFieldView`，label 为「账号」、左侧 icon 为 SF Symbol `person.crop.circle`、placeholder 为「请输入账号」

#### Scenario: 密码输入框
- **WHEN** 密码模式激活
- **THEN** 展示 `LoginFieldView`，label 为「密码」、左侧 icon 为 SF Symbol `lock`、placeholder 为「请输入密码」、默认 `isSecureTextEntry = true`

#### Scenario: 密码显隐切换
- **WHEN** 用户点击密码输入框右侧的 eye toggle 按钮
- **THEN** 密码明文/密文切换，icon 在 `eye` / `eye.slash` 之间切换

---

### Requirement: Submit Button
登录页 SHALL 展示全宽的登录/注册提交按钮。

#### Scenario: 按钮样式
- **WHEN** 页面渲染提交按钮
- **THEN** 按钮全宽（左右对齐输入框）、高度 52pt、背景色 `UIColor.fdPrimary`（`#FF7A50`）、文字白色 16pt bold、圆角 18pt、阴影 `0 6px 18px rgba(255, 122, 80, 0.32)`

#### Scenario: 按钮交互态
- **WHEN** 用户按下按钮
- **THEN** 按钮 opacity 降至 0.88（高亮态）
- **WHEN** 按钮处于 disabled 状态（登录中）
- **THEN** 按钮 opacity 为 0.72

#### Scenario: 验证码模式提交
- **WHEN** 用户在验证码模式下点击提交
- **THEN** 校验手机号和验证码非空，空时 toast 提示，通过后调用 BLL 层 `LoginService.loginByPhone(phone:code:)`，按钮显示「登录中…」且 disabled

#### Scenario: 密码模式提交
- **WHEN** 用户在密码模式下点击提交
- **THEN** 校验账号和密码非空，空时 toast 提示，通过后调用 BLL 层 `LoginService.loginByPassword(username:password:)`，按钮显示「登录中…」且 disabled

---

### Requirement: Login Mode Switch Link
登录页 SHALL 在提交按钮下方提供模式切换链接。

#### Scenario: 切换到密码模式链接
- **WHEN** 当前为验证码模式
- **THEN** 显示右对齐按钮「使用账号密码登录」，文字颜色 `UIColor.fdPrimary`、13pt

#### Scenario: 切换到验证码模式链接
- **WHEN** 当前为密码模式
- **THEN** 显示右对齐按钮「返回验证码登录」，文字颜色 `UIColor.fdPrimary`、13pt

---

### Requirement: Agreement Notice
登录页 SHALL 展示用户协议告知文字。

#### Scenario: 协议文字展示
- **WHEN** 页面渲染
- **THEN** 在模式切换链接下方 14pt 处展示居中文字「登录即代表同意《用户协议》与《隐私政策》」，文字颜色 `UIColor.fdMuted`、11pt

#### Scenario: 协议链接交互
- **WHEN** 用户点击《用户协议》或《隐私政策》
- **THEN** 通过 Router 打开对应协议的 WebView 页面（具体 URL 在 BLL 层配置）

---

### Requirement: WeChat Login Entry
登录页 SHALL 提供微信第三方登录入口。

#### Scenario: 微信按钮样式
- **WHEN** 页面渲染
- **THEN** 在页面底部（协议文字下方 28pt）居中展示微信登录按钮：52×52pt 圆形、白色背景、带阴影（`shadow-pop`）、内嵌微信 icon（绿色 `#07C160`、28pt、SF Symbol 或自定义图标）

#### Scenario: 微信按钮点击
- **WHEN** 用户点击微信登录按钮
- **THEN** 弹出 WechatAuthSheet（底部弹层），展示微信授权确认界面

---

### Requirement: WeChat Authorization Sheet
微信登录 SHALL 通过底部弹层展示授权确认界面。

#### Scenario: 弹层内容
- **WHEN** WechatAuthSheet 展示
- **THEN** 弹层包含：
  - 微信 icon（56×56pt、圆角 18pt、浅绿背景 `rgba(7, 193, 96, 0.12)`）
  - 标题「微信快捷登录」（18pt bold）
  - 说明文字「将通过微信授权登录富德健康。继续即表示同意《用户协议》与《隐私政策》。」（13pt `UIColor.fdSubtext`）
  - 微信登录按钮「微信登录」（全宽、48pt 高、圆角 14pt、绿色背景 `#07C160`、白色文字 15pt semibold）

#### Scenario: 授权确认
- **WHEN** 用户点击「微信登录」
- **THEN** 按钮显示「授权中…」、调用 BLL 层 `LoginService.loginByWeChat()`、成功后 dismiss 弹层并完成登录

#### Scenario: 关闭弹层
- **WHEN** 用户点击弹层外部区域或下拉关闭
- **THEN** 弹层 dismiss，回到登录页

---

### Requirement: Design Token Mapping
登录页 SHALL 使用统一的设计 Token（UIColor / UIFont 扩展），不硬编码颜色和字号。

#### Scenario: 颜色引用
- **WHEN** 开发者设置任何 UI 元素的颜色
- **THEN** 必须通过 `UIColor.fd*` 扩展属性引用，不得直接使用 `UIColor(hex:)` 或 `UIColor.system*`

**完整颜色 Token 表** (来源: funde-client `tokens.css`):

| Token | Hex | 用途 |
|-------|-----|------|
| `UIColor.fdPrimary` | `#FF7A50` | 主按钮、链接、聚焦边框 |
| `UIColor.fdPrimaryDeep` | `#E55A2E` | 按钮按下态 |
| `UIColor.fdPrimarySoft` | `#FFF3EE` | 验证码按钮背景 |
| `UIColor.fdPrimaryEdge` | `#FFD9C7` | 主色描边 |
| `UIColor.fdText` | `#1F2430` | 标题、品牌名 |
| `UIColor.fdText2` | `#3D4555` | 次主文字 |
| `UIColor.fdSubtext` | `#6B7280` | label、说明文字 |
| `UIColor.fdMuted` | `#9AA0AC` | 协议提示、倒计时文字 |
| `UIColor.fdBorder` | `#ECE4DD` | 输入框边框 |
| `UIColor.fdSurface` | `#FFFFFF` | 输入框背景 |
| `UIColor.fdBg` | `#FDF6F3` | 页面背景 |
| `UIColor.fdBg2` | `#F6ECE4` | 倒计时按钮背景 |
| `UIColor.fdWechatGreen` | `#07C160` | 微信按钮色 |

#### Scenario: 字号引用
- **WHEN** 开发者设置字体大小
- **THEN** 优先使用 `UIFont.preferredFont(forTextStyle:)` 支持 Dynamic Type，或使用 `UIFont.fd*` 扩展

**字号对照表**:

| 用途 | funde Token | 标准值 | 老年模式 | iOS Text Style |
|------|-----------|--------|---------|---------------|
| 品牌名称 | `--fd-h2` | 22pt | 26pt | `.title2` |
| 输入框文字 | `--fd-body` | 15pt | 19pt | `.body` |
| label | `--fd-caption` | 13pt | 16pt | `.caption1` |
| 协议/提示 | `--fd-micro` | 11pt | 14pt | `.caption2` |
| Logo Mark 文字 | — | 22pt | 26pt | `.title2` |
| 提交按钮 | — | 16pt | — | `.headline` |

---

### Requirement: Senior Mode Adaptation
登录页 SHALL 支持老年模式，所有字号随系统「辅助功能→更大字体」设置自动放大，可点击区域最小 44pt。

#### Scenario: 字号自动放大
- **WHEN** 系统 `preferredContentSizeCategory` 为 `.accessibility*` 或用户在 App 内开启老年模式
- **THEN** 所有 UILabel 和 UITextField 的字号按 funde-client senior mode 倍率放大（约 1.2x–1.3x）

#### Scenario: 触摸目标
- **WHEN** 老年模式激活
- **THEN** 所有可点击元素（按钮、链接、icon）的触摸区域 ≥ 44×44pt

#### Scenario: 布局不破
- **WHEN** 字号放大后
- **THEN** 布局不溢出、不截断，UIScrollView 支持垂直滚动以容纳放大的内容

---

### Requirement: Loading State
登录页 SHALL 在登录请求进行中时展示加载态，防止重复提交。

#### Scenario: 按钮加载态
- **WHEN** 登录请求进行中
- **THEN** 提交按钮 disabled、文字显示「登录中…」（或「授权中…」）

#### Scenario: 请求完成
- **WHEN** 登录请求返回（成功或失败）
- **THEN** 按钮恢复可交互状态，失败时 toast 提示错误信息

---

## Component Inventory

从 funde-client 参考页面提取，需要在 iOS 项目中创建的组件：

| Component | Type | funde ref | iOS 实现 |
|-----------|------|-----------|---------|
| `BrandHeaderView` | UIView | `login-brand` + `login-brand__mark/name/tagline` | Custom UIView subclass |
| `LoginFieldView` | UIView | `login-field` + `login-field__shell/icon/input/label` | Custom UIView subclass (label + icon + textField) |
| `VerifyCodeButton` | UIButton | `login-code-btn` + `login-code-btn--sent` | Custom UIButton subclass (倒计时) |
| `SubmitButton` | UIButton | `login-submit-btn` | UIButton + SnapKit (全宽) |
| `WechatLoginButton` | UIButton | `login-wechat__entry` | UIButton (圆形浮动) |
| `WechatAuthSheetView` | UIView/VC | `wechat-sheet` | Custom Modal VC |
| `ModeSwitchButton` | UIButton | `login-switch__link` | UIButton (文字链接) |

---

## BLL Interface

登录页依赖以下 BLL 层接口（在本 spec 中定义协议，具体实现在后续变更中完成）：

```swift
protocol LoginServiceProtocol {
    /// 验证码登录
    func loginByPhone(_ phone: String, code: String) async throws -> User
    /// 密码登录
    func loginByPassword(_ username: String, password: String) async throws -> User
    /// 微信登录
    func loginByWeChat(_ authCode: String) async throws -> User
    /// 发送验证码
    func sendVerificationCode(to phone: String) async throws
}
```

---

## States

| State | 表现 |
|-------|------|
| **默认** | 验证码模式、输入框为空 |
| **聚焦** | 当前输入框边框高亮为品牌色 |
| **倒计时** | 验证码按钮灰色、倒计时文字 |
| **加载中** | 提交按钮 disabled、loading 文案 |
| **密码模式** | 账号 + 密码输入框可见、验证码相关隐藏 |
| **微信弹层** | WechatAuthSheet present |
| **老年模式** | 全局字号放大 1.2–1.3x、最小 44pt 触摸区域 |
| **错误** | toast 提示具体错误信息 |

---

## Acceptance Checklist

- [ ] 登录页全屏展示，无 Tab Bar
- [ ] 品牌区 Logo Mark 渐变背景正确渲染
- [ ] 验证码模式：手机号 + 验证码 + 获取验证码按钮并排
- [ ] 密码模式：账号 + 密码（可显隐切换）
- [ ] 双模式切换动画流畅
- [ ] 提交按钮全宽、品牌色、圆角、阴影
- [ ] 获取验证码倒计时 60s 正常工作
- [ ] 手机号格式校验（中国大陆号段）
- [ ] 微信登录按钮圆形悬浮
- [ ] 微信授权弹层内容正确
- [ ] 协议文字可点击跳转
- [ ] 键盘弹起时输入框不被遮挡
- [ ] 老年模式字号放大、布局不破、最小触摸区域 44pt
- [ ] 登录中 loading 态、防止重复提交
- [ ] 所有颜色通过 `UIColor.fd*` Token 引用
- [ ] 登录成功 dismiss → 进入主 Tab 页
