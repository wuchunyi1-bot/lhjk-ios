# Service Module Delta — sync-funde-service-module

## MODIFIED Requirements

### Requirement: 服务首页顶栏（对齐 funde ServicesView.vue）

服务 Tab 顶栏 SHALL 固定展示左侧文案与右侧购物车，**不得**展示搜索入口或机构切换。

#### Scenario: 左侧文案
- **WHEN** 服务首页展示
- **THEN** 左侧主标题为「健康服务」
- **AND** 副标题为「德系健康管理 · 9 大产品线」

#### Scenario: 购物车
- **WHEN** 用户点击右上角购物车图标
- **THEN** 跳转 `/services/cart`

#### Scenario: 无搜索
- **WHEN** 服务首页展示
- **THEN** 顶栏不展示搜索按钮；套餐搜索入口不在 Hub 顶栏（可在列表页等其他入口）

---

### Requirement: 服务首页 Banner 轮播

运营 Banner 区域 SHALL **仅**展示图片轮播（无文案叠加卡），自动播放单向循环。

#### Scenario: 仅 Banner 图
- **WHEN** Banner 有图片 URL
- **THEN** 仅展示圆角图片，不叠加 code / 标题 / 副标题文案层
- **WHEN** 无图片
- **THEN** 展示纯色占位底，仍不叠加文案控件

#### Scenario: 自动轮播单向循环
- **WHEN** Banner 数量 > 1
- **THEN** 每 3.6s 向下一张滚动
- **AND** 从最后一张切到第一张时 MUST 继续向前滚动（无限循环），MUST NOT 反向回滚整段

#### Scenario: 指示器
- **WHEN** Banner 数量 > 1
- **THEN** 展示页码指示器，当前页为品牌主色

---

### Requirement: 服务首页 Hub 布局（对齐 funde-client 2026-07）

服务 Tab 根页面区块顺序：

1. 运营 Banner 轮播（`columnContent/getByCode`，仅图片）
2. 德系 9 宫格（字典 parentId `2074711686115364864`）
3. **富德优选**预览（非「推荐服务」Tab）

#### Scenario: 富德优选预览

- **WHEN** 服务首页加载完成
- **THEN** 在 9 宫格之后展示 Section「富德优选」
- **AND** `RetailCategoryService` 从字典解析「电商零售」二级类目 `value`（Integer）作为 `packageMainCategory`
- **AND** 最多展示 6 条套包卡片（无横向类目 Tab）
- **AND** Section 右侧「查看全部 ›」跳转 `/mall`
- **AND** 卡片点击或「购买」跳转 `/services/pkg`，参数 `id` 为列表返回的商品 id

#### Scenario: 富德优选无数据

- **WHEN** 零售套包接口返回空列表
- **THEN** 隐藏整个富德优选 Section

#### Scenario: 9 宫格点击

- **WHEN** 用户点击某德系产品线
- **THEN** 跳转 `/services/list`，`params: ["code": code]`（code 为产品线字典展示名，如「德好」）
- **AND** 列表页按健康管理类目展示（见下方列表页 Requirement），不因德系 code 无匹配而崩溃

---

### Requirement: 套餐列表页（`/services/list`）

系统 SHALL 以双栏 TableView 展示健康管理类目与套包列表，数据来自字典 + 套包分页 API。

#### Scenario: 左栏类目

- **WHEN** 进入套餐列表页
- **THEN** BLL 调用 `POST /v1/dictionary/getDictionaryByParentId2`，`parentIds: [2074711807339139072]`
- **AND** 左栏展示字典 children 的 `title`（`name` → `description` → `value`）
- **AND** 默认选中：路由 `code` 若等于某类目 `title` 或 `value` 则选中该项，否则选中排序后第一项

#### Scenario: 右栏套包

- **WHEN** 用户选中左栏某类目
- **THEN** 调用套包分页接口，`packageMainCategory` = 该类目字典 `value`
- **AND** 右栏顶部展示当前类目名称与描述（无德系 icon 方块）
- **AND** 下列表展示套包卡片：名称、简介、价格、推荐标签
- **AND** 空列表展示「套餐即将开放」空态

#### Scenario: 进入详情

- **WHEN** 用户点击套包卡片或「查看详情」
- **THEN** 跳转 `/services/pkg`，`params: ["id": packageId]`

#### Scenario: 禁止 mock

- **WHEN** 列表页渲染
- **THEN** **不得**使用 `SvcPkg` / 德系矩阵本地 mock 作为数据源

---

### Requirement: 富德优选商城（`/mall`）

#### Scenario: 商品列表

- **WHEN** 用户进入富德优选商城
- **THEN** `RetailCategoryService` 解析零售类目后调用套包分页接口，`packageMainCategory` 为字典 `value`（Integer），`pageSize=20`
- **AND** 以 2 列 CollectionView 展示商品卡片
- **AND** 点击卡片或「购买」跳转 `/services/pkg`

#### Scenario: 禁止 mock 商品

- **WHEN** 商城页渲染
- **THEN** **不得**使用 `ServiceCatalogService.loadMallProducts()` 原型数据

---

### Requirement: 详情路由统一

#### Scenario: 商城旧路由兼容

- **WHEN** 路由 `/mall/detail` 带 `id`
- **THEN** 打开与 `/services/pkg` 相同的 `ServicePackageDetailViewController`

---

## REMOVED Requirements

### Requirement: 服务首页 Section recommend（推荐服务 Tab）

**Reason**: funde-client Hub 已改为「富德优选」固定预览，类目 Tab 移至套餐列表页左栏。

**Migration**: iOS 删除 Hub 上 `HealthPackageCategoryCell` 与 `selectCategory` 逻辑；字典 parentId `2074711807339139072` 改由列表页消费。

### Requirement: 服务首页顶栏搜索 / 机构切换

**Reason**: funde `ServicesView.vue` 与 page-spec 明确 Hub 无搜索、固定「健康服务」文案；搜索入口不在服务首页顶栏。

### Requirement: 服务首页三好卡 ActivateBanner

**Reason**: 对齐当前 funde Hub，去掉 `ActivateBannerCell` / `showActivateBanner`。
