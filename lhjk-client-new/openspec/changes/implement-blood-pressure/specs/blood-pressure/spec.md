# Blood Pressure / 血压监测

## Purpose

从 jumper-angel-doctor `ADBloodPressure` 模块移植完整血压监测能力到 lhjk-client iOS。保持接口路径与参数字段不变，UI 样式对齐源项目。模块归属 **Health Tab**（`BLL/Health`、`PL/Health`）。

> **Reference**: jumper-angel-doctor `AngelDoctor/Classes(业务)/BuleToothDevice/ADBloodPressure/`

---

## Module Flow

```
健康 Hub / 体征网格
    └── /health/metrics/blood-pressure  →  血压服务首页
            ├── 蓝牙 Banner（绑定设备状态）
            ├── 圆环仪表 + 最新读数 + 状态
            ├── [手动记录] [历史记录]
            ├── 血压建议卡 → 详情
            ├── /manual  →  手动记录 → 保存 → 详情
            └── /history →  血压记录
                    ├── Tab0 趋势图（7/30/90 天）
                    ├── Tab1 日志（按月分页）
                    └── Tab2 统计
            └── /detail?monitorId=  →  血压详情（可删除）
```

---

## API Contract

所有接口经 `APIManager`，base 已含 `/mobile`。

### 1. 首页 / 详情数据

- **Path**: `POST /v1/monitor/getPressureHomePageData`
- **Request** (`DeviceHomeRequest`):

```json
{
  "businessId": 2,
  "monitorId": "可选，详情时传入",
  "newbornId": null,
  "sugarId": null,
  "pregnantId": null
}
```

- **Response** (`BloodPressureRecord`):

| 字段 | 类型 | 说明 |
|------|------|------|
| highBloodPressure | String/Number | 收缩压 mmHg |
| lowBloodPressure | String/Number | 舒张压 mmHg |
| heartRate | String/Number | 心率 次/分 |
| monitorResults | String | 结果文案，如「正常」 |
| monitorResultsId | String/Number | 结果字典 ID |
| color | String | 状态徽章背景色 hex |
| description | String | 健康建议 |
| recordTime | String | 毫秒时间戳 |
| monitorId | String | 记录 ID |
| dataSource | String | 来源，如「手动记录」 |

### 2. 保存记录

- **Path**: `POST /v1/monitor/saveOrUpdateMonitorData`
- **Request** (`MonitorSaveRequest`):

```json
{
  "beginTime": "毫秒时间戳字符串",
  "endTime": "毫秒时间戳字符串",
  "businessId": 2,
  "collectionType": 1,
  "version": "毫秒时间戳字符串",
  "equipmentMac": "蓝牙时必填",
  "equipmentName": "蓝牙时必填",
  "serialNumber": "蓝牙时必填",
  "monitorData": {
    "data": {
      "recordTime": "毫秒时间戳字符串",
      "highBloodPressure": 120,
      "lowBloodPressure": 80,
      "heartRate": 72
    }
  }
}
```

- `collectionType`: `1` 手动，`2` 蓝牙
- **Response**: `data.monitorData.monitorId` 用于跳转详情

### 3. 趋势历史

- **Path**: `POST /v1/monitor/selectPressureHistoryData`
- **Request**: `{ "dateType": 2, "timeType": 7|30|90, "pageSize": 1000 }`
- **Response**: 数组，每项含 `dateStr`, `timeStr`, `highBloodPressure`, `lowBloodPressure`, `heartRate`

### 4. 日志列表

- **Path**: `POST /v1/monitor/getPressureRecords`
- **Request**: `{ "dateType": 2, "searchTime": "月份毫秒戳", "pageNum": 1, "pageSize": 20 }`
- **Response**: `{ "list": [BloodPressureLogItem] }`

`BloodPressureLogItem` 字段：`dateStr`, `timeStr`, `highBloodPressure`, `lowBloodPressure`, `heartRate`, `monitorResults`, `color`, `dataSource`, `descriptionField`, `monitorId`

### 5. 统计

- **Path**: `POST /v1/monitor/getMonitorStatistics`
- **Request**: `{ "dateType": 2, "searchTime": "当前毫秒戳" }`
- **Response**: `{ "ninety": PeriodStats, "seven": PeriodStats, "thirty": PeriodStats }`

`PeriodStats`: `days`, `high`, `low`, `normal`, `noRecordDays`, `total`, `standardObtainedRate`

### 6. 删除

- **Path**: `DELETE /v1/monitor/delMonitorDataByMonitorId?monitorId={id}`

### 7. 绑定设备列表

- **Path**: `GET /v1/equipmentUser/getEquipmentUserByParam?type=4&pageNum=1&pageSize=100`
- **Response**: `{ "list": [{ "mac", "name", "imgUrl", ... }] }`

---

## Layout — 血压服务首页

```
┌──────────────────────────────────────────┐
│  Nav: 血压服务              [历史记录]      │
├──────────────────────────────────────────┤
│  BluetoothStatusBanner（设备名/连接态）    │
├──────────────────────────────────────────┤
│  UITableView                              │
│  Row0: 圆环仪表 + 收缩/舒张 + 心率 + 状态   │
│  Row1: [手动记录] | [历史记录]  双卡片入口   │
│  Row2: 血压建议（空态显示测量提示文案）      │
└──────────────────────────────────────────┘
```

- 背景 `fdBg`（对齐源 `ColorVCBg` / `#F1F3F5`）
- 圆环：`BloodPressureGaugeView`，230° 弧，绿→橙→红渐变
- 空数据：显示 `--/--`，建议标题「还没有您的血压记录」

---

## Layout — 手动记录

- 导航标题「手动记录」
- Head Cell：大号 `120/80`、心率、建议文案
- Date Row：点击弹出日期时间选择器（最大当前时间）
- Footer：`BloodPressureValuePickerView` 三列（收缩压 / 舒张压 / 心率）
- 底部「保存」→ 校验三项已选 → `saveOrUpdateMonitorData` → 跳转详情并移除手动页

---

## Layout — 历史记录

- 导航标题「血压记录」
- 顶部 Tab：`趋势图` | `日志` | `统计`（`UISegmentedControl` + 子 VC 容器）
- **趋势图**：Segment 7/30/90 天；上卡双折线（收缩+舒张），下卡心率折线；圆角 16pt 卡片
- **日志**：月份选择 `yyyy-MM`；下拉刷新 + 上拉分页；Cell 显示 `120/80 mmHg`、心率、状态色标、时间
- **统计**：头部总次数/正常/偏低/偏高 + 达标率进度条；列表近 7 天、近 30 天行

---

## Layout — 详情

- 导航标题「血压详情」
- 顶部装饰背景
- 时间行 + 右侧状态徽章（`color` 背景 + `monitorResults` 文案）
- 三列指标：收缩压 / 舒张压 / 心率（`mmHg` / `mmHg` / `次/分`）
- 建议区：服务端 `description`；固定参考范围文案
- 导航栏删除按钮 → 确认 → `delMonitorDataByMonitorId` → 发通知 → pop

---

## Requirements

### Requirement: Architecture
血压模块 SHALL 遵循 PL → BLL → DAL 单向依赖；PL 禁止直接调用 `APIManager`。

#### Scenario: Service 注入
- **WHEN** ViewModel 初始化
- **THEN** 通过 `AppContainer.shared.bloodPressureService` 注入，支持测试替换

---

### Requirement: Service Home Page
系统 SHALL 提供血压服务首页，展示最新监测数据与健康建议。

#### Scenario: 加载首页数据
- **WHEN** 页面 `viewWillAppear`
- **THEN** 调用 `getPressureHomePageData(businessId: 2)` 并刷新仪表、状态、建议区

#### Scenario: 空态建议
- **WHEN** 无历史记录（接口失败或字段为空）
- **THEN** 建议标题为「还没有您的血压记录」，正文为测量前休息 5 分钟等提示文案

#### Scenario: 历史入口
- **WHEN** 用户点击导航栏「历史记录」或记录入口卡「历史记录」
- **THEN** push `/health/metrics/blood-pressure/history`

#### Scenario: 手动入口
- **WHEN** 用户点击「手动记录」
- **THEN** push `/health/metrics/blood-pressure/manual`

---

### Requirement: Manual Entry
系统 SHALL 支持手动录入收缩压、舒张压、心率及测量时间。

#### Scenario: 数值范围
- **WHEN** 手动记录页展示选择器
- **THEN** 收缩压与舒张压可选 40–300，心率可选 20–220

#### Scenario: 保存校验
- **WHEN** 用户未选择完整三项就点保存
- **THEN** Toast 提示「请选择收缩压、舒张压、心率」

#### Scenario: 保存成功
- **WHEN** 校验通过并调用保存接口成功
- **THEN** Toast「保存成功」，push 详情页（带返回的 `monitorId`），并从导航栈移除手动页

---

### Requirement: History Trends
系统 SHALL 在趋势 Tab 按 7/30/90 天展示收缩压、舒张压、心率折线图。

#### Scenario: 时段切换
- **WHEN** 用户切换 Segmented 索引
- **THEN** 以对应 `timeType` 重新请求 `selectPressureHistoryData` 并刷新双图表

#### Scenario: 图表样式
- **WHEN** 趋势图渲染
- **THEN** 收缩压折线色 `#FF7C9C`，舒张压 `#FFB25C`，单点数据时显示 marker

---

### Requirement: History Log
系统 SHALL 按月分页展示血压日志，支持点击进详情。

#### Scenario: 月份筛选
- **WHEN** 用户选择月份
- **THEN** `searchTime` 传该月毫秒戳，`pageNum` 重置为 1 并刷新列表

#### Scenario: 分页加载
- **WHEN** 上拉触底且本页条数等于 pageSize
- **THEN** `pageNum` 自增并追加数据；否则标记无更多

#### Scenario: 点击行
- **WHEN** 用户点击日志行
- **THEN** push 详情页并传入该行 `monitorId`

---

### Requirement: History Statistics
系统 SHALL 展示血压监测统计数据。

#### Scenario: 头部汇总
- **WHEN** 统计 Tab 加载
- **THEN** 展示 `ninety` 周期的 total/normal/low/high 及正常占比进度条

#### Scenario: 周期列表
- **WHEN** 统计列表渲染
- **THEN** 展示「近7天」「近30天」两行，数据来自 `seven`、`thirty`

---

### Requirement: Record Detail
系统 SHALL 展示单条血压记录详情并支持删除。

#### Scenario: 加载详情
- **WHEN** 详情页打开且传入 `monitorId`
- **THEN** 请求 `getPressureHomePageData` 带 `monitorId` 并填充 UI

#### Scenario: 删除记录
- **WHEN** 用户确认删除
- **THEN** 调用删除接口，发送 `bloodPressureRecordDidDelete` 通知，返回上一页

---

### Requirement: Bluetooth Banner
系统 SHALL 查询用户绑定的血压计设备并展示连接状态 Banner。

#### Scenario: 已绑定设备
- **WHEN** `getEquipmentUserByParam(type: 4)` 返回非空列表
- **THEN** Banner 展示设备名称与图片（Kingfisher）

#### Scenario: 未绑定
- **WHEN** 设备列表为空
- **THEN** Banner 展示未绑定状态，可跳转 `/me/devices`

---

### Requirement: Routing
血压模块路由 SHALL 注册于 `HealthRoutes`。

#### Scenario: Hub 入口
- **WHEN** 用户从健康 Hub 点击血压卡片
- **THEN** 打开 `/health/metrics/blood-pressure`（血压服务首页）

#### Scenario: 旧录入路由兼容
- **WHEN** 打开 `/health/metrics/add` 且 `key=blood-pressure`
- **THEN** 打开手动记录页（与 `/health/metrics/blood-pressure/manual` 等价）

---

### Requirement: No Mock Data
血压模块接入真实 API 后 SHALL 不在 BLL/DAL 请求参数或展示逻辑中使用 mock/硬编码监测数据。

#### Scenario: 列表空态
- **WHEN** 接口返回空列表
- **THEN** 展示空态文案，不使用假数据填充

---

## Component Inventory

| Component | 说明 |
|-----------|------|
| `BloodPressureGaugeView` | 圆环仪表（源 `TemperatureMeter`） |
| `BloodPressureMetricColumnView` | 三列指标（源 `ADCustomTBView`） |
| `BloodPressureRecordEntryCell` | 手动/历史双入口 |
| `BloodPressureAdviceCell` | 建议卡 |
| `BloodPressureValuePickerView` | 三列数值选择器 |
| `BloodPressureHistoryLogCell` | 日志行 |
| `BloodPressureStatsPeriodCell` | 统计周期行 |
| `BluetoothDeviceBannerView` | 设备状态 Banner |

## Acceptance Checklist

- [ ] 服务首页展示 API 最新读数与建议
- [ ] 手动录入保存成功并跳转详情
- [ ] 历史三 Tab 数据来自真实接口
- [ ] 详情删除后历史页自动刷新
- [ ] 无 mock 血压数值流入 API
- [ ] 路由从 Hub 正确进入服务首页
- [ ] 新增 Swift 文件已提示开发者加入 Xcode 工程
