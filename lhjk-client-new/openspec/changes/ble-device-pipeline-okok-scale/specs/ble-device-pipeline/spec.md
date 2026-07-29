## ADDED Requirements

### Requirement: BLE 设备管道分层

系统 SHALL 将 BLE 能力分为「基础层」与「设备 Handler 层」，以支持多设备并行接入且互不耦合。

#### Scenario: 基础层职责边界

- **WHEN** 实现或扩展 `BluetoothManager`
- **THEN** 其仅负责 Central 状态、扫描启停、连接/断开、GATT 读写与 Notify、以及原样转发 advertisement / 特征值数据
- **AND** 不得包含任一厂商协议帧解析或业务落库逻辑

#### Scenario: 设备 Handler 隔离

- **WHEN** 接入任一具体蓝牙设备
- **THEN** 该设备协议解析与领域事件位于独立类型（如 `OKOKBroadcastScaleHandler`）
- **AND** Handler 仅依赖基础层发布的原始事件模型，不直接持有 `CBCentralManager`

#### Scenario: Handler 注册与启停

- **WHEN** BLL 开始某类设备测量会话
- **THEN** 通过注册表按设备 kind 取得 Handler 并 `start`
- **WHEN** 会话结束或离开测量页
- **THEN** 调用对应 Handler `stop`，并停止不必要的扫描以省电

### Requirement: 原始广播事件

基础层 SHALL 在扫描时发布原始广播事件，供广播类与连接类设备共用过滤入口。

#### Scenario: 发布 advertisement

- **WHEN** Central 回调发现外围设备且带有 advertisementData
- **THEN** 发布包含 peripheralId、name、rssi、advertisementData（含 manufacturerData）、timestamp 的事件
- **AND** 不在基础层解读 manufacturerData 业务含义

#### Scenario: 允许重复广播

- **WHEN** 广播类测量会话请求扫描且需要连续重量更新
- **THEN** 扫描选项允许 duplicates（`AllowDuplicates = true`）
- **WHEN** 普通设备列表扫描
- **THEN** 默认不允许 duplicates，避免列表抖动
