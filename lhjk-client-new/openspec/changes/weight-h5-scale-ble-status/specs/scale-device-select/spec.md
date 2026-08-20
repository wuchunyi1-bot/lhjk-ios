# scale-device-select

> 对齐 funde-client：`docs/v0.1/pages/health/metrics/weight.md` §6.6、  
> `prototype/src/views/health/metrics/BodyScaleSelectDeviceView.vue`（选择设备）、  
> `prototype/src/views/health/metrics/MyScaleDeviceView.vue`（我的设备）。  
> 接口以 Apifox 已发布 path 为准：`getEquipmentUserByParam`、`getEquipmenByApp`。

## ADDED Requirements

### Requirement: 统一设备页入口

系统 SHALL 提供 Health 原生「设备选择 / 我的设备」页，路由 `/health/scale/devices`。体重 H5 横条「去绑定」、已绑定点击、以及 `ble.openManager` MUST 进入该页（不再跳转 `/health/scale/measure` 或 `/me/devices`）。

同一 VC 按绑定数据切换标题与布局：

| 条件 | 导航标题 | 对应原型 |
|------|----------|----------|
| `getEquipmentUserByParam` 无有效记录 | 选择设备 | `BodyScaleSelectDeviceView` |
| 有有效记录 | 我的设备 | `MyScaleDeviceView` |

#### Scenario: 未绑定点击去绑定

- **WHEN** 体重 H5 横条 `bound == false` 且用户点击「去绑定」
- **THEN** 跳转 `/health/scale/devices`

#### Scenario: 已绑定点击横条

- **WHEN** 体重 H5 横条 `bound == true` 且会话监听中，用户点击横条
- **THEN** 跳转 `/health/scale/devices`

#### Scenario: Bridge 打开设备管理

- **WHEN** H5 调用 `ble.openManager` 且 `metric` 为 `weight`
- **THEN** 打开 `/health/scale/devices`
- **AND** MUST NOT 因此隐式 `startSession()`

### Requirement: 进页并行拉绑定与型号

进入 `/health/scale/devices` 后，ViewModel SHALL 并行调用：

| 接口 | Service | Query / Body |
|------|---------|--------------|
| `GET /v1/equipmentUser/getEquipmentUserByParam` | `fetchBoundDevices(category: .weight)` | `type=3` |
| `POST /v1/equipment/getEquipmenByApp` | `fetchEquipmentCatalog(category: .weight)` | `type=3` |

PL MUST 只调 `EquipmentBindService`，禁止直连 path。`type` 使用 `EquipmentCategoryType.weight = 3`。

#### Scenario: 进页加载

- **WHEN** `viewWillAppear`（含从测量页返回）
- **THEN** 并行请求上述两个接口
- **AND** 请求期间展示 loading
- **AND** 失败 Toast 错误信息，列表为空态

### Requirement: 无绑定记录 — 仅展示可绑定型号

当 `getEquipmentUserByParam` 的 `records` 为空（或无有效设备）时，页面 SHALL：

- 标题为「选择设备」
- **不**展示「当前设备」区块
- **不**展示「添加设备 / 收起设备」按钮
- 仅展示 `getEquipmenByApp` 中的**可绑定**型号列表

可绑定判定：`status` 为空或 `status != 0`（0 视为停用，不展示）。

卡片字段对齐选择设备原型：

| UI | 数据来源 |
|----|----------|
| 图标 | `imgUrl`（Kingfisher）；无图用系统秤图标 |
| 名称 | `name` → `bluetoothName` → `model` →「体脂秤」 |
| 设备编码 | `model`；空则不展示编码行 |

点击卡片：仅 `bluetoothName` 为 `OKOK`（忽略大小写）的型号走绑定链；其它型号 Toast「暂不支持该设备」，MUST NOT 进入测量页。

OKOK 点击 → `/health/scale/bind`（设备绑定页），params 带 `equipmentType`、`bluetoothName`、`equipmentName`。设备选择页 MUST NOT 调用 `startSession()`。

#### Scenario: 点击可绑定型号（OKOK）

- **WHEN** 用户点击型号卡且 `bluetoothName` 等于 `OKOK`（忽略大小写）
- **THEN** 跳转 `/health/scale/bind`，携带该型号 `equipmentType`

#### Scenario: 点击非 OKOK 型号

- **WHEN** 用户点击型号卡且 `bluetoothName` 不是 `OKOK`
- **THEN** Toast「暂不支持该设备」
- **AND** MUST NOT 跳转测量页或绑定页

#### Scenario: 未绑定展示型号列表

- **WHEN** 绑定列表为空且型号接口返回至少一台可绑定设备
- **THEN** 页面标题为「选择设备」
- **AND** 仅渲染可绑定型号卡片（名称 + 设备编码 + 右箭头）
- **AND** 不出现「添加设备」按钮

#### Scenario: 未绑定且无可绑定型号

- **WHEN** 绑定列表为空且过滤后型号列表为空
- **THEN** 展示空态「暂无可绑定设备」

### Requirement: 有绑定记录 — 当前设备 + 添加设备

当绑定列表非空时，页面 SHALL：

- 标题为「我的设备」
- 展示「当前设备」区块：绑定列表每条一张卡
- 默认**收起**更多设备；底部按钮文案「添加设备」（主色实心）
- 点击「添加设备」展开「更多设备」列表，按钮变为描边「收起设备列表」
- 再点按钮收起更多列表

当前设备卡片对齐我的设备原型：

| UI | 数据来源 |
|----|----------|
| 图标 | `imgUrl`；无图用系统秤图标 |
| 名称 | `name` → `commodityName` → `bluetoothName` → `model` →「体脂秤」 |
| 设备编码 | `equipmentId` → `mac` → `model` |
| 解除绑定 | 右侧描边按钮 |

更多设备列表 = 可绑定型号中，排除已绑定的 `equipmentTypeId` / `equipmentId`（与型号 `id` 相同者）。卡片样式同选择设备（可点、带右箭头）。无剩余型号时，「添加设备」仍可点，展开后展示空列表或隐藏更多区块。

#### Scenario: 已绑定默认态

- **WHEN** 绑定列表至少一条
- **THEN** 标题为「我的设备」
- **AND** 展示「当前设备」卡片与「添加设备」按钮
- **AND** 默认不展示「更多设备」

#### Scenario: 展开添加设备

- **WHEN** 用户点击「添加设备」
- **THEN** 展示「更多设备」标题与可绑定且尚未绑定的型号列表
- **AND** 按钮切换为「收起设备列表」

#### Scenario: 收起更多设备

- **WHEN** 更多列表已展开且用户点击「收起设备列表」
- **THEN** 隐藏「更多设备」区块
- **AND** 按钮恢复「添加设备」

#### Scenario: 点击更多设备卡片（OKOK）

- **WHEN** 用户点击更多设备中 `bluetoothName` 为 `OKOK` 的型号卡
- **THEN** 跳转 `/health/scale/bind`

#### Scenario: 点击更多设备卡片（非 OKOK）

- **WHEN** 用户点击更多设备中非 OKOK 型号卡
- **THEN** Toast「暂不支持该设备」

### Requirement: 解除绑定

当前设备卡片的「解除绑定」SHALL 弹出二次确认（文案：「确定要解除设备绑定？」；取消 / 确认）。确认后调用 `unbindEquipment(equipmentUserId:)`（`DELETE /v1/equipmentUser/deleteEquipmentUserById`），成功后刷新本页两个接口；若刷新后绑定列表为空，切换为「选择设备」布局。

`equipmentUserId` 取绑定记录 `id`。无效 `id` 时 Toast「无法解绑该设备」，不发请求。

#### Scenario: 确认解绑

- **WHEN** 用户点击「解除绑定」并确认
- **THEN** 调用解绑接口
- **AND** 成功后重新拉取绑定列表与型号列表
- **AND** Toast「已解除绑定」

#### Scenario: 取消解绑

- **WHEN** 用户在确认框点击取消
- **THEN** 不发解绑请求，页面保持不变

### Requirement: 本页不启蓝牙扫描

本页仅展示绑定关系与可绑定型号，MUST NOT 调用 `ScaleBleSessionService.startSession()`。OKOK 扫描与三接口绑定在 `/health/scale/bind` 完成；测量页 `/health/scale/measure` 仅称重 UI。
