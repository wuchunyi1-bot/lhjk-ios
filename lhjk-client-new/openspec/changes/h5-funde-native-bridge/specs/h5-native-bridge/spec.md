## ADDED Requirements

### Requirement: FundeNative Bridge 通道

iOS WebView SHALL 注入 `FundeNative` script message handler，并按宿主文档与 H5 双向通信。

#### Scenario: H5 调用原生

- **WHEN** H5 执行 `window.webkit.messageHandlers.FundeNative.postMessage(message)`
- **THEN** 原生解析 JSON：`action`、`params`（可选）、`callbackId`（可选）
- **AND** 成功时调用 `window.__fundeBridge.respond(callbackId, result)`
- **AND** 失败时调用 `window.__fundeBridge.reject(callbackId, error)`（`error` 为 string 或 `{ message }`）

#### Scenario: 原生推送事件

- **WHEN** 原生需主动通知 H5
- **THEN** 调用 `window.__fundeBridge.emit(event, payload)`

### Requirement: 体重 BLE Bridge 首期

在 `platform=ios` 体重 H5 场景下，原生 SHALL 支持文档中的体重蓝牙 actions / events。

#### Scenario: ble.getStatus

- **WHEN** action 为 `ble.getStatus` 且 `params.metric` 为 `weight`（或缺省按 weight）
- **THEN** 回包 Status：`metric`、`bound`、`connected`、`deviceName`、`lastSyncAt`

#### Scenario: ble.openManager

- **WHEN** action 为 `ble.openManager` 且 metric 为 weight
- **THEN** 打开原生设备管理页（`/me/devices`），回包可空

#### Scenario: 状态与同步事件

- **WHEN** 绑定/连接/会话状态变化
- **THEN** emit `ble.statusChange`（payload 同 Status）
- **WHEN** 原生完成一次锁定测量落库（或等价成功）
- **THEN** emit `ble.synced`（含 `metric`，可选 `monitorId` 与 Status 字段）
- **WHEN** 蓝牙权限或会话错误
- **THEN** emit `ble.error`（`message` 必填）

#### Scenario: 未知 action

- **WHEN** action 未实现
- **THEN** reject，提示未知 action

### Requirement: 宿主 URL 约定索引

App 打开 H5 时 SHALL 继续使用 `H5Config` 拼接 `token` + `platform=ios` 与业务 Query，与文档路由表一致（体重/血压/血糖/饮食运动/健康档案等既有路径不回退）。
