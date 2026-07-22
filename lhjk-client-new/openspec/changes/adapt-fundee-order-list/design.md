# Design: adapt-fundee-order-list

## Context

权威来源（优先级）：

1. funde-client `prototype/src/views/orders/OrderListView.vue`（Tab 定义）
2. `OrderListCard.vue` + `useOrderListCardPresenter.ts`（卡片）
3. `app端prd初稿/05_用户_我的订单_v1.0.md`
4. `docs/page-specs/orders-list.page.yaml`

iOS 已接 `GET /v1/order/getAppOrderList`，status 1–9。保持该 API，仅调整 Tab → 筛选映射与 UI。

## Goals / Non-Goals

**Goals**

- 8 Tab，顺序与 Vue 一致；无 Tab 数量角标
- 卡片结构对齐 OrderListCard
- 退款/售后 Tab 用 `statusList=6,9`（退款/售后 + 退款审核中）
- 空态文案按 Tab

**Non-Goals（本期）**

- 取消订单 / 去支付 / 确认收货 / 续费 / 结算 / 售后对话框真实 API
- 订单详情页
- 下拉刷新、分页 load-more（可保留 pageSize=10 首屏）
- 售后拒绝 HintBar

## Decisions

### Tab → API

| Tab | query key | API |
|-----|-----------|-----|
| 全部 | `all` | 不传 status |
| 待支付 | `pending_payment` | `status=1` |
| 待发货 | `paid_pending_delivery` | `status=2` |
| 待收货 | `pending_receipt` | `status=3` |
| 使用中 | `in_progress` | `status=4` |
| 已逾期 | `overdue` | `status=7` |
| 退款/售后 | `after_sale` | `statusList=6,9` |
| 已完成 | `completed` | `status=5` |

`cancelled=8` 仅出现在「全部」。

### 卡片布局

```
[building] 机构名                    [状态徽章]
[72×72 图]  套餐名称（≤2 行）
            一句话卖点（1 行）     ¥金额
            [次要按钮] [主按钮]   （按状态，右对齐）
```

- 机构：`hospitalName`，空则「服务机构」
- 封面：`packageImageUrl`（Kingfisher），无图占位「套餐」
- 名称：`orderName`
- 卖点：`packageDescription`
- 金额：优先 `payable`，否则 `price`
- 操作按钮：按状态展示；点击本期 Toast「功能即将开放」（详情点击卡片仍进 `/orders/detail`）

### 空态

| Tab | 文案 |
|-----|------|
| 退款/售后 | 暂无退款/售后记录 |
| 待收货 | 暂无待收货订单 |
| 使用中 | 暂无使用中订单 |
| 已完成 | 暂无已完成订单 |
| 已逾期 | 暂无已逾期订单 |
| 其他 | 暂无订单 |

## Risks

| Risk | Mitigation |
|------|------------|
| 后端 `statusList` 不支持 6,9 | 验证；失败则仅 `status=6` 并记 follow-up |
| packageType 不足以区分零售/综合服务操作 | 本期操作按钮用简化规则（待支付双按钮、待发货取消、待收货确认收货等） |
