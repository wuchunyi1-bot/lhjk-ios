## MODIFIED Requirements

### Requirement: 套餐列表页（`/services/list`）

系统 SHALL 以双栏布局展示**医院服务**业务分类与套包列表，对齐 funde-client `ServiceListView.vue`。

#### Scenario: 左栏医院服务分类

- **WHEN** 页面加载
- **THEN** 调用 `GET /v1/hospitalPackage/getCategoryServiceListByType`
- **AND** `type=1`（hospitalService）
- **AND** **必传** `hospitalId`
- **AND** 左栏展示 `serviceName` 列表

#### Scenario: 右栏医院套包列表

- **WHEN** 用户选中左栏某类目
- **THEN** 调用 `GET /v1/hospitalPackage/getEnabledHospitalPackagePage`
- **AND** 传 `categoryServiceId`（类目 `id`）与 `hospitalId`
- **AND** **不得**使用 `getEnabledRetailHospitalPackagePage`（零售接口仅用于 `/mall`）

#### Scenario: hospitalId 来源

- **WHEN** 构建上述请求
- **THEN** 优先使用 `loginUserInfo.hospitalId`
- **AND** 否则使用 `ServiceCatalogService.selectedApiHospitalId()` 或临时 `hospitalId` 常量

#### Scenario: 页面结构

- **WHEN** 用户从德系 9 宫格进入
- **THEN** 展示机构卡片 + 左栏 78pt 类目 + 右栏套包卡片
- **AND** 导航栏含搜索、购物车

#### Scenario: 默认类目

- **WHEN** 路由带 `code`（如「德好」）
- **THEN** 匹配类目 `serviceName` 选中；否则选第一项

#### Scenario: 空态与详情

- **WHEN** 某类目 `packageList` 为空
- **THEN** 左栏仍展示该类目 `serviceName`
- **AND** 右栏展示该类目标题，下方不展示套餐卡片、不展示全页「暂无套餐」插画（对齐小程序）
- **WHEN** 接口 `data` 为空或无有效类目
- **THEN** 右栏展示「暂无套餐」
- **WHEN** 点击卡片或「查看详情 ›」→ `/services/pkg?id=`

#### Scenario: 本地无选中机构时补全

- **WHEN** `InstitutionSelectionStore` 无已选机构，且用户档案有合法 `hospitalId`
- **THEN** 调用 `GET /v1/hospital/getById`
- **AND** 将返回的医院写入 `InstitutionSelectionStore`
- **AND** 顶栏展示该医院名称 / 类型 / 地址，**不得**展示占位「富德联好健康」
- **AND** 套餐列表 `hospitalId` 与顶栏为同一机构

#### Scenario: 禁止 mock

- **WHEN** 列表页渲染
- **THEN** 不得使用字典类目或 `SvcPkg` mock
