## ADDED Requirements

### Requirement: 退款/售后列表去退货入口

退款/售后 Tab（及全部 Tab 中同状态卡片）在合资格时 SHALL 展示「去退货」，规则与 `order-return-goods` 一致。

#### Scenario: 售后处理中卡片

- **WHEN** 订单 `status=6` 且满足去退货资格（存在已发货/已签收/已收货/待自提发货任务商品，且退货未完成）
- **THEN** 卡片操作区展示「去退货」
- **AND** 点击打开去退货抽屉（非再次申请退款）

#### Scenario: 退款审核卡片

- **WHEN** 订单为退款审核（`status=9`，仅全部 Tab）
- **THEN** **不得**展示「去退货」
