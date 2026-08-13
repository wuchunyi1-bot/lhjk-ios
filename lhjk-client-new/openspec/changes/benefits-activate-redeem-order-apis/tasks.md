# Tasks: benefits-activate-redeem-order-apis

## 1. Spec & inventory

- [x] 1.1 proposal / design / activate + order-confirm delta
- [x] 1.2 更新 `openspec/specs/activate/spec.md` API 索引
- [x] 1.3 更新 `docs/api-inventory.md`（35g–35k）

## 2. BLL

- [x] 2.1 DTO：`BenefitsActivationOverviewVO`、`BenefitsRedeemPageInfoVO`、`BenefitsRedeemCategoryVO`、`HospitalPackagePageVO`（分页）、`BenefitsRedeemCardVO`
- [x] 2.2 `VoucherService` 五个方法；`refreshAvailableBenefitCount` 可优先 overview

## 3. PL

- [x] 3.1 Hub：`getActivationOverview`
- [x] 3.2 `BenefitRedeemViewController`：pageInfo + package page + Tab + 跳转详情
- [x] 3.3 `OrderConfirmViewModel` + `OrderBenefitPickerSheet`：order list + update + 刷新结算
