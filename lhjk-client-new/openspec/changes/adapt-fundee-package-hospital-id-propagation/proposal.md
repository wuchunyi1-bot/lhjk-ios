## Why

套包列表接口（`getEnabledRetailHospitalPackagePage`、`getEnabledHospitalPackagePage`）与详情 `packageInfo` 均已返回 `hospitalId`。此前客户端跳转详情、加购、立即下单仍依赖全局机构选择或临时常量，导致与列表所属机构不一致。

## What Changes

- 列表 DTO / UI 模型增加 `hospitalId`，Mapper 写入 `HealthPackageItem`
- 列表卡片点击跳转 `/services/pkg` 时携带列表项 `hospitalId`
- 详情请求 `getHospitalPackageDetail` 使用路由传入的 `hospitalId`（来自列表）
- 详情 `packageInfo.hospitalId` 映射到 `ServicePackageDetail`，加购 / 立即下单优先使用
- 搜索、服务列表、商城、Hub 预览等入口统一传递

## Capabilities

### New Capabilities

- `package-hospital-id`: 套包列表 → 详情 → 加购/下单 `hospitalId` 传递规则

### Modified Capabilities

- `service-package-detail`: 详情加载与提交时的 `hospitalId` 解析优先级
- `service` / `retail-package-infinite-scroll`: 列表跳转参数

## Impact

- `BLL/Service/ServiceRecommendModels.swift`、`ServiceModels.swift`、`HospitalPackageDetailModels.swift`
- `BLL/Service/ServiceRoutes.swift`
- `PL/Service/` 各列表页 Cell 与 VC、`ServicePackageDetailViewModel`
