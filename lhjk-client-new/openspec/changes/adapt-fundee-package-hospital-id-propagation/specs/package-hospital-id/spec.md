## ADDED Requirements

### Requirement: 套包列表项携带 hospitalId

`getEnabledRetailHospitalPackagePage` 与 `getEnabledHospitalPackagePage` 返回的列表项 SHALL 解码 `hospitalId` 字段，并映射至 `HealthPackageItem.hospitalId`。

#### Scenario: 零售列表解码

- **WHEN** 调用 `getEnabledRetailHospitalPackagePage` 且记录含 `hospitalId`
- **THEN** `HospitalPackagePageVO.hospitalId` 为纯数字字符串
- **AND** `HealthPackageItem.hospitalId` 与接口返回值一致

#### Scenario: 医院服务列表解码

- **WHEN** 调用 `getEnabledHospitalPackagePage`（推荐 / 搜索 / 服务列表）
- **THEN** 列表项 `hospitalId` 解码与映射规则与零售列表相同

### Requirement: 列表跳转详情传递 hospitalId

从套包列表进入详情时，SHALL 将列表项 `hospitalId` 作为路由参数传递。

#### Scenario: 点击列表卡片

- **WHEN** 用户在服务列表、富德优选、Hub 预览、搜索结果的套包卡片上点击
- **THEN** 跳转 `/services/pkg`（或 `/services/detail`）
- **AND** `params.id` 为列表 `id`
- **AND** 列表项存在有效 `hospitalId` 时 `params.hospitalId` 必须传入

#### Scenario: 详情接口请求

- **WHEN** 详情页以数字 `packageId` 加载
- **THEN** 调用 `getHospitalPackageDetail`，`hospitalId` 参数使用路由传入值（来自列表）
- **AND** 路由无有效 `hospitalId` 时可降级为已选机构 id 或临时常量

### Requirement: packageInfo.hospitalId 用于加购与下单

详情 `packageInfo` 返回的 `hospitalId` SHALL 映射至 `ServicePackageDetail`，并在加购 / 立即下单时优先使用。

#### Scenario: 详情映射

- **WHEN** `getHospitalPackageDetail` 成功且 `packageInfo.hospitalId` 存在
- **THEN** `ServicePackageDetail.hospitalId` 等于 `packageInfo.hospitalId`

#### Scenario: 加入购物车

- **WHEN** 用户点击「加入购物车」
- **THEN** `saveShoppingCartOrPurchase` 请求体 `hospitalId` 优先取 `packageInfo.hospitalId`
- **AND** 详情未返回时依次降级：路由 `hospitalId` → 已选机构 → 临时常量

#### Scenario: 立即下单

- **WHEN** 用户点击「立即下单」
- **THEN** `hospitalId` 解析优先级与加入购物车相同
