# equipment-bind-api

> 蓝牙设备绑定与监测上报 BLL 封装。Path 以 **Apifox funde-api（2026-08-19）** 为准；后端流程图中的新 path 未发布前不得写入请求构建逻辑。

## ADDED Requirements

### Requirement: BLL 设备绑定服务

系统 SHALL 在 `BLL/Health` 提供 `EquipmentBindService`，经 `APIManager` 调用下列接口；PL 层 MUST 通过 `AppContainer.shared.equipmentBindService` 访问，禁止 PL 直连 path 字符串。

#### Scenario: 服务注册

- **WHEN** 应用启动后任意模块需要设备绑定能力
- **THEN** `AppContainer` 暴露 `equipmentBindService: EquipmentBindService`
- **AND** 默认实现为 `EquipmentBindService.shared`

### Requirement: 绑定查询接口

| Method | Path | Service 方法 |
|--------|------|--------------|
| GET | `/v1/equipmentUser/getEquipmentUserByParam` | `fetchBoundDevices(category:pageNum:pageSize:)` |
| GET | `/v1/equipmentUser/getEquipmentByOne` | `fetchLastUsedDevice(category:)` |

#### Scenario: 查询体重秤绑定列表

- **WHEN** 调用 `fetchBoundDevices(category: .weight)`
- **THEN** Query 含 `type=3`、`pageNum`、`pageSize`
- **AND** 解析 `PaginatedEquipmentUserData.records`（兼容中文分页 key `数据集合`）

#### Scenario: 最近使用设备

- **WHEN** 调用 `fetchLastUsedDevice(category: .weight)`
- **THEN** Query 含 `type=3`
- **AND** 返回 `EquipmentUserVO?`（含 `mac`、`bluetoothName`、`verify` 等）

### Requirement: 型号与白名单接口

| Method | Path | Service 方法 |
|--------|------|--------------|
| POST | `/v1/equipment/getEquipmenByApp` | `fetchEquipmentCatalog(category:pageNum:pageSize:userId:)` |
| GET | `/v1/equipment/getCompatibleBluetoothList` | `fetchCompatibleBluetoothNames(category:)` |

#### Scenario: 拉取可连接型号

- **WHEN** 进入设备搜索/绑定流程且需展示型号
- **THEN** `fetchEquipmentCatalog` Body 含 `type`（设备大类）
- **AND** 返回 `EquipmentCatalogItemVO` 列表（含 `id`、`verify`、`bluetoothName`）

#### Scenario: 蓝牙广播白名单

- **WHEN** 开始 BLE 扫描前
- **THEN** `fetchCompatibleBluetoothNames` Query `type` **必填**
- **AND** 返回 `string[]` 用于过滤 `localName`

### Requirement: 校验与绑定接口

| Method | Path | Service 方法 |
|--------|------|--------------|
| GET | `/v1/equipmentUser/checkEquipmentVaild` | `checkEquipmentValid(equipmentType:mac:deviceId:)` |
| GET | `/v1/equipmentUser/checkEquipmentBind` | `checkEquipmentBind(mac:deviceId:)` |
| POST | `/v1/equipmentUser/bindEquipment` | `bindEquipment(_:)` |
| DELETE | `/v1/equipmentUser/deleteEquipmentUserById` | `unbindEquipment(equipmentUserId:)` |

#### Scenario: 型号库存校验

- **WHEN** 用户选定扫描到的设备且已知型号 id
- **THEN** `checkEquipmentValid` Query **必须**含 `equipmentType`（对应 `getEquipmenByApp.id`）
- **AND** 可选 `mac`、`deviceId`
- **AND** 失败时抛出 `EquipmentBindServiceError.requestFailed`

#### Scenario: 绑定状态检查

- **WHEN** 绑定前检查设备是否已被绑定
- **THEN** `checkEquipmentBind` Query 含 `mac` 和/或 `deviceId`（不可全空）
- **AND** `APIResponse.isSuccess == true` 表示**已经绑定**
- **AND** `isSuccess == false` 表示**未绑定**，调用方继续 `bindEquipment`（网络错误仍抛错）

#### Scenario: 写入绑定

- **WHEN** 调用 `bindEquipment`
- **THEN** POST Body 为 `BindEquipmentRequest`（`mac`、`bluetoothName`、`equipmentType`、`businessId` 等）
- **AND** 成功以 `APIResponse.isSuccess` 为准

#### Scenario: 解绑

- **WHEN** 用户在设备管理页解绑
- **THEN** `unbindEquipment(equipmentUserId:)` DELETE Query `equipmentUserId`

### Requirement: 固件查询（可选）

| Method | Path | Service 方法 |
|--------|------|--------------|
| GET | `/v1/firmware/getFirmwareUrlByParam` | `fetchFirmwareUpgradeInfo(query:)` |

#### Scenario: 查询 OTA

- **WHEN** GATT 类设备连接成功后检查升级
- **THEN** Query 可含 `name`、`model`、`devmodelSn`、`battery`、`versionCode`
- **AND** 解析 `FirmwareUpgradeInfoVO.url`（兼容 `firmwareUrl` / `upgradeUrl` 别名）

### Requirement: 监测数据上报

| Method | Path | Service 方法 |
|--------|------|--------------|
| POST | `/v1/monitor/saveOrUpdateMonitorData` | `saveMonitorData(_:)` / `saveWeightBluetoothMonitor(...)` |
| POST | `/v1/monitor/getWeightHomePageData` | `fetchWeightHomePageData(monitorId:)` |
| DELETE | `/v1/monitor/delMonitorDataByMonitorId` | `deleteMonitorData(monitorId:)` |

#### Scenario: 体重蓝牙上报

- **WHEN** OKOK 广播秤锁定测量完成且需入库
- **THEN** `saveWeightBluetoothMonitor` 使用 `businessId=4`、`collectionType=2`
- **AND** 必填 `equipmentMac`、`equipmentName`、`serialNumber`（MAC 可兼作 serialNumber）
- **AND** `monitorData.data` 含 `weight`、`bodyFatScaleMonitor` 及体脂字段
- **AND** 成功返回非空 `monitorId`

#### Scenario: 拉取体重报告

- **WHEN** 蓝牙上报成功且需展示体成分报告
- **THEN** `fetchWeightHomePageData(monitorId:)` 调用 `POST /v1/monitor/getWeightHomePageData`
- **AND** Body 含 `businessId=4`、本次 `monitorId`
- **AND** 解析 `data.bodyCompositionResults`（名称、数值、单位、`monitorResults`）
- **AND** 请求失败时抛错，由调用方 Toast，不打开报告页

#### Scenario: 上报不改绑定

- **WHEN** 仅调用 `saveMonitorData`
- **THEN** MUST NOT 隐式调用 `bindEquipment`

#### Scenario: 删除监测记录

- **WHEN** 原生体重报告页点击「重新测量」
- **THEN** `deleteMonitorData(monitorId:)` 调用 `DELETE /v1/monitor/delMonitorDataByMonitorId`
- **AND** Query 仅含当前记录 `monitorId`（URLEncoding），禁止 mock / 假 id
- **AND** 业务 `code` 非成功时抛错，由 PL Toast，不 pop

### Requirement: 流程图新 path 约束

后端序列图中的下列 path **Apifox 暂未发布**，本阶段 **禁止** 在 `EquipmentBindService` 中硬编码调用：

- `bindEquipmentByApp`
- `device/register`
- `saveHealthData` / `uploadMonitorData` v2
- `deleteEquipmentUserBind`（按 MAC 解绑）
- `/v1/equipment/user/...` 重构前缀

#### Scenario: 后端发布新 path 后

- **WHEN** Apifox 补充文档且联调 path 稳定
- **THEN** 仅更新 `EquipmentBindService` path 与 DTO，PL 调用方保持不变

### Requirement: 与 OKOK 广播秤的关系

`EquipmentBindService` 封装 **服务端** 绑定与上报；**蓝牙扫描会话** 仍由 `ScaleBleSessionService` + `OKOKBroadcastScaleHandler` 管理。

#### Scenario: 职责分离

- **WHEN** 体重 H5 测量流程
- **THEN** BLE 扫描启停由 `ScaleBleSessionService` 负责
- **AND** 绑定/校验/上报由 `EquipmentBindService` 负责（接入后替换本地 `UserDefaults` 绑定）

## 业务常量

### 设备大类 `type`（`getEquipmentUserByParam` / `getEquipmenByApp`）

| type | 含义 | `EquipmentCategoryType` |
|------|------|-------------------------|
| 2 | 血糖 | `.bloodSugar` |
| 3 | 体重 | `.weight` |
| 4 | 血压 | `.bloodPressure` |
| 5 | 体温 | `.temperature` |
| 6 | 血氧 | `.bloodOxygen` |

### 监测上报

| 常量 | 值 | 用途 |
|------|-----|------|
| `EquipmentCategoryType.weight` | 3 | 体重设备大类 `type` |
| `MonitorBusinessId.weight` | 4 | 体重监测 `businessId` |
| `MonitorCollectionType.bluetooth` | 2 | 蓝牙采集 `collectionType` |
