# Health Metrics / 体征监测

## Purpose

定义健康模块「体征监测」在 iOS App 中的入口行为：**Hub 卡片与指标网格由原生渲染，所有指标详情/录入/历史由 H5 WebView 承载**。

> **Reference**: H5 dev `http://192.168.15.249:5181/#/{metric-key}`
> **Supersedes**: 原生 DGCharts 详情页、Angel API BLL、`MetricAddViewController`

---

## Architecture

```
健康 Tab (原生)
├── HealthViewController (Hub)
│   └── HealthVitalMetricsCell → MetricCardCell × 10
│       └── tap → Router.push("/health/metrics/{key}")
├── MetricsViewController (体征监测网格)
│   └── MetricCardCell × 10
│       └── tap → Router.push("/health/metrics/{key}")
└── WebViewController (H5)
    └── H5Config.metricPageURL(for: key)
```

**三层职责**：
- **PL**：仅 Hub / 网格入口 UI + `WebViewController` 容器
- **BLL**：`HealthRoutes` 注册路由；`H5Config` 管理 URL
- **DAL**：无体征专用网络层（H5 自行请求后端）

---

## Requirements

### Requirement: Metric Keys

SHALL 支持以下 10 个指标 key，与 Hub / MetricsView mock 数据一致：

| key | 中文标题 |
|-----|---------|
| `blood-pressure` | 血压 |
| `blood-sugar` | 血糖 |
| `weight` | 体重 |
| `heart-rate` | 心率 |
| `sleep` | 睡眠 |
| `ecg` | 心电 |
| `fundus` | 鹰瞳眼底 |
| `exercise` | 饮食运动 |
| `spo2` | 血氧 |
| `digestive` | 消化道 |

#### Scenario: H5 URL 构建
- **WHEN** 需要打开指标 `blood-pressure`
- **THEN** URL 为 `{H5Environment.baseURL}#/blood-pressure`

---

### Requirement: Hub Entry

SHALL 在 `HealthViewController` 体征监测区块展示 10 张 `MetricCardCell`。

#### Scenario: 卡片点击
- **WHEN** 用户点击任意指标卡片
- **THEN** `Router.push("/health/metrics/{key}")` 打开 H5 WebView

---

### Requirement: Metrics Grid Entry

SHALL 提供 `/health/metrics` 路由，展示 2×N 指标网格（`MetricsViewController`）。

#### Scenario: 网格点击
- **WHEN** 用户在网格页点击指标
- **THEN** 跳转逻辑与 Hub 一致，打开对应 H5 页

---

### Requirement: H5 WebView Route

SHALL 将所有体征相关路由解析为 `WebViewController`。

#### Scenario: 主路由
- **WHEN** 访问 `/health/metrics/{key}`（key 为上表之一）
- **THEN** 展示 `WebViewController`，`urlString = H5Config.metricPageURL(for: key)`，`title = H5Config.metricTitle(for: key)`

#### Scenario: 兼容子路由
- **WHEN** 访问历史深链，如 `/health/metrics/blood-pressure/manual`、`/health/metrics/weight/detail`、`/health/metrics/exercise/add-diet`
- **THEN** 仍打开同一 H5 入口页（`#/{key}`），由 H5 处理内部导航

#### Scenario: 录入路由
- **WHEN** 访问 `/health/metrics/add?key={key}`
- **THEN** 打开 `#/{key}` 对应 H5 页

---

### Requirement: H5 Environment

SHALL 通过 `H5Config.environment` 切换 H5 base URL。

| Environment | base URL |
|-------------|----------|
| development | `http://192.168.15.249:5181` |
| staging | `https://staging-h5.lhjk.com` |
| production | `https://h5.lhjk.com` |

---

### Requirement: No Native Metric Implementation

SHALL NOT 在 App 内实现体征详情、图表、手动录入、Angel API 调用。

#### Scenario: 已删除能力
- **THEN** 不存在 `BloodPressureViewController`、`WeightService`、`MetricAddViewController` 等原生体征实现
- **THEN** `AppContainer` 不暴露体征 BLL Service

---

## Route Registration

| Route | Target | Status |
|-------|--------|--------|
| `/health` | HealthViewController | ✅ 原生 Hub |
| `/health/metrics` | MetricsViewController | ✅ 原生网格 |
| `/health/metrics/{key}` | WebViewController → H5 | ✅ |
| `/health/metrics/{key}/*` | WebViewController → H5 | ✅ 兼容 |
| `/health/metrics/add?key={key}` | WebViewController → H5 | ✅ |

---

## Deferred

- Hub / MetricsView 摘要数据接真实 API（当前 mock）
- H5 与 App 登录态同步（Token / Cookie 注入）
- 生产环境 HTTPS 与 ATS 正式配置
