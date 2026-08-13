# Change: benefits-activate-redeem-order-apis

## Why

权益卡「激活兑换 / 兑换套餐 / 确认订单选卡」后端已补齐专用接口；此前 Hub 用状态计数近似、兑换页空态、确认订单用 `getCustomerPage` + 本地试算。需对齐 Apifox 与原型截图，改为服务端权威数据。

## What Changes

- Hub「当前有 N 张」→ `GET /v1/benefitsTake/getActivationOverview`
- 兑换套餐页机构头 + 分类 Tab → `GET /v1/benefitsTake/getRedeemPageInfo`
- 可兑套餐列表 → `GET /v1/benefitsTake/getRedeemPackagePage`（`categoryServiceId` / 分页）
- 确认订单权益卡列表 → `GET /v1/benefitsTake/getOrderBenefitsList?orderId=`
- 确认选卡绑单 → `POST /v1/benefitsTake/updateOrderBenefits`（query：`orderId`、`benefitsTakeIds[]`），成功后刷新结算
- 更新 `openspec/specs/activate`、订单确认权益卡逻辑与 `docs/api-inventory.md`
- **不做**：改 Apifox；不 mock 套餐/卡数量

## Impact

- BLL：`VoucherModels` / `VoucherService`
- PL：`ActivateViewController`、`BenefitRedeemViewController`、`OrderConfirmViewModel` / `OrderBenefitPickerSheet`
- Spec：activate / order-confirm；api-inventory
