# Change: 实现体重监测模块

## Why

健康 Tab 体征网格中体重仍为 funde mock 原型页，需从 jumper-angel-doctor `ADWeightDevice` 移植真实 API 与完整页面流，与血压/血糖模块对齐。

## What Changes

- 新增 `WeightService` + `WeightModels`（BLL）
- 新增 `PL/Health/Metrics/Weight/` 全套页面（服务首页、手动、历史 2 Tab、详情）
- 更新 `HealthRoutes`，删除旧 `WeightViewController`
- 新增 OpenSpec `weight` 规格文档

## Impact

- Affected specs: `weight`（新建）
- Affected code: `BLL/Health/`, `PL/Health/Metrics/Weight/`, `DAL/AppContainer.swift`, `HealthRoutes.swift`
