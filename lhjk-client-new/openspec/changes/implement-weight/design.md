# Design: 体重监测模块

## 架构

沿用血压/血糖模式：PL ViewController + ViewModel → `WeightService` → `APIManager`。

## 业务常量

| 常量 | 值 |
|------|-----|
| businessId | 4 |
| dateType | 4 |
| history type | 2（`selectWeightHistoryData`） |
| equipment type | 3 |

## 与源项目差异

| 项 | 源项目 | lhjk 实现 |
|----|--------|-----------|
| 孕期生长曲线 | `ADDrawWeightCurveView` 原生绘制 | DGCharts 折线 + 推荐上下限虚线；孕期曲线视图延后 |
| BMI 计算 | `pregnancy.frontHeight` | 有身高时客户端计算；无身高时 BMI 字段可选不传 |
| 蓝牙体脂秤 | SDK 实时测量 | Banner + 设备列表；体脂字段在保存接口已预留 |
| 统计 Tab | 无 | 不实现（源项目无） |

## 复用组件

- `BluetoothDeviceBannerView`
- `BloodPressureRecordEntryCell`
- `BloodPressureAdviceCell`
- `BloodPressureGaugeView`
- `BloodPressureMetricColumnView`
- `MetricRulerView`（30–200 kg，步进 0.5）

## 趋势图点色规则

| 条件 | 颜色 |
|------|------|
| weight < xresult | `#FE6186` 偏低 |
| weight > yresult | `#FFB25C` 偏高 |
| 其他 | `#5AD480` 正常 |

## 通知

删除成功后发送 `Notification.Name.weightRecordDidDelete`，历史容器刷新图表与日志。
