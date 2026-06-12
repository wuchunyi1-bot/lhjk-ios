# Bluetooth

## Purpose

提供蓝牙低功耗（BLE）连接功能，支持扫描外围设备、建立连接、发现服务和特征、读写数据以及处理连接状态变化。

## Requirements

### Requirement: BLE Central Manager
系统 SHALL 使用 CoreBluetooth 框架实现 BLE 中心模式（Central），负责扫描、连接和管理外围设备。

#### Scenario: 初始化蓝牙管理器
- **WHEN** 应用启动并初始化蓝牙模块
- **THEN** DAL 层创建 `CBCentralManager` 实例，并监听蓝牙状态变化

#### Scenario: 蓝牙状态检测
- **WHEN** 设备蓝牙状态发生变化
- **THEN** BLL 层通过回调或通知将状态（poweredOn / poweredOff / unauthorized / unsupported）传递至 PL 层展示

---

### Requirement: Device Scanning
系统 SHALL 支持扫描附近的 BLE 设备，并能按设备名称或服务 UUID 进行过滤。

#### Scenario: 开始扫描
- **WHEN** 用户触发扫描操作
- **THEN** 蓝牙管理器调用 `scanForPeripherals(withServices:options:)` 开始扫描，并通过 delegate 回调返回发现的设备列表

#### Scenario: 停止扫描
- **WHEN** 用户停止扫描或扫描超时
- **THEN** 蓝牙管理器调用 `stopScan()` 停止扫描以节省电量

#### Scenario: 扫描结果显示
- **WHEN** 发现新的外围设备
- **THEN** PL 层实时更新设备列表 UI，显示设备名称、信号强度（RSSI）和连接状态

---

### Requirement: Device Connection
系统 SHALL 支持与指定外围设备建立和断开连接。

#### Scenario: 建立连接
- **WHEN** 用户选择目标设备
- **THEN** 蓝牙管理器调用 `connect(_:options:)` 建立连接，PL 层显示连接中状态

#### Scenario: 连接成功
- **WHEN** 连接建立成功
- **THEN** 蓝牙管理器在 `centralManager(_:didConnect:)` 中自动触发服务发现，PL 层更新设备状态为已连接

#### Scenario: 连接失败
- **WHEN** 连接失败或超时
- **THEN** BLL 层根据错误类型进行重试（最多 3 次），重试失败后通知 PL 层展示失败原因

#### Scenario: 断开连接
- **WHEN** 用户主动断开或设备断开连接
- **THEN** 系统清理该设备的服务和特征缓存，PL 层更新 UI 状态

---

### Requirement: Service & Characteristic Discovery
系统 SHALL 支持发现已连接设备的服务和特征。

#### Scenario: 服务发现
- **WHEN** 设备连接成功后
- **THEN** 自动调用 `discoverServices(_:)` 发现所有服务，并将结果缓存至 DAL 层

#### Scenario: 特征发现
- **WHEN** 服务发现完成后
- **THEN** 对每个服务调用 `discoverCharacteristics(_:for:)` 发现特征，区分 Read / Write / Notify 属性

---

### Requirement: Data Communication
系统 SHALL 支持通过特征进行数据读写和接收通知。

#### Scenario: 读取特征值
- **WHEN** BLL 层需要读取某个特征的值
- **THEN** 调用 `readValue(for:)` 并通过 delegate 回调获取结果

#### Scenario: 写入特征值
- **WHEN** BLL 层需要向设备发送数据
- **THEN** 调用 `writeValue(_:for:type:)` 完成写入，支持带响应（.withResponse）和无响应（.withoutResponse）两种模式

#### Scenario: 接收通知
- **WHEN** 订阅了某个特征的 Notify 通知
- **THEN** 当设备发送数据时，通过 `peripheral(_:didUpdateValueFor:error:)` 接收数据并传递给 BLL 层处理
