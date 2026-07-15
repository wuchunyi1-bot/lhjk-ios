## Why

健康 Tab 血糖页面仍为 funde 原型 mock，需从 jumper-angel-doctor 移植完整血糖监测能力，与已完成的血压模块对齐。

## What Changes

- 新增 `blood-sugar` spec 与 BLL/PL 完整实现
- 替换 `BloodSugarViewController` 为服务首页 + 手动录入 + 历史四 Tab + 详情
- 接入真实 API，删除 mock

## Capabilities

### New Capabilities

- `blood-sugar`: 血糖监测完整模块

## Impact

- `BLL/Health/BloodSugarModels.swift`、`BloodSugarService.swift`
- `PL/Health/Metrics/BloodSugar/`
- `HealthRoutes.swift`、`AppContainer.swift`
