# Service Cart Delta — 去结算 insertOrEdit

## MODIFIED Requirements

### Requirement: 购物车单卡结算（禁止统一结算）

#### Scenario: 单卡去结算

- **WHEN** 用户点击某卡片「去结算」
- **THEN** 调用 `POST /v1/order/insertOrEdit`，Body 至少包含：
  - `id`：该行 `orderId`（Int64，禁止 mock）
  - `status`：`1`（待支付）
- **AND** **不得**传 `serialNumber`
- **AND** 接口成功后进入 `/orders/confirm?orderId=`（可带 `serialNumber`）
- **AND** 请求进行中禁止重复点击

#### Scenario: 点击卡片无操作

- **WHEN** 用户点击卡片主体（非「删除」「去结算」按钮）
- **THEN** **不得**跳转确认订单或套餐详情
- **AND** 仅取消列表选中高亮

#### Scenario: 点击卡片进确认订单（已废弃）

- **REMOVED**：点击卡片主体不再进入确认订单
