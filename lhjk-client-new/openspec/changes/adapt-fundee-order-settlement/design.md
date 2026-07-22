# Design: adapt-fundee-order-settlement

## Context

- 立即购买：`POST /v1/shoppingCart/saveShoppingCartOrPurchase`（flag=1）成功后 `data` **直接是订单 id**
- 结算：`GET /v1/order/getOrderSettlement?orderId=` → 确认页唯一主数据
- 自提：`GET /v1/hospital/getById?id=`（hospitalId 来自结算 `appOrderDetailBO`）

## Goals / Non-Goals

**Goals**

- 解析购买接口返回的订单 id，路由只带 `orderId`（可选 `serialNumber`）
- 确认页进入后必调 `getOrderSettlement`，UI 全部来自该响应
- 默认自提；`orderExpress==1` 才可选快递

**Non-Goals**

- 创单支付 SDK 完整链路
- 用上一页草稿兜底展示结算字段

## Decisions

1. **路由**：`/orders/confirm` 主参数改为 `orderId`；购物车带同行 `orderId` + 可选 `serialNumber`
2. **BLL**：`saveShoppingCartOrPurchase` 返回 `Int64?`（柔性解码 number/string）
3. **确认页**：无有效 `orderId` 或结算失败 → Toast 并 pop；不再读 `PackageOrderDraftStore` 作为主源

## Risks

| Risk | Mitigation |
|------|------------|
| 购物车行无 orderId | Toast「订单信息缺失」，不进确认页 |
| data 类型偶发 object | 柔性解码失败则 Toast，不进确认页 |
