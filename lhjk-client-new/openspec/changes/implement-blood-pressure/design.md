## Context

**源项目**（jumper-angel-doctor）血压模块位于 `ADBloodPressure/`，采用 MVC：VC 直接调 `ABNetWorkABI`，XIB 布局，AAInfographics 图表，AngelDoctorBluetooth SDK 蓝牙测量。

**目标项目**（lhjk-client-new）遵循 PL → BLL → DAL 三层架构，纯代码 + SnapKit，ViewModel 模式，DGCharts 已集成。现有 `BloodPressureViewController` 为 funde 风格折线图原型，含 mock 数据。

**约束**：接口相对路径、请求/响应字段与源项目保持一致；UI 视觉与交互对齐源项目；禁止 mock 数据流入 API 参数。

## Goals / Non-Goals

**Goals:**

- 完整移植血压业务流程：服务首页 → 手动录入 → 历史（趋势/日志/统计）→ 详情/删除
- BLL 封装全部监测 API，PL 通过 ViewModel 订阅
- UI 复刻源项目：圆环仪表、三列数值、建议卡、双折线趋势图、日志列表、统计摘要
- 健康 Hub 点击「血压」进入服务首页（替换原 funde 详情页）

**Non-Goals:**

- AngelDoctor 专有蓝牙 SDK（`ASBluetoothPressure`）完整接入 — 本期实现设备列表查询 + 状态 Banner UI，测量上传逻辑预留 `BloodPressureBluetoothCoordinator` 接口
- 首页待办任务 `updateUserMonitorTask` 回传（源项目已注释）
- 紧急联系人校验弹窗（源项目 `ADRecordRuler`，与 lhjk 用户体系无关）

## Decisions

### 1. 模块目录

```
PL/Health/Metrics/BloodPressure/
├── BloodPressureServiceViewController.swift      # 血压服务首页
├── BloodPressureManualViewController.swift       # 手动记录
├── BloodPressureHistoryViewController.swift      # 历史容器（3 Tab）
├── BloodPressureHistoryChartViewController.swift
├── BloodPressureHistoryLogViewController.swift
├── BloodPressureHistoryStatsViewController.swift
├── BloodPressureDetailViewController.swift
├── ViewModels/ ...
└── Components/ ...
BLL/Health/
├── BloodPressureService.swift
└── BloodPressureModels.swift
```

**理由**：子 VC 独立文件夹符合 PL 层规范；与 funde 风格 `Metrics/*.swift` 平铺区分。

### 2. API 路径

`APIManager.environment.baseURL` 已含 `/mobile` 前缀，BLL 调用路径为：

| 功能 | Path | Method |
|------|------|--------|
| 首页/详情 | `/v1/monitor/getPressureHomePageData` | POST JSON |
| 保存记录 | `/v1/monitor/saveOrUpdateMonitorData` | POST JSON |
| 趋势数据 | `/v1/monitor/selectPressureHistoryData` | POST JSON |
| 日志列表 | `/v1/monitor/getPressureRecords` | POST JSON |
| 统计数据 | `/v1/monitor/getMonitorStatistics` | POST JSON |
| 删除记录 | `/v1/monitor/delMonitorDataByMonitorId` | DELETE query |
| 绑定设备 | `/v1/equipmentUser/getEquipmentUserByParam` | GET query |

### 3. 业务常量

| 常量 | 值 | 用途 |
|------|-----|------|
| `businessId` | `2` | 血压监测类型 |
| `dateType` | `2` | 历史/统计筛选 |
| `equipmentType` | `4` | 血压计设备 |
| `collectionType.manual` | `1` | 手动录入 |
| `collectionType.bluetooth` | `2` | 蓝牙上传 |

### 4. 图表库

**选择 DGCharts** 替代 AAInfographics。

- 收缩压 `#FF7C9C`、舒张压 `#FFB25C`（对齐源项目）
- 心率图单独卡片，同色折线
- 时段 Segmented：7 / 30 / 90 天

### 5. 手动录入控件

源项目使用 `BRStringPickerView` 三列滚轮。目标项目实现 `BloodPressureValuePickerView`（`UIPickerView` 三列），范围：收缩/舒张 40–300，心率 20–220，默认索引对应约 90/70/90。

**不采用** 现有 `MetricRulerView`（funde 水平刻度尺），因用户要求源项目样式。

### 6. ViewModel 模式

每个 VC 对应一个 `final class XxxViewModel: ObservableObject`：

- `@Published` 驱动 UI 刷新
- `PassthroughSubject` 用于一次性导航/Toast 事件
- `init(service: BloodPressureService = AppContainer.shared.bloodPressureService)`

### 7. 路由

| Route | VC |
|-------|-----|
| `/health/metrics/blood-pressure` | `BloodPressureServiceViewController` |
| `/health/metrics/blood-pressure/manual` | `BloodPressureManualViewController` |
| `/health/metrics/blood-pressure/history` | `BloodPressureHistoryViewController` |
| `/health/metrics/blood-pressure/detail` | `BloodPressureDetailViewController`（`monitorId` 可选） |

`/health/metrics/add?key=blood-pressure` 重定向到 manual 路由。

### 8. 删除通知

定义 `Notification.Name.bloodPressureRecordDidDelete`，历史三 Tab 监听后刷新（对齐源项目 `NotiMonitorDelete`）。

## Risks / Trade-offs

- **[Risk] 蓝牙 SDK 不可用** → 本期仅展示绑定状态 Banner；连接/测量按钮提示「功能开发中」或跳转 `/me/devices`
- **[Risk] 字典 `monitorResultsId` 文案** → 复用 `DictionaryService` 若存在对应字典；否则直接展示服务端 `monitorResults` 字段
- **[Risk] 时间戳格式** → 源项目用毫秒字符串；保存时 `recordTime`/`beginTime`/`endTime`/`version` 均传毫秒时间戳字符串
- **[Trade-off] 统计页复用血糖统计布局** → 独立实现 `BloodPressureHistoryStatsViewController`，字段映射 `ninety/seven/thirty`

## Migration Plan

1. 实现 BLL + Models
2. 实现 PL 页面（先手动+历史+详情，后服务首页）
3. 替换 `HealthRoutes` 注册，删除旧 `BloodPressureViewController.swift`
4. 从 Hub/Metrics 移除血压 mock 展示值（改为进入服务页后由 API 填充，Hub 卡片暂保留占位或后续接汇总接口）

## Open Questions

- Hub 体征卡片血压数值是否需单独汇总 API？（本期不阻塞，卡片仍显示占位，进入详情后走 `getPressureHomePageData`）
