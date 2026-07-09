# Service Recommend Packages

服务 Tab（商城模块）套包能力：推荐服务（字典 Tab + 套包分页）与搜索套餐（关键字 + 同一套包分页接口）。

## Scope

- **仅服务/商城模块**（`BLL/Service`、`PL/Service`）
- 健康模块（`BLL/Health`、`PL/Health`）不包含此能力

## API 约定

`GET /v1/hospitalPackage/getEnabledHospitalPackagePage`：

| 场景 | 必传 | 可选 |
|------|------|------|
| 推荐服务 | `packageMainCategory` | `hospitalId` |
| 搜索套餐 | `name`（关键字） | `hospitalId` |

## Spec

`openspec/changes/service-recommend-packages/specs/service/spec.md`
