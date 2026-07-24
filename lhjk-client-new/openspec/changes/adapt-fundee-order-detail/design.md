# Design: adapt-fundee-order-detail

## Context

权威来源（优先级）：

1. Apifox `GET /v1/order/getAppOrderDetail` → `AppOrderDetailBO`
2. funde-client `adapt-fundee-order-list` 设计（列表卡片、状态 1–9、待发货 `status=2`）
3. iOS 已有确认订单页组件风格（`OrderConfirm*` 卡片、Design Token）

列表跳转规则（保持不变）：

| 列表 `status` | 卡片点击 |
|---------------|----------|
| 1 待支付 | `/orders/confirm?orderId=` |
| 其它 | `/orders/detail?id=` |

## Goals / Non-Goals

**Goals**

- 非待支付订单进入详情页，按 `orderId` 拉取 `getAppOrderDetail` 渲染
- **待发货（status=2）** 完整展示：状态头、机构、套餐封面、商品明细、履约地址、费用、订单元信息、底部「取消订单」
- 其它状态复用同一详情页骨架，按状态切换提示文案与底部按钮可见性
- 金额统一两位小数（`ServicePackageMoney`）

**Non-Goals（本期）**

- 取消订单 / 确认收货 / 续费 / 结算 / 售后真实 API
- 物流轨迹页、退款进度页
- 下拉刷新、从详情返回后自动刷新列表（可后续补）

## 页面结构

```
OrderDetailViewController
├── 状态区（大标题 + 副标题 hint）
├── 履约地址卡（自提 / 快递只读）
├── 套餐卡（封面 + 名称 + 卖点 + 机构）
├── 商品明细卡（shoppingCartPackageDetailList）
├── 费用卡（商品金额 / 运费 / 优惠券 / 实付）
├── 订单信息卡（订单号 / 下单时间 / 支付方式 / 备注）
└── 底部操作栏（按状态：待发货=取消订单；待收货=确认收货；…）
```

### 待发货（status=2）— 对齐 funde 列表后续详情预期

| 区块 | 数据源 | 说明 |
|------|--------|------|
| 状态头 | `status` | 主文案「待发货」；副文案「商家备货中，请耐心等待」 |
| 履约 | `typeOrder`, `receiver`, `phone`, `address`, `hospitalName` | `typeOrder=1` 标题「收货信息」；`0` 为「自提信息」 |
| 套餐 | `packageImageUrl`, `orderName`, `packageDescription`, `hospitalName` | 与列表卡片一致 |
| 明细 | `shoppingCartPackageDetailList[]` | `commodityName`/`packageName` + `quantity` + `billingType` 单位 + `price` |
| 费用 | `payable`, `price`, `expressAmount`, `couponAmount` | 商品金额优先 `payable - express + coupon` 回退 `payable`；实付取 `price` 再退 `payable` |
| 订单信息 | `id`, `createTime`, `paymentType`, `description` | 支付方式字典 1微信/2支付宝/3现金/4银行卡 |
| 底部 | — | 「取消订单」；点击 Toast「功能即将开放」 |

### 其它状态 hint（同页复用）

| status | 副标题示例 |
|--------|------------|
| 3 待收货 | 商品已发货，请注意查收 |
| 4 使用中 | 服务进行中 |
| 5 已完成 | 订单已完成 |
| 6/9 退款 | 退款处理中 |
| 7 已逾期 | 订单已逾期 |
| 8 已取消 | 订单已取消 |

待收货额外展示：`logisticsVendor` + `logisticsNumber`（有值时）。

## 架构

```
PL/My/Order/Detail/
├── OrderDetailViewController.swift
├── ViewModels/OrderDetailViewModel.swift
└── Components/OrderDetailComponents.swift

BLL/Service/
├── OrderDetailModels.swift   # AppOrderDetailBO
└── OrderService.swift        # getAppOrderDetail
```

ViewModel：`ObservableObject` + `@Published`，默认注入 `AppContainer.shared.orderService`。

## Decisions

- 详情 DTO 独立 `AppOrderDetailBO`，不与列表 `MOrder` 混用（字段更全）
- 商品明细行复用与结算一致的 `billingType` 单位映射（天/月/次/件）
- 路由参数兼容 `id` 与 `orderId` 字符串

## Risks

| Risk | Mitigation |
|------|------------|
| 列表与详情金额字段不一致 | 详情以 `getAppOrderDetail` 为准 |
| 部分订单无明细列表 | 空态隐藏明细卡，仅展示套餐卡 |
