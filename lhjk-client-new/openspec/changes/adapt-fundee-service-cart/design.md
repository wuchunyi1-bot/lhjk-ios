## Context

权威 UI：`funde/funde-client/prototype/src/views/services/CartView.vue`  
数据样例：`services.json` → `cart.items`（`targetId` 关联套餐/商品）  
文档：`docs/v0.1/pages/services/cart.md`（部分字段与现行 Vue 不完全一致，**以 Vue 为准**）

iOS 现状：`/services/cart` 为占位；套餐详情「加入购物车」仅跳转占位页。

## Goals / Non-Goals

**Goals:**

- 购物车列表 UI 对齐 Vue（卡片头 + 元信息网格 + 去结算 + 底栏）
- 勾选状态驱动「已选 N 项」与合计金额
- 套餐详情可加入购物车（本地持久化）
- 空态「去逛逛」→ `/mall`；结算 → `/orders/confirm`

**Non-Goals:**

- 购物车服务端同步 / 删除滑动手势（Vue 原型亦未做）
- 数量加减编辑（展示 quantity，暂不可改）
- 优惠券选择（仅展示是否已匹配文案）

## Decisions

1. **模块归属**：服务 / 商城（`PL/Service/Cart/`、`BLL/Service/`）。
2. **数据**：`CartService` 单例；UserDefaults 持久化；首次空车可注入与 Vue 同构的原型 3 条，便于联调展示（标记 `isPrototypeSeed`，加入真实商品后可保留并存）。
3. **摘要解析**：`targetId` 优先查 `ServiceCatalogService.packageDetail` / `product`；无匹配则用写入时快照字段。
4. **勾选**：卡片左侧圆点勾选（对齐 Vue）；底栏结算取**当前已选第一项** `targetId` 跳转确认单（对齐 Vue `selectedItems[0]`）；单卡「去结算」用该卡 `targetId`。
5. **加入购物车**：同一 `targetId` 合并数量 +1；跳转 `/services/cart`。

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| 无后端购物车 API | 本地持久化；接入 API 后替换 `CartService` 存储层 |
| 结算只带一项 | 对齐现行 Vue；多选合并下单另开变更 |
| 原型种子与真实数据混用 | 种子 id 前缀 `cart-`；真实加入用 UUID |
