## MODIFIED Requirements

### Requirement: 富德优选商城（`/mall`）

系统 SHALL 提供富德优选商城页，布局对齐 funde-client `HealthMallView.vue`。

#### Scenario: 顶部分类 Tab

- **WHEN** 用户进入 `/mall`
- **THEN** 展示横向滚动分类 Tab 栏
- **AND** 第一项固定为「全部」
- **AND** 其余 Tab 来自 `GET /v1/hospitalPackage/getCategoryServiceListByType?type=2`
- **AND** Tab 文案取 `serviceName`；默认选中「全部」
- **AND** 激活 Tab 为胶囊样式（`fdPrimary` 背景 + 白字）

#### Scenario: 全部商品列表

- **WHEN** 选中「全部」Tab
- **THEN** 调用 `GET /v1/hospitalPackage/getEnabledRetailHospitalPackagePage`
- **AND** `categoryServiceId` 传空字符串 `""`
- **AND** 以 2 列 `UICollectionView` 展示套包卡片

#### Scenario: 分类商品列表

- **WHEN** 用户点击某业务分类 Tab
- **THEN** 调用同一零售分页接口
- **AND** `categoryServiceId` 传该 Tab 的 `id`
- **AND** 刷新双栏商品网格

#### Scenario: 商品卡片与跳转

- **WHEN** 列表渲染商品
- **THEN** 每张卡片含：1:1 封面（有 `imageUrl` 时 Kingfisher 加载）、推荐角标（`recommend==1`）、名称、简介、参考价、「购买」按钮
- **AND** 点击卡片或「购买」跳转 `/services/pkg`，`id` 为列表返回的套餐 id

#### Scenario: 分类无商品

- **WHEN** 当前 Tab 下接口返回空列表
- **THEN** 展示空态「该分类暂无商品，敬请期待」

#### Scenario: 底部保障说明

- **WHEN** 页面展示
- **THEN** 列表下方固定展示「正品保障 · 德好健康监制 · 7天无忧退换」

#### Scenario: 禁止 mock

- **WHEN** 商城页渲染
- **THEN** **不得**使用 `ServiceCatalogService.loadMallProducts()` 或本地 mock 作为数据源
