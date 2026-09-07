# Change: order-pay-result-page

## Why

确认订单调起微信 / 支付宝后，当前成功只 Toast 并直接进订单列表，失败只 Toast 留在确认页。产品要求成功或失败都进入独立支付结果页（Figma `3506:9196`），完成与返回统一落到订单列表，避免回到确认页重复提交。

## What Changes

- 新增 PL 支付结果页 `/orders/pay-result`，成功 / 失败两态
- 确认订单支付成功、SDK / 渠道支付失败后 push 结果页（不再 Toast 后直达列表）
- 结果页进入时即跨 Tab 落到「我的 → 订单列表 → 支付结果」，选择套餐 / 购物车 / 其它来源均重建底层栈
- 结果页「完成」与导航栏返回落到「我的订单 · 全部」；「查看订单」落到「我的 → 订单列表 → 订单详情」
- 用户取消支付、结算金额版本拒绝（`payRejected`）仍留在确认页

## Impact

- PL：`OrderConfirmViewModel` / `OrderConfirmViewController`、新增 `PayResult/`
- 路由：`MyRoutes` `/orders/pay-result`
- 导航：`OrderNavigationCoordinator`
- Spec：`payment`、确认订单支付后导航
