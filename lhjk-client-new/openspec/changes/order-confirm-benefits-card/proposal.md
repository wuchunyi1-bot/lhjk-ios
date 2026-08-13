# Change: order-confirm-benefits-card

## Why

确认订单页权益卡行仍为「暂无可用」占位；卡包已接 `/v1/benefitsTake/*`，需对齐 funde `OrderConfirmView` / `orders-confirm.page.yaml`：多选可用卡、不抵运费、费用明细联动。

## What Changes

- 确认页权益卡行：有可用 / 已使用 N 张共优惠 / 暂无可用
- 底部多选弹层（对齐优惠券弹层交互，支持多选 +「不使用」）
- 可用列表：`GET /v1/benefitsTake/getCustomerPage?status=3`，排除转赠锁定
- 抵扣试算：客户端计算；**不抵运费**；上限 = 套餐金额 − 优惠券抵扣
- 应付 = 结算应付 − 权益卡抵扣（结算暂无权益字段时本地扣减）
- **Apifox 缺口**：尚无 `bindBenefitsTake` 类绑单接口、结算无 `benefitsTakeList` / 权益抵扣金额；本期不发明写接口；支付成功核销列为后续

## Impact

- `OrderConfirmViewModel` / `OrderConfirmViewController` / 权益卡选择 Sheet
- OpenSpec：`order-confirm` delta；`docs/api-inventory` 注明复用 35a
- 不改 Apifox
