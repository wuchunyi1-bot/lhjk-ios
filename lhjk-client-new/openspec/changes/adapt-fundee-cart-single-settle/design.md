# Design: adapt-fundee-cart-single-settle

## Context

权威：

1. PRD-604《购物车》（`06_用户_套餐购买支付链路_v1.0.md`）
2. `docs/page-specs/services-cart.page.yaml`
3. `prototype/src/views/services/CartView.vue`

iOS 已接：`getShoppingCartList` / `deleteShoppingCart` / 加购 `saveShoppingCartOrPurchase`。继续用服务端列表，UI 对齐单卡结算。

## Goals / Non-Goals

**Goals**

- 仅卡片内「去结算」；一张卡一次结算
- 无勾选、无全选、无底栏合计
- 卡片结构对齐 Vue OrderListCard 风格购物车卡
- 空态文案与 CTA 对齐 funde
- 删除二次确认后调删除 API

**Non-Goals**

- 套餐下架/内容变更「重新确认」完整校验矩阵（后续）
- 注销演示 / 本地 demo seed
- 多选合并下单
- 结算后强制删行（Vue 本地删；iOS 本期：去结算写草稿进确认页；服务端行保留直至用户删或后续接「结算消费」）

## Decisions

1. **结算唯一入口**：卡片「去结算」→ `PackageOrderDraft.fromCartLine` → `Router.push("/orders/confirm", id: packageId)`
2. **底栏删除**：整页无底部 bar；table 贴底
3. **封面**：`imgUrl` → Kingfisher；无图占位「套餐」
4. **机构**：`hospitalName`，空则「服务机构」
5. **空态 CTA**：`/services`（服务 Hub），不用 `/mall`
6. **ViewModel**：去掉 `selectedIds` / `toggle` / `selectedCount` / `selectedTotalText`
7. **点击卡片 / 去结算**：均进确认订单；`status=3` 已失效样式 + 不可结算

## Risks

| Risk | Mitigation |
|------|------------|
| 用户期望底栏批量结算 | Spec/PRD 明确禁止；UI 去掉合计避免误导 |
| 去结算后仍留在购物车 | 与「立即下单不移除来源卡」类似；可后续在确认支付成功后再删 |
