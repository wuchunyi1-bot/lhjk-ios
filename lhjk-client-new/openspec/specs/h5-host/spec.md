# H5 宿主 — App WebView 与 H5 交互

> 权威文档：`h5接入文档`（Hash 路由 `{base}/#/{path}?{query}`）  
> 代码：`H5Config`、`FundePageURL`、`WebViewController`、`FundeNativeBridge`

App 用 `WebViewController` 承载 H5。交互分两层：**打开页面**（URL + Query）与 **JSBridge**（H5 ↔ 原生）。

---

## 1. 打开 H5

形态：`{baseURL}/#/{path}?token={access_token}&platform=ios&{业务参数}`

| 参数 | 必填 | 说明 |
|------|------|------|
| `token` | 需登录页 | `auth_access_token`；H5 读取后从地址栏移除 |
| `platform` | 建议 | 固定 `ios` |

入口：

| 来源 | 打开方式 |
|------|----------|
| CMS `pageUrl`（`FundeH5:`） | `FundePageURL.open` → `H5Config.authenticatedPageURL` |
| 本地路由 `/health/metrics/{key}` 等 | `HealthRoutes` / `H5Config.authenticatedMetricURL` |
| 资讯详情 | `H5Config.contentDetailPageURL`（本页可不传 token） |

`FundeH5:/package/bridge?packageId=123&hospitalId=456` 打开后即为：

```
{base}/#/package/bridge?packageId=123&hospitalId=456&token=xxx&platform=ios
```

---

## 2. 路由表（文档 → iOS）

H5 hash 路径由 `H5Config` 拼接；饮食运动根路径为 `exercise-food`（App key `exercise`）。

| 页面 | H5 路由 | 额外 Query | iOS 打开 |
|------|---------|------------|----------|
| 体重 / 录入 / 记录 / 详情 | `#/weight` `/add` `/records` `/detail` | 详情 `monitorId` 必填 | `/health/metrics/weight` + suffix |
| 体重体成分报告 | 原生 `WeightScaleResultViewController` | `monitorId` | `/health/metrics/weight/scale/result` |
| 血压 | `#/blood-pressure` … | 详情 `monitorId` | `/health/metrics/blood-pressure` |
| 血糖 | `#/blood-sugar` … | 详情 `sugarId`+`monitorId` | `/health/metrics/blood-sugar` |
| 体温 | `#/temperature` … | — | `/health/metrics/temperature` |
| 饮食运动 | `#/exercise-food` | — | `/health/metrics/exercise` |
| 添加饮食 | `#/exercise-food/add` | `meal` 必填 | `…/add-diet` |
| 运动打卡 | `#/exercise-food/check-in` | `monitorId` 可选 | `…/add-motion` |
| 健康档案 | `#/health/record` | — | `/health/record`、`/me/health-profile` |
| 健康报告 | `#/health/report` | — | `/health/report`、`/health/assessment/report`、`/me/health-report` |
| 健康报告详情 | `#/health/report/detail` | `id` 必填（报告 id） | `/health/report/detail`、`/me/health-report/detail` |
| 健康评估 | `#/health-assessment` | — | `/me/health-assessment`、`/health-assessment` |
| 健康测评 | `#/health-evaluations` | — | `/me/health-evaluations`、`/health-evaluations` |
| 饮食方案 | `#/diet-plan` | `date` 可选（`yyyy-MM-dd`，默认当天） | `/me/diet-plan`、`/diet-plan` |
| 体检报告 | `#/medical-reports` `/detail` `/upload` | 详情 `reportId` | `/me/medical-reports*` |
| 监测方案 | `#/monitoring-plan` `/{key}` | `type` 可选 | `/me/monitoring-plan` |
| 用药 | `#/medication` | — | `/medication` |
| 营养补剂 | `#/supplement` | — | `/supplement` |
| 血氧 | `#/spo2` | — | `/spo2`、`/health/metrics/spo2` |
| 健康陪伴列表 | `#/companion` | — | 首页「更多 ›」、`/companion`、`FundeH5:/companion` |
| 资讯详情 | `#/content/detail` | `id` 必填 | 首页健康陪伴条目等 |
| **套餐中间页** | `#/package/bridge` | `packageId` 必填；`hospitalId` 可选 | CMS `FundeH5:/package/bridge?…` |

`meal`：`breakfast` / `lunch` / `dinner` / `snack`。

---

## 3. JSBridge 通道

`WebViewController` 同时注册两个 handler（名称必须与 H5 一致）：

| Handler | 方向 | 用途 |
|---------|------|------|
| **`FundeBridge`** | H5 → Native | 套餐中间页等宿主导航（本文档） |
| `FundeNative` | 双向 | 体重 BLE：`ble.getStatus` / `ble.openManager` + emit 事件 |

`FundeBridge` 消息体为扁平 JSON（字段在顶层，**不是** `{ action, params }` 嵌套）：

```json
{
  "action": "navigatePackageDetail",
  "packageId": "123456",
  "hospitalId": "789"
}
```

H5 调用：`window.webkit.messageHandlers.FundeBridge.postMessage(payload)`。

---

## 4. 套餐中间页 → 原生详情

CMS 统一配 `FundeH5:/package/bridge?packageId=&hospitalId=`。H5 展示「查看套餐」，点击后发 `navigatePackageDetail`。

| 字段 | 必填 | 说明 |
|------|------|------|
| `action` | 是 | 固定 `navigatePackageDetail` |
| `packageId` | 是 | 套餐 ID |
| `hospitalId` | 否 | 医院 / 机构 ID，无则空字符串 |

宿主 `openPackageDetail(packageId:hospitalId:)` **MUST** 打开 **iOS 原生套餐详情**（`ServicePackageDetailViewController`），路由 `/services/pkg`，参数 `id` = packageId、可选 `hospitalId`。MUST NOT 再开一层 H5 套餐页。

`packageId` 为空时 MUST NOT 跳转。

---

## Requirements

### Requirement: 打开 H5 携带 platform 与 token

App 经 `WebViewController` 打开需登录的 H5 时 SHALL 拼接 `platform=ios`；有登录态时 SHALL 拼接 `token`。

#### Scenario: CMS FundeH5

- **WHEN** 栏位 `pageUrl` 为 `FundeH5:/package/bridge?packageId=123&hospitalId=456`
- **THEN** 打开 `{base}/#/package/bridge?packageId=123&hospitalId=456&token=…&platform=ios`

### Requirement: 注册 FundeBridge

所有 `WebViewController` SHALL 向 `WKUserContentController` 注册名为 `FundeBridge` 的 script message handler。

#### Scenario: 收到套餐跳转

- **WHEN** H5 向 `FundeBridge` postMessage，且 `action` 为 `navigatePackageDetail`，`packageId` 非空
- **THEN** 调用 `openPackageDetail`，push 原生 `/services/pkg`（`id`、可选 `hospitalId`）

#### Scenario: packageId 缺失

- **WHEN** `packageId` 为空
- **THEN** MUST NOT 打开套餐详情

#### Scenario: 未知 action

- **WHEN** `FundeBridge` 收到未实现的 `action`
- **THEN** 忽略（不崩溃）

### Requirement: 体重 BLE 仍走 FundeNative

既有 `FundeNative` + `__fundeBridge` 体重蓝牙通道 SHALL 保持不变。
