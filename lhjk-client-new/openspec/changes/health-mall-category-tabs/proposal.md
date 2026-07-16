## Why

富德优选商城（`/mall`）需对齐 funde-client `HealthMallView.vue`：顶部横向分类 Tab + 双栏商品网格。类目与商品须对接真实 API，不再本地过滤 mock。

## What Changes

- 顶部 Tab：首项固定「全部」，其余来自 `getCategoryServiceListByType`（`type=2` 零售类）
- 商品列表：`getEnabledRetailHospitalPackagePage`，`categoryServiceId` 为选中 Tab id（「全部」传空）
- 布局对齐 funde：胶囊 Tab、1:1 封面、双栏网格、底部保障文案

## Capabilities

- `service`：富德优选商城 Tab 筛选与 API 对接（delta）

## Impact

| 层 | 文件 |
|----|------|
| BLL Models | `ServiceRecommendModels.swift` |
| BLL Service | `HospitalPackageService.swift` |
| PL | `MallCategoryTabBar.swift`、`HealthMallViewModel.swift`、`HealthMallViewController.swift`、`MallProductCell.swift` |

**参考**：`funde-client/prototype/src/views/services/HealthMallView.vue`、`docs/page-specs/mall-hub.page.yaml`
