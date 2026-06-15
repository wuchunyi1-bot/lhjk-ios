## 1. Design Token 基础设施

- [ ] 1.1 创建 `Other/Common/Extensions/UIColor+Theme.swift`，定义所有 `UIColor.fd*` Token（来源 funde-client tokens.css）
- [ ] 1.2 创建 `Other/Common/Extensions/UIFont+Theme.swift`，定义 `UIFont.fd*` 字号映射

## 2. 可复用组件（PL 层）

- [ ] 2.1 创建 `PL/RegisterLogin/Components/BrandHeaderView.swift` — Logo Mark（72×72 品牌色方块）+ 名称 + Slogan
- [ ] 2.2 创建 `PL/RegisterLogin/Components/LoginFieldView.swift` — label + icon + textField 组合控件，支持 focus/unfocus 边框色切换、密码显隐切换
- [ ] 2.3 创建 `PL/RegisterLogin/Components/VerifyCodeButton.swift` — 60s 倒计时按钮（默认态「获取验证码」→ 倒计时态「{N}s 后重发」→ 结束态「重新获取」）
- [ ] 2.4 创建 `PL/RegisterLogin/Components/AgreementCheckboxView.swift` — 协议勾选框 + 富文本链接（《用户协议》《隐私政策》可点击跳转）
- [ ] 2.5 创建 `PL/RegisterLogin/Components/CaptchaVerifyView.swift` — 拼图滑块验证弹窗（滑块 + 拼图区域 + 关闭/刷新按钮）
- [ ] 2.6 创建 `PL/RegisterLogin/Components/PrivacyPromptView.swift` — 隐私保护提示弹窗（标题 + 说明 + 协议链接 + 同意/不同意按钮）
- [ ] 2.7 创建 `PL/RegisterLogin/Components/WechatLoginButton.swift` — 52×52 圆形浮动按钮
- [ ] 2.8 创建 `PL/RegisterLogin/Components/WechatAuthSheetView.swift` — 微信授权底部弹层
- [ ] 2.9 创建 `PL/RegisterLogin/Components/PhoneBindingView.swift` — 微信绑定手机号弹层（手机号 + 验证码 + 提交）
- [ ] 2.10 创建 `PL/RegisterLogin/Components/NotificationGuideView.swift` — 通知权限预引导弹窗

## 3. 登录主页面

- [ ] 3.1 重写 `PL/RegisterLogin/LoginViewController.swift` — 按新 spec 完整实现全屏登录布局
- [ ] 3.2 实现隐私授权检查逻辑：首次打开或协议更新时先展示 PrivacyPromptView，不同意则展示不可用状态页
- [ ] 3.3 实现本机号检测：默认展示脱敏本机号（V1.0 mock），失败降级为手动输入
- [ ] 3.4 实现双模式切换逻辑（验证码 ↔ 密码），含表单字段的显示/隐藏与动画，切换时保留已输入手机号
- [ ] 3.5 实现协议勾选校验：获取验证码、验证码登录、密码登录、微信绑定前均需校验勾选状态
- [ ] 3.6 实现拼图验证流程：点击获取验证码 → 拼图弹窗 → 获取 captcha_token → 发送验证码
- [ ] 3.7 集成 Keyboard 管理（`IQKeyboardManager` 或手动监听 `UIKeyboardWillShow/Hide`）确保输入框和主按钮不被遮挡
- [ ] 3.8 实现完整输入验证（手机号格式、验证码 6 位、密码至少 6 位、非空校验）+ 30 条错误提示文案
- [ ] 3.9 实现协议链接点击（通过 Router 打开 WebView）
- [ ] 3.10 实现登录成功后 redirect/deeplink 处理（白名单校验、非法目标回退 `/home`）

## 4. 忘记密码

- [ ] 4.1 创建 `PL/RegisterLogin/ForgotPasswordViewController.swift` — 忘记密码页
- [ ] 4.2 实现忘记密码流程：手机号 → 拼图验证 → 发送验证码 → 输入验证码 → 设置新密码 → 提交重置
- [ ] 4.3 重置成功后返回密码登录页并预填手机号

## 5. 微信登录与绑定

- [ ] 5.1 实现微信授权弹层（WechatAuthSheetView）展示与交互
- [ ] 5.2 实现微信已绑定手机号的直接登录路径
- [ ] 5.3 实现微信未绑定手机号的绑定流程（PhoneBindingView）
- [ ] 5.4 实现手机号绑定冲突处理：手机号已绑定其他微信 → 二次确认后换绑；微信已绑定其他手机号 → 阻止并引导客服

## 6. 通知权限

- [ ] 6.1 实现登录成功后通知预引导弹窗（NotificationGuideView）
- [ ] 6.2 实现系统通知权限请求（`UNUserNotificationCenter.requestAuthorization`）
- [ ] 6.3 处理权限各状态（允许/拒绝/系统不再弹窗），均不阻塞进入首页

## 7. 登录态与账号状态管理

- [ ] 7.1 实现登录过期检测：token 失效时清理登录态、跳转登录页、展示过期提示、携带 redirect
- [ ] 7.2 实现账号冻结/注销中状态处理：阻止登录，展示对应弹窗提示
- [ ] 7.3 实现密码变更导致的登录态失效处理

## 8. 业务逻辑层（BLL）

- [ ] 8.1 创建 `BLL/RegisterLogin/LoginServiceProtocol.swift` — 定义完整登录业务接口（隐私版本、本机号、验证码、密码、微信、重置密码、会话状态、通知权限）
- [ ] 8.2 创建 `BLL/RegisterLogin/LoginService.swift` — 实现协议（V1.0 阶段可 mock 所有接口）
- [ ] 8.3 实现验证码发送与倒计时协调逻辑
- [ ] 8.4 实现登录成功后的 token 存储（iOS Keychain）与读取

## 9. 集成

- [ ] 9.1 在 SceneDelegate / Router 中注册登录页路由拦截中间件，支持 redirect/deeplink 参数传递
- [ ] 9.2 登录成功后 dismiss 登录页 → 根据 redirect/deeplink 进入目标页或主 Tab 页
- [ ] 9.3 注册 App 内目标页白名单，实现 redirect/deeplink 合法性校验
- [ ] 9.4 编译验证：确保无编译错误，在 iOS 15.0 Simulator 上可正常展示和交互

## 10. 错误处理与边界测试

- [ ] 10.1 覆盖全部 30 条错误提示文案（MSG-01 至 MSG-30）的触发规则
- [ ] 10.2 覆盖异常场景：网络异常、服务超时、系统异常、离线状态
- [ ] 10.3 覆盖重复提交防护：所有提交按钮在请求进行中禁用
- [ ] 10.4 覆盖测试数据场景：固定验证码 `111111`、新用户、已注册用户、冻结账号、注销中账号
