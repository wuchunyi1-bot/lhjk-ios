# Change: adapt-fundee-order-list

## Why

iOS「我的订单」当前为 **10 个 Tab**（含已取消、退款审核中独立 Tab），卡片布局与 funde-client `OrderListView` / PRD-05 不一致。需对齐 **8 Tab 顺序与命名**，并按 `OrderListCard` 重做列表卡片。

## What Changes

- Tab 收敛为 funde 顺序 8 个：全部 → 待支付 → 待发货 → 待收货 → 使用中 → 已逾期 → 退款/售后 → 已完成
- 去掉独立「已取消」「退款审核中」Tab（已取消/退款审核仅在「全部」等可见；退款审核并入「退款/售后」筛选）
- 状态文案「待付款」→「待支付」
- `OrderCardCell` 重布局：机构+状态 → 封面+套餐名/卖点/金额 → 底部操作区（本期按状态展示按钮骨架，真实取消/支付/售后 API 后续）
- 空态文案按 Tab 区分
- 更新 `openspec/specs/order-list` 的 delta

## Impact

- Affected: `OrderListViewController`、`OrderTabViewController`、`OrderCardCell`、`OrderModels`（展示文案）
- Specs: `order-list`
- 参考：funde-client `OrderListView.vue`、`OrderListCard.vue`、`orders-list.page.yaml`、`05_用户_我的订单_v1.0.md`
