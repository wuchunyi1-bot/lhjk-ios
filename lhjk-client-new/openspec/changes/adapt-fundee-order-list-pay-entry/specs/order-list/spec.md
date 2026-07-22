## MODIFIED Requirements

### Requirement: 订单列表卡片布局（对齐 OrderListCard）

#### Scenario: 待支付卡片点击

- **WHEN** 用户在待支付列表点击订单卡片非按钮区域
- **THEN** 进入 `/orders/confirm`，params `orderId` = 订单 `id`
- **AND** **不得**进入 `/orders/detail`
- **WHEN** 订单 `id` 缺失
- **THEN** Toast「订单信息缺失」，不跳转

#### Scenario: 操作按钮（去支付）

- **WHEN** 待支付订单点击「去支付」
- **THEN** 进入 `/orders/confirm`，params `orderId` = 订单 `id`
- **WHEN** 订单 `id` 缺失
- **THEN** Toast「订单信息缺失」，不跳转

#### Scenario: 其它状态卡片点击（不变）

- **WHEN** 用户点击非待支付订单卡片
- **THEN** 进入 `/orders/detail`，params `id` = 订单 `id`

#### Scenario: 其它操作按钮（不变）

- **WHEN** 用户点击非「去支付」按钮且对应 API 未接入
- **THEN** Toast「功能即将开放」，**不得**崩溃

## 参考

- `adapt-fundee-order-settlement`（确认页主数据源 = `getOrderSettlement`）
- funde `OrderListView.vue` / `OrderListCard.vue`
