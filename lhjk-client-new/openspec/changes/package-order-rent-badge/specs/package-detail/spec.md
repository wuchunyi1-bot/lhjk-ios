# Package Detail / 套餐详情 — 出租标记

## ADDED Requirements

### Requirement: 权益行出租标记

套餐详情权益行 SHALL 按明细 `saleFlag` 决定是否在商品名后展示出租标记。

#### Scenario: 出租商品

- **WHEN** `packageHospitalDetailList` 或其 `children` 中某行 `saleFlag == 1`
- **THEN** 该行商品名右侧展示切图 `package_detail_ rent`（40×16pt）

#### Scenario: 出售或不标识

- **WHEN** `saleFlag` 为 `2`、空或其它值
- **THEN** 该行不展示出租标记，也不展示出售标记
