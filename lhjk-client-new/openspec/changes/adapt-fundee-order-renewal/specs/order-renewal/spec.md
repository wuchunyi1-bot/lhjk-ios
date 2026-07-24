## ADDED Requirements

### Requirement: 续费入口导航

「使用中」「已逾期」订单在满足 `packageType` 条件时，SHALL 在列表卡片与订单详情展示「续费订单」，点击后进入套餐详情续费态。

#### Scenario: packageType 展示规则

| `packageType` | 含义 | 是否展示「续费订单」 |
|---------------|------|---------------------|
| `1` | 租赁套餐 | **是** |
| `2` | 售卖套餐 | 否 |
| `3` | 虚拟套餐 | 否 |
| `4` | 体验套餐 | 否 |
| 缺失 / 未知 | — | 否 |

- **WHEN** 订单 `status` 为使用中（4）或已逾期（7）
- **AND** `packageType == 1`
- **THEN** 列表卡片与详情底栏展示「续费订单」
- **WHEN** `packageType` 为 2 / 3 / 4 或缺失
- **THEN** **不得**展示「续费订单」（「结算订单」规则不变）

#### Scenario: 从订单列表续费

- **WHEN** 用户在「使用中」或「已逾期」Tab 点击卡片「续费订单」
- **THEN** 跳转 `/services/pkg`
- **AND** params 含 `id`（packageId）、`orderId`（当前订单 id）
- **AND** 若有 `hospitalId` / `categoryServiceId` 一并传入

#### Scenario: 从订单详情续费

- **WHEN** 用户在订单详情底栏点击「续费订单」
- **THEN** 行为与列表一致

#### Scenario: 缺少 packageId

- **WHEN** 列表项无 `packageId`
- **THEN** 先请求 `GET /v1/order/getAppOrderDetail`
- **AND** 解析到 `packageId` 后跳转；仍缺失则 Toast「无法获取套餐信息」

---

### Requirement: 套餐详情续费态展示

续费态（路由含有效 `orderId`）SHALL 调整套餐详情页文案与金额来源。

#### Scenario: 页面标题与底栏

- **WHEN** 进入续费态
- **THEN** 导航标题为「续费规格」
- **AND** 底栏金额标签为「续费金额」（非「应付」）
- **AND** 左侧按钮文案「取消」，点击返回上一页
- **AND** 右侧按钮文案「立即续费」

#### Scenario: 明细续费价

- **WHEN** 拉取 `getHospitalPackageDetail` 且为续费态
- **THEN** `packageHospitalDetailList` 各行展示与合计使用 `reprice`（续费金额）
- **AND** `reprice` 缺失时回退 `price`

---

### Requirement: 续费下单提交

续费态「立即续费」SHALL 调用 `POST /v1/shoppingCart/saveShoppingCartOrPurchase`，并携带父订单 id。

#### Scenario: parentId

- **WHEN** 用户点击「立即续费」且已选明细有效
- **THEN** `flag = 1`
- **AND** Body 传 `parentId` = 路由带入的 `orderId`
- **AND** 其余必填字段与普通立即下单一致
- **AND** 成功后进入 `/orders/confirm`，params 含返回的 `orderId`

#### Scenario: 续费态不加购

- **WHEN** 续费态点击「取消」
- **THEN** 不调用加购接口，仅返回上一页
