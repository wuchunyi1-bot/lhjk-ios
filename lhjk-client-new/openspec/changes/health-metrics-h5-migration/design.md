## Context

H5 宿主接入文档约定：

```
{baseURL}#/{路径}?token={access_token}&platform=ios&{业务参数}
```

- `token`：需登录页面必填，H5 读取后从地址栏移除
- `platform`：建议传 `ios` / `android` / `mp`
- 饮食运动 H5 路径为 `exercise-food`，非 App key `exercise`

本期**仅健康模块体征 H5**采用 `token + platform=ios`；登录协议等其它 WebView 后续单独评估。

## Decisions

### 1. URL 构建（`H5Config`）

集中提供：

```swift
static func authenticatedMetricURL(
    metricKey: String,
    nativeSuffix: String? = nil,
    routeParams: [String: Any] = [:]
) -> URL
```

规则：

1. `metricKey` → H5 根路径（`exercise` → `exercise-food`）
2. `nativeSuffix` → H5 子路径（见下表）
3. Query 固定：`token`（有则传）、`platform=ios`
4. 业务 Query：从 `routeParams` 提取（`monitorId`、`sugarId`、`meal` 等）

`token` 来源：`UserDefaults` `auth_access_token`（与 `APIManager` 一致）。

### 2. App key → H5 path

| App `metricKey` | H5 hash 根路径 |
|-----------------|---------------|
| `blood-pressure` | `blood-pressure` |
| `blood-sugar` | `blood-sugar` |
| `weight` | `weight` |
| `exercise` | `exercise-food` |
| 其余 key | 与 key 同名（`heart-rate` → `heart-rate`，待 H5 就绪） |

### 3. 原生子路由 → H5 子路径

| 原生 suffix | H5 子路径 | 额外 Query |
|-------------|----------|-----------|
| `manual` | `add` | — |
| `history` | `records` | — |
| `detail` | `detail` | `monitorId`；血糖另需 `sugarId` |
| `service` | （无，回首页） | — |
| `add-diet` | `add` | `meal`（默认 `breakfast`） |
| `add-motion` | `check-in` | `monitorId` 可选 |
| `home` / `search` | （无，回首页） | — |

示例：

```
#/weight?token=xxx&platform=ios
#/weight/detail?token=xxx&platform=ios&monitorId=2051465082076262401
#/exercise-food/add?token=xxx&platform=ios&meal=breakfast
```

### 4. 环境 Base URL

| Environment | base URL |
|-------------|----------|
| development | `http://h5-dev.lianhaojiankang.com` |
| staging | `https://staging-h5.lhjk.com` |
| production | `https://h5.lhjk.com` |

与 `APIEnvironment` 对齐切换（本期可先手动设置 `H5Config.environment`）。

### 5. 路由层（`HealthRoutes`）

- `/health/metrics/{key}` → `authenticatedMetricURL(metricKey:key)`
- `/health/metrics/{key}/{suffix}` → 带 `nativeSuffix` 与路由 `params`
- `/health/metrics/add?key={key}` → 对应指标 H5 首页（或后续扩展为 `/add`）

`WebViewController` 仍只负责加载最终 URL，不解析业务；**返回行为**由 `WKWebView` 历史栈驱动（`canGoBack` → `goBack`，否则 pop/dismiss）。

### 6. H5 返回栈

- 导航栏返回按钮与侧滑手势统一走 `handleBackNavigation()`
- 返回时在点击/手势回调中读取 `webView.canGoBack`，无需 KVO 监听
- 侧滑：`interactivePopGestureRecognizer.delegate` 拦截，有 H5 历史时 `goBack()` 并 `return false`

### 7. 不变部分

- Hub / `MetricsViewController` 入口 UI 仍为原生 mock 摘要
- 健康档案 `/health/record` 仍走原生页（文档虽有 `#/health/record`，本期不迁）
- 无 token 时仍打开 H5（由 H5 处理未登录）；`token` 有则必传

## Risks

| Risk | Mitigation |
|------|------------|
| dev HTTP ATS | 开发者手动配置 Info.plist |
| 6 个未文档化指标 H5 未上线 | 仍带 token 打开，H5 自行兜底 |
| `token` 过期 | 依赖现有 OAuth 刷新；H5 401 由 H5 处理 |
