# scale-device-bind

> 对齐 funde-client：`BodyScaleConnectView.vue`、`weight.md` §6.6 设备绑定页。  
> 本期只接 `bluetoothName=OKOK` 的广播体脂秤。

## ADDED Requirements

### Requirement: 设备绑定页入口

系统 SHALL 提供 Health 原生「设备绑定」页，路由 `/health/scale/bind`。由设备选择页在用户点击 OKOK 型号后 push。本页负责 BLE 扫描与服务端绑定；MUST NOT 使用 `/health/scale/measure`（测量页仅称重）。

#### Scenario: 从选择设备进入

- **WHEN** 用户在 `/health/scale/devices` 点击 OKOK 型号卡
- **THEN** 打开 `/health/scale/bind`，携带 `equipmentType`、`bluetoothName`、`equipmentName`

### Requirement: 绑定页扫描 OKOK 广播

进入绑定页且系统蓝牙可用时，SHALL 以 `ScaleSessionContext.deviceBind` **重启**扫描（无 MAC 过滤、不 GATT）。听到 **第一帧** OKOK 广播（实时或锁定均可）即停扫，用该帧 MAC 走绑定链。MUST NOT 在本页调用 `saveWeightBluetoothMonitor`。

超时 30 秒未发现设备：Toast「未发现体脂秤，请轻踩唤醒后重试」，提供「重新搜索」。

#### Scenario: 第一帧即进入绑定链

- **WHEN** 扫描到第一帧带 MAC 的 OKOK 广播
- **THEN** 停止扫描
- **AND** 使用该 MAC 调用校验/绑定接口

#### Scenario: 蓝牙不可用

- **WHEN** 系统蓝牙关闭或未授权
- **THEN** Toast 既有蓝牙提示文案
- **AND** 不调绑定接口

### Requirement: 三接口绑定链

停扫后按顺序：

1. `GET /v1/equipmentUser/checkEquipmentVaild`（`equipmentType` + `mac`）
2. `GET /v1/equipmentUser/checkEquipmentBind`（`mac`）
3. 若未绑定：`POST /v1/equipmentUser/bindEquipment`

`checkEquipmentVaild` 失败：Toast 接口 `msg`，留在绑定页。

`checkEquipmentBind`：**`isSuccess == true` 表示已经绑定**；`isSuccess == false` 表示未绑定，继续 `bindEquipment`。已绑定：Toast `msg`（空则「该设备已绑定」），随后 pop 回体重 H5 主页。

`bindEquipment` Body 含 `equipmentType`（型号 id）、`mac`、`bluetoothName`（目录 `OKOK`）、`businessId=4`、`userId`。失败 Toast `msg`。

#### Scenario: 校验失败

- **WHEN** `checkEquipmentVaild` 返回失败
- **THEN** Toast 接口返回文案
- **AND** 不调用后续绑定接口

#### Scenario: 设备尚未绑定

- **WHEN** `checkEquipmentBind` 的 `isSuccess == false`
- **THEN** 调用 `bindEquipment`

#### Scenario: 设备已经绑定

- **WHEN** `checkEquipmentBind` 的 `isSuccess == true`
- **THEN** MUST NOT 再调 `bindEquipment`
- **AND** Toast 后 pop 回体重 H5 主页

#### Scenario: 绑定成功

- **WHEN** `bindEquipment` 成功
- **THEN** Toast「设备绑定成功」
- **AND** pop 至体重 H5 主页（栈中的体重 `WebViewController`）
- **AND** MUST NOT 打开体重详情（无 `monitorId`）

### Requirement: 上报仍在 H5 锁定后

绑定页 MUST NOT 保存监测数据。用户回到体重 H5 后，由宿主 `getEquipmentByOne` 启扫；**锁定帧**才 `saveWeightBluetoothMonitor`。
