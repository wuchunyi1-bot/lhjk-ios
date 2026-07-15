# Design: 饮食运动模块

## 架构

PL ViewController + ViewModel → `ExerciseFoodService` → `APIManager`。

## 业务常量

| 常量 | 值 | 说明 |
|------|-----|------|
| `businessId` 运动 | 8 | `saveSportDietData` |
| `businessId` 饮食 | 9 | `saveSportDietData` |
| `definitionCommon.type` 运动 | 1 | 字典项查询 |
| `definitionCommon.type` 食材 | 2 | 字典项查询 |
| 食材分类字典 parentId | `1373093850922487808` | `getDictionaryByParentId2` |

## 餐次 timeType

| 值 | 名称 |
|----|------|
| 1 | 早餐 |
| 2 | 早加餐 |
| 3 | 午餐 |
| 4 | 午加餐 |
| 5 | 晚餐 |
| 6 | 晚加餐 |

底部栏入口映射（对齐源项目）：
- `+早餐` → timeType 1
- `+午餐` → timeType 3
- `+晚餐` → timeType 5
- `+加餐` → ActionSheet 选 2/4/6
- `+运动` → 添加运动页

## 与源项目差异

| 项 | 源项目 | lhjk 实现 |
|----|--------|-----------|
| 顶部日历 | `ADRecordCaclendarView` 横滑周历 | 日期切换条 + 日期选择器；周历打点延后 |
| 热量圆环 | `ADDrawArcView` 自定义弧 | `ExerciseFoodCalorieHeaderView` 渐变卡 + 圆环进度 |
| 数量选择 | `ADFoodSelectUnitShowView` + `SQRulerScrollView` | `ExerciseFoodQuantitySheet` 底部弹层 + `MetricRulerView` |
| 拍照记录 | `ADAddPhotoFoodViewController` + OSS | **延后**；添加饮食页保留入口占位 |
| 健康报告 | 导航栏更多 → `ADHealthReportVC` | 延后 |

## 复用

- `MetricRulerView` — 数量/时长刻度
- `BloodPressureTime` — 毫秒戳与日期格式化
- `FlexibleString` / `FlexibleInt` — 响应解码
- Kingfisher — 食材/运动图标

## 通知

删除记录后发送 `exerciseFoodRecordDidChange`，首页刷新当日数据。
