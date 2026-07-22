## Why

`/orders/confirm` 仍为占位页。funde-client 已有确认订单页（`OrderConfirmView.vue` + `orders-confirm.page.yaml` + PRD-605），用于支付前确认套餐快照、履约/地址、备注、优惠、费用与支付方式。iOS 需对齐该页面结构与主流程，打通详情「立即下单」/购物车「去结算」→ 确认订单。

## What Changes

- 新增确认订单页（替换 Placeholder）
- 引入套餐订单草稿 `PackageOrderDraft`（对齐 funde `package-order-draft:v4`）
- 详情立即下单 / 购物车结算写入草稿后进入确认页
- 本期：**UI + 草稿 + 地址/履约/备注/费用/支付方式选择**；优惠券/权益卡先空态；立即支付校验通过后 Toast 并跳转订单列表（真实创单/支付 SDK 后续迭代）

## Capabilities

### New Capabilities

- `order-confirm`: 确认订单页展示、草稿、提交前校验

### Modified Capabilities

- 套餐详情 / 购物车结算入口：写草稿再跳转

## Impact

- `BLL/Service/`（草稿 Store）
- `PL/My/Order/Confirm/`
- `MyRoutes`、套餐详情、购物车
- 参考：`funde-client/prototype/src/views/orders/OrderConfirmView.vue`、`docs/page-specs/orders-confirm.page.yaml`、`app端prd初稿/06_…PRD-605`
