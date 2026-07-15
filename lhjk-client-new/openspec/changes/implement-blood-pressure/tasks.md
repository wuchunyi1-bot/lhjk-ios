## 1. BLL / DAL 层

- [x] 1.1 新增 `BloodPressureModels.swift`（请求/响应模型、业务常量）
- [x] 1.2 新增 `BloodPressureService.swift`（6 个监测 API + 设备列表 + 删除）
- [x] 1.3 在 `AppContainer` 注册 `bloodPressureService`
- [x] 1.4 定义 `Notification.Name.bloodPressureRecordDidDelete`

## 2. UI 组件

- [x] 2.1 `BloodPressureGaugeView` 圆环仪表
- [x] 2.2 `BloodPressureMetricColumnView` 三列指标
- [x] 2.3 `BloodPressureRecordEntryCell` 手动/历史入口
- [x] 2.4 `BloodPressureAdviceCell` 建议卡
- [x] 2.5 `BloodPressureValuePickerView` 三列数值选择器
- [x] 2.6 `BloodPressureHistoryLogCell` 日志行
- [x] 2.7 `BluetoothDeviceBannerView` 设备 Banner

## 3. ViewModel

- [x] 3.1 `BloodPressureServiceViewModel`
- [x] 3.2 `BloodPressureManualViewModel`
- [x] 3.3 `BloodPressureHistoryChartViewModel`
- [x] 3.4 `BloodPressureHistoryLogViewModel`
- [x] 3.5 `BloodPressureHistoryStatsViewModel`
- [x] 3.6 `BloodPressureDetailViewModel`

## 4. ViewController

- [x] 4.1 `BloodPressureServiceViewController` 服务首页
- [x] 4.2 `BloodPressureManualViewController` 手动记录
- [x] 4.3 `BloodPressureHistoryViewController` 三 Tab 容器
- [x] 4.4 `BloodPressureHistoryChartViewController` 趋势图
- [x] 4.5 `BloodPressureHistoryLogViewController` 日志
- [x] 4.6 `BloodPressureHistoryStatsViewController` 统计
- [x] 4.7 `BloodPressureDetailViewController` 详情与删除

## 5. 路由与清理

- [x] 5.1 更新 `HealthRoutes` 注册新路由，兼容 `/health/metrics/add?key=blood-pressure`
- [x] 5.2 删除旧 `BloodPressureViewController.swift`（funde 原型）

## 6. 验收

- [x] 6.1 编译检查（lint）无新增错误
- [ ] 6.2 提示开发者将新文件加入 Xcode 工程
