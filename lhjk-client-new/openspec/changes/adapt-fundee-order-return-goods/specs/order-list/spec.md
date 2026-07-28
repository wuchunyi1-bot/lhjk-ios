## MODIFIED Requirements

### Requirement: 退款/售后列表去退货入口

退款/售后 Tab（及全部 Tab 中同状态卡片）在合资格时 SHALL 展示「去退货」，规则与 `order-return-goods` 一致。

列表数据来自 `GET /v1/order/getAppOrderList`，新增字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `canReturnGoods` | Bool | 是否可去退货 |
| `refundId` | Int64 | 退款单 ID（提交退货用） |

#### Scenario: 合资格展示

- **WHEN** 订单 `status=6` 且 `canReturnGoods == true` 且 `refundId > 0`
- **THEN** 卡片操作区展示「去退货」
- **AND** 点击打开去退货抽屉（非再次申请退款）
- **AND** 提交时使用该卡片的 `refundId`，不得用订单 `id` 顶替

#### Scenario: 非合资格不展示

- **WHEN** `status != 6`，或 `canReturnGoods != true`，或无有效 `refundId`
- **THEN** **不得**展示「去退货」
