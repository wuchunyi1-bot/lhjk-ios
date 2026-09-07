## MODIFIED Requirements

### Requirement: 确认订单立即支付

确认订单页点击「立即支付」或待支付「去支付」SHALL 调用支付统一接口并调起所选渠道；支付终态进入结果页。

#### Scenario: 微信支付

- **WHEN** 用户选择微信支付并点击支付
- **THEN** 调用 `POST /v1/orderPay/orderPay`（JSON body：`orderId`、`payType=1`、`amountVersion`、`expectedPayableAmount`）
- **AND** 用返回预支付参数调起微信 Open SDK
- **AND** 用户取消支付时停留当前页并提示「已取消支付」
- **AND** 支付成功或失败（取消除外）进入 `/orders/pay-result`，不直接进入订单列表

#### Scenario: 支付宝

- **WHEN** 用户选择支付宝并点击支付
- **THEN** 调用 `POST /v1/orderPay/orderPay`（JSON body：`orderId`、`payType=2`、`amountVersion`、`expectedPayableAmount`）
- **AND** 用返回 `data.aliBody`（支付宝 `orderStr`）调起支付宝 SDK
- **AND** 用户取消支付时停留当前页并提示「已取消支付」
- **AND** 支付成功或失败（取消除外）进入 `/orders/pay-result`，不直接进入订单列表

#### Scenario: 结算金额已变化

- **WHEN** 点击支付后服务端发现优惠券/权益卡过期、改运费等导致应付或结算版本与提交值不一致
- **THEN** **不**调起第三方支付
- **AND** **不**进入支付结果页
- **AND** 用接口 `msg` 提醒用户金额已变化
- **AND** 重新请求 `getOrderSettlement` 刷新确认页金额后停留当前页

### Requirement: 确认订单入口来源

确认订单页 SHALL 根据路由参数 `entry` 区分导航行为。支付结果页继承同一 `entry`。

#### Scenario: 购物车来源

- **WHEN** `entry=cart`
- **THEN** 使用 `OrderConfirmEntry.cartCheckout`
- **AND** 自定义导航栏返回按钮
- **AND** 返回、加载失败回退调用 `OrderNavigationCoordinator.navigateToMyOrdersAll(from:)`
- **AND** 支付成功或失败进入支付结果页，调用 `presentPayResultOnMyOrders` 重建「我的」栈

#### Scenario: 默认来源（含选择套餐）

- **WHEN** 未传 `entry` 或值非 `cart`（含服务 Tab 选择套餐 → 确认订单）
- **THEN** 使用 `OrderConfirmEntry.default` 或 `orderListPay`
- **AND** 确认页返回为 `navigationController?.popViewController`
- **AND** 支付成功或失败同样调用 `presentPayResultOnMyOrders`：服务 Tab 清到根，我的栈为 `[我的, 订单列表全部, 支付结果]`
- **AND** 结果页完成/返回落到「我的订单 · 全部」，不得留在选择套餐栈上

#### Scenario: 订单列表待支付导航

- **WHEN** `entry=order_pay` 用户点击返回
- **THEN** `pop` 回订单列表（**不得**跨 Tab）
- **WHEN** 支付成功或失败
- **THEN** 进入支付结果页，同样重建为 `[我的, 订单列表全部, 支付结果]`
