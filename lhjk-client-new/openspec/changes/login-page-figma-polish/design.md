## Context

对照 Figma「登录页-优化前 / 优化后」并排稿，仅改登录主路径 UI；忘记密码 / 绑定手机号仍用 pill 验证码按钮。

## Decisions

1. **资源来源**：通过官方 Figma MCP `get_design_context` / `download_assets` 从节点 `3021:569` 下载原始资源，禁止截图裁切、生成图或占位图。
   - `login_hero_bg` ← Figma `3021:587` 原始 PNG
   - `login_logo` ← Figma `3021:590` 原始 SVG
   - `login_phone_icon` ← Figma `3021:577` 原始 PNG
   - `login_code_icon` ← Figma `3021:579` 原始 PNG
   - `login_wechat` ← Figma `3021:618` 原始 SVG
   - `login_checkbox` ← Figma `3021:624` 原始 SVG
2. **验证码**：登录页 `VerifyCodeButton(style: .inline)` 挂 `LoginFieldView.trailingAccessoryView`；其它页 `.pill`。
3. **主按钮**：`CAGradientLayer` `#FE9B43 → #FE622C`（通过登录 Token），375pt 基准下 `327×51`、圆角 `25.5`。
4. **协议位置**：底部；业务校验逻辑不变。
5. **过期提示**：`sessionExpiredLabel`，由 `UserDefaults fd_session_expired_hint` 控制，非常驻。
6. **几何基准**：画板 `375×830`；头图高 `243`，表单从 `y=251` 开始，主按钮 `y=448`，微信入口 `y=592`，协议 `y=722`。窄屏通过 ScrollView 保持可滚动。
7. **字体**：Figma 标题使用 DingTalk JinBuTi，正文使用 OPPO Sans；工程未内置字体文件，因此 Token 优先尝试 DingTalk 字体，缺失时回退系统中文字体。资源与几何不作替代。

## Non-Goals

- 不改登录 API / ViewModel 流程
- 不实现真实微信 SDK（入口可见，仍走现有 mock sheet）
