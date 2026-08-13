# 激活兑换 (Activate)

## Purpose

首页「激活兑换」与卡包绑定/兑换入口的统一链路，对齐 funde `/activate`、`/activate/bind`、`/activate/redeem`。

## Routes

| 路径 | 页面 | 入口 |
|------|------|------|
| `/activate` | 激活兑换 Hub | 首页快捷入口等 |
| `/activate/bind` | 绑定权益卡 | Hub「去绑定」整卡；卡包绑定入口 |
| `/activate/redeem` | 兑换套餐专区 | Hub「去兑换」整卡；卡包立即兑换 |

## Hub 导航（对齐 `ActivateView.vue`）

- 绑定卡 / 「去绑定」→ `Router.push("/activate/bind", from: Hub VC)`
- 兑换卡 / 「去兑换」→ `Router.push("/activate/redeem", from: Hub VC)`（无可用卡亦可进）
- 实现：整卡 `UITapGestureRecognizer`；内层 Stack `isUserInteractionEnabled = false`，避免吞点击
- 规格增量：`openspec/changes/fix-activate-hub-navigation/`

## Requirements

见进行中变更：

- `openspec/changes/adapt-fundee-activate-flow/specs/activate/spec.md`
- `openspec/changes/benefits-activate-redeem-order-apis/specs/activate/spec.md`
- `openspec/changes/fix-activate-hub-navigation/specs/activate/spec.md`

## APIs

| 场景 | Path |
|------|------|
| Hub 可用卡数量 | `GET /v1/benefitsTake/getActivationOverview` |
| 兑换页机构+分类 | `GET /v1/benefitsTake/getRedeemPageInfo` |
| 可兑套餐分页 | `GET /v1/benefitsTake/getRedeemPackagePage` |
| 绑定 | `POST .../preCheckByKey` → `POST .../bindByKey` |
| 角标回退 | `GET /v1/benefitsTake/getCustomerStatusCount` |
