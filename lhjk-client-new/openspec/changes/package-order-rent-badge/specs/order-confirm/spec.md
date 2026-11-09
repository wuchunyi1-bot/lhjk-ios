# Order Confirm / 确认订单 — 出租标记

## ADDED Requirements

### Requirement: 套餐内容行出租标记

确认订单套餐内容行 SHALL 使用 `GET /v1/order/getOrderSettlement` 的 `details[].saleFlag`（1 租 / 2 售）。

#### Scenario: 出租商品

- **WHEN** 结算明细 `saleFlag == 1`
- **THEN** 商品名右侧展示切图 `package_detail_ rent`（40×16pt）

#### Scenario: 出售或不标识

- **WHEN** `saleFlag` 为 `2`、空或其它值
- **THEN** 该行不展示出租标记，也不展示出售标记
