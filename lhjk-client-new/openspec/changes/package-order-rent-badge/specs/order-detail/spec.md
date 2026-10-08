# Order Detail / 订单详情 — 出租标记

## ADDED Requirements

### Requirement: 套餐内容行出租标记

订单详情套餐内容行 SHALL 解码并使用 `shoppingCartPackageDetailList[].saleFlag`（1 租 / 2 售）。

#### Scenario: 出租商品

- **WHEN** 明细行 `saleFlag == 1`
- **THEN** 商品名右侧展示切图 `package_detail_ rent`（40×16pt）

#### Scenario: 出售或不标识

- **WHEN** `saleFlag` 为 `2`、空或其它值
- **THEN** 该行不展示出租标记，也不展示出售标记

#### Scenario: 字段类型

- **WHEN** `saleFlag` 以数字或数字字符串下发
- **THEN** 解码成功，且不导致该行商品明细解析失败
