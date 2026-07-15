## Context

对齐 `implement-blood-pressure` 架构，UI 样式参考 jumper-angel-doctor `ADSugarService`。

## Goals

- 服务首页、手动录入（餐次+刻度尺）、历史四 Tab、详情删除
- API 路径与参数与源项目一致

## Non-Goals

- 蓝牙 SDK（Jumper/Roche）实时测量
- 糖尿病类型弹窗与 `updatePregnantByUserId`（孕期档案）

## Decisions

- 复用血压模块 `BluetoothDeviceBannerView`、`BloodPressureRecordEntryCell`、`BloodPressureAdviceCell`、`BloodPressureGaugeView`、`MetricRulerView`
- 历史比血压多「表格」Tab
- 保存重复记录 `G0009` → `submitTimes: 2` 二次确认
