## Context

卡包优惠券已接 `getCouponTakeList`。Apifox 对 `CouponTaskListBO` 各展示字段写明了「何时返回 / 标题怎么写」，需与 UI 一一对齐，避免沿用原型 Mock 的规则文案。

文档：[Apifox](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330752e0.md)

## Goals / Non-Goals

**Goals:**

- Spec 固化 Query `status` 与响应字段映射表
- 票券力度、门槛、有效期、规则展开严格按返回字段
- 空字段不展示对应行；无任何规则内容时隐藏展开入口

**Non-Goals:**

- 解码全部非展示字段（`createId` 等）仅在需要时补充
- 权益卡 API、订单选券交互改版

## Decisions

### 1. 响应字段 → 卡包 UI

| 字段 | 用途 |
|------|------|
| `id` | 领用主键，列表 cell id / 绑定用 |
| `name` | 券名 |
| `type` | 1 满减 / 2 减价 / 3 折扣 → 左侧力度样式 |
| `amount` | 卡券金额（满减等） |
| `couponAmount` | **仅减价券**优先展示金额，缺省回退 `amount` |
| `discountRatio` | 折扣券力度；≤1 按小数换算为「折」（0.88→8.8） |
| `conditionPrice` | 门槛；≤0 或空 →「无门槛」 |
| `endTime` | 「有效期至 …」 |
| `getTime` | 领取时间（排序/内部用） |
| `status` | 1 已领取→待使用；2 已使用→已领用；3 已过期 |
| `rule` | **只影响**业务/套餐标题：1「适用*」/ 0「不适用*」；**不影响**机构与排除商品标题 |
| `categoryServiceName` | 非空才展示；服务端约定仅无套餐且无机构时返回 |
| `packageNames` | 顿号分隔；非空才展示 |
| `hospitalNames` | 顿号分隔；非空才展示；标题固定「适用机构」 |
| `commodityNames` | 顿号分隔；非空才展示；标题固定「不参与折扣的商品」 |
| `description` | 使用规则说明；非空才展示 |

### 2. 规则区交互

- 有任一规则行（业务/套餐/机构/排除商品/`description`）才显示「使用规则」折叠按钮
- 不再展示原型「仅以下业务适用」总标题行；直接按字段标题 + 内容渲染

### 3. 分页

继续兼容 `data.list` + `totalCount` 与顶层 `total`；中文键作兜底。

## Risks / Trade-offs

- [服务端 `discountRatio` 量纲不一致] → ≤1 乘 10；>1 原样当折数  
- [减价券同时有 `amount`/`couponAmount`] → 展示优先 `couponAmount`
