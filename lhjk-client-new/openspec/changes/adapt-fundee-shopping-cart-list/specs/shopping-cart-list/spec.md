## ADDED Requirements

### Requirement: 查询购物车列表

系统 SHALL 通过 `GET /v1/shoppingCart/getShoppingCartList`（[Apifox Markdown](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330722e0.md)，operationId `getShoppingCartList`）加载购物车列表。

#### Scenario: 请求

- **WHEN** 用户进入 `/services/cart`（含 `viewWillAppear` 刷新）
- **THEN** 调用列表接口；Query 可含 `pageNum`、`pageSize`（默认合理分页，如 pageSize≥50 以覆盖首屏）
- **AND** **不得**传入 `hospitalId`（需展示当前用户在全部医疗机构下的套餐）
- **AND** **不得**传入 mock / 本地假 `userId`
- **AND** 其余筛选（type、mobileOrUsername 等）无业务需要时可不传

#### Scenario: 响应展示

- **WHEN** 接口成功且 `数据集合` / `list` 非空
- **THEN** 按 `ShoppingCartListBO` 渲染列表行：名称 `packageName`、副标题优先 `introduction` 否则 `hospitalName`、数量 `totalQuantity`、金额取自 `totalPrice`
- **AND** 结算跳转 `targetId` 使用 `packageId` 字符串
- **WHEN** 列表为空或 `records` 为空
- **THEN** 展示空态「购物车空空如也」，**不得**用 mock / 本地 seed 填充

#### Scenario: 失败

- **WHEN** 接口失败
- **THEN** 列表按空处理或保留上次成功数据（实现选一）；Toast 展示 `msg`；**不得**回退到本地假数据

### Requirement: 禁止本地购物车缓存与 mock

系统 SHALL **不得**再将加购结果写入 UserDefaults，也 **不得**注入原型购物车 seed。

#### Scenario: 加购后仅服务端可见

- **WHEN** 用户在套餐详情成功调用 `saveShoppingCartOrPurchase` 且 `flag=2`
- **THEN** **不得**再调用本地 `addPackage` / 写入本地购物车
- **AND** 跳转 `/services/cart` 后通过列表接口拉取；仅服务端已存在的条目可展示

#### Scenario: 清理

- **WHEN** 本变更落地
- **THEN** 删除 `CartService` 原型 seed 与 `service.cart.items.v1` 持久化读写逻辑（或整类移除）

### Requirement: 勾选与结算（仍以服务端行为目为准）

#### Scenario: 勾选

- **WHEN** 用户切换勾选
- **THEN** 仅更新本页内存选中态与底部「已选 N 项 / 合计」
- **AND** 合计为已选行 `totalPrice` 之和（取整）

#### Scenario: 结算

- **WHEN** 已选 ≥ 1 且结算
- **THEN** 以已选第一项 `packageId` 跳转 `/orders/confirm`

### Requirement: 删除购物车

系统 SHALL 通过 `DELETE /v1/shoppingCart/deleteShoppingCart`（[Apifox Markdown](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330724e0.md)，operationId `deleteShoppingCart`）删除购物车条目。

#### Scenario: 请求参数

- **WHEN** 用户确认删除某购物车行
- **THEN** 请求 Query **必填** `serialNumber`（int32），取自列表接口该行 `ShoppingCartListBO.serialNumber`
- **AND** **不得**用 mock / 本地假 serialNumber；若该行缺少有效 `serialNumber`，不发起请求并 Toast「无法删除该商品」

#### Scenario: 垃圾桶删除

- **WHEN** 用户点击卡片垃圾桶并确认弹窗
- **THEN** 调用删除接口；成功后从当前列表移除该行并更新底部合计
- **AND** 最后一项删除后展示空态
- **AND** 失败时 Toast 展示服务端 `msg`，列表保持不变

#### Scenario: 滑动删除

- **WHEN** 用户左滑并点「删除」
- **THEN** 同样调用删除接口（可不再二次弹窗，与现有滑动交互一致）
- **AND** 成功 / 失败处理与垃圾桶一致

#### Scenario: 防重

- **WHEN** 删除请求进行中
- **THEN** 同一行或全局不得重复触发删除
