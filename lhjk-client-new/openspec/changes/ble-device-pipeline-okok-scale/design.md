## Context

- 现状：`DAL/Bluetooth/BluetoothManager` 提供 Central 扫描/连接/GATT；扫描默认 `AllowDuplicates=false`，且无 advertisement manufacturerData 事件，无法支撑单向广播秤。
- 业务：多设备接入；OKOK V3 为首个协议样板（广播体脂秤，不连 GATT）。
- 分层约束：PL → BLL → DAL；设备协议解析不得塞进 `BluetoothManager`。

## Goals / Non-Goals

**Goals:**

- 通用基础层只做「蓝牙通用能力 + 原始事件」
- 每种设备一个独立 Handler，可插拔注册
- OKOK V3：扫广播 → 解析 → 锁定落库（体重 kg + 电阻 raw）
- 架构可扩展到血压计等连接式设备（同一管道，不同 Handler）

**Non-Goals:**

- 体脂率/肌肉等算法与 SDK
- 正式产品 ID 未到前的「量产过滤」写死（用可配置 allowlist，缺省宽松 + log）
- 本期不实现第二款设备的完整协议
- 不改 H5 体重页内部；原生落库 API 对齐既有 Weight 接口字段即可

## Architecture

```text
PL (测量页 / Banner)
    ↓ 只调 BLL
BLL DeviceSession / WeightBleService
    ↓ 启停会话、订阅业务事件、落库
DAL
  ├── BluetoothManager          # 基础层：CBCentral、扫描、连接、GATT、原始广播事件
  ├── BLEAdvertisementEvent     # 通用模型：peripheralId、name、rssi、advertisementData、timestamp
  └── Devices/
        ├── BLEDeviceHandler    # 协议：canHandle / start / stop / events
        ├── OKOKBroadcastScaleHandler + OKOKV3PacketParser
        └── (future) XxxBPHandler …
```

### 分层职责

| 层 | 职责 | 禁止 |
|----|------|------|
| `BluetoothManager` | poweredOn、scan/stop、connect、GATT R/W/Notify、**原样**抛出 advertisement | 解析厂商帧、业务落库、设备 UI |
| `BLEDeviceHandler` | 识别本设备、解析协议、发出领域事件（如 `weightLocked`） | 直接操作 CBCentral（经 Manager） |
| BLL | 注册/选择 Handler、会话生命周期、调用落库 API | CoreBluetooth 细节 |
| PL | 展示实时/锁定体重、权限引导 | 解析广播字节 |

### 广播 vs 连接

- **广播设备**（OKOK V3）：`startScan(allowDuplicates: true)`，Handler 只读 `advertisementPublisher`，**不 connect**。
- **连接设备**（未来血压计等）：Manager 仍走 connect + GATT；对应 Handler 订阅 `dataReceivedPublisher`。

## Decisions

1. **Handler 注册表**：`BLEDeviceRegistry` 持有 `[BLEDeviceKind: Handler]`；会话按业务传入 kind（如 `.okokBroadcastScale`），避免 Manager 内 if-else 堆品牌。
2. **原始事件模型**：统一 `BLEAdvertisementEvent`（含 `manufacturerData` / serviceData / localName）；Parser 只收 `Data`。
3. **厂商识别（优先）**：在厂商自定义广播中定位「首字节 `0xC0` + 第 10–15 字节为 MAC」的数据域；此为厂商口头对接规则，与 V3 数据域布局一致（版本在 offset0，MAC 在 offset9…14）。
4. **OKOK V3 解析**：在识别出的 15 字节数据域上解析重量/电阻/产品 ID/属性；外层若有 `0x10 0xFF` 或 Company ID 前缀则剥离/跳过。
5. **锁定落库**：仅 `isLocked == true` 且相对上次「流水号或重量变化」时落库；非锁定只发实时事件。
6. **产品 ID**：可选 allowlist；空则只靠 C0+MAC 过滤。
7. **AllowDuplicates**：仅广播测量会话开启。
8. **模块归属**：`DAL/Bluetooth/` 基础层；`DAL/Bluetooth/Devices/OKOK/` Handler；Health BLL 会话编排。

## OKOK V3 数据域（实现对照，与厂商过滤对齐）

| 偏移（0-based） | 厂商说法（1-based） | 字段 | 说明 |
|-----------------|---------------------|------|------|
| 0 | 第 1 字节 | 版本 | 必须为 `0xC0`（过滤条件） |
| 1 | 第 2 字节 | 流水号 | 非锁定递增；锁定保持 |
| 2–3 | 第 3–4 字节 | 重量 | 大端；÷10^小数位 |
| 4–5 | 第 5–6 字节 | 电阻 | 大端 raw |
| 6–7 | 第 7–8 字节 | 产品 ID | 可选 allowlist |
| 8 | 第 9 字节 | 属性 | 单位/小数/锁定等 |
| 9–14 | **第 10–15 字节** | **MAC** | 大端 6 字节（过滤条件） |

落库最小字段（本期）：`weightKg`、`resistanceRaw`、`mac`、`productId`、`measuredAt`；体脂字段不传。

## Risks / Trade-offs

- [manufacturerData 封装差异] → 仅允许：载荷以 C0 开头，或去掉 2 字节 Company ID / `0x10 0xFF` 后以 C0 开头；禁止在载荷中部搜索 C0
- [广播耗电] → 仅测量会话扫描
- [体重 HTTP 可能已迁 H5] → BLL 先发事件 + 本地最近一次锁定缓存；有 WeightService 再挂保存
- [ST:LB] → 延后

## 厂商 Checklist

- [x] 过滤规则：首字节 C0 + 10–15 字节 MAC（厂商已确认）
- [ ] 正式产品 ID 列表（可选加固）
- [ ] 真机 ADV hex 样例（非锁定 + 锁定）
- [ ] （后续）体脂算法 SDK

## Open Questions

- 无阻塞项；落库 HTTP 随体重模块恢复再接
