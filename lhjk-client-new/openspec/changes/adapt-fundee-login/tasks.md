## 1. Design Token 基础设施

- [ ] 1.1 创建 `Other/Common/Extensions/UIColor+Theme.swift`，定义所有 `UIColor.fd*` Token（来源 funde-client tokens.css）
- [ ] 1.2 创建 `Other/Common/Extensions/UIFont+Theme.swift`，定义 `UIFont.fd*` 字号映射

## 2. 可复用组件（PL 层）

- [ ] 2.1 创建 `PL/RegisterLogin/Components/BrandHeaderView.swift` — Logo Mark（72×72 品牌色方块）+ 名称 + Slogan
- [ ] 2.2 创建 `PL/RegisterLogin/Components/LoginFieldView.swift` — label + icon + textField 组合控件，支持 focus/unfocus 边框色切换
- [ ] 2.3 创建 `PL/RegisterLogin/Components/VerifyCodeButton.swift` — 60s 倒计时按钮
- [ ] 2.4 创建 `PL/RegisterLogin/Components/WechatLoginButton.swift` — 52×52 圆形浮动按钮
- [ ] 2.5 创建 `PL/RegisterLogin/Components/WechatAuthSheetView.swift` — 微信授权底部弹层

## 3. 登录主页面

- [ ] 3.1 重写 `PL/RegisterLogin/LoginViewController.swift` — 按新 spec 完整实现全屏登录布局
- [ ] 3.2 实现双模式切换逻辑（验证码 ↔ 密码），含表单字段的显示/隐藏与动画
- [ ] 3.3 集成 Keyboard 管理（`IQKeyboardManager` 或手动监听 `UIKeyboardWillShow/Hide`）确保输入框不被遮挡
- [ ] 3.4 实现输入验证（手机号格式、非空校验）+ Toast 提示
- [ ] 3.5 实现协议链接点击（通过 Router 打开 WebView）

## 4. 业务逻辑层（BLL）

- [ ] 4.1 创建 `BLL/RegisterLogin/LoginServiceProtocol.swift` — 定义登录业务接口
- [ ] 4.2 创建 `BLL/RegisterLogin/LoginService.swift` — 实现协议（初始阶段可 mock）
- [ ] 4.3 实现验证码发送与倒计时协调逻辑

## 5. 集成

- [ ] 5.1 在 SceneDelegate / Router 中注册登录页路由拦截中间件
- [ ] 5.2 登录成功后 dismiss 登录页 → 展示主 Tab 页
- [ ] 5.3 编译验证：确保无编译错误，在 iOS 15.0 Simulator 上可正常展示和交互
