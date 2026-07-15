## Context

iOS 服务模块已接入 Banner、9 宫格字典、套包分页与详情 API，但 Hub 仍保留「推荐服务」横向 Tab（与 funde-client 最新 Hub 不一致），`ServiceListViewController` 与 `HealthMallViewController` 仍使用本地 mock。

funde-client 当前口径：

| 页面 | 数据来源 | 导航 |
|------|---------|------|
| Hub 富德优选 | `retailPackages.slice(0,6)` | `/services/pkg/:id`，查看全部 → `/mall` |
| 列表页左栏 | `healthManagementBusinessCategories` | — |
| 列表页右栏 | 按 `businessCategory` 过滤套包 | `/services/pkg/:id` |
| 商城 | `retailPackages` | `/services/pkg/:id` |

iOS API 映射：`businessCategory=电商零售` → 字典二级类目 `value`（**Integer**）作为 `packageMainCategory`；健康管理类目 → 字典 parentId `2074711807339139072` 的 `value`（同为 Integer）。

## Goals / Non-Goals

**Goals**

- Hub、列表、商城与 funde-client 信息架构一致
- 删除服务模块内流入 UI 的 mock 套餐/商品数据
- 详情入口统一为已实现的 `ServicePackageDetailViewController`

**Non-Goals**

- 购物车 v5 单条结算（见 `adapt-funde-service-cart`，本变更不重复实现）
- 就医协助详情页内容
- 订单确认/支付页完整流程
- 机构选择真实 API（仍用临时 `hospitalId`）

## Decisions

### 1. Hub Section 重命名

`ServiceViewModel.Section.recommend` → `mallPreview`；`ServiceHubSnapshot.recommendedPackages` → `mallPreviewPackages`；移除 Hub 上的 `categories` / `selectedCategoryId`（类目 Tab 仅保留在列表页）。

### 2. 零售套包查询

```swift
// RetailCategoryService 从字典树解析「电商零售」二级类目 value（Int）
// HospitalPackageService.fetchRetailPackageItems → packageMainCategory: Int
```

Hub 预览 `pageSize=6`；商城 `pageSize=20`。

### 3. 列表页 ViewModel 化

新增 `ServiceListViewModel`：加载字典类目 + 按选中类目请求套包；路由参数 `code` 若匹配某类目 `title`/`value` 则选中，否则默认第一项（对齐 funde `syncActiveCategory`）。

### 4. 商城 ViewModel 化

`HealthMallViewModel` 拉取零售套包；Tab「全部」展示全部结果（funde 零售仅 `电商零售` 一类，首版可隐藏 SegmentedControl 或保留「全部」单 Tab）。

### 5. 路由

- `/mall/detail` → 与 `/services/pkg` 相同 VC
- 列表/Hub/商城卡片点击 → `/services/pkg`

## Risks / Trade-offs

- **后端 `packageMainCategory` 类型**：必须为字典 `value` 解析的 **Integer**；禁止传中文业务分类名
- **列表左栏文案较长**：沿用 funde 多行类目名，左栏宽度保持 78–88pt，字体 `fdMicro`

## Migration

- 删除 `ServiceListViewController` 内 `SvcMatrix`/`SvcPkg` mock 数组（`ServiceListModels.swift` 中 mock 类型可保留给 Cell 过渡或改为 `HealthPackageItem`）
- `ServiceCatalogService.loadMallProducts()` 标记废弃，调用方改走 `HospitalPackageService`
