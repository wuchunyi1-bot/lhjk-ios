# Design: benefits-activate-redeem-order-apis

## Context

五条新接口均属 `App端/商城/员工权益卡管理`，与现有 `VoucherService` 同域。原型三屏：激活兑换 Hub、兑换套餐列表、确认订单权益卡行。

## Decisions

### 1. BLL 收敛到 VoucherService

新增 DTO 与方法放在 `VoucherModels` / `VoucherService`，PL 不直连 path。

| Method | Path | Notes |
|--------|------|-------|
| `getActivationOverview` | GET `.../getActivationOverview` | `availableBenefitsCount`；可同步 `cachedAvailableBenefitCount` |
| `getRedeemPageInfo` | GET `.../getRedeemPageInfo` | 机构 + `categories` |
| `getRedeemPackagePage` | GET `.../getRedeemPackagePage` | query 可选 `categoryServiceId`、`pageNum`、`pageSize`；分页中英文字段兼容 |
| `getOrderBenefitsList` | GET `.../getOrderBenefitsList` | 必填 `orderId` → `[BenefitsRedeemCardVO]` |
| `updateOrderBenefits` | POST `.../updateOrderBenefits` | **query**：`orderId` + `benefitsTakeIds`（空数组=不使用）；`postFormURLEncodedAsync` / query encoding |

### 2. Hub

`viewWillAppear` 调 `getActivationOverview`（失败可回退 `refreshAvailableBenefitCount`），文案「当前有 N 张权益卡可用」。

### 3. 兑换套餐页

1. `getRedeemPageInfo` 渲染机构头（logo / 名称 /「品牌机构」/ 地址）与分类 Tab（首项「全部」+ `categories`）
2. 选中分类后 `getRedeemPackagePage`；「全部」不传或空 `categoryServiceId`
3. 列表项：图、标题（优先 `name`/`packageName`，缺省用 `introduction`）、简介、`¥x 起`、`去兑换` → `/services/pkg`（`id` + `hospitalId`）
4. `HospitalPackagePageVO` Apifox 无 `name`：解码可选 name 字段，禁止 mock
5. 无套餐空态；无卡仍可看列表（与原型一致），空态仅在列表空时

### 4. 确认订单权益卡

- 列表：`getOrderBenefitsList`，以 `selected` / `available` / `deductAmount` 为准
- 弹层多选：仅 `available==true` 可点；「不使用」→ `benefitsTakeIds=[]`
- 确认：`updateOrderBenefits` → `getOrderSettlement` → 再拉列表
- 行摘要：已选 N 张 + Σ`deductAmount`；应付以刷新后结算为准；若结算未含抵扣则本地 `settlementPayable - ΣdeductAmount` 兜底（不抵运费语义由服务端 `deductAmount` 保证）

## Risks

- `updateOrderBenefits` 数组 query 编码（brackets vs noBrackets）需联调
- 套餐 VO 缺 name 时标题可能偏简介文案，待后端补字段后自动生效
