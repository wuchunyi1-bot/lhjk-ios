## 1. Spec

- [x] 1.1 新增 `weight-h5-scale-ble` delta spec
- [x] 1.2 更新 `h5-host` delta（体重专用宿主）
- [x] 1.3 新增 `equipment-bind-api` delta spec（设备绑定/监测上报 BLL）
- [x] 1.5 新增 `scale-device-bind` delta spec（OKOK 绑定页扫描 + 三接口）

## 2. Implementation

- [x] 2.1 `WeightScaleBleStatusBarView` 横条 UI
- [x] 2.2 `WeightScaleBleStatusCoordinator` + `WebViewController(enablesWeightBle:)`
- [x] 2.3 `WebViewController` / `FundeNativeBridge` 收窄 BLE 订阅
- [x] 2.4 `ble.getStatus` 改为只读
- [x] 2.5 `HealthRoutes` 体重路由切换专用 VC
- [x] 2.6 `EquipmentBindModels` + `EquipmentBindService`（设备绑定/监测上报 API 封装）
- [x] 2.7 `AppContainer.equipmentBindService` 注册
- [x] 2.8a 体重 H5 宿主：`getEquipmentByOne(type=3)` + 有设备才启扫 + MAC 过滤 + 锁定上报
- [x] 2.8b 测量页仅称重：不在此页做服务端绑定链
- [x] 2.12 `ScaleDeviceBind`：OKOK 第一帧 → Vaild → Bind 检查 → `bindEquipment` → pop 体重 H5 主页
- [x] 2.13 选择页：OKOK 进绑定页；非 OKOK Toast「暂不支持该设备」
- [x] 2.9 `ScaleDeviceSelectViewModel`：并行 `getEquipmentUserByParam` + `getEquipmenByApp`，分支布局与解绑
- [x] 2.10 `ScaleDeviceSelectViewController` + 设备卡片 UI（选择设备 / 我的设备）
- [x] 2.11 注册 `/health/scale/devices`；横条「去绑定」与已绑定点击、`ble.openManager` 改走该页
- [x] 2.14 体重报告页「保存」pop；「重新测量」`delMonitorDataByMonitorId` 成功后清暂停并 pop

## 3. Verify

- [ ] 3.1 体重主页/详情/录入 H5 显示横条，血压等 H5 无横条
- [ ] 3.2 离开体重页停止扫描；返回后横条恢复监听
- [ ] 3.3 未绑定「去绑定」进入选择设备（型号列表）；已绑定进入我的设备（当前设备 + 添加设备）
- [ ] 3.5 点 OKOK 进绑定页扫描；非 OKOK Toast；绑定成功 pop 回体重 H5 主页
- [ ] 3.6 体重 H5 锁定测量后调用 `saveOrUpdateMonitorData`，`ble.synced` 带 `monitorId`，并停止蓝牙扫描
