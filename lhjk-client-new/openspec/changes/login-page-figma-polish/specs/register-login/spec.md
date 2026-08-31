# register-login（登录页 Figma 优化）Delta

## ADDED Requirements

### Requirement: 登录页视觉对齐 Figma 优化稿

登录主页面 SHALL 按 Figma「登录页-优化后」布局与样式展示：顶部插画、品牌 Logo 图、内嵌验证码按钮、渐变主按钮、居中模式切换、微信入口、底部协议。

#### Scenario: 品牌区

- **WHEN** 登录页渲染
- **THEN** 顶部展示节点 `3021:587` 的原始插画背景；中部 72×72 容器内展示节点 `3021:590` 的原始 Logo SVG +「富德联好健康」+ Slogan「全生命周期健康守护数智化平台」

#### Scenario: 验证码登录表单

- **WHEN** 验证码模式
- **THEN** 「手机号」「验证码」标签在输入框上方；输入壳白底圆角；左侧分别使用节点 `3021:577`、`3021:579` 的原始图标；「获取验证码」为输入壳内橙色文字按钮

#### Scenario: 主操作

- **WHEN** 验证码模式
- **THEN** 主按钮文案为「登录/注册」，水平主色渐变、胶囊圆角；下方居中「使用账号密码登录」主色链接

#### Scenario: 微信与协议

- **WHEN** 登录表单步骤
- **THEN** 展示节点 `3021:618` 的微信 SVG 与「微信登录」文案；协议勾选位于页面底部并使用节点 `3021:624` 的圆形 SVG，协议名称为主色可点链接

### Requirement: Figma 资源真实性

登录页图片与图标 SHALL 使用 Figma MCP 导出的原始字节，不得用截图裁切、AI 生成图、SF Symbol 或自绘路径替代。

#### Scenario: 资源进入工程

- **WHEN** 登录页资源写入 Asset Catalog
- **THEN** 资源来源可追溯至 Figma 节点及 MCP asset URL；临时 URL 下载完成后仅引用本地 Asset Catalog

#### Scenario: 登录过期提示

- **WHEN** 本地标记 `fd_session_expired_hint` 为真
- **THEN** 在协议上方展示「当前登录状态已失效，请重新登录后继续操作」，展示后清除标记
