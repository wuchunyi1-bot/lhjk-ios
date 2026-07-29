## 1. PL 测量页

- [x] 1.1 新增 `ScaleBroadcastMeasureViewModel`（启停会话、订阅 realtime/locked/error）
- [x] 1.2 新增 `ScaleBroadcastMeasureViewController`（居中按钮 + 体重展示 + Design Token）
- [x] 1.3 离开页 `stopSession`；锁定后自动停止并恢复「再测一次」

## 2. 路由与入口

- [x] 2.1 `HealthRoutes` 注册 `/health/scale/measure`
- [x] 2.2 `DevicesViewController`「添加新设备」跳转该路由

## 3. 验收

- [x] 3.1 进入页不自动扫描；点击后能收到实时/锁定数据并展示
