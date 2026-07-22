## ADDED Requirements

### Requirement: 购物车单卡结算（禁止统一结算）

`/services/cart` SHALL 仅支持单张卡片结算，对齐 funde-client PRD-604 / `CartView.vue`。

#### Scenario: 禁止多选与底栏

- **WHEN** 用户进入购物车页
- **THEN** **不得**展示勾选框、全选、底部合计栏或底栏「结算」按钮
- **AND** **不得**支持多选合并结算

#### Scenario: 单卡去结算

- **WHEN** 用户点击某卡片「去结算」
- **THEN** 以该行写入 `PackageOrderDraft`（至少 packageId、名称、金额、hospitalId 等）
- **AND** 进入 `/orders/confirm`，params `id` = 该行 `packageId`
- **AND** 一次仅处理一张卡片

#### Scenario: 点击卡片进确认订单

- **WHEN** 用户点击卡片非「删除」按钮区域（含卡片主体）
- **THEN** 与「去结算」相同：写草稿并进入 `/orders/confirm`
- **AND** **不得**再跳转套餐详情 `/services/pkg`
- **AND** 点击「删除」**不得**触发进确认订单

### Requirement: 购物车行 status

列表行 `ShoppingCartListBO.status` SHALL 映射为展示态并影响卡片样式。

| status | 含义 |
|--------|------|
| 1 | 已生成 |
| 2 | 未生成 |
| 3 | 已失效 |

#### Scenario: 已失效样式

- **WHEN** 行 `status = 3`（已失效）
- **THEN** 卡片使用失效样式（整体降透明度、文案偏灰，并展示「已失效」标识）
- **AND** **不得**展示「去结算」主按钮（或按钮禁用且不可进入确认订单）
- **AND** 点击卡片 **不得**进入确认订单；可 Toast「该套餐已失效」
- **AND** 仍可「删除」

#### Scenario: 已生成 / 未生成

- **WHEN** `status` 为 1 或 2（或缺失按未失效处理）
- **THEN** 使用正常卡片样式，可点击卡片 /「去结算」进入确认订单

### Requirement: 购物车卡片布局

购物车列表卡片 SHALL 对齐 funde `CartView` 卡片结构。

#### Scenario: 卡片结构

- **WHEN** 渲染一行购物车
- **THEN** 自上而下为：
  1. 顶栏：机构图标 + 机构名（`hospitalName`，空则「服务机构」）
  2. 主体：左侧 72×72 封面（`imgUrl`，无图占位「套餐」）；右侧套餐名称（≤2 行）、简介（1 行，空隐藏）、金额右对齐（行总价）
  3. 底栏右对齐：「删除」（次要）+「去结算」（主按钮）
- **AND** **不得**展示套餐内容明细、购买数量步进、优惠/运费行、服务对象/履约多列表格

#### Scenario: 删除

- **WHEN** 用户点击「删除」
- **THEN** 弹窗确认（文案含套餐名，对齐「确认删除该套餐？」意图）
- **AND** 确认后调用 `DELETE /v1/shoppingCart/deleteShoppingCart?serialNumber=`
- **AND** 成功后从列表移除该行；Toast「已删除」可选

### Requirement: 空态

#### Scenario: 无数据

- **WHEN** 列表为空且非加载中
- **THEN** 展示「购物车还是空的」
- **AND** 主按钮「去看看服务」跳转 `/services`
- **AND** **不得**使用「购物车空空如也」+「去逛逛」→ `/mall` 旧文案

## 参考

- funde-client `CartView.vue`
- `docs/page-specs/services-cart.page.yaml`
- PRD-604
- iOS `ShoppingCartService` 列表/删除 API（`adapt-fundee-shopping-cart-list`）
