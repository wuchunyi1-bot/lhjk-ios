## Context

funde 网关对登录失效常返回 HTTP 200 + `code=A0230` / `msg=登录已失效!`。iOS 侧 `OAuthAuthenticator` 仅在 HTTP 401 时刷新，且 `OAuthCredential.requiresRefresh == false`，业务码失效完全被忽略。原型通过 `fd-auth-expired` 事件弹出底部 sheet，点击「重新登录」进登录页。

约束：PL → BLL → DAL；AI 不改 pbxproj（新文件需开发者手动加入工程）；Apifox 只读。

## Goals / Non-Goals

**Goals:**

- 认证 Session 请求响应中识别会话失效业务码并统一处理
- **优先** `refresh_token` 静默续期；失败再清登录态 + 全局弹窗
- 点击「重新登录」进登录页并打上登录页失效提示标记
- 启用 `OAuthCredential.requiresRefresh`（本地过期前 60s 由 Alamofire 自动刷新）

**Non-Goals:**

- 刷新成功后自动重放触发 `A0230` 的那一次业务请求（用户再次操作 / 下一次 `load` 即可）
- 密码变更 / 他端登录 专属文案与路由 redirect 回跳
- 修改登录流程内验证码错误码映射（登录未认证 `publicSession` 不触发本流程）

## Decisions

1. **在 DAL 解析 raw JSON 的 `code`/`msg`，不依赖 `APIResponse` 泛型成功分支**  
   - 原因：业务码在 HTTP 200 下仍会 decode 成功并交给 BLL；必须在统一出口拦截。  
   - 备选：各 Service 各自判断 → 易漏。

2. **仅认证 `session` 触发；`publicSession` 不触发**  
   - 避免登录/发码等公开接口误弹「登录过期」。

3. **识别规则**  
   - `code == "A0230"`，或 msg 含「登录已失效」「登录状态已过期」等明确会话失效文案。  
   - HTTP 401（认证请求）在 Interceptor 刷新失败后同样走协调器。

4. **A0230 → 先 `APIManager.refreshCredentialIfPossible()`，失败再弹窗**  
   - 复用已有 `POST /auth/oauth2/token` + `grant_type=refresh_token`（`OAuthAuthenticator` / inventory 已登记）。  
   - 手动刷新成功用 `setCredential` 重建 Session（非 Interceptor 内的 `persistRefreshedCredential`）。

5. **协调器放 BLL：`SessionExpiryCoordinator`；展示由 PL 注入**  
   - DAL：`APIManager.onSessionInvalidated`  
   - BLL：去重 + refresh +（失败时）清会话  
   - PL：`SessionExpiryPresenter` + `SessionExpirySheet`

6. **UI：底部 sheet 对齐原型 `session-sheet`（非系统 Alert）**  
   - 仅刷新失败后展示；遮罩不可点关。

7. **清理范围对齐主动退出（不做 logout API）**  
   - 仅刷新失败后：`clearSession` + IM / Hub / Health / Institution / 融云 / `UserManager.clear`。

## Risks / Trade-offs

- [refresh 接口本身也返回失效] → 走弹窗重新登录  
- [并发多接口同时 A0230] → 协调器 `isHandling` 门闩，只刷新一次  
- [刷新成功但当前页已用空数据渲染] → 不自动重放原请求；用户下拉/再进页可拉到数据  
- [JWT `exp` 极长但网关仍发 A0230] → 依赖业务码路径刷新，不单靠 `requiresRefresh`  
- [登录页自身若误用认证 Session] → 公开接口走 `publicSession`；协调器若已在登录根且无 credential 则忽略  

## Migration Plan

- 增量上线；无数据迁移。回滚：移除响应钩子与协调器注册即可。

## Open Questions

- 无。redirect 回跳留后续登录中间件迭代。
