## Why

「选择套餐」页（`/services/list`）属于**医院服务**场景，左栏类目须使用 `getCategoryServiceListByType` 的 `type=1`（hospitalService）并**必传 `hospitalId`**；右栏套包使用 `getEnabledHospitalPackagePage`（非零售接口）。

## What Changes

- 左栏：`type=1` + `hospitalId`
- 右栏：`getEnabledHospitalPackagePage`，`categoryServiceId` + `hospitalId`
- `hospitalId` 优先取登录 `loginUserInfo.hospitalId`，否则 `ServiceCatalogService.selectedApiHospitalId()`，再降级临时常量

## 与 `/mall` 区分

| 页面 | 类目 type | 套包接口 |
|------|-----------|----------|
| `/services/list` 选择套餐 | `1` hospitalService + hospitalId | `getEnabledHospitalPackagePage` |
| `/mall` 富德优选 | `2` retail | `getEnabledRetailHospitalPackagePage` |
