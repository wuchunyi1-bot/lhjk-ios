# Service Cart Delta — 确认订单返回导航

## MODIFIED Requirements

### Requirement: 购物车单卡结算（禁止统一结算）

#### Scenario: 单卡去结算进入确认页

- **WHEN** 用户点击某卡片「去结算」且 `insertOrEdit` 成功
- **THEN** 进入 `/orders/confirm`，参数至少包含 `orderId` 与 **`entry=cart`**
- **AND** 可带 `serialNumber` 供 `getOrderSettlement` 使用（**不得**传入 `insertOrEdit` Body）

#### Scenario: 购物车来源确认页返回

- **WHEN** 用户在 `entry=cart` 的确认订单页点击导航栏返回
- **THEN** **不得** pop 回购物车
- **AND** 切换到「我的」Tab，导航栈为 `MyViewController` → `OrderListViewController(initialTab: "all")`
- **AND** 订单列表页 **不得** 展示底部 Tab 栏（二级页面）
- **AND** 服务 Tab 导航栈移除确认页，保留购物车页

#### Scenario: 购物车来源确认页支付成功

- **WHEN** 用户在 `entry=cart` 的确认订单页完成支付成功流程（`navigateToOrders`）
- **THEN** 与返回相同，落到「我的 → 我的订单 → 全部」
- **AND** 服务 Tab 不再保留确认页

#### Scenario: 购物车来源禁用侧滑返回

- **WHEN** 确认页 `entry=cart`
- **THEN** 禁用 `interactivePopGestureRecognizer`，避免仅 pop 到购物车
