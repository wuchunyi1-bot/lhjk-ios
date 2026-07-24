# Health Metrics / 体征监测

## Purpose

健康模块「体征监测」：**Hub 卡片与指标网格由原生渲染，详情/录入/历史由 H5 WebView 承载**。打开 H5 时 MUST 按宿主文档拼接 `token` + `platform=ios` 及业务 query。

> **Reference**: 宿主文档 `h5接入文档.docx` — `http://h5-dev.lianhaojiankang.com/#/{path}?token=...&platform=ios`

---

## Architecture

```
健康 Tab (原生)
├── HealthViewController → HealthVitalMetricsCell → tap → /health/metrics/{key}
├── MetricsViewController → tap → /health/metrics/{key}
└── WebViewController
    └── H5Config.authenticatedMetricURL(...)
```

- **PL**：Hub / 网格入口 + `WebViewController`
- **BLL**：`HealthRoutes`、`H5Config`（URL / 鉴权 / 路径映射）
- **DAL**：无体征专用 API（H5 自行请求后端）

---

## Requirements

### Requirement: H5 鉴权 Query（健康模块）

健康体征相关 H5 URL SHALL 包含以下 query（有 token 时）：

| 参数 | 必填 | 值 |
|------|------|-----|
| `token` | 需登录页必填 | `auth_access_token` |
| `platform` | 建议 | `ios` |

#### Scenario: 打开体重首页

- **WHEN** 用户点击 Hub 体重卡片
- **THEN** 加载 URL 形如 `{baseURL}#/weight?token={access_token}&platform=ios`
- **AND** `token` 来自 App 当前登录凭证

#### Scenario: 无 token

- **WHEN** 本地无 `auth_access_token`
- **THEN** 仍构建 URL，仅含 `platform=ios`（不传 `token`）
- **AND** 由 H5 处理未登录态

---

### Requirement: Metric Keys 与 H5 路径映射

| App key | 中文 | H5 根路径 |
|---------|------|----------|
| `blood-pressure` | 血压 | `blood-pressure` |
| `blood-sugar` | 血糖 | `blood-sugar` |
| `weight` | 体重 | `weight` |
| `exercise` | 饮食运动 | `exercise-food` |
| `heart-rate` | 心率 | `heart-rate` |
| `sleep` | 睡眠 | `sleep` |
| `ecg` | 心电 | `ecg` |
| `fundus` | 鹰瞳眼底 | `fundus` |
| `spo2` | 血氧 | `spo2` |
| `digestive` | 消化道 | `digestive` |

#### Scenario: 饮食运动

- **WHEN** `metricKey == "exercise"`
- **THEN** H5 hash 路径为 `exercise-food`，**不得**使用 `#/exercise`

---

### Requirement: 子路由与业务 Query

原生深链 SHALL 映射到文档约定的 H5 子路径与 query：

| 原生路由 suffix | H5 子路径 | 业务 query |
|----------------|----------|-----------|
| `manual` | `add` | — |
| `history` | `records` | — |
| `detail` | `detail` | `monitorId`；血糖另加 `sugarId` |
| `add-diet` | `add` | `meal`（`breakfast`/`lunch`/`dinner`/`snack`，缺省 `breakfast`） |
| `add-motion` | `check-in` | `monitorId` 可选 |

#### Scenario: 体重详情深链

- **WHEN** 打开 `/health/metrics/weight/detail` 且 `params.monitorId` 有值
- **THEN** URL 为 `#/weight/detail?token=...&platform=ios&monitorId={id}`

#### Scenario: 血糖详情深链

- **WHEN** 打开 `/health/metrics/blood-sugar/detail` 且含 `sugarId`、`monitorId`
- **THEN** 两者均拼入 query

#### Scenario: 兼容旧 suffix

- **WHEN** 打开 `/health/metrics/{key}/service` 或 `/health/metrics/exercise/home`
- **THEN** 打开对应指标 H5 **首页**（无子路径）

---

### Requirement: Hub 与网格入口

SHALL 在 `HealthViewController` 展示体征卡片；点击跳转 `/health/metrics/{key}`。

#### Scenario: 卡片点击

- **WHEN** 用户点击任意指标卡片
- **THEN** `Router.push("/health/metrics/{key}")` → `WebViewController` + 鉴权 URL

#### Scenario: 体征监测网格

- **WHEN** 用户从 `/health/metrics` 网格点击指标
- **THEN** 跳转逻辑与 Hub 一致

---

### Requirement: H5 Environment

| Environment | base URL |
|-------------|----------|
| development | `http://h5-dev.lianhaojiankang.com` |
| staging | `https://staging-h5.lhjk.com` |
| production | `https://h5.lhjk.com` |

---

### Requirement: H5 内返回优先于原生 Pop

`WebViewController` 在用户触发返回（导航栏按钮或侧滑）时 SHALL 先判断 `WKWebView.canGoBack`：

1. `canGoBack == true` → `webView.goBack()`，留在当前原生容器
2. `canGoBack == false` → `navigationController.popViewController`；若为 modal 根页则 `dismiss`

#### Scenario: H5 内多级跳转后返回

- **WHEN** 用户在 H5 内从首页进入子页（如体重列表 → 详情）
- **AND** `webView.canGoBack == true`
- **THEN** 点击导航栏返回或边缘侧滑时执行 `webView.goBack()`
- **AND** 不 pop 原生 `WebViewController`

#### Scenario: H5 无历史时返回原生

- **WHEN** 用户位于 H5 入口页且 `webView.canGoBack == false`
- **THEN** 返回操作 pop 至上一个原生页面（或 dismiss modal）

---

### Requirement: 非体征 WebView 不在本期范围

登录协议、预约体检等其它 `WebViewController` 调用方 **SHALL NOT** 在本期强制追加 `token` + `platform`（后续单独变更）。

---

## Route Registration

| Route | H5 目标 |
|-------|--------|
| `/health/metrics/{key}` | `#/{h5Path}?token&platform` |
| `/health/metrics/{key}/{suffix}` | `#/{h5Path}/{subPath}?token&platform&...` |
| `/health/metrics/add?key={key}` | 指标首页 |

---

## Deferred

- Hub / MetricsView 摘要接真实 API
- 健康档案 `#/health/record` 迁移
- 体温 `#/temperature`（Hub 暂无入口）
- H5 ↔ App JSBridge（关闭页、刷新 Hub）
