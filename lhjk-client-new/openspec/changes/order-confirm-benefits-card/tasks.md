# Tasks: order-confirm-benefits-card

## 1. Spec

- [x] 1.1 proposal / design / order-confirm delta
- [x] 1.2 更新 `openspec/specs/vouchers/spec.md` 确认页引用
- [x] 1.3 `docs/api-inventory.md` 注明确认页复用 35a

## 2. ViewModel

- [x] 2.1 注入 `VoucherService`；加载后拉取待使用卡并更新可用数
- [x] 2.2 `selectedBenefitIds` + `benefitDiscount` + `payableAmount` 本地公式
- [x] 2.3 `fetchBenefitOptions` / `applyBenefitSelection`；券刷新后 prune 失效选中

## 3. UI

- [x] 3.1 `OrderBenefitPickerSheet` 多选弹层（并入 `OrderCouponPickerSheet.swift`）
- [x] 3.2 `OrderConfirmViewController` 绑定权益卡行与弹层

## 4. Verify

- [ ] 4.1 无可用 / 有可用未选 / 多选抵扣上限 / 不抵运费 / 与券叠加（需真机/联调）
