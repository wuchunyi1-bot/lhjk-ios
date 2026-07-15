## Why

先前移植将 Hub 入口改成了 Angel Doctor 风格服务页，产品要求仍保留 Funde 风格的体征详情展示（图表 + 统计卡 + 记录列表）。网络接口与数据模型继续使用 jumper-angel-doctor 已对接的真实 API，不再使用 mock。

## What Changes

- **BREAKING（路由入口）**：`/health/metrics/blood-pressure|blood-sugar|weight|exercise` 重新指向 Funde 风格 `*ViewController`
- 恢复并改造：`BloodPressureViewController`、`BloodSugarViewController`、`WeightViewController`、`ExerciseFoodViewController`
- 上述页面通过 ViewModel 调用已有 BLL Service（`BloodPressureService` / `BloodSugarService` / `WeightService` / `ExerciseFoodService`），删除本地硬编码监测数据
- 保留 Angel 侧子流程入口：手动录入、历史记录、饮食/运动添加等仍可从 Funde 页导航栏或按钮进入已实现的子页
- 同步更新 OpenSpec：本变更为权威「Hub 展示层」说明；先前 `implement-*` 中的 Angel 服务首页作为子页/备用，不再作为 Hub 默认入口

## Capabilities

### New Capabilities

- `funde-metric-homes`：四个体征 Hub 页的 Funde UI + Angel API 数据绑定契约

### Modified Capabilities

- （主规格库 `openspec/specs/` 尚无归档的 blood-pressure 等能力；改动体现于本 change 的 delta 与现有 `implement-*` 路由约定覆盖）

## Impact

- `PL/Health/Metrics/{BloodPressure,BloodSugar,Weight,ExerciseFood}ViewController.swift`（恢复 + 接 API）
- 新增对应 `ViewModels/` 或内联 ViewModel
- `BLL/Health/HealthRoutes.swift` 入口改回 Funde VC
- 复用已有 BLL Service，不改 API 路径/参数
- 开发者需手动将恢复的 `.swift` 重新加入 Xcode（若曾从工程移除）
