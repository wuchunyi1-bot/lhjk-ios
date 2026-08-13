# Design: 确认订单接入权益卡

## Context

- 优惠券已走 `getCouponTakeList` + `bindCouponTake` + 结算 `amount` 回写。
- 权益卡卡包已接 `VoucherService` / `getCustomerPage`。
- Apifox「员工权益卡管理」文件夹下 **无** 订单绑定权益卡接口；`getOrderSettlement` / `insertOrEdit` **无** 权益卡抵扣 / `benefitsTakeIds` 字段（`benefitsId` 为企业配置 ID，非 C 端实例）。
- 产品规则见 funde `docs/page-specs/orders-confirm.page.yaml` 与原型 `OrderConfirmView.vue`。

## Goals

1. 确认页可选多张待使用权益卡，费用明细与底栏应付即时更新。
2. 规则与原型一致：先券后卡、不抵运费、不找零、默认不选。
3. Spec / 清单明确 API 缺口，便于后端补绑单与结算字段后无缝切换。

## Non-Goals

- 支付成功后核销写回（status→4）——无核销 API 前不做。
- 「有更省方案」提示、套餐业务类适用范围（高血压/高血糖）过滤——无后台适用范围字段前，展示全部可点用的待使用卡。
- 修改 Apifox。

## 抵扣公式

```
cardLimit     = max(0, packageAmount - couponDiscount)
rawCardAmount = Σ selectedCards.price（面值）
benefitDiscount = min(cardLimit, rawCardAmount)
payable       = max(0, settlementPayable - benefitDiscount)
```

- `packageAmount` / `couponDiscount` / `settlementPayable` 来自 `getOrderSettlement`。
- 运费不参与 `cardLimit`。
- 券变更后：若已选卡导致超额，仍按 `min` 截断展示；失效卡从选择中剔除。

## 数据流

```
进入确认页 / 绑券刷新结算
  → 并行或随后 getCustomerPage(status=3)
  → 过滤：status=待使用 且 pendingTransferId 空
  → 行文案：暂无可用 | 有N张可用 | 已使用N张，共优惠 ¥x

点击权益卡行 → OrderBenefitPickerSheet（多选）
  → 完成 / 不使用 → ViewModel 更新 selectedBenefitIds
  → 重算 benefitDiscount / payable（本地，不调绑单）
```

## API 现状与后续切换

| 能力 | 现状 | 后续 |
|------|------|------|
| 列表 | `GET /v1/benefitsTake/getCustomerPage?status=3` | 若提供「按订单/套餐可用」接口则替换 |
| 写回订单 | **无** | 对齐 `bindCouponTake` 的 `bindBenefitsTake(orderId, benefitsTakeIds[])` |
| 结算回写 | **无** | `appOrderDetailBO` 增权益抵扣金额与已选列表；应付含权益后去掉本地扣减 |

切换条件：Apifox 出现绑单接口且结算返回权益金额后，将「本地选中 + 本地扣减」改为「绑单成功 → refreshSettlement」，UI 不变。

## 文件

| 层 | 文件 |
|----|------|
| PL | `OrderConfirmViewModel`、`OrderConfirmViewController`、`OrderBenefitPickerSheet`（并入已入工程的 `OrderCouponPickerSheet.swift`） |
| BLL | 复用 `VoucherService.getCustomerPage` / `BenefitCard` |
| Spec | 本 change；`openspec/specs/vouchers` 补确认页引用 |
