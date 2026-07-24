# Order Confirm Delta — 来源与导航

## ADDED Requirements

### Requirement: 确认订单入口来源

确认订单页 SHALL 根据路由参数 `entry` 区分导航行为。

#### Scenario: 购物车来源

- **WHEN** `entry=cart`
- **THEN** 使用 `OrderConfirmEntry.cartCheckout`
- **AND** 自定义导航栏返回按钮
- **AND** 返回、加载失败回退、支付成功均调用 `OrderNavigationCoordinator.navigateToMyOrdersAll(from:)`

#### Scenario: 默认来源

- **WHEN** 未传 `entry` 或值非 `cart`
- **THEN** 使用 `OrderConfirmEntry.default`
- **AND** 返回为 `navigationController?.popViewController`
- **AND** 支付成功为当前 Nav 栈内 `replaceWithOrders`（`OrderListViewController(initialTab: "all")`）
