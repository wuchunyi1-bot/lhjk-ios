## Why

服务模块应展示**套餐详情**（健康包组合配置页），并从真实接口拉取数据。列表须带上商品 `id`，详情用 `getPackageDetail` 查询。

## What Changes

- 列表 `getEnabledHospitalPackagePage` 解析 `id` → `HealthPackageItem.id`
- 详情 `GET /v1/hospitalPackage/getPackageDetail`（hospitalId 临时常量 + packageId）
- 详情页 UI：轮播 / 信息头 / 套餐内容·详情 Tab / 必选组合 / 应付+加购+下单
- `/services/detail`、`/services/pkg` 统一指向套餐详情 VC

## Capabilities

### New Capabilities

- `service-package-detail`: 套餐详情 UI、列表 id、详情 API 映射

### Modified Capabilities

- （无）

## Impact

- `PL/Service/ServicePackageDetail/`
- `BLL/Service/HospitalPackageService.swift`、`HospitalPackageDetailModels.swift`、`ServiceRecommendModels.swift`
- `ServiceRoutes.swift`
