## MODIFIED Requirements

### Requirement: 体重 BLE 仍走 FundeNative

体重指标 H5 SHALL 经 `WebViewController(enablesWeightBle: true)` 承载：注入 `FundeNative` 并由 `WeightScaleBleStatusCoordinator` 管理横条与会话。其它 `WebViewController` SHALL 注册 `FundeNative`（与 `FundeBridge` 共存）但 `enablesWeightBle = false`，不得订阅体重 BLE 事件推送。

#### Scenario: 体重页 Bridge

- **WHEN** 打开 `/health/metrics/weight` 及其子路由（add/records/detail）
- **THEN** 使用 `WebViewController(..., enablesWeightBle: true)`
- **AND** 展示原生体脂秤状态横条

#### Scenario: 非体重页

- **WHEN** 打开血压、套餐中间页等其它 H5
- **THEN** 使用通用 `WebViewController`
- **AND** 不向 H5 推送 `ble.statusChange`（除非该页主动调用且未来扩展；本期体重以外不推送）
