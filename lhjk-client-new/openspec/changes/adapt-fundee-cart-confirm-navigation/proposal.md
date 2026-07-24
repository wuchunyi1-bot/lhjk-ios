# Change: adapt-fundee-cart-confirm-navigation

## Why

服务 Tab 购物车「去结算」进入确认订单后，用户点击返回或支付成功时不应回到购物车确认页栈内 pop，而应落到「我的 → 我的订单 → 全部」，与 funde 结算后查看待支付订单的预期一致。订单列表进入时也应默认选中「全部」Tab。

## What Changes

- 购物车 push `/orders/confirm` 时携带 `entry=cart`
- 确认页识别 `cartCheckout` 来源：自定义返回、禁用侧滑 pop，返回与支付成功均跨 Tab 跳转「我的 → 我的订单 → 全部」
- 封装 `OrderNavigationCoordinator.navigateToMyOrdersAll(from:)`
- `/orders` 路由未传 `tab` 时默认 `all`（全部）
- 其它入口（订单列表去支付、套餐立即下单）保持原栈内 `pop` / `replaceWithOrders`

## Impact

- `PL/My/Order/OrderNavigationCoordinator.swift`（新增）
- `PL/My/Order/Confirm/OrderConfirmViewController.swift`
- `PL/Service/Cart/ServiceCartViewController.swift`
- `BLL/My/MyRoutes.swift`
- `Other/RootTabBarController.swift`（Tab 索引常量）
