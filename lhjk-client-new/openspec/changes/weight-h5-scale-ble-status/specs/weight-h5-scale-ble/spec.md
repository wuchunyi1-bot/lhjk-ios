# weight-h5-scale-ble

> 对齐 funde-client：`docs/v0.1/pages/health/metrics/weight.md` §6.6、归档 `智能体脂秤设备连接与测量_PRD_v1.1.md` §5.1–5.2  
> 技术基础：`okok-broadcast-scale`、`h5-native-bridge`

## ADDED Requirements

### Requirement: 体重 H5 专用宿主

系统 SHALL 为体重指标 H5（`#/weight` 及其子路径）使用 `WebViewController(enablesWeightBle: true)`，由 `WeightScaleBleStatusCoordinator` 在导航栏下方展示原生体脂秤状态横条；其它体征 H5 SHALL 使用 `enablesWeightBle: false` 且不得展示该横条。

#### Scenario: 打开体重主页

- **WHEN** 用户经 `/health/metrics/weight` 或等价路由进入体重 H5
- **THEN** 展示 `WeightScaleBleStatusBarView` 于 WebView 上方
- **AND** WebView 加载 `#/weight?token&platform=ios`

#### Scenario: 打开非体重 H5

- **WHEN** 用户打开血压、血糖等其它指标 H5
- **THEN** MUST NOT 展示体脂秤状态横条
- **AND** MUST NOT 因该页启停 OKOK 广播会话

### Requirement: 广播会话生命周期

体重 H5 宿主 SHALL 管理 `ScaleBleSessionService` 启停，对齐 PRD「离开体重模块断开蓝牙连接、保留绑定」。

#### Scenario: 进入体重页

- **WHEN** `WebViewController` 即将显示且 `enablesWeightBle == true`、系统蓝牙可用
- **THEN** 调用 `startSession()` 开始广播扫描（allowDuplicates，不 GATT connect）

#### Scenario: 离开体重页

- **WHEN** 用户 pop/dismiss 离开体重 `WebViewController`（`enablesWeightBle == true`）
- **THEN** 调用 `stopSession()` 停止扫描
- **AND** 本地绑定信息（`fd_okok_bound_mac` 等）保持不变

#### Scenario: 蓝牙不可用

- **WHEN** 系统蓝牙关闭或未授权
- **THEN** 横条展示对应提示文案
- **AND** 不进入有效扫描

### Requirement: 状态横条展示与交互

横条 SHALL 根据 `BleWeightStatus` 与系统蓝牙状态展示文案，交互对齐 weight.md 设备横条。

#### Scenario: 未绑定

- **WHEN** `bound == false`
- **THEN** 展示「您尚未绑定体脂秤」与「去绑定」
- **AND** 点击跳转 `/health/scale/devices`

#### Scenario: 已绑定且会话监听中

- **WHEN** `bound == true` 且 `connected == true`（会话活跃）
- **THEN** 展示转圈动画与「正在连接，请轻踩唤醒设备」
- **AND** 点击跳转 `/health/scale/devices`

#### Scenario: 已绑定但未监听

- **WHEN** `bound == true` 且 `connected == false`
- **THEN** 展示设备名称与未连接提示
- **AND** 点击调用 `startSession()` 重试

#### Scenario: 锁定测量完成

- **WHEN** 体重 H5 宿主会话收到 `OKOKScaleEvent.locked`
- **THEN** 调用 `POST /v1/monitor/saveOrUpdateMonitorData`（`businessId=4`，`collectionType=2`）保存本次体重
- **AND** 立即 `stopSession()` 停止广播扫描（绑定关系保留）
- **AND** 横条刷新 `lastSyncAt`，展示已绑定未监听（可点「点击重试」再测）
- **AND** 经 Bridge emit `ble.synced`（含 `weightKg`；保存成功时含 `monitorId`）

### Requirement: FundeNative 体重 BLE 只读查询

在体重 H5 场景下，`ble.getStatus` SHALL 返回当前 `BleWeightStatus`，且 MUST NOT 隐式调用 `startSession()`。

#### Scenario: H5 查询状态

- **WHEN** H5 调用 `ble.getStatus` 且 `metric` 为 `weight`
- **THEN** respond Status 字段：`metric`、`bound`、`connected`、`deviceName`、`lastSyncAt`
- **AND** 不改变会话启停状态

#### Scenario: 状态推送

- **WHEN** 体重宿主 `enablesWeightBle == true` 且绑定/会话状态变化
- **THEN** emit `ble.statusChange`（payload 同 Status）

### Requirement: OKOK 广播语义

体脂秤连接语义 SHALL 遵循 OKOK 单向广播模型，不得假造 GATT 连接状态。

#### Scenario: connected 字段含义

- **WHEN** 文档或 H5 读取 `connected`
- **THEN** 表示「广播监听会话是否活跃且蓝牙可用」，而非 GATT 已连接
