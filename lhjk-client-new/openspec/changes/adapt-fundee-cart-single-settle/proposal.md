# Change: adapt-fundee-cart-single-settle

## Why

iOS 购物车仍保留多选勾选 + 底部「结算」合计栏，与 funde-client PRD-604 / `CartView.vue` / `services-cart.page.yaml` 冲突。权威口径为 **仅单卡去结算**，无全选、无合并结算、无底部合计栏。卡片布局也需对齐 Vue（机构 + 封面 + 名称/卖点/金额 + 删除/去结算）。

## What Changes

- 去掉勾选、底部合计栏、「结算」底栏
- 卡片重布局：机构行 → 封面+名称/简介/金额 → 「删除」+「去结算」
- 空态：「购物车还是空的」+「去看看服务」→ `/services`
- 删除确认文案对齐「确认删除该套餐？」
- 去结算：写 `PackageOrderDraft` →（可选）删服务端该行 → `/orders/confirm`
- Spec 明确禁止统一结算；保留服务端列表/删除 API

## Impact

- Affected: `ServiceCartViewController`、`ServiceCartViewModel`、`CartModels` / `CartLineDisplay`
- Specs: `service-cart`（delta）
- 参考：funde `CartView.vue`、`services-cart.page.yaml`、PRD-604
