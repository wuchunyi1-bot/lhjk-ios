## Context

体征监测 H5 与 funde-client 前端对齐，使用 hash 路由。iOS App 健康 Tab 的 Hub 卡片与「体征监测」网格页仍由原生 UIKit 渲染（mock 摘要数据），用户点击任意指标后进入内嵌 WebView。

## Decisions

### 1. 路由统一为 H5

| 原生路由 | 目标 |
|---------|------|
| `/health/metrics/{key}` | `WebViewController` → `H5Config.metricPageURL(for: key)` |
| `/health/metrics/{key}/manual` 等子路由 | 同上（H5 内部管理子页面） |
| `/health/metrics/add?key={key}` | 同上 |

支持的 `key`（与 Hub / MetricsView 一致）：

| key | 标题 | H5 hash |
|-----|------|---------|
| `blood-pressure` | 血压 | `#/blood-pressure` |
| `blood-sugar` | 血糖 | `#/blood-sugar` |
| `weight` | 体重 | `#/weight` |
| `heart-rate` | 心率 | `#/heart-rate` |
| `sleep` | 睡眠 | `#/sleep` |
| `ecg` | 心电 | `#/ecg` |
| `fundus` | 鹰瞳眼底 | `#/fundus` |
| `exercise` | 饮食运动 | `#/exercise` |
| `spo2` | 血氧 | `#/spo2` |
| `digestive` | 消化道 | `#/digestive` |

### 2. H5Config

```swift
enum H5Config {
    static var environment: H5Environment = .development
    static let metricKeys: [(key: String, title: String)]
    static func metricPageURL(for key: String) -> URL
    static func metricTitle(for key: String) -> String
}
```

环境 base URL：
- development: `http://192.168.15.249:5181`
- staging / production: 待定正式域名

### 3. 删除原生实现

以下代码**全部删除**（不再保留回退）：

**BLL**：`BloodPressureService`、`BloodSugarService`、`WeightService`、`ExerciseFoodService` 及对应 Models；`BluetoothService`（仅体征模块使用）。

**PL**：`PL/Health/Metrics/` 下除 `MetricsViewController.swift` 外的所有 ViewController、ViewModel、Cell、Component（含血压/血糖/体重/饮食运动完整子目录，以及心率/睡眠/血氧/心电/眼底/消化道占位页、`MetricAddViewController`、`MetricRulerView`、ECG Cells）。

### 4. 保留原生部分

- `HealthViewController` + `HealthVitalMetricsCell` + `MetricCardCell`（Hub 体征卡片）
- `MetricsViewController`（体征监测网格页）
- `WebViewController`（通用 H5 容器）
- 健康档案、评估报告等非体征子模块

### 5. Info.plist ATS（开发者手动）

dev H5 为 HTTP + IP，需在 `NSAppTransportSecurity` 下添加 `NSAllowsArbitraryLoads` 或改用 HTTPS 正式域名。AI 不修改 Info.plist。

### 6. 登录态注入 H5

Token / Cookie 注入方案待 H5 联调；当前仅加载 URL，不附带鉴权参数。

## Risks / Trade-offs

- Hub / MetricsView 仍展示 mock 摘要，与 H5 内真实数据可能不一致，待后续接 Hub API
- 删除原生代码后无法离线查看体征；全部依赖 H5 与网络
