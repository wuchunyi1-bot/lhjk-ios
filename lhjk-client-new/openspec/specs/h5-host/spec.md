# H5 宿主 — App WebView 与 H5 交互

> 权威文档：`h5接入文档`（Hash 路由 `{base}/#/{path}?{query}`）  
> 代码：`H5Config`、`FundePageURL`、`WebViewController`、`FundeNativeBridge`

App 用 `WebViewController` 承载 H5。交互分两层：**打开页面**（URL + Query）与 **JSBridge**（H5 ↔ 原生）。

---

## 1. 打开 H5

形态：`{baseURL}/#/{path}?token={access_token}&platform=ios&senior={0\|1}&{业务参数}`

| 参数 | 必填 | 说明 |
|------|------|------|
| `token` | 需登录页 | `auth_access_token`；H5 读取后从地址栏移除 |
| `platform` | 建议 | 固定 `ios` |
| `senior` | 是 | 长辈模式：`1` 开启，`0` 关闭。跳转时读本地 `fd_senior_mode`，链接里自带的同名参数不覆盖 |

入口：

| 来源 | 打开方式 |
|------|----------|
| CMS `pageUrl`（`FundeH5:`） | `FundePageURL.open` → `H5Config.authenticatedPageURL` |
| 本地路由 `/health/metrics/{key}` 等 | `HealthRoutes` / `H5Config.authenticatedMetricURL` |
| 资讯详情 | `H5Config.contentDetailPageURL`（本页可不传 token） |

`FundeH5:/package/bridge?packageId=123&hospitalId=456` 打开后即为：

```
{base}/#/package/bridge?packageId=123&hospitalId=456&token=xxx&platform=ios&senior=0
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
| 运动打卡 | `#/exercise-food/check-in` | `taskId`（今日健康任务）；`monitorId` 可选 | `/exercise-food/check-in`、`…/add-motion` |
| 健康档案 | `#/health/record` | — | `/health/record`、`/me/health-profile` |
| 健康报告 | `#/health/report` | — | `/health/report`、`/health/assessment/report`、`/me/health-report` |
| 健康报告详情 | `#/health/report/detail` | `id` 必填（报告 id） | `/health/report/detail`、`/me/health-report/detail` |
| 健康评估 | `#/health-assessment` | — | `/me/health-assessment`、`/health-assessment` |
| 健康测评 | `#/health-evaluations` | — | `/me/health-evaluations`、`/health-evaluations` |
| 饮食方案 | `#/diet-plan` | `date` 可选（`yyyy-MM-dd`，默认当天） | `/me/diet-plan`、`/diet-plan` |
| 体检报告 | `#/medical-reports` `/detail` `/upload` | 详情 `reportId` | `/me/medical-reports*` |
| 监测方案 | `#/monitoring-plan` `/{key}` | `type` 可选 | `/me/monitoring-plan` |
| 用药 | `#/medication` | — | `/medication` |
| 营养补剂 | `#/supplement` | — | `/supplement`（健康 Tab / CMS 列表） |
| 营养补剂录入 | `#/supplement/add` | `taskId` 可选（今日健康任务） | `/supplement/add?taskId=` |
| 血氧 | `#/spo2` | — | `/spo2`、`/health/metrics/spo2` |
| 鹰瞳眼底 | `#/fundus` | — | `/health/metrics/fundus`。页内「扫一扫」走 `FundeBridge` `scanCode`，不由 H5 打开摄像头 |
| 健康陪伴列表 | `#/companion` | — | 首页「更多 ›」、`/companion`、`FundeH5:/companion` |
| 资讯详情 | `#/content/detail` | `id` 必填 | 首页健康陪伴条目等 |
| **套餐中间页** | `#/package/bridge` | `packageId` 必填；`hospitalId` 可选 | CMS `FundeH5:/package/bridge?…` |

`meal`：`breakfast` / `lunch` / `dinner` / `snack`。

---

## 3. JSBridge 通道

`WebViewController` 同时注册两个 handler（名称必须与 H5 一致）：

| Handler | 方向 | 用途 |
|---------|------|------|
| **`FundeBridge`** | H5 → Native | 套餐跳转、饮食方案保存食谱到相册、体检报告文档预览、原生扫码 |
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

保存食谱（饮食方案页「保存食谱到手机」）同一通道，字段仍在顶层：

```json
{
  "action": "saveImageToAlbum",
  "dateTime": "2026-09-04",
  "schemeId": "123",
  "fileName": "食谱清单.png",
  "bizType": "dietPoster"
}
```

`fileName` 缺省「食谱清单.png」，`bizType` 缺省 `dietPoster`。宿主用登录态 `GET /v1/diningScheme/downloadDietPoster` 按二进制取图并写入相册。

体检报告详情「查看原件」同一通道。图片仍由 H5 自己预览；`pdf`、`doc`、`docx`、`xls`、`xlsx`、`ppt`、`pptx` 交给宿主。无异步结果回传。

```json
{
  "action": "previewDocument",
  "fileUrl": "https://image.lianhaojiankang.com/common/example.pdf",
  "fileName": "体检报告.pdf",
  "fileType": "pdf"
}
```

| 字段 | 必填 | 说明 |
|------|------|------|
| `action` | 是 | 固定 `previewDocument` |
| `fileUrl` | 是 | 完整 HTTPS 地址，保留签名 query，不重复 URL 解码 |
| `fileName` | 是 | 显示名称；缺省「报告原件」 |
| `fileType` | 是 | 小写扩展名，无点号，仅上述七种 |

宿主校验地址与类型后下载到缓存目录（不附加业务登录 token），再用 Quick Look 打开。关闭预览回到原 WebView。

鹰瞳眼底 `#/fundus` 点击「扫一扫」走同一通道。二维码内容是设备 SN 原文（如 `FN12416A288AA00205XB`），H5 不访问摄像头。`onlyFromCamera` 为 true 时只打开相机，不提供相册。

```json
{
  "action": "scanCode",
  "callback": "FundeScanCodeCallback",
  "scanType": ["qrCode"],
  "onlyFromCamera": true
}
```

宿主在主线程打开原生「扫一扫」页。关闭扫码页、回到原 WebView 后，在该 WebView 的 JS 上下文调用 `window.{callback}`。成功、取消、失败都要回传，包括返回键、右滑返回和拒绝相机权限。`callback` 缺省 `FundeScanCodeCallback`，且必须是合法 JS 标识符。

成功：

```javascript
window.FundeScanCodeCallback({
  action: 'scanCode',
  status: 'success',
  data: { result: 'FN12416A288AA00205XB' }
})
```

取消（返回键、右滑返回）：

```javascript
window.FundeScanCodeCallback({
  action: 'scanCode',
  status: 'cancel'
})
```

失败（拒绝相机权限、相机不可用、初始化失败）：

```javascript
window.FundeScanCodeCallback({
  action: 'scanCode',
  status: 'fail',
  message: '相机权限被拒绝'
})
```

`result` 为扫码原文，不拼接 token 或其它 query。`scanType` 含 `qrCode` 时只识别二维码。

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

### Requirement: FundeBridge 保存食谱到相册

饮食方案 H5「保存食谱到手机」SHALL 经 `FundeBridge` `action=saveImageToAlbum` 由宿主下载海报并写入相册。

#### Scenario: 保存成功

- **WHEN** H5 postMessage `action=saveImageToAlbum`
- **THEN** 读取 `dateTime`、`schemeId`、`fileName`（缺省「食谱清单.png」）、`bizType`（缺省 `dietPoster`）
- **AND** `GET /v1/diningScheme/downloadDietPoster` 仅传非空 query，响应按二进制解码为图片并写入相册
- **AND** 提示「已保存到相册」

#### Scenario: 下载失败

- **WHEN** 响应为业务错误 JSON 或无法解码为图片
- **THEN** 不写入相册，提示失败原因

#### Scenario: 相册权限拒绝

- **WHEN** 添加相册权限被拒绝或受限
- **THEN** 不写入相册，引导用户在系统设置中开启

### Requirement: FundeBridge 预览报告原件

体检报告详情「查看原件」中的文档 SHALL 经 `FundeBridge` `action=previewDocument` 由宿主下载并预览。图片预览不走该动作。投递成功后无异步回传。

#### Scenario: 打开文档

- **WHEN** H5 postMessage `action=previewDocument`，`fileUrl` 为 HTTPS，`fileType` 为 `pdf`、`doc`、`docx`、`xls`、`xlsx`、`ppt`、`pptx` 之一
- **THEN** 显示加载提示，将 `fileUrl` 原样下载到缓存目录，不附加业务登录 token，不重复 URL 解码
- **AND** HTTP 成功后在主线程用 `QLPreviewController` 打开本地文件，`fileName` 作为显示名称，落盘名去掉路径字符并保留扩展名
- **AND** 关闭预览回到原 WebView，不重建页面

#### Scenario: 地址或类型无效

- **WHEN** `fileUrl` 不是 HTTPS，或 `fileType` 不在上述七种之内
- **THEN** 不下载，提示无法打开

#### Scenario: 下载或预览失败

- **WHEN** 下载超时、HTTP 失败、响应为空，或 Quick Look 无法预览该文件
- **THEN** 关闭加载提示并提示原因
- **AND** 链接过期（HTTP 401/403）时提示返回报告重新获取

### Requirement: FundeBridge 原生扫码

鹰瞳眼底 H5「扫一扫」SHALL 经 `FundeBridge` `action=scanCode` 打开原生扫码页。H5 MUST NOT 直接访问摄像头。扫码页关闭并回到原 WebView 后，宿主 SHALL 调用 payload 中的 `callback`（缺省 `FundeScanCodeCallback`）。

#### Scenario: 扫到设备 SN

- **WHEN** H5 postMessage `action=scanCode`，`scanType` 含 `qrCode`，`onlyFromCamera` 为 true
- **THEN** 主线程 push 标题为「扫一扫」的相机扫码页，只识别二维码，不提供相册选图
- **AND** 识别成功后关闭扫码页，回到原 WebView
- **AND** 调用 `window.FundeScanCodeCallback({ action:'scanCode', status:'success', data:{ result } })`，`result` 为二维码原文

#### Scenario: 返回或右滑取消

- **WHEN** 用户点击返回或右滑返回，且未识别到码
- **THEN** 关闭扫码页并调用 `window.FundeScanCodeCallback({ action:'scanCode', status:'cancel' })`

#### Scenario: 拒绝相机权限或相机不可用

- **WHEN** 相机权限被拒绝、权限受限、设备无相机或相机会话初始化失败
- **THEN** 关闭扫码页并调用 `window.FundeScanCodeCallback({ action:'scanCode', status:'fail', message })`
- **AND** 拒绝权限时 `message` 为「相机权限被拒绝」

### Requirement: 体重 BLE 仍走 FundeNative

既有 `FundeNative` + `__fundeBridge` 体重蓝牙通道 SHALL 保持不变。
