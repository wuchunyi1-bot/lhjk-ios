## Why

App 将接入多种 BLE 设备（体重秤、血压计等）；现有 `BluetoothManager` 仅覆盖连接/GATT 读写，缺少「广播扫描 + 多设备协议分离」的扩展点。OKOK 单向广播体脂秤 V3 可作为首个落地样板，先做扫描解析与锁定落库（不含体脂算法）。

## What Changes

- **DAL 基础层**：扩展通用 BLE 能力（含广播 advertisement 事件流），不解析任何厂商协议
- **设备协议层**：每种设备独立 Handler/Parser 类，只消费基础层原始广播/连接数据
- **首设备 OKOK V3**：解析 17 字节厂商数据 → 非锁定实时体重 / 锁定后落库（体重 + 电阻原始值；体脂算法本期不做）
- **BLL 编排**：按业务启动对应 Handler；落库走体重相关 Service（或本地队列），与 PL 解耦
- **Checklist**：厂商待补齐项（产品 ID、样例包）写入 design，不阻塞架构落地

## Capabilities

### New Capabilities

- `ble-device-pipeline`: 多设备 BLE 分层管道（基础层 + 设备 Handler 注册）
- `okok-broadcast-scale`: OKOK V3 广播秤扫描解析与锁定落库

### Modified Capabilities

- `bluetooth`: 补充广播扫描、允许重复广播、原始 advertisement 事件（不破坏既有连接/GATT 能力）

## Impact

- `DAL/Bluetooth/`：`BluetoothManager`、models；新增 pipeline / handlers 目录
- `BLL/Health/`（或设备编排 Service）：调用 Handler、触发落库
- 参考：OKOK《健康秤 APP 接入协议-单向广播体脂秤 V3》；既有 `openspec/specs/bluetooth/`
- **本期不做**：体脂算法/SDK、App Store 评分类无关能力、其它品牌设备 Handler 实现（仅预留注册点）
