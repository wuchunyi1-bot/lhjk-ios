# 订单续费（使用中 / 已逾期）

## Why

「使用中」「已逾期」订单需支持续费：从列表/详情进入套餐详情续费态，展示续费金额并携带原订单 `parentId` 下单。

## What

- 列表卡片、订单详情「续费订单」（**仅 `packageType=1` 租赁套餐**）→ `/services/pkg`，传 `orderId`（作 `parentId`）及 `packageId` / `hospitalId`
- 套餐详情续费态：标题「续费规格」；明细价取 `reprice`；底栏「续费金额」+「取消」/「立即续费」
- `saveShoppingCartOrPurchase` 续费时 Body 传 `parentId` = 原订单 id

## Scope

- PL：订单列表/详情导航、套餐详情续费 UI 与提交
- BLL：`reprice` 解码、续费映射、`parentId` 请求
- 非目标：结算订单、续费资格校验 API
