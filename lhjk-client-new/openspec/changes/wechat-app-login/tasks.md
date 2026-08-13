## 1. BLL 模型与接口

- [x] 1.1 以 `WeChatLoginStep` 替换 Mock `WechatAuthResult` / `wechatTempToken`
- [x] 1.2 `LoginService.loginByWeChat(code:)` 真实 `WE_CHAT_APP_LOGIN`；映射 `AU0001`
- [x] 1.3 `LoginService.loginByWeChatBinding(code:mobile:smsCode:)` 真实二次 token
- [x] 1.4 更新 `LoginServiceProtocol`、`LoginError`（含 `AU0001` 文案映射）；抽取存 Token 私有方法

## 2. SDK

- [x] 2.1 `WeChatSDKManager.sendAuth` 校验回调 `state`

## 3. PL 编排

- [x] 3.1 `LoginViewModel.startWeChatLogin`：SDK → BLL → 成功编排或抛出需绑定
- [x] 3.2 `LoginViewController` 去掉 mock code；绑定页使用微信 `code`；取消清 code
- [x] 3.3 `PhoneBindingView` 发码走真实 `sendVerificationCode(.login)`

## 4. 文档

- [x] 4.1 `docs/api-inventory.md` 注明 token 支持 `WE_CHAT_APP_LOGIN` / `AU0001`
- [x] 4.2 勾选本 tasks 完成项
