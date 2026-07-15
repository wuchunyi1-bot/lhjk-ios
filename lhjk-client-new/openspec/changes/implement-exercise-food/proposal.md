# Change: 实现饮食运动模块

## Why

健康 Tab 体征网格中「饮食运动」仍为 funde mock 原型页（硬编码热量/营养数据），需从 jumper-angel-doctor `FoodAndMotion` 移植真实 API 与完整记录流程。

## What Changes

- 新增 `ExerciseFoodService` + `ExerciseFoodModels`（BLL）
- 新增 `PL/Health/Metrics/ExerciseFood/` 全套页面
- 更新 `HealthRoutes`，删除旧 `ExerciseFoodViewController`
- 新增 OpenSpec `exercise-food` 规格文档

## Impact

- Affected specs: `exercise-food`（新建）
- Affected code: `BLL/Health/`、`PL/Health/Metrics/ExerciseFood/`、`HealthRoutes.swift`
