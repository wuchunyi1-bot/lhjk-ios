# Tasks: 体重监测模块

## 1. BLL

- [x] `WeightModels.swift` — 常量、请求/响应模型
- [x] `WeightService.swift` — 首页、保存、趋势、日志、删除、设备
- [x] `AppContainer.weightService`

## 2. PL

- [x] `WeightServiceViewController` + ViewModel
- [x] `WeightManualViewController` + ViewModel（刻度尺 30–200 kg）
- [x] `WeightHistoryViewController`（趋势图 + 日志）
- [x] `WeightHistoryChartViewController` + ViewModel
- [x] `WeightHistoryLogViewController` + ViewModel
- [x] `WeightDetailViewController` + ViewModel（孕期字段 + 体脂六宫格）
- [x] `WeightServiceHeadCell`、`WeightHistoryLogCell`

## 3. 路由

- [x] `/health/metrics/weight` 及子路由
- [x] `/health/metrics/add?key=weight`
- [x] 删除旧 `WeightViewController`

## 4. Spec

- [x] `openspec/changes/implement-weight/specs/weight/spec.md`
- [x] 同步扩展 `implement-blood-sugar/specs/blood-sugar/spec.md`

## 5. 待手动

- [ ] 开发者将新增 Swift 文件加入 Xcode 工程
- [ ] 从工程中移除已删 `WeightViewController` 引用
