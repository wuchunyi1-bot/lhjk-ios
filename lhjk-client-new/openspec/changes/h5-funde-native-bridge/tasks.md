## 1. Spec 与 Bridge 骨架

- [x] 1.1 编写 OpenSpec（proposal/design/specs/tasks）
- [x] 1.2 实现 `FundeNativeBridge` + Weak handler；`WebViewController` 注入

## 2. 体重 BLE

- [x] 2.1 `ScaleBleSessionService` 暴露 Status / statusPublisher / synced 通知
- [x] 2.2 处理 `ble.getStatus` / `ble.openManager`；推送 statusChange / synced / error

## 3. 验收

- [x] 3.1 对照文档联调清单：横条依赖的 getStatus / openManager / 事件字段齐全
