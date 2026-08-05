## Why

登录页视觉仍停留在早期 funde 骨架（橙色方块 Logo、独立验证码胶囊、协议在按钮上方），与 Figma「登录页-优化后」不一致，需要按设计稿对齐。

Figma: [登录页-优化后 node 3021-569](https://www.figma.com/design/JEIKBLlcPpylp8GJ7BVmFd/%F0%9F%8C%9F%E5%BC%80%E5%8F%91%E5%AF%B9%E6%8E%A5-%E9%A1%B9%E7%9B%AE%E6%8F%90%E4%BA%A4?node-id=3021-569)

## What Changes

- 顶部暖色插画背景 + 真实品牌 Logo 图
- 输入框：白底圆角、Figma 原始手机号/验证码图标、验证码「获取验证码」内嵌输入壳
- 主按钮：水平渐变胶囊，「登录/注册」
- 模式切换居中主色链接；微信登录圆形入口 + 文案
- 协议勾选移至底部、圆形 checkbox；登录过期提示在协议上方

## Capabilities

### Modified Capabilities

- `register-login`: 登录页视觉与信息架构对齐 Figma 优化稿（逻辑流不变）

## Impact

- `PL/RegisterLogin/LoginViewController.swift`
- `PL/RegisterLogin/Components/{BrandHeaderView,LoginFieldView,VerifyCodeButton,AgreementCheckboxView}.swift`
- Assets（均为 Figma MCP 原始资源）: `login_hero_bg` / `login_logo` / `login_phone_icon` / `login_code_icon` / `login_wechat` / `login_checkbox`
