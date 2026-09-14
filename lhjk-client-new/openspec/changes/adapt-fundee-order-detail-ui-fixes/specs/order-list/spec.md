# Order List Delta — 列表卡片操作隐藏

## MODIFIED Requirements

### Requirement: 订单列表卡片操作按钮

列表卡片操作区 SHALL 使用 `OrderListCardAction.listActions(for:)`，**过滤**以下仅详情内展示的操作：

- `cancel`（取消订单）
- `afterSale`（退款/售后）

合资格时列表 **SHALL** 展示「去退货」（与详情底栏同一资格：`status=6` + `canReturnGoods` + `refundId > 0`）。

#### Scenario: 待支付列表卡片

- **WHEN** 订单 `status=1`
- **THEN** 列表仅展示「去支付」
- **AND** **不得**展示「取消订单」

#### Scenario: 待发货列表卡片

- **WHEN** 订单 `status=2`
- **THEN** 列表**不展示**任何操作按钮（取消仅在详情内）

#### Scenario: 退款/售后列表卡片

- **WHEN** 订单 `status=6` 且 `canReturnGoods == true` 且 `refundId > 0`
- **THEN** 列表展示「去退货」
- **AND** 点击打开去退货抽屉（与详情固定底栏同一流程）
