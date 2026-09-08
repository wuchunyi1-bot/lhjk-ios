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
- **THEN** 展示白卡横条：体脂秤图标、「您尚未绑定体脂秤」、描边按钮「去绑定」（对齐 Figma `4449:11585`）
- **AND** 点击跳转 `/health/scale/devices`

#### Scenario: 已绑定且会话监听中

- **WHEN** `bound == true` 且 `connected == true`（会话活跃）
- **THEN** 展示白卡横条：旋转搜索图标、「正在连接，请轻踩唤醒设备」、右侧箭头（对齐 Figma `5126:7385`）
- **AND** 点击跳转 `/health/scale/devices`

#### Scenario: 已绑定但未监听

- **WHEN** `bound == true` 且 `connected == false`
- **THEN** 展示白卡横条：「{设备名}·未连接｜点击重试」（「点击重试」跟在状态文案后，灰色分隔符 `｜`，橙色 14 Medium）、右侧箭头（对齐 Figma `5136:12244`）
- **AND** 点击整卡（不含「点击重试」）跳转 `/health/scale/devices`（已连接 / 我的设备）
- **AND** 仅点击「点击重试」调用 `resumeScanAfterUserRetry()` 重新扫描

#### Scenario: 已绑定开扫 30 秒未发现设备

- **WHEN** 体重 H5 已绑定并 `startSession(context: .weightH5Host)`
- **AND** 30 秒内未收到 MAC 匹配的 OKOK 广播（实时或锁定）
- **THEN** `stopSession()`，横条切到已绑定未监听（「点击重试」）
- **AND** MUST NOT 设置测量后自动启扫暂停标记（离开再进入仍可自动开扫）
- **WHEN** 30 秒内已收到 MAC 匹配的实时广播
- **THEN** 取消本次超时，保持扫描直到锁定、离开页面或用户停止会话

#### Scenario: 锁定测量完成

- **WHEN** 体重 H5 宿主会话收到 `OKOKScaleEvent.locked`
- **AND** 广播 MAC 与 `getEquipmentByOne` 返回的 MAC 规范化后完全一致（`AA:BB:CC:DD:EE:FF`）
- **THEN** 调用 `POST /v1/monitor/saveOrUpdateMonitorData`（`businessId=4`，`collectionType=2`）保存本次体重
- **AND** 该请求开始发出时立即 `stopSession()` 停止广播扫描（绑定关系保留；上报期间不得重新启扫）
- **AND** 收到 MAC 匹配的锁定帧时 MUST 同步 `stopSession()`，不得等网络请求返回后再停扫
- **AND** 测量完成后 MUST 暂停自动启扫，直至用户点击横条「点击重试」或离开体重模块
- **AND** `/health/metrics/weight/detail`、`/health/metrics/weight/scale/result` 等只读子页 MUST NOT 启扫或展示体脂秤横条
- **AND** 横条刷新 `lastSyncAt`，展示已绑定未监听（可点「点击重试」再测）
- **AND** 经 Bridge emit `ble.synced`（含 `weightKg`、`impedance`；保存成功时含 `monitorId`）
- **AND** `impedance > 0` 时先请求 `POST /v1/monitor/getWeightHomePageData`（`monitorId`），成功后再打开原生 `/health/metrics/weight/scale/result`（`WeightScaleResultViewController`，体重报告，对齐 Figma `5175:12518`）
- **AND** `getWeightHomePageData` 失败时 Toast 错误信息，MUST NOT 打开体重报告页
- **AND** `impedance == 0`（未测到电阻）时跳转 `/health/metrics/weight/detail`（H5 `#/weight/detail`，仅体重详情）

#### Scenario: MAC 与绑定设备不一致

- **WHEN** 扫描到 OKOK 广播，但其 MAC 与 `getEquipmentByOne.mac` 规范化后不一致（或接口未返回 MAC）
- **THEN** MUST NOT 采用该帧体重/电阻
- **AND** MUST NOT 调用 `saveOrUpdateMonitorData`
- **AND** MUST NOT emit `ble.synced`

### Requirement: 原生体重报告页操作

有阻抗的原生体重报告页 SHALL 提供「保存」与「重新测量」。本页打开时监测记录**已经**由 `saveOrUpdateMonitorData` 写入服务端，PL 只调 `EquipmentBindService`，禁止直连 path。

#### Scenario: 保存

- **WHEN** 用户点击「保存」
- **THEN** MUST NOT 再次调用 `saveOrUpdateMonitorData`
- **AND** MUST NOT 调用 `delMonitorDataByMonitorId`
- **AND** MUST NOT 清除测量后自动启扫暂停标记（返回体重页后仍需点横条「点击重试」）
- **AND** 立即 `pop` 返回上一页（体重 H5），保留本次 `monitorId` 对应记录

#### Scenario: 重新测量

- **WHEN** 用户点击「重新测量」
- **THEN** 调用 `DELETE /v1/monitor/delMonitorDataByMonitorId`，Query `monitorId` 为当前报告页记录 ID
- **AND** 删除成功后清除测量后自动启扫暂停标记（`ScaleBleSessionService.clearAutoScanPause`），以便返回体重页后可再次扫描
- **AND** `pop` 返回上一页
- **WHEN** 删除请求失败
- **THEN** Toast 错误信息，停留本页，MUST NOT pop、MUST NOT 清除暂停标记

#### Scenario: 按钮展示

- **WHEN** 报告数据加载成功
- **THEN** 主按钮为「保存」（品牌主色胶囊，327×51 / 随屏宽左右各再缩 8pt）
- **AND** 次操作「重新测量」为灰色纯文字，无描边底
- **AND** 删除进行中两按钮均不可点

#### Scenario: 报告页结构

- **WHEN** `getWeightHomePageData` 成功并进入原生体重报告页
- **THEN** 对齐 Figma `5175:12518`：顶部半圆弧概要卡（体重、当前(KG)、测量时间、身体年龄 / BMI / 体脂率）、「我的指标」白卡双列体成分、底部保存 / 重新测量
- **AND** 指标名称、数值、单位、`monitorResults` 状态标签取接口 `bodyCompositionResults`

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
