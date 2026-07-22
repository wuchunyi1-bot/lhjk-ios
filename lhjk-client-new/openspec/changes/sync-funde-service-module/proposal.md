## Why

funde-client 服务模块（2026-07）已完成结构性调整：Hub 去掉「推荐服务」类目 Tab，改为「富德优选」零售预览；套餐列表页左侧改为健康管理类目（非德系 9 宫格）；商城与 Hub 预览统一跳转 `/services/pkg/:id`；购物车 v5 为单条结算模型。iOS 需对齐产品逻辑并删除仍在使用的 mock 数据。

## What Changes

- **Hub 顶栏**：左侧固定「健康服务」+「德系健康管理 · 9 大产品线」；去掉搜索、机构切换与购物车（购物车入口仅保留选择套餐页、「我的」金刚区）
- **Hub Banner**：仅图片轮播（无文案叠加）；自动播 3.6s **单向无限循环**（不反向回滚）
- **Hub 区块**：Banner + 德系 9 宫格 + **富德优选**（前 6 条零售套包，无 Tab）+ 三好卡提示条
- **套餐列表** `/services/list`：左栏健康管理类目（字典 `2074711807339139072`），右栏套包分页 API；去除德系 mock 矩阵/套餐
- **富德优选商城** `/mall`：套包 API，去除 `services.json` mall mock
- **路由统一**：商品/套包详情一律 `/services/pkg`（`/mall/detail` 兼容重定向）
- **Spec 归档**：合并 `service-recommend-packages` Hub 区块变更，补充列表页与商城 spec delta

## Capabilities

### New Capabilities

- （无独立 capability；在 `service` delta 中描述）

### Modified Capabilities

- `service`: Hub 富德优选、列表页健康管理类目、商城 API 化、路由统一

## Impact

- `PL/Service/`（Hub、List、Mall、Routes）
- `BLL/Service/`（`ServiceHubCacheService`、`HospitalPackageService`、`ServiceCatalogService`、`ServiceModels`）
- `openspec/changes/service-recommend-packages` 中 Hub「推荐服务」描述需以本变更为准

## Reference

- funde-client: `prototype/src/views/services/ServicesView.vue`, `ServiceListView.vue`, `HealthMallView.vue`
- funde-client: `prototype/src/mock/health-package-source.ts`（`retailPackages`, `healthManagementBusinessCategories`）
- funde-client: `docs/v0.1/modules/services.md`
