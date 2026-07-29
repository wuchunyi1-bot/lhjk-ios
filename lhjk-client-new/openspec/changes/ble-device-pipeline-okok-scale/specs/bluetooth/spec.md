## MODIFIED Requirements

### Requirement: Device Scanning

系统 SHALL 支持扫描附近的 BLE 设备，并能按设备名称或服务 UUID 进行过滤；**并支持广播测量场景下的重复广播与原始 advertisement 转发**。

#### Scenario: 开始扫描

- **WHEN** 用户触发扫描操作
- **THEN** 蓝牙管理器调用 `scanForPeripherals(withServices:options:)` 开始扫描，并通过 delegate 回调返回发现的设备列表

#### Scenario: 停止扫描

- **WHEN** 用户停止扫描或扫描超时
- **THEN** 蓝牙管理器调用 `stopScan()` 停止扫描以节省电量

#### Scenario: 扫描结果显示

- **WHEN** 发现新的外围设备
- **THEN** PL 层实时更新设备列表 UI，显示设备名称、信号强度（RSSI）和连接状态

#### Scenario: 广播测量扫描

- **WHEN** 广播类设备会话请求扫描
- **THEN** 允许 duplicates，并将每次 discovery 的 advertisementData 原样经 Publisher 传出
- **AND** 基础层不解析厂商协议
