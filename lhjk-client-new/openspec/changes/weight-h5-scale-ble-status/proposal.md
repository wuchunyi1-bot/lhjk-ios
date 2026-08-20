## Why

体重 H5 已迁宿主，体脂秤能力依赖原生 OKOK 广播管道与 `FundeNative` Bridge。funde-client PRD（`weight.md` + 归档 SCALE PRD v1.1）定义了体重页设备入口横条的状态机与交互，但 iOS 侧逻辑分散在 `ScaleBleSessionService`、`FundeNativeBridge` 与通用 `WebViewController`，且 Bridge 在所有 H5 页注入并 `getStatus` 时自动开扫，与文档「仅体重模块启停会话」不一致。

## What Changes

- 新增 OpenSpec **`weight-h5-scale-ble`**：对齐 funde-client 绑定/连接/测量概念，映射到 iOS OKOK 广播实现
- 体重 H5 通过 `WebViewController(enablesWeightBle: true)` + `WeightScaleBleStatusCoordinator` 展示横条
- 进入体重 H5 启广播会话、离开停扫；其它 H5 页不展示横条、不订阅 BLE 事件
- `ble.getStatus` 改为**只读**当前状态，不再隐式 `startSession`
- 新增 **`equipment-bind-api`**：`EquipmentBindService` 封装 Apifox 已发布的设备绑定/监测上报接口
- 新增 **`scale-device-select`**：体重「去绑定」进入原生设备选择/我的设备页
- 新增 **`scale-device-bind`**：OKOK 设备绑定页（第一帧广播 + Vaild/Bind/bindEquipment），成功 pop 回体重 H5 主页

## Capabilities

### New Capabilities

- `weight-h5-scale-ble`: 体重 H5 体脂秤状态横条与会话生命周期
- `equipment-bind-api`: 蓝牙绑定与监测上报 BLL（`EquipmentBindService`）
- `scale-device-select`: 设备选择 / 我的设备页（绑定列表 + 可绑定型号）
- `scale-device-bind`: OKOK 设备绑定页（扫描 + 三接口）

### Modified Capabilities

- `h5-host`: 体重路由使用专用 WebView 宿主；FundeNative BLE 订阅范围收窄

## Impact

- `PL/Health/Weight/Components/`：`WeightScaleBleStatusBarView`、`WeightScaleBleStatusCoordinator`
- `BLL/Health/`：`EquipmentBindModels`、`EquipmentBindService`
- `WebViewController`、`FundeNativeBridge`、`HealthRoutes`、`AppContainer`
- `PL/Health/ScaleDevice/`：设备选择 / 我的设备 / 设备绑定
- `ScaleBleSessionService`（H5 查询上报；`deviceBind` 上下文第一帧绑定）
- 参考文档：funde-client `docs/v0.1/pages/health/metrics/weight.md`、`BodyScaleSelectDeviceView.vue`、`MyScaleDeviceView.vue`

## Non-Goals

- 体脂算法、H5 横条 UI 重做
- 血压等其它 metric 蓝牙
- 「我的」Tab 通用 `/me/devices` mock 页替换（本期仅体重设备选择页）
- 流程图新 path（`bindEquipmentByApp` 等）在 Apifox 发布前的业务串联
