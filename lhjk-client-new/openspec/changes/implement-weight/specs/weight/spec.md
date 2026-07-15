# Weight / 体重监测

## Purpose

从 jumper-angel-doctor `ADWeightDevice` 模块移植完整体重监测能力到 lhjk-client iOS。保持接口路径与参数字段不变，UI 样式对齐源项目。模块归属 **Health Tab**（`BLL/Health`、`PL/Health`）。

> **Reference**: jumper-angel-doctor `AngelDoctor/Classes(业务)/BuleToothDevice/ADWeightDevice/`

---

## Module Flow

```
健康 Hub / 体征网格
    └── /health/metrics/weight  →  体重服务首页
            ├── 蓝牙 Banner（绑定体脂秤/体重秤）
            ├── 圆环仪表 + 体重 kg + BMI + 状态
            ├── [手动记录] [历史记录]
            ├── 体重建议卡 → 详情
            ├── /manual  →  手动记录（刻度尺 30–200 kg）→ 保存 → 详情
            └── /history →  体重记录
                    ├── Tab0 趋势图（全量历史 + 推荐区间）
                    └── Tab1 日志（按月分页）
            └── /detail?monitorId=  →  体重详情（孕期增重 + 体脂六宫格，可删除）
```

---

## Business Constants

| 常量 | 值 | 说明 |
|------|-----|------|
| `businessId` | 4 | 保存/首页 |
| `dateType` | 4 | 日志 |
| `historyType` | 2 | `selectWeightHistoryData.type` |
| `equipmentType` | 3 | 设备列表 `type` |
| `collectionType` | 1 手动 / 2 蓝牙 | 保存入参 |

---

## API Contract

所有接口经 `APIManager`，base 已含 `/mobile`。

### 1. 首页 / 详情

- **Path**: `POST /v1/monitor/getWeightHomePageData`
- **Request**:

```json
{
  "businessId": 4,
  "monitorId": "可选，详情时传入"
}
```

- **Response** (`WeightRecord`):

| 字段 | 说明 |
|------|------|
| weight | 体重 kg |
| bmi | BMI |
| monitorResults | 结果文案 |
| color | 状态色 hex |
| description | 健康建议 |
| recordTime | 毫秒时间戳 |
| monitorId | 记录 ID |
| showStatus | 1 备孕 / 2 怀孕 / 3 已分娩 / 4 双胎 BMI<18.5 |
| increasedWeight | 已增重 kg |
| recommendStr | 推荐增重文案 |
| weekRecommend | 本周推荐增重 |
| distanceTarget | 距目标 |
| bodyFatScaleMonitor | 1 表示体脂秤数据 |
| bodyFat, muscle, bodyWater, basalMetabolism, fatVolume, bone | 体脂指标 |

### 2. 保存记录

- **Path**: `POST /v1/monitor/saveOrUpdateMonitorData`
- **Request**:

```json
{
  "beginTime": "毫秒时间戳",
  "endTime": "毫秒时间戳",
  "businessId": 4,
  "collectionType": 1,
  "version": "毫秒时间戳",
  "monitorData": {
    "data": {
      "recordTime": "毫秒时间戳",
      "weight": "60.5",
      "bmi": "22.1",
      "bodyFatScaleMonitor": 0
    }
  }
}
```

- 蓝牙体脂秤额外字段：`muscle`, `bodyFat`, `bodyWater`, `basalMetabolism`, `fatVolume`, `bone`, `bodyFatScaleMonitor: 1`
- **Response**: `data.monitorData.monitorId`

### 3. 趋势历史

- **Path**: `POST /v1/monitor/selectWeightHistoryData`
- **Request**: `{ "dateType": 4, "type": 2, "pageSize": 1000 }`
- **Response**: `[WeightHistoryDataPoint]`
- 每项含 `dayStr`, `xresult`/`yresult`（推荐区间）, `weightData.weight`

### 4. 日志列表

- **Path**: `POST /v1/monitor/getWeightRecords`
- **Request**: `{ "dateType": 4, "searchTime": "月份毫秒戳", "pageNum": 1, "pageSize": 20 }`
- **Response**: `{ "list": [WeightLogItem] }`

### 5. 删除

- **Path**: `DELETE /v1/monitor/delMonitorDataByMonitorId?monitorId={id}`
- 无需 `sugarId`

### 6. 绑定设备

- **Path**: `GET /v1/equipmentUser/getEquipmentUserByParam?type=3`

---

## Layout — 体重服务首页

- 导航「体重服务」+ 右侧「历史记录」
- `BluetoothDeviceBannerView`
- Row0: `WeightServiceHeadCell` — 圆环 + 体重 kg + BMI + 状态 + 时间
- Row1: `BloodPressureRecordEntryCell` — 手动/历史双入口
- Row2: `BloodPressureAdviceCell` — 建议卡

---

## Layout — 手动记录

- 大号体重数值 + BMI（有身高时计算，否则 `--`）
- 建议文案（来自首页 `description`）
- 日期时间选择（最大当前时间）
- `MetricRulerView`：30–200 kg，步进 0.5，主色 `#5AD480`
- 保存成功 → 详情（`monitorId`），移除手动页

---

## Layout — 历史记录（2 Tab）

### Tab0 趋势图

- 单次请求全量趋势（无 7/30/90 分段，对齐源项目）
- DGCharts 折线 + 按点着色（正常/偏低/偏高图例）
- 推荐上下限虚线（`xresult` / `yresult`）

### Tab1 日志

- 月份 `yyyy-MM` 选择
- 下拉刷新 + 上拉分页
- `WeightHistoryLogCell`：时间、体重、状态、来源
- 点击行 → 详情

---

## Layout — 详情

- 时间 + 状态徽章
- 两列：体重 kg、BMI
- 孕期增重信息区（`showStatus`, `increasedWeight`, `recommendStr`, `weekRecommend`, `distanceTarget`）
- 健康建议
- 体脂六宫格（`bodyFatScaleMonitor == 1` 时展示）
- 删除 → 确认 → 删除接口 → `weightRecordDidDelete` → pop

---

## Requirements

### Requirement: Architecture
体重模块 SHALL 遵循 PL → BLL → DAL；PL 通过 ViewModel 调用 `WeightService`。

#### Scenario: Service 注入
- **WHEN** ViewModel 初始化
- **THEN** 默认 `AppContainer.shared.weightService`

---

### Requirement: Service Home Page
系统 SHALL 展示最新体重、BMI、建议与设备 Banner。

#### Scenario: 加载首页
- **WHEN** `viewWillAppear`
- **THEN** 并行请求 `getWeightHomePageData` 与 `getEquipmentUserByParam(type:3)`

#### Scenario: 空态建议
- **WHEN** 无 `description`
- **THEN** 展示默认体重测量提示文案

---

### Requirement: Manual Entry
系统 SHALL 支持刻度尺录入体重（30–200 kg，步进 0.5）。

#### Scenario: BMI
- **WHEN** 用户有身高档案
- **THEN** 客户端计算 BMI 并随保存请求提交
- **WHEN** 无身高
- **THEN** BMI 字段可选，UI 显示 `BMI --`

---

### Requirement: History Chart
系统 SHALL 展示体重趋势，数据点按推荐区间着色。

#### Scenario: 点色
- **WHEN** `weight < xresult`
- **THEN** 点色 `#FE6186`
- **WHEN** `weight > yresult`
- **THEN** 点色 `#FFB25C`
- **ELSE** `#5AD480`

---

### Requirement: History Log
系统 SHALL 按月分页展示体重日志。

#### Scenario: 删除后刷新
- **WHEN** 收到 `weightRecordDidDelete`
- **THEN** 历史容器刷新趋势图与日志

---

### Requirement: Record Detail
系统 SHALL 展示单条记录详情，含孕期增重与体脂数据。

#### Scenario: 体脂展示
- **WHEN** `bodyFatScaleMonitor == 1`
- **THEN** 展示体脂率、肌肉量、体水分、基础代谢、脂肪量、骨量六宫格

---

### Requirement: Routing

| 路由 | 页面 |
|------|------|
| `/health/metrics/weight` | 服务首页 |
| `/health/metrics/weight/manual` | 手动记录 |
| `/health/metrics/weight/history` | 历史记录 |
| `/health/metrics/weight/detail` | 详情（`monitorId`） |
| `/health/metrics/add?key=weight` | 手动记录 |

---

### Requirement: No Mock Data
体重模块接入真实 API 后 SHALL NOT 在请求参数或列表中使用 mock 监测数据。

---

## Component Inventory

| Component | 说明 |
|-----------|------|
| `WeightServiceHeadCell` | 服务首页表头 |
| `WeightHistoryLogCell` | 日志行 |
| `MetricRulerView` | 体重刻度尺（共享） |
| `BloodPressureRecordEntryCell` | 双入口（复用） |
| `BloodPressureAdviceCell` | 建议卡（复用） |
| `BloodPressureGaugeView` | 圆环（复用） |
| `BloodPressureMetricColumnView` | 详情指标列（复用） |
| `BluetoothDeviceBannerView` | 设备 Banner（复用） |

## Deferred

- AngelDoctor 蓝牙体重/体脂秤 SDK 实时测量
- 孕期生长曲线原生视图（`ADDrawWeightCurveView`）
- 用户身高档案接入后自动 BMI 计算

## Acceptance Checklist

- [ ] 服务首页展示 API 最新读数与建议
- [ ] 手动录入保存成功并跳转详情
- [ ] 历史两 Tab 数据来自真实接口
- [ ] 详情删除后历史页自动刷新
- [ ] 无 mock 体重数值流入 API
- [ ] 路由从 Hub 正确进入服务首页
- [ ] 新增 Swift 文件已加入 Xcode 工程
