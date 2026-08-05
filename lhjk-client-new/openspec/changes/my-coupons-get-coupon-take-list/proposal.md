## Why

`GET /v1/couponTake/getCouponTakeList` 的 `CouponTaskListBO` 返回字段已按 Apifox 明确展示语义（`rule` / `description` / `categoryServiceName` / `packageNames` / `hospitalNames` / `commodityNames`，以及 `type`/`amount`/`couponAmount`/`discountRatio`）。需把字段→UI 映射写进 OpenSpec，并让卡包列表严格按文档渲染。

文档：[查询优惠券领用列表](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330752e0.md)

## What Changes

- Delta spec 补充 **CouponTaskListBO 字段映射与规则展开** 要求
- iOS：按 `type` 选用力度字段；规则区仅渲染非空返回字段；标题文案对齐文档
- 无规则可展内容时不展示「使用规则」入口

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `vouchers`: 明确领用列表返回字段 → 票券卡展示逻辑

## Impact

- `openspec/changes/my-coupons-get-coupon-take-list/`
- `CouponModels` / `VoucherModels` / `CouponCardCell`
