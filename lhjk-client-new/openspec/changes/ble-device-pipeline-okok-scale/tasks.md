## 1. DAL 基础层

- [x] 1.1 扩展 `BluetoothManager`：扫描参数支持 `allowDuplicates`；新增 `advertisementPublisher`（原始事件）
- [x] 1.2 补充 `BLEAdvertisementEvent` 等通用模型；保持既有连接/GATT API 可用
- [x] 1.3 定义 `BLEDeviceHandler` 协议 + `BLEDeviceRegistry` 注册表

## 2. OKOK V3 Handler

- [x] 2.1 实现 `OKOKV3PacketParser`（厂商 C0 + 10–15 MAC 过滤；V3 数据域解析）
- [x] 2.2 实现 `OKOKBroadcastScaleHandler`：订阅 advertisement → 过滤 → 发布 realtime / locked 事件
- [x] 2.3 产品 ID allowlist 配置（可空）；锁定去重逻辑

## 3. BLL 编排与落库

- [x] 3.1 Health 侧 `ScaleBleSessionService`：启停 OKOK Handler / 扫描；订阅 locked
- [x] 3.2 锁定写入本地缓存（weightKg + mac 等）；HTTP 待 WeightService 恢复；不传体脂算法字段

## 4. 验收与文档

- [x] 4.1 Parser 覆盖：C0 过滤、Len+Type 前缀、Company ID 搜索窗口
- [x] 4.2 design 已更新厂商过滤规则；第二台设备只需新增 Handler
