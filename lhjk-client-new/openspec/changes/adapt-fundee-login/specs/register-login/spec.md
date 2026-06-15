# Register & Login

## Purpose

定义注册/登录完整流程的 UI 布局、交互行为、异常处理和适配规则。参考 funde-client（富德健康）PRD `用户注册与登录_v1.0.md` 及 `LoginView.vue` + `design-system.md` 的设计规范，通过 UIKit + SnapKit 将其适配到 iOS 项目。

页面覆盖完整的用户注册与登录链路：**隐私授权 → 本机号识别 → 验证码/密码登录 → 微信授权绑定 → 通知权限 → 登录后目标页还原**，以及**登录过期、账号状态异常、忘记密码**等分支流程。

> **Deferred**: 老年模式适配（Dynamic Type 联动）和 Logo Mark 渐变背景（CAGradientLayer）暂不在本次实现，先使用纯色品牌色方块代替渐变。

> **Reference**: funde-client PRD `/Users/chunyi/Desktop/lhjk/用户注册与登录_v1.0.md`、`/prototype/src/views/auth/LoginView.vue`、`/prototype/src/styles/tokens.css`、`/docs/design/design-system.md`

---

## Layout Architecture

页面布局采用全屏滚动结构（无 Tab Bar），从上到下分为以下区域：

```
┌──────────────────────────────────────────┐
│            UIScrollView                   │
│  ┌──────────────────────────────────────┐│
│  │         BrandHeaderView              ││
│  │  ┌──────┐  Logo Mark (72×72)        ││
│  │  │ 品牌 │  品牌色方块 + 白色文字       ││
│  │  └──────┘                            ││
│  │  富德健康      (appName, 22pt bold)   ││
│  │  全生命周期... (tagline, 13pt muted)  ││
│  └──────────────────────────────────────┘│
│  ┌──────────────────────────────────────┐│
│  │  ┌──────────────────────────────┐    ││
│  │  │ 脱敏本机号展示 / 手动手机号输入  │    ││
│  │  └──────────────────────────────┘    ││
│  │  ┌──────────────────┬───────────┐    ││
│  │  │ 验证码输入框       │ 获取验证码  │    ││
│  │  └──────────────────┴───────────┘    ││
│  │         ---  或 密码模式  ---          ││
│  │  ┌──────────────────────────────┐    ││
│  │  │ 手机号输入框                   │    ││
│  │  └──────────────────────────────┘    ││
│  │  ┌──────────────────────────────┐    ││
│  │  │ 密码输入框 (含显隐切换)         │    ││
│  │  └──────────────────────────────┘    ││
│  │  ┌──────────────────────────────┐    ││
│  │  │ ☐ 同意《用户协议》与《隐私政策》  │    ││
│  │  └──────────────────────────────┘    ││
│  │  ┌──────────────────────────────┐    ││
│  │  │     Submit Button            │    ││
│  │  │     "登录 / 注册" 或 "密码登录"  │    ││
│  │  └──────────────────────────────┘    ││
│  │  使用账号密码登录 / 返回验证码登录      ││
│  │  忘记密码                             ││
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

### Requirement: Privacy Protection Prompt
用户首次打开 App 或隐私协议版本更新后，SHALL 必须先展示隐私保护提示弹窗。用户同意后才允许进入登录页；不同意则不能继续使用 App。

#### Scenario: 首次展示
- **WHEN** 用户首次安装后第一次打开 App
- **THEN** 展示隐私保护提示弹窗，包含标题「隐私保护提示」、核心说明文字（不超过 4 行）、《用户协议》链接、《隐私政策》链接、「同意」主按钮、「不同意」次按钮

#### Scenario: 用户同意
- **WHEN** 用户点击「同意」
- **THEN** 记录当前协议版本号与同意时间到本地存储，关闭弹窗，进入登录页

#### Scenario: 用户不同意
- **WHEN** 用户点击「不同意」
- **THEN** 展示不可继续使用状态页，文案为「未同意隐私政策，暂无法使用富德健康」，提供「重新查看并同意」和「退出 App」两个操作

#### Scenario: 协议版本更新
- **WHEN** 本地已同意的协议版本号低于服务端最新版本（`latest_privacy_version > local_agreed_version`）
- **THEN** 再次展示隐私弹窗，文案更新为「我们更新了用户协议与隐私政策，请阅读并同意后继续使用」

#### Scenario: 协议链接点击
- **WHEN** 用户点击《用户协议》或《隐私政策》链接
- **THEN** 通过 Router 打开对应协议的 WebView 页面

#### Scenario: 协议链接加载失败
- **WHEN** 点击协议链接后网络异常导致加载失败
- **THEN** 保留弹窗，toast 提示「协议加载失败，请稍后重试」，允许用户重试

---

### Requirement: Full-Screen Layout
登录页 SHALL 以全屏方式展示，不显示底部 Tab Bar。

#### Scenario: 页面展示方式
- **WHEN** 用户已同意隐私政策后进入登录页
- **THEN** 系统 `present` LoginViewController 为全屏 modal（`modalPresentationStyle = .fullScreen`），或通过 SceneDelegate 设置为 root ViewController

#### Scenario: 键盘弹起
- **WHEN** 用户点击输入框导致键盘弹出
- **THEN** UIScrollView 自动调整 contentInset，确保当前输入框和主按钮不被键盘遮挡，必要时页面整体上移

#### Scenario: 背景色
- **WHEN** 登录页渲染
- **THEN** 页面背景色 SHALL 为 `UIColor.fdBg`（对应 funde-client `#FDF6F3` 暖米底色）

---

### Requirement: Brand Header
登录页顶部 SHALL 展示品牌标识区域，包含 Logo Mark、应用名称、Slogan。

#### Scenario: Logo Mark
- **WHEN** 页面渲染品牌区
- **THEN** 展示 72×72pt 的 Logo Mark（圆角 22pt），背景使用品牌色 `UIColor.fdPrimary`（`#FF7A50`），居中显示品牌简称文字（白色、22pt、bold）
- **NOTE**: 渐变背景（`#FFB48A` → `#FF7A50` → `#F25E36`）延迟到后续迭代实现，本次使用纯色 `#FF7A50`

#### Scenario: App Name
- **WHEN** 页面渲染品牌区
- **THEN** Logo Mark 下方 16pt 处展示应用名称「富德健康」（22pt、bold、`UIColor.fdText`）

#### Scenario: Slogan
- **WHEN** 页面渲染品牌区
- **THEN** 应用名称下方 6pt 处展示 Slogan「全生命周期健康守护数智化平台」（13pt、`UIColor.fdSubtext`），不超过一行，小屏不可换行遮挡核心表单

#### Scenario: Brand 区顶部间距
- **WHEN** 页面渲染品牌区
- **THEN** Brand 区顶部与 safeAreaLayoutGuide.topAnchor 间距为 80pt

---

### Requirement: Local Phone Number Detection
登录页 SHALL 默认尝试获取本机手机号，展示脱敏号码；获取失败时自动切换为手动手机号输入。

#### Scenario: 本机号获取成功
- **WHEN** 运营商能力成功返回本机手机号
- **THEN** 展示脱敏手机号（格式如 `156****8923`，保留前 3 后 4），下方提供「使用其他手机号」链接

#### Scenario: 本机号获取失败
- **WHEN** 运营商不支持、无 SIM 卡、双卡异常、网络异常或用户拒绝授权
- **THEN** 自动切换为手动手机号输入框，toast 提示「暂未获取到本机号码，请输入手机号登录」

#### Scenario: 使用其他手机号
- **WHEN** 用户点击「使用其他手机号」
- **THEN** 脱敏本机号展示切换为手动手机号输入框，保留已输入的验证码（如有）

#### Scenario: 本机号 mock 模式
- **WHEN** V1.0 原型阶段未接入真实运营商 SDK
- **THEN** 使用 mock 本机号数据，并在代码中标注 TODO 标记，待 V1.1 接入真实 SDK

---

### Requirement: Login Mode Switching
登录页 SHALL 支持验证码登录和密码登录两种模式，默认展示验证码登录。切换时保留已输入的手机号。

#### Scenario: 默认模式
- **WHEN** 用户进入登录页
- **THEN** 展示验证码登录模式（手机号 + 验证码 + 获取验证码按钮）

#### Scenario: 切换到密码登录
- **WHEN** 用户点击「使用账号密码登录」
- **THEN** 表单切换为密码模式（手机号 + 密码），验证码相关输入框隐藏，密码相关输入框显示，保留已输入手机号

#### Scenario: 切换回验证码登录
- **WHEN** 用户在密码模式下点击「返回验证码登录」
- **THEN** 表单切换回验证码模式，保留已输入手机号

#### Scenario: 提交按钮文案
- **WHEN** 验证码模式下
- **THEN** 提交按钮显示「登录 / 注册」
- **WHEN** 密码模式下
- **THEN** 提交按钮显示「密码登录」

#### Scenario: 不做整页跳转
- **WHEN** 用户在验证码登录和密码登录之间切换
- **THEN** 切换动画平滑，不做整页跳转或大幅度布局抖动

---

### Requirement: Phone Number Field
验证码模式和密码模式下 SHALL 均展示手机号输入框。

#### Scenario: 输入框结构
- **WHEN** 手动输入模式激活
- **THEN** 展示 `LoginFieldView`，label 为「手机号」、左侧 icon 为 SF Symbol `phone`、placeholder 为「请输入手机号」、keyboardType 为 `.phonePad`、maxLength 为 11

#### Scenario: 输入框样式
- **WHEN** 输入框处于默认状态
- **THEN** 高度 48pt、背景色 `UIColor.fdSurface`（白色）、边框 1pt `UIColor.fdBorder`（`#ECE4DD`）、圆角 12pt

#### Scenario: 输入框聚焦态
- **WHEN** 输入框获得焦点 (becomeFirstResponder)
- **THEN** 边框色变为 `UIColor.fdPrimary`（`#FF7A50`），附带 3pt 宽度 brand color 弱阴影

#### Scenario: 手机号格式校验
- **WHEN** 用户提交手机号相关操作（获取验证码、登录）
- **THEN** 系统校验手机号格式（中国大陆手机号 `^1[3-9]\d{9}$`），为空提示「请输入手机号」，格式错误提示「请输入正确的手机号」

---

### Requirement: Verification Code Field
验证码模式下 SHALL 展示验证码输入框及获取验证码按钮，两者水平并排。

#### Scenario: 输入框结构
- **WHEN** 验证码模式激活
- **THEN** 展示 `LoginFieldView`（flexible width），label 为「验证码」、左侧 icon 为 SF Symbol `shield`、placeholder 为「请输入验证码」、keyboardType 为 `.numberPad`、maxLength 为 6
- **NOTE**: 使用单个输入框 + 数字键盘，不采用 6 个独立方框

#### Scenario: 获取验证码按钮（默认态）
- **WHEN** 用户尚未点击获取验证码
- **THEN** 按钮显示「获取验证码」、文字颜色 `UIColor.fdPrimary`（`#FF7A50`）、背景色 `UIColor.fdPrimarySoft`（`#FFF3EE`）、高度 48pt、圆角 12pt、字体 13pt semibold

#### Scenario: 获取验证码前校验
- **WHEN** 用户点击获取验证码
- **THEN** 系统依次校验：
  1. 协议是否已勾选 → 未勾选 toast「请先阅读并同意用户协议与隐私政策」
  2. 手机号格式是否正确 → 格式错误 toast「请输入正确的手机号」
  3. 以上均通过后 → 弹出拼图验证

#### Scenario: 获取验证码按钮（倒计时态）
- **WHEN** 验证码发送成功后
- **THEN** 按钮进入 60 秒倒计时，显示「{N}s 后重发」、文字颜色 `UIColor.fdMuted`、背景色 `UIColor.fdBg2`（`#F6ECE4`）、按钮不可交互

#### Scenario: 倒计时结束
- **WHEN** 60 秒倒计时归零
- **THEN** 按钮恢复文字为「重新获取」，恢复可点击状态

#### Scenario: 验证码发送失败
- **WHEN** 短信接口失败或超时
- **THEN** 不开始倒计时，toast 提示「验证码发送失败，请稍后重试」，允许用户重试

#### Scenario: 验证码发送频繁
- **WHEN** 同一手机号短时间多次请求触发频控
- **THEN** 阻止发送，toast 提示「验证码发送过于频繁，请稍后再试」

---

### Requirement: Captcha (Puzzle) Verification
用户获取短信验证码前 SHALL 必须完成拼图滑块真人验证，验证通过后才调用验证码发送流程。

#### Scenario: 拼图弹窗展示
- **WHEN** 用户点击获取验证码且前置校验通过
- **THEN** 弹出拼图验证弹窗，包含拼图区域、滑块控件、「关闭」按钮、「刷新」按钮

#### Scenario: 验证通过
- **WHEN** 用户滑动滑块到目标位置并通过验证
- **THEN** 获取 `captcha_token`，关闭弹窗，立即调用发送验证码接口

#### Scenario: 验证失败
- **WHEN** 滑块滑动未通过验证
- **THEN** 保留弹窗，toast 提示「验证未通过，请重新拖动」，允许重试

#### Scenario: 用户关闭验证
- **WHEN** 用户点击「关闭」按钮
- **THEN** 关闭弹窗，不发送验证码，回到登录页

#### Scenario: 验证服务异常
- **WHEN** 拼图加载失败或接口超时
- **THEN** 允许刷新重试，toast 提示「验证加载失败，请刷新重试」，不可绕过验证直接发码

#### Scenario: 多次失败
- **WHEN** 连续失败达到 5 次
- **THEN** 不锁定用户，toast 提示「验证失败次数较多，请刷新后重试」，要求刷新拼图后重试

#### Scenario: 测试环境跳过
- **WHEN** 测试环境配置开关开启
- **THEN** 允许跳过拼图验证（仅用于自动化回归，生产环境不得开启）

---

### Requirement: Password Fields (Password Mode)
密码模式下 SHALL 展示手机号和密码两个输入框，以及忘记密码入口。

#### Scenario: 手机号输入框
- **WHEN** 密码模式激活
- **THEN** 展示 `LoginFieldView`，label 为「手机号」、左侧 icon 为 SF Symbol `phone`、placeholder 为「请输入手机号」、keyboardType 为 `.phonePad`、maxLength 为 11

#### Scenario: 密码输入框
- **WHEN** 密码模式激活
- **THEN** 展示 `LoginFieldView`，label 为「密码」、左侧 icon 为 SF Symbol `lock`、placeholder 为「请输入密码」、默认 `isSecureTextEntry = true`、最少 6 位

#### Scenario: 密码显隐切换
- **WHEN** 用户点击密码输入框右侧的 eye toggle 按钮
- **THEN** 密码明文/密文切换，icon 在 `eye` / `eye.slash` 之间切换，触控区域 ≥ 44×44pt，与输入文字间距 ≥ 8pt

#### Scenario: 忘记密码入口
- **WHEN** 密码模式激活
- **THEN** 在密码输入框下方展示「忘记密码」链接（13pt、`UIColor.fdPrimary`），点击进入忘记密码流程

#### Scenario: 返回验证码登录
- **WHEN** 密码模式激活
- **THEN** 在提交按钮下方展示「返回验证码登录」链接（13pt、`UIColor.fdPrimary`），点击切回验证码模式

---

### Requirement: Forgot Password
用户 SHALL 可通过手机号验证码完成密码重置，重置成功后返回密码登录页并预填手机号。

#### Scenario: 忘记密码流程
- **WHEN** 用户点击「忘记密码」
- **THEN** 进入忘记密码页面，流程为：输入手机号 → 拼图验证 → 发送短信验证码 → 输入验证码 → 设置新密码 → 提交重置

#### Scenario: 重置成功
- **WHEN** 密码重置接口返回成功
- **THEN** toast 提示「密码已重置，请重新登录」，返回密码登录页并预填手机号

#### Scenario: 手机号未注册
- **WHEN** 验证码校验后确认手机号未注册
- **THEN** 不在手机号输入阶段暴露注册状态；验证码校验后 toast 提示「该手机号尚未注册，请使用验证码登录」

#### Scenario: 新密码校验
- **WHEN** 用户提交重置
- **THEN** 校验新密码非空（为空提示「请设置新密码」）、至少 6 位（长度不足提示「新密码至少 6 位」）

#### Scenario: 验证码错误/过期
- **WHEN** 重置时验证码校验失败
- **THEN** toast 提示「验证码错误或已过期，请重新获取」

---

### Requirement: Agreement Checkbox
登录页 SHALL 展示用户协议勾选框，获取验证码和任何登录/绑定提交前必须勾选。

#### Scenario: 协议勾选框展示
- **WHEN** 页面渲染
- **THEN** 在提交按钮上方展示勾选框 + 协议文字：「我已阅读并同意《用户协议》与《隐私政策》」，默认未勾选

#### Scenario: 协议链接可点击
- **WHEN** 用户点击《用户协议》或《隐私政策》
- **THEN** 通过 Router 打开对应协议的 WebView 页面

#### Scenario: 未勾选协议阻止操作
- **WHEN** 用户未勾选协议时点击获取验证码、登录/注册、密码登录或微信绑定
- **THEN** 阻止操作，toast 提示「请先阅读并同意用户协议与隐私政策」

#### Scenario: 协议在所有登录方式中强制
- **WHEN** 用户在验证码登录、密码登录或微信登录中
- **THEN** 协议勾选要求在所有登录方式提交前均生效

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
- **THEN** 按钮 opacity 为 0.72，文字显示「登录中…」，按钮不可交互

#### Scenario: 验证码模式提交
- **WHEN** 用户在验证码模式下点击提交
- **THEN** 校验协议已勾选、手机号非空且格式正确、验证码非空且为 6 位数字，通过后调用 BLL 层 `LoginService.loginByPhone(phone:code:)`，按钮显示「登录中…」且 disabled

#### Scenario: 密码模式提交
- **WHEN** 用户在密码模式下点击提交
- **THEN** 校验协议已勾选、手机号非空且格式正确、密码非空且至少 6 位，通过后调用 BLL 层 `LoginService.loginByPassword(phone:password:)`，按钮显示「登录中…」且 disabled

#### Scenario: 验证码校验结果
- **WHEN** 验证码校验成功且手机号为新用户
- **THEN** 自动注册并登录
- **WHEN** 验证码校验成功且手机号已注册
- **THEN** 直接登录

---

### Requirement: WeChat Login Entry
登录页 SHALL 提供微信第三方登录入口。

#### Scenario: 微信按钮样式
- **WHEN** 页面渲染
- **THEN** 在页面底部居中展示微信登录按钮：52×52pt 圆形、白色背景、带阴影（`shadow-pop`）、内嵌微信 icon（绿色 `#07C160`、28pt、自定义图标）

#### Scenario: 微信未安装
- **WHEN** 设备未安装微信或环境不支持
- **THEN** 保留手机号登录入口，toast 提示「当前设备未安装微信，请使用手机号登录」，可隐藏微信按钮或置灰

#### Scenario: 微信 SDK 加载超时
- **WHEN** 微信 SDK 5 秒未就绪
- **THEN** 隐藏微信入口，仅保留手机号登录

---

### Requirement: WeChat Authorization & Phone Binding
微信登录 SHALL 通过底部弹层展示授权确认界面，授权后根据绑定状态决定是否需要手机号验证码绑定。

#### Scenario: 微信授权弹层内容
- **WHEN** WechatAuthSheet 展示
- **THEN** 弹层包含：
  - 微信 icon（56×56pt、圆角 18pt、浅绿背景 `rgba(7, 193, 96, 0.12)`）
  - 标题「微信快捷登录」（18pt bold）
  - 说明文字「将通过微信授权登录富德健康。继续即表示同意《用户协议》与《隐私政策》。」（13pt `UIColor.fdSubtext`）
  - 微信登录按钮「微信登录」（全宽、48pt 高、圆角 14pt、绿色背景 `#07C160`、白色文字 15pt semibold）

#### Scenario: 用户取消微信授权
- **WHEN** 微信授权页点击取消
- **THEN** 返回登录页，toast 提示「已取消微信授权」

#### Scenario: 微信授权失败
- **WHEN** 微信 SDK 返回失败
- **THEN** 返回登录页，toast 提示「微信授权失败，请稍后重试」，允许重试

#### Scenario: 微信已绑定手机号 → 直接登录
- **WHEN** 微信授权成功且已有手机号绑定关系
- **THEN** 直接登录，进入通知权限流程

#### Scenario: 微信未绑定手机号 → 绑定流程
- **WHEN** 微信授权成功但无绑定手机号
- **THEN** 打开手机号绑定弹层，提示「请绑定手机号后继续使用」，用户需输入手机号 + 验证码完成绑定

#### Scenario: 手机号已绑定其他微信（换绑冲突）
- **WHEN** 绑定手机号时校验发现该手机号已绑定其他微信号
- **THEN** toast 提示「该手机号已绑定其他微信号，请更换手机号，或联系客服解绑后重试」；用户坚持换绑时需二次确认，通过原手机号验证码校验后换绑当前微信，记录安全日志

#### Scenario: 微信已绑定其他手机号
- **WHEN** 当前微信已有其他手机号绑定关系
- **THEN** 阻止自动覆盖，toast 提示「当前微信已绑定其他手机号，请联系客服处理」

#### Scenario: 关闭弹层
- **WHEN** 用户点击弹层外部区域或下拉关闭
- **THEN** 弹层 dismiss，回到登录页

---

### Requirement: Push Notification Permission
登录成功后 SHALL 先展示 App 内通知预引导，再请求系统推送通知权限。用户允许或拒绝均不影响进入目标页或首页。

#### Scenario: 通知预引导弹窗
- **WHEN** 登录成功后
- **THEN** 展示 App 内预引导弹窗：
  - 主文案：「开启通知，及时获取健康提醒和保单服务动态。」
  - 辅助说明：「我们会提醒您查看健康服务进度、重要通知和账号安全提醒。」
  - 「去开启」主按钮 → 调用系统通知权限请求
  - 「暂不开启」次按钮 → 不调用系统权限，直接进入目标页或 `/home`

#### Scenario: 用户允许通知
- **WHEN** 系统授权允许
- **THEN** 记录授权状态，进入目标页或 `/home`

#### Scenario: 用户拒绝通知
- **WHEN** 系统授权拒绝
- **THEN** toast 提示「已暂不接收通知，可在设置中重新开启」，进入目标页或 `/home`

#### Scenario: 系统不再弹窗
- **WHEN** 用户曾拒绝且系统不再询问
- **THEN** 展示 App 内提示后进入目标页或 `/home`，文案：「如需接收服务提醒，请在系统设置中开启通知」

#### Scenario: 通知权限请求异常
- **WHEN** 权限请求失败（如 SDK 异常）
- **THEN** 不阻塞首页，toast 提示「通知权限暂不可用，可稍后在设置中开启」

---

### Requirement: Post-Login Redirect / DeepLink
登录成功后 SHALL 根据是否有合法 `redirect` 或 `deeplink` 参数决定目标页面。合法则进入目标页，否则进入 `/home`。

#### Scenario: 无 redirect/deeplink
- **WHEN** 登录成功且无 redirect/deeplink 参数
- **THEN** 进入 `/home` 首页

#### Scenario: 有合法 redirect
- **WHEN** 登录成功且有合法 `redirect` 参数（App 内白名单路径）
- **THEN** 进入 `redirect` 指向的 App 内目标页

#### Scenario: 有合法 deeplink
- **WHEN** 登录成功且有合法 `deeplink` 参数
- **THEN** 解析 deeplink 并进入对应 App 内白名单路径

#### Scenario: 非法目标页
- **WHEN** redirect/deeplink 指向外部 URL、未注册路由、越权页面或解析失败
- **THEN** 统一回退进入 `/home`，可 toast「登录成功」

#### Scenario: 登录过期回跳
- **WHEN** 因 token 失效跳转登录页时
- **THEN** 携带当前白名单路径为 `redirect`，重新登录成功后回到原页面

---

### Requirement: Session Expiry & Account States
系统 SHALL 处理登录过期、账号冻结和账号注销中等状态，引导用户重新登录或联系客服。

#### Scenario: 登录过期（token 失效）
- **WHEN** 接口返回 token 失效或长期未登录
- **THEN** 清理本地登录态，跳转登录页，展示提示「为保护您的健康数据安全，登录状态已过期，请重新登录」，携带当前白名单路径为 `redirect`

#### Scenario: 密码变更导致失效
- **WHEN** 其他端修改密码导致当前 token 失效
- **THEN** 清理登录态，展示提示「账号安全信息已更新，请重新登录」

#### Scenario: 账号冻结
- **WHEN** 后端返回账号冻结状态
- **THEN** 阻止登录，弹窗提示「当前账号暂无法登录，请联系客服处理」，提供客服/申诉入口 [待确认]

#### Scenario: 账号注销中
- **WHEN** 后端返回注销中状态
- **THEN** 阻止登录，弹窗提示「账号正在注销处理中，暂无法登录」，注销冷静期内同手机号不可重新注册

#### Scenario: 旧手机号无法接码
- **WHEN** 用户点击「无法接收验证码」
- **THEN** 提供客服申诉入口，展示「无法接收验证码？请联系客服协助处理」

---

### Requirement: Multi-Device Login
V1.0 SHALL 允许多设备同时登录，不踢出旧设备；新设备登录时发送安全提醒。

#### Scenario: 多设备同时登录
- **WHEN** 用户在另一设备登录同一账号
- **THEN** 旧设备不被踢出，保持可用状态

#### Scenario: 新设备登录提醒
- **WHEN** 检测到新设备成功登录
- **THEN** 向已登录设备或绑定手机号发送安全提醒：「您的账号刚刚在新设备登录，如非本人操作请及时修改密码」[待确认：提醒通道]

---

### Requirement: Global Error Handling
系统 SHALL 对全局异常场景统一处理，提供可理解的用户提示。

#### Scenario: 网络异常
- **WHEN** 接口请求因网络问题失败
- **THEN** 停止 loading，按钮恢复可点，toast 提示「网络不稳定，请稍后重试」

#### Scenario: 服务超时
- **WHEN** 接口请求超时
- **THEN** 不进入下一步，不消耗倒计时（验证码场景），toast 提示「请求超时，请稍后重试」

#### Scenario: 系统异常
- **WHEN** 服务端返回系统级错误
- **THEN** 停止当前流程，保留登录页，toast 提示「系统暂时不可用，请稍后再试」

#### Scenario: 重复提交防护
- **WHEN** 登录/绑定/重置密码请求未返回时用户再次点击
- **THEN** 按钮 loading/置灰，不发起重复请求，无需额外提示

#### Scenario: 离线状态
- **WHEN** 页面初始化时网络不可用
- **THEN** 展示离线提示页，提供「重新加载」按钮

---

### Requirement: Input Validation & Error Messages
系统 SHALL 对用户输入进行前端校验，并按触发规则展示对应的错误提示文案。

#### Scenario: 手机号校验
| 场景 | 触发条件 | 提示文案 |
|------|---------|---------|
| 手机号为空 | 提交时手机号为空 | 请输入手机号 |
| 手机号格式错误 | 不符合 11 位大陆手机号格式 | 请输入正确的手机号 |

#### Scenario: 验证码校验
| 场景 | 触发条件 | 提示文案 |
|------|---------|---------|
| 验证码为空 | 提交时验证码为空 | 请输入验证码 |
| 验证码位数不足 | 少于 6 位 | 请输入 6 位验证码 |
| 验证码错误 | 后端校验失败 | 验证码错误，请重新输入 |
| 验证码过期 | 超过 5 分钟有效期 | 验证码已过期，请重新获取 |
| 验证码多次错误 | 同一验证码错误 ≥ 5 次 | 尝试次数过多，请重新获取验证码 |

#### Scenario: 密码校验
| 场景 | 触发条件 | 提示文案 |
|------|---------|---------|
| 密码为空 | 提交时密码为空 | 请输入密码 |
| 密码长度不足 | 少于 6 位 | 密码至少 6 位 |
| 密码错误 | 后端校验失败 | 手机号或密码错误，请重试。如忘记密码，可点击下方"忘记密码"重置 |
| 连续错误 ≥ 5 次 | 同一账号连续错误 | 尝试次数过多，请 15 分钟后再试或使用验证码登录 |

#### Scenario: 账号状态异常提示
| 场景 | 提示文案 |
|------|---------|
| 账号冻结 | 当前账号暂无法登录，请联系客服处理 |
| 账号注销中 | 账号正在注销处理中，暂无法登录 |
| 注销冷静期同号注册 | 该手机号正在注销处理中，请稍后再试或联系客服 |

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

#### Scenario: 适老化触控区域
- **WHEN** 任何可交互元素渲染
- **THEN** 主按钮、图标按钮、密码可见按钮触控区域 ≥ 44×44pt

---

### Requirement: Senior Mode Adaptation **[DEFERRED]**
> **状态**: 延迟到后续迭代实现。本次所有字号使用固定 pt，不做 Dynamic Type 联动。老年模式需求保留以备后续规划。

---

### Requirement: Loading State
登录页 SHALL 在登录请求进行中时展示加载态，防止重复提交。

#### Scenario: 按钮加载态
- **WHEN** 登录/注册/绑定/重置密码请求进行中
- **THEN** 相应提交按钮 disabled、文字显示对应的加载文案（如「登录中…」「授权中…」）

#### Scenario: 请求完成
- **WHEN** 请求返回（成功或失败）
- **THEN** 按钮恢复可交互状态，失败时 toast 提示错误信息

#### Scenario: 提交中不可重复点击
- **WHEN** 任何提交按钮处于请求中状态
- **THEN** 按钮不可交互，防止重复提交

---

## Component Inventory

从 funde-client PRD 和参考页面提取，需要在 iOS 项目中创建的组件：

| Component | Type | funde ref | iOS 实现 | 状态 |
|-----------|------|-----------|---------|------|
| `PrivacyPromptView` | UIView/VC | 隐私保护提示弹窗 | Custom Modal VC | 新增 |
| `BrandHeaderView` | UIView | `login-brand` | Custom UIView subclass | 已有 |
| `LoginFieldView` | UIView | `login-field` | Custom UIView subclass (label + icon + textField) | 已有 |
| `VerifyCodeButton` | UIButton | `login-code-btn` | Custom UIButton subclass (倒计时) | 已有 |
| `CaptchaVerifyView` | UIView/VC | 拼图验证弹窗 | Custom Modal VC | 新增 |
| `SubmitButton` | UIButton | `login-submit-btn` | UIButton + SnapKit (全宽) | 已有 |
| `AgreementCheckboxView` | UIView | 协议勾选 | UIView (checkbox + attributed label) | 新增 |
| `WechatLoginButton` | UIButton | `login-wechat__entry` | UIButton (圆形浮动) | 已有 |
| `WechatAuthSheetView` | UIView/VC | `wechat-sheet` | Custom Modal VC | 已有 |
| `PhoneBindingView` | UIView/VC | 微信绑定手机号 | Custom Modal VC | 新增 |
| `ForgotPasswordView` | UIView/VC | 忘记密码页 | Custom VC | 新增 |
| `NotificationGuideView` | UIView/VC | 通知预引导弹窗 | Custom Modal VC | 新增 |
| `ModeSwitchButton` | UIButton | `login-switch__link` | UIButton (文字链接) | 已有 |

---

## BLL Interface

登录页依赖以下 BLL 层接口（在本 spec 中定义协议，具体实现在后续变更中完成）：

```swift
protocol LoginServiceProtocol {
    /// 获取最新隐私协议版本
    func getPrivacyVersion() async throws -> PrivacyVersionInfo
    /// 记录用户同意隐私协议
    func agreePrivacy(version: Int) async throws

    /// 获取本机手机号（运营商 SDK）
    func getLocalPhoneNumber() async throws -> String?

    /// 发送短信验证码
    func sendVerificationCode(to phone: String, captchaToken: String) async throws -> SMSResponse
    /// 验证码登录（新用户自动注册）
    func loginByPhone(_ phone: String, code: String, smsRequestId: String) async throws -> LoginResult
    /// 密码登录
    func loginByPassword(_ phone: String, password: String) async throws -> LoginResult

    /// 微信授权
    func wechatAuth(authCode: String) async throws -> WechatAuthResult
    /// 微信绑定手机号
    func wechatBindPhone(wechatToken: String, phone: String, code: String, confirmRebind: Bool) async throws -> LoginResult

    /// 重置密码
    func resetPassword(phone: String, code: String, newPassword: String) async throws

    /// 查询登录态和账号状态
    func getSessionStatus() async throws -> SessionStatus
    /// 记录通知授权结果
    func reportNotificationPermission(status: NotificationPermissionStatus) async throws
}

// MARK: - Data Types

enum LoginType {
    case sms        // 验证码登录
    case password   // 密码登录
    case wechat     // 微信登录
}

struct LoginResult {
    let accessToken: String
    let refreshToken: String
    let isNewUser: Bool
    let redirectAllowed: String?
}

struct SMSResponse {
    let smsRequestId: String
    let expireSeconds: Int
    let resendAfter: Int
}

struct WechatAuthResult {
    let bindStatus: WechatBindStatus
    let wechatTempToken: String?
    let maskedPhone: String?
}

enum WechatBindStatus {
    case bound       // 已绑定手机号，可直接登录
    case unbound     // 未绑定，需手机号验证码绑定
}

struct SessionStatus {
    let isValid: Bool
    let accountStatus: AccountStatus
    let reason: String?
}

enum AccountStatus {
    case normal
    case frozen
    case canceling
}

enum NotificationPermissionStatus {
    case allowed
    case denied
    case notDetermined
    case unavailable
}
```

---

## States

| State | 表现 |
|-------|------|
| **隐私未授权** | 隐私弹窗覆盖，登录页不可见 |
| **隐私已拒绝** | 不可用状态页，「重新查看并同意」+「退出 App」 |
| **默认（验证码模式）** | 本机号脱敏展示（成功）/ 手机号输入框（失败）、验证码输入框、获取验证码按钮 |
| **聚焦** | 当前输入框边框高亮为品牌色 |
| **倒计时** | 验证码按钮灰色、倒计时文字「{N}s 后重发」 |
| **拼图验证中** | 拼图弹窗覆盖，滑块交互 |
| **加载中** | 提交按钮 disabled、loading 文案（「登录中…」「授权中…」） |
| **密码模式** | 手机号 + 密码输入框可见、忘记密码链接、验证码相关隐藏 |
| **忘记密码** | 忘记密码页（手机号 → 拼图 → 验证码 → 新密码） |
| **微信弹层** | WechatAuthSheet present |
| **微信绑定手机号** | 手机号绑定弹层（手机号 + 验证码 + 提交） |
| **通知预引导** | 通知引导弹窗（「去开启」/「暂不开启」） |
| **错误** | toast 提示具体错误信息，按钮恢复 |
| **登录过期** | 登录页 + 过期提示条 |
| **账号冻结/注销中** | 弹窗提示，阻止登录 |

---

## Acceptance Checklist

### 隐私授权
- [ ] 首次打开展示隐私保护弹窗
- [ ] 协议版本更新后再次展示隐私弹窗
- [ ] 已同意当前版本不再弹窗
- [ ] 不同意展示不可用状态页，支持重新查看并同意或退出 App
- [ ] 协议链接可点击查看，加载失败有重试提示

### 本机号识别
- [ ] 默认展示脱敏本机手机号（格式 `156****8923`）
- [ ] 本机号获取失败自动切换手动输入，展示提示文案
- [ ] 「使用其他手机号」可切换手动输入

### 验证码登录
- [ ] 手机号 + 验证码 + 获取验证码按钮并排
- [ ] 获取验证码前校验协议勾选和手机号格式
- [ ] 拼图验证弹窗正常展示、通过后发码、失败可重试、关闭不发码
- [ ] 获取验证码倒计时 60s 正常工作
- [ ] 新用户自动注册登录，老用户直接登录

### 密码登录
- [ ] 密码模式展示手机号 + 密码（可显隐切换）+ 忘记密码
- [ ] 密码显隐切换按钮触控区 ≥ 44×44pt
- [ ] 双模式切换动画流畅，保留已输入手机号

### 忘记密码
- [ ] 完整流程：手机号 → 拼图 → 验证码 → 新密码 → 重置成功
- [ ] 手机号未注册时不在输入阶段暴露，验证码后引导验证码登录
- [ ] 重置成功后返回密码登录并预填手机号

### 协议勾选
- [ ] 协议勾选框默认未勾选
- [ ] 未勾选时阻止获取验证码和任何登录/绑定提交
- [ ] 协议链接可点击跳转 WebView

### 微信登录
- [ ] 微信按钮圆形悬浮、白色背景、绿色 icon
- [ ] 微信未安装时 toast 提示并提供手机号登录
- [ ] 微信授权弹层内容正确
- [ ] 微信已绑定手机号直接登录
- [ ] 微信未绑定手机号进入绑定流程
- [ ] 手机号绑定冲突有明确换绑/解绑路径

### 通知权限
- [ ] 登录成功后展示通知预引导弹窗
- [ ] 「去开启」调用系统权限，「暂不开启」跳过
- [ ] 允许/拒绝均进入目标页或 `/home`
- [ ] 系统不再弹窗时展示设置引导

### 登录后导航
- [ ] 无 redirect/deeplink 进入 `/home`
- [ ] 合法 redirect/deeplink 进入目标页
- [ ] 非法目标回退 `/home`

### 登录态与账号状态
- [ ] 登录过期清理登录态并提示
- [ ] 账号冻结阻止登录并提供客服入口
- [ ] 注销中阻止登录并提示

### 通用
- [ ] 登录页全屏展示，无 Tab Bar
- [ ] 品牌区 Logo Mark 纯色品牌色方块正确渲染
- [ ] 提交按钮全宽、品牌色、圆角、阴影
- [ ] 键盘弹起时输入框不被遮挡
- [ ] 登录中 loading 态、防止重复提交
- [ ] 错误提示均按触发规则展示（30 条文案全覆盖）
- [ ] 所有颜色通过 `UIColor.fd*` Token 引用
- [ ] 所有可交互元素触控区域 ≥ 44×44pt
- [ ] 登录成功 dismiss → 进入主 Tab 页或目标页
