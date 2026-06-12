## ADDED Requirements

### Requirement: Route Registration
系统 SHALL 支持各业务模块在启动时向 Router 注册路由映射。

#### Scenario: 注册路由
- **WHEN** 应用启动时
- **THEN** 各 BLL 模块通过 `Router.register(path:target:action:)` 注册 URL 路径 → Target-Action 的映射关系

#### Scenario: 路由冲突检测
- **WHEN** 两个模块注册了相同的 URL 路径
- **THEN** Router 在 DEBUG 模式下输出警告日志，后者覆盖前者

### Requirement: URL-Based Navigation
系统 SHALL 支持通过 URL Scheme 进行页面跳转，格式为 `lhjk://{module}/{action}?{params}`。

#### Scenario: 内部跳转
- **WHEN** PL 层需要跳转到其他模块的页面
- **THEN** 调用 `Router.push("/home/detail?id=123")` 或 `Router.present("/health/report?type=weekly")`，路由自动解析 URL 并执行对应的 Target-Action

#### Scenario: 外部唤起（Deep Link）
- **WHEN** 应用通过 URL Scheme 或 Universal Link 被外部唤起
- **THEN** SceneDelegate 将 URL 传递给 `Router.openURL(url)`，路由解析后导航到目标页面

#### Scenario: 推送通知跳转
- **WHEN** 用户点击推送通知
- **THEN** 根据推送 payload 中的路由路径跳转到对应页面（如消息会话、健康报告详情）

#### Scenario: 路由未匹配
- **WHEN** URL 路径未注册
- **THEN** Router 降级到默认页面（首页），输出警告日志

### Requirement: Target-Action Decoupling
系统 SHALL 通过 Target-Action 模式实现模块间解耦，模块间不直接引用。

#### Scenario: 跨模块跳转
- **WHEN** 首页模块需要跳转到健康模块的详情页
- **THEN** 首页模块通过 `Router.push("/health/detail?id=xxx")` 跳转，不直接 import 健康模块的 ViewController

#### Scenario: 参数传递
- **WHEN** 跳转需要传递复杂参数
- **THEN** 参数以 Dictionary 形式通过路由传递：`Router.push("/message/chat", params: ["conversationId": "xxx", "title": "张三"])`

#### Scenario: 返回值回调
- **WHEN** 页面需要回传结果给来源页
- **THEN** 通过 `Router.push("/select/item", params: [...], completion: { result in ... })` 在页面返回时执行回调

### Requirement: Route Middleware
系统 SHALL 支持路由中间件，在页面跳转前执行拦截逻辑（如登录检查、权限校验）。

#### Scenario: 登录拦截
- **WHEN** 用户未登录时访问需要登录的页面
- **THEN** Router 的登录中间件拦截请求，先跳转登录页，登录成功后自动继续原目标页面的跳转

#### Scenario: 路由日志
- **WHEN** 每次路由跳转发生时
- **THEN** Router 记录跳转日志（来源页、目标页、参数、时间），DEBUG 模式下输出到控制台
