## ADDED Requirements

### Requirement: 套餐详情页布局

`/services/detail` 与 `/services/pkg` SHALL 展示对齐图示 / `HealthPackageDetailView` 的套餐配置详情（非商城商品详情）。

#### Scenario: Hero 与信息区

- **WHEN** 用户携带 `id` 进入套餐详情
- **THEN** 导航标题为「套餐详情」
- **AND** 顶部展示圆角轮播（优先 `bannerList` / `packageCarousel` 图片；无图时渐变占位）
- **AND** 信息区展示：可选角标 + 套餐名称、简介、参考价、适用人群标签

#### Scenario: Tab 区

- **WHEN** 用户浏览主体内容
- **THEN** 展示「套餐内容」「套餐详情」双 Tab，默认「套餐内容」
- **AND** 「套餐内容」：按 `packageHospitalDetailList` 分组展示；`checkType=2` 强制组红色虚线「必选」；`1` 单选；`3` 可选；每行名称 / 数量单位 / 价格
- **AND** 「套餐详情」：展示 `description` / `introduction` 及详情图（若有）

#### Scenario: 底部栏

- **WHEN** 用户查看底部操作栏
- **THEN** 左侧「应付」+ 实时总价（套餐参考价 + 可选组勾选增值）
- **AND** 右侧「加入购物车」「立即下单」

### Requirement: 列表返回套餐 id

`GET /v1/hospitalPackage/getEnabledHospitalPackagePage` 列表项 SHALL 解析商品主键 `id`，并写入 `HealthPackageItem.id`，供详情页作为 `packageId`。

#### Scenario: 推荐 / 搜索列表

- **WHEN** 列表接口返回记录含 `id`（String 或 Number）
- **THEN** `HospitalPackagePageVO.id` 解码为字符串
- **AND** `HealthPackageItem.id` 等于该值（不再使用 `hospital-pkg-{index}` 占位，除非 `id` 缺失）

### Requirement: 套餐详情接口

服务模块套餐详情 SHALL 调用 `GET /v1/hospitalPackage/getPackageDetail`（[Apifox](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/485486161e0)）。

#### Scenario: 请求参数

- **WHEN** 用户从推荐服务 / 搜索进入详情，且 `packageId` 为有效数字 id
- **THEN** 请求 Query：`hospitalId` + `packageId`
- **AND** `hospitalId` 暂固定为 `1372444113118564352`（机构列表 API 接入后改为服务端下发）
- **AND** `packageId` 为列表项 `id`

#### Scenario: 响应映射

- **WHEN** 接口成功返回 `HospitalPackageDetailBO`
- **THEN** `packageInfo` → 名称 / 简介 / 参考价 / 角标 / 适用人群
- **AND** `bannerList`（及 `packageCarousel`）→ 轮播
- **AND** `packageHospitalDetailList[]` → 套餐内容分组；`checkType`：1 单选、2 强制、3 可选
- **AND** 计费单位 `billingType`：1 天、2 月、3 次、4 件

#### Scenario: 非 API id 降级

- **WHEN** 路由 `id` 非数字（如德系原型 `dehao-m`）或详情接口失败
- **THEN** 可降级本地原型数据或展示空态 / 错误提示，**不得**把 mock id 传给详情 API

### Requirement: 入口路由

#### Scenario: 推荐服务 / 搜索

- **WHEN** 用户点击「了解详情」
- **THEN** `Router.push("/services/detail", params: ["id": pkg.id])`，其中 `pkg.id` 为列表接口商品 id
