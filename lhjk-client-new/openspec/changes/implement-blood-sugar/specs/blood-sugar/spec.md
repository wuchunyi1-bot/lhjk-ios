# Blood Sugar / 血糖监测

## Purpose

从 jumper-angel-doctor `ADSugarService` 模块移植完整血糖监测能力到 lhjk-client iOS。保持接口路径与参数字段不变，UI 样式对齐源项目。模块归属 **Health Tab**（`BLL/Health`、`PL/Health`）。

> **Reference**: jumper-angel-doctor `AngelDoctor/Classes(业务)/BuleToothDevice/ADSugarService/`

---

## Module Flow

```
健康 Hub / 体征网格
    └── /health/metrics/blood-sugar  →  血糖服务首页
            ├── 蓝牙 Banner（绑定设备状态）
            ├── 圆环仪表 + 最新读数 + 餐次 + 状态
            ├── 糖尿病类型行（占位 `--`，待接档案接口）
            ├── [手动记录] [历史记录]
            ├── 血糖建议卡 → 详情
            ├── /manual  →  手动记录 → 保存 → 详情
            └── /history →  血糖记录
                    ├── Tab0 表格（按日餐次矩阵）
                    ├── Tab1 趋势图（7/30/90 天 + 餐次筛选）
                    ├── Tab2 日志（按月分页）
                    └── Tab3 统计
            └── /detail?monitorId=&sugarId=  →  血糖详情（可删除）
```

---

## Business Constants

| 常量 | 值 | 说明 |
|------|-----|------|
| `businessId` | 5 | 保存/首页 |
| `dateType` | 5 | 历史/日志/统计 |
| `equipmentType` | 2 | 设备列表 `type` |
| `collectionType` | 1 手动 / 2 蓝牙 | 保存入参 |
| `duplicateErrorCode` | `G0009` | 重复记录二次确认 |

---

## API Contract

所有接口经 `APIManager`，base 已含 `/mobile`。

### 1. 餐次类型

- **Path**: `POST /v1/monitor/getSugarTypes`
- **Request**: `{}`
- **Response**: `[BloodSugarMealType]`

| 字段 | 说明 |
|------|------|
| name | 餐次名称，如「空腹」 |
| valueList | 餐次 type 值（字符串） |
| minValue / maxValue | 控糖标准范围 |
| configStatus | `0` 不在测量页展示 |

### 2. 首页 / 详情

- **Path**: `POST /v1/monitor/getSugarHomePageData`
- **Request**:

```json
{
  "businessId": 5,
  "monitorId": "可选",
  "sugarId": "可选，详情时传入",
  "newbornId": null,
  "pregnantId": null
}
```

- **Response** (`BloodSugarRecord`): `value`, `unit`, `type`, `typeRemark`, `monitorResults`, `color`, `description`, `recordTime`, `monitorId`, `id`（sugarId）

### 3. 保存记录

- **Path**: `POST /v1/monitor/saveOrUpdateMonitorData`
- **Request**:

```json
{
  "beginTime": "毫秒时间戳",
  "endTime": "毫秒时间戳",
  "businessId": 5,
  "collectionType": 1,
  "version": "毫秒时间戳",
  "submitTimes": 1,
  "monitorData": {
    "data": {
      "recordTime": "毫秒时间戳",
      "value": "6.5",
      "type": 1,
      "typeRemark": "空腹",
      "dataSource": "手动记录"
    }
  }
}
```

- `submitTimes: 2` 用于 `G0009` 重复记录二次确认
- **Response**: `data.monitorData.monitorId`、`data.id`（sugarId）

### 4. 历史（表格 + 趋势）

- **Path**: `POST /v1/monitor/getSugarHistory`
- **Request**: `{ "dateType": 5, "timeType": 7|30|90, "pageSize": 1000, "type": 餐次type可选 }`
- **Response**: `{ monitors, highNum, lowNum, normalNum, testNum }`
- `monitors[]`: `monitorDate`, `data[]`（含 `value`, `type`, `typeRemark`, `color`, `recordTime`）

### 5. 日志列表

- **Path**: `POST /v1/monitor/getSugarRecords`
- **Request**: `{ "dateType": 5, "searchTime": "月份毫秒戳", "pageNum": 1, "pageSize": 20 }`
- **Response**: `{ "list": [BloodSugarLogItem] }`
- Log 项 `id` 解码为 `sugarId`

### 6. 统计

- **Path**: `POST /v1/monitor/getMonitorStatistics`
- **Request**: `{ "dateType": 5, "searchTime": "当前毫秒戳" }`
- **Response**: 同血压 `{ ninety, seven, thirty }` → `PeriodStats`

### 7. 删除

- **Path**: `DELETE /v1/monitor/delMonitorDataByMonitorId`
- **Query**: `monitorId` 必填，`sugarId` 可选

### 8. 绑定设备

- **Path**: `GET /v1/equipmentUser/getEquipmentUserByParam?type=2`

---

## Layout — 血糖服务首页

- 导航「血糖服务」+ 右侧「历史记录」
- `BluetoothDeviceBannerView`（设备名/未绑定）
- Row0: `BloodSugarServiceHeadCell` — 圆环 + 数值 + mmol/L + 餐次 + 状态 + 时间
- Row1: `BloodSugarDiabetesTypeCell` — 糖尿病类型（当前占位 `--`）
- Row2: `BloodPressureRecordEntryCell` — 手动/历史双入口（复用血压组件）
- Row3: `BloodPressureAdviceCell` — 建议卡

---

## Layout — 手动记录

- 餐次 Tab：`BloodSugarMealTypeTabsView`（来自 `getSugarTypes`，过滤 `configStatus != 0`）
- 大号数值 + 餐次控糖标准提示
- 日期时间选择（最大当前时间）
- `MetricRulerView`：0–15 mmol/L，步进 0.1
- 保存按钮色 `#FF406F`
- 保存成功 → 详情（带 `monitorId`、`sugarId`），移除手动页
- `G0009` → Alert 二次确认 → `submitTimes=2` 重试

---

## Layout — 历史记录（4 Tab）

### Tab0 表格

- `BloodSugarHistoryFormViewController`
- 按日期行 × 餐次列展示血糖值矩阵
- 数据来自 `getSugarHistory`（`timeType` 随 7/30/90 切换）

### Tab1 趋势图

- Segment 7/30/90 天
- 餐次筛选按钮（来自 `getSugarTypes`）
- DGCharts 折线图，标题随餐次变化

### Tab2 日志

- 月份 `yyyy-MM` 选择
- 下拉刷新 + 上拉分页
- `BloodSugarHistoryLogCell`：时间、餐次、数值、状态色标、来源
- 点击行 → 详情（`monitorId` + `sugarId`）

### Tab3 统计

- 复用 `BloodPressureHistoryStatsViewController` 模式
- 头部汇总 + 近 7/30 天行（`BloodPressureStatsPeriodCell`）

---

## Layout — 详情

- 时间 + 状态徽章
- 血糖值 + 餐次
- 健康建议（`description`）
- 删除 → 确认 → `delMonitorDataByMonitorId` → `bloodSugarRecordDidDelete` 通知 → pop

---

## Requirements

### Requirement: Architecture
血糖模块 SHALL 遵循 PL → BLL → DAL；PL 通过 ViewModel 调用 `BloodSugarService`。

#### Scenario: Service 注入
- **WHEN** ViewModel 初始化
- **THEN** 默认 `AppContainer.shared.bloodSugarService`

---

### Requirement: Service Home Page
系统 SHALL 展示最新血糖读数、餐次、建议与设备 Banner。

#### Scenario: 加载首页
- **WHEN** `viewWillAppear`
- **THEN** 并行请求 `getSugarHomePageData` 与设备列表

#### Scenario: 空态建议
- **WHEN** 无 `description`
- **THEN** 展示默认测量提示文案

---

### Requirement: Manual Entry
系统 SHALL 支持餐次 + 刻度尺录入血糖值。

#### Scenario: 餐次加载
- **WHEN** 手动页打开
- **THEN** 请求 `getSugarTypes` 并默认选中首项

#### Scenario: 重复记录
- **WHEN** 保存返回 `code == G0009`
- **THEN** 弹窗确认，用户确认后 `submitTimes=2` 重试

---

### Requirement: History
系统 SHALL 提供表格、趋势、日志、统计四 Tab。

#### Scenario: 删除后刷新
- **WHEN** 收到 `bloodSugarRecordDidDelete`
- **THEN** 历史容器刷新各子 Tab

---

### Requirement: Routing

| 路由 | 页面 |
|------|------|
| `/health/metrics/blood-sugar` | 服务首页 |
| `/health/metrics/blood-sugar/manual` | 手动记录 |
| `/health/metrics/blood-sugar/history` | 历史记录 |
| `/health/metrics/blood-sugar/detail` | 详情（`monitorId`, `sugarId`） |
| `/health/metrics/add?key=blood-sugar` | 手动记录 |

---

### Requirement: No Mock Data
血糖模块接入真实 API 后 SHALL NOT 在请求参数或列表中使用 mock 监测数据。

---

## Component Inventory

| Component | 说明 |
|-----------|------|
| `BloodSugarServiceHeadCell` | 服务首页表头 |
| `BloodSugarMealTypeTabsView` | 餐次 Tab |
| `BloodSugarDiabetesTypeCell` | 糖尿病类型行 |
| `BloodSugarHistoryLogCell` | 日志行 |
| `BloodSugarHistoryFormViewController` | 表格 Tab |
| `MetricRulerView` | 刻度尺（共享） |
| `BloodPressureRecordEntryCell` | 双入口（复用） |
| `BloodPressureAdviceCell` | 建议卡（复用） |
| `BloodPressureGaugeView` | 圆环（复用） |
| `BluetoothDeviceBannerView` | 设备 Banner（复用） |

## Deferred

- AngelDoctor 蓝牙血糖仪 SDK 实时测量
- 糖尿病类型选择（`updatePregnantByUserId` 等档案接口）
- 孕期联系人门禁

## Acceptance Checklist

- [ ] 服务首页展示 API 最新读数与建议
- [ ] 手动录入含餐次选择与 G0009 二次确认
- [ ] 历史四 Tab 数据来自真实接口
- [ ] 详情删除后历史页自动刷新
- [ ] 无 mock 血糖数值流入 API
- [ ] 路由从 Hub 正确进入服务首页
