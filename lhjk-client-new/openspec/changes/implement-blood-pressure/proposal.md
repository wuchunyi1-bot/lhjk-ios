## Why

健康 Tab 中血压页面目前为 funde 风格的纯 UI 原型（硬编码 mock 数据），未接入真实监测接口，也无法完成手动录入、历史趋势、日志与详情等完整业务流程。需要从 jumper-angel-doctor 项目移植已验证的血压模块逻辑，保持接口路径与参数不变，UI 按源项目样式实现。

## What Changes

- 新增 `blood-pressure` 规格，定义完整血压模块（服务首页、手动录入、历史三 Tab、详情、删除）
- 新增 BLL `BloodPressureService` + 数据模型，封装 6 个监测 API + 设备列表 API
- 新增 PL 层血压子模块目录，替换现有 `BloodPressureViewController`（funde 折线图原型）
- 路由扩展：`/health/metrics/blood-pressure/*` 子路径（manual / history / detail）
- 删除血压相关 mock 数据，全部走真实网络
- 蓝牙测量 UI 与设备绑定流程对齐源项目；AngelDoctor 专有 SDK 测量逻辑作为独立阶段接入（见 design.md）

## Capabilities

### New Capabilities

- `blood-pressure`: 血压监测完整模块（API、业务逻辑、页面流、UI 组件）

### Modified Capabilities

- （无）不修改 `openspec/specs/` 下已有归档 spec 的行为定义；健康 Hub 仍通过 `/health/metrics/blood-pressure` 进入血压模块

## Impact

- **PL**: `PL/Health/Metrics/BloodPressure/` 新增多 VC + ViewModel + Components；移除或替换 `BloodPressureViewController.swift`
- **BLL**: `BLL/Health/BloodPressureService.swift`、`BloodPressureModels.swift`、`HealthRoutes.swift`
- **DAL**: 通过现有 `APIManager` 调用 `/v1/monitor/*`、`/v1/equipmentUser/*`
- **AppContainer**: 注册 `bloodPressureService`
- **依赖**: 复用已有 DGCharts（趋势图）、SnapKit、Design Tokens
