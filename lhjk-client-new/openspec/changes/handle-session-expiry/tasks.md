## 1. Detection & Coordinator

- [x] 1.1 在 `APIManager` 增加会话失效 raw JSON 检测与 `onSessionInvalidated` 回调；认证请求成功/401 失败时调用
- [x] 1.2 实现 `SessionExpiryCoordinator`（BLL）：去重、清会话/缓存/IM/融云/UserManager、主线程展示入口
- [x] 1.3 在 `SceneDelegate`（或 App 启动）注册 `APIManager.onSessionInvalidated → Coordinator`
- [x] 1.4 A0230/401：优先 `refreshCredentialIfPossible`；失败再弹窗；启用 `requiresRefresh`

## 2. UI

- [x] 2.1 实现 `SessionExpirySheet`（PL）：底部 sheet，标题/说明/「重新登录」，遮罩不可关
- [x] 2.2 点击「重新登录」设置 `fd_session_expired_hint` 并 `Router.setRoot("/login")`

## 3. Polish

- [x] 3.1 确认登录页 `applySessionExpiredIfNeeded` 仍消费 hint
- [x] 3.2 勾选本 tasks 完成项；提示开发者将新增 Swift 文件加入 Xcode
