# Order List Delta — 默认 Tab

## MODIFIED Requirements

### Requirement: 订单列表 Tab（对齐 funde OrderListView）

#### Scenario: 默认选中全部

- **WHEN** 用户通过 `/orders` 进入订单列表且未指定 `tab` 参数
- **THEN** 默认选中「全部」Tab（`initialTab: "all"`）
- **AND** 跨 Tab 跳转 `navigateToMyOrdersAll` 时显式使用 `initialTab: "all"`
