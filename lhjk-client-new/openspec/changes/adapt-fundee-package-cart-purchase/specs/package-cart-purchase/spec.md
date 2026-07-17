## ADDED Requirements

### Requirement: 套餐详情加购 / 立即下单接口

套餐详情页「加入购物车」「立即下单」SHALL 调用 `POST /v1/shoppingCart/saveShoppingCartOrPurchase`（[Apifox Markdown](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330718e0.md)，operationId `saveShoppingCart`）。

请求体 schema：`SaveShoppingCartVO`；成功响应：`Result`（`code` / `data` / `msg` / `success`）。

#### Scenario: SaveShoppingCartVO 公共请求体

- **WHEN** 用户触发加购或立即下单，且当前套餐 `packageId` 为有效数字 id
- **THEN** Body **必填**：`hospitalId`（int64）、`packageId`（int64）、`categoryServiceId`（int64）
- **AND** Body 携带：`flag`（int32）、`packageHospitalDetailList`（选中的 `PackageHospitalDetailBO` 数组）
- **AND** `hospitalId` 解析优先级：服务模块已选机构 → 详情入参 → `HospitalPackageService.temporaryHospitalId`
- **AND** `categoryServiceId` 解析优先级：详情 `packageInfo.categoryServiceId` → 路由入参 `categoryServiceId`
- **AND** 缺少有效 `categoryServiceId` 时不发起请求，Toast「套餐类别缺失」
- **AND** 其余可选字段无值时**不传**：`doctorId`、`userId`、`archiveId`、`angetId`、`parentId`、`instruction`、`couponTakeId`、`orderChannel`、`authCode`、`receiver`、`phone`、`address`

#### Scenario: flag 分支

- **WHEN** 用户点击「加入购物车」
- **THEN** `flag = 2`（添加购物车）
- **AND** 成功后 Toast「已加入购物车」，进入 `/services/cart`
- **AND** **不得**再写入本地购物车；列表仅通过 `getShoppingCartList` 展示服务端数据
- **WHEN** 用户点击「立即下单」
- **THEN** `flag = 1`（立即购买）
- **AND** 成功后进入 `/orders/confirm`，params 含 `id`（packageId）；若 `data` 可解析出订单 id 则一并传入

#### Scenario: packageHospitalDetailList 组装

- **WHEN** 组装已选明细
- **THEN** 必选组（`checkType=2`）全部行；单选组（`checkType=1`）仅当前选中行；可选组（`checkType=3`）仅已勾选行
- **AND** 含子项行（详情 `children` 展平后的行）；子项 `parentId` 为父明细 id
- **AND** 每条至少携带服务端下发的明细 `id`，以及已知的 `name`、`quantity`、`price`、`billingType`、`checkType`、`defaultCheck`、`packageDetailId`、`commodityId`、`categoryId`、`categoryName`、`imageUrl`、`number` 等字段

#### Scenario: 选中明细为空或非法

- **WHEN** 无法解析 `hospitalId` / `packageId` / `categoryServiceId`，或已选明细无有效数字 `id`
- **THEN** 不发起请求，Toast 提示（如「套餐内容配置异常」/「机构信息缺失」/「套餐类别缺失」）

#### Scenario: 非 API 原型套餐

- **WHEN** 套餐 id 非数字（本地原型）
- **THEN** **不得**调用本接口；维持本地加购 / 跳转确认页降级逻辑

#### Scenario: 失败与防重

- **WHEN** 接口失败（`success`/`code` 非成功）
- **THEN** Toast 展示服务端 `msg` 或通用失败文案；不跳转
- **WHEN** 请求进行中
- **THEN** 底部「加入购物车」「立即下单」不可重复触发
