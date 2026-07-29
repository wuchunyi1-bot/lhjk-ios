## Why

OKOK 体脂秤为**单向广播**设备（不连 GATT）。现有 `ScaleBleSessionService` 已能扫广播解析，但缺少面向用户的原生测量页；H5 Bridge 在查询状态时就自动 `startSession`，也不符合「用户主动点按再听广播」的交互。需要一个极简原生页：中间一个按钮，点击后开始获取广播数据。

## What Changes

- 新增 Health 模块原生页「体脂秤测量」：居中主按钮控制启停广播扫描
- 测量中展示实时体重；锁定后展示最终体重并停止会话（可选继续）
- 注册路由 `/health/scale/measure`；从「智能设备」页可进入
- 页面生命周期：离开页必须 `stopSession`，避免后台空扫
- 复用既有 `ScaleBleSessionService` / OKOK Handler，不新开协议层

## Capabilities

### New Capabilities

- `scale-broadcast-measure`: 广播体脂秤原生测量页（启停扫描、实时/锁定展示）

### Modified Capabilities

- （无归档主规格变更；OKOK 协议行为仍以 `ble-device-pipeline-okok-scale` 为准）

## Impact

- `PL/Health/ScaleMeasure/` 新建 VC + ViewModel
- `BLL/Health/HealthRoutes.swift` 注册路由
- `PL/My/Devices/DevicesViewController` 入口跳转
- `ScaleBleSessionService`（只消费，必要时微调会话语义）
