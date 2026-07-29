## Why

H5 宿主文档新增 App ↔ H5 Bridge（`FundeNative` / `__fundeBridge`），首期用于体重页蓝牙横条：查询状态、打开设备管理、接收同步/错误事件。现有 `WebViewController` 仅加载 URL，无 JSBridge；`ScaleBleSessionService` 也未对 H5 暴露 Status。

## What Changes

- 注入 `webkit.messageHandlers.FundeNative`，解析 `{ action, params, callbackId }`
- 回包 / 推事件：调用 H5 `window.__fundeBridge.respond|reject|emit`
- 实现 `ble.getStatus`、`ble.openManager`；推送 `ble.statusChange` / `ble.synced` / `ble.error`
- `ScaleBleSessionService` 补充 Status 模型与状态变更通知
- 对齐文档路由/Query 已由 `H5Config` 覆盖的部分写入 spec 索引（本期不重做 URL）

## Capabilities

### New Capabilities

- `h5-native-bridge`: FundeNative JSBridge 与体重 BLE 首期能力

### Modified Capabilities

- （无主 specs 归档修改；delta 在本 change）

## Impact

- `WebViewController`、新增 Bridge 模块
- `ScaleBleSessionService` / 可选 `AppContainer`
- 参考：`/Users/chunyi/Desktop/h5接入文档.md`
