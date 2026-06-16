# Order List / 全部订单

## Purpose

定义「我的 → 服务履约 → 全部订单」页面的 UI 布局与交互行为。参考 funde-client `OrderListView.vue`，通过 UIKit + SnapKit 适配到 iOS。

> **Reference**: funde-client `/prototype/src/views/orders/OrderListView.vue`、`/prototype/src/mock/orders.json`
> **Deferred**: 订单详情页

---

## Layout Architecture

```
┌──────────────────────────────────────────┐
│  UINavigationBar: "我的订单" + back        │
├──────────────────────────────────────────┤
│  UISegmentedControl (sticky)              │
│  [全部] [待使用] [使用中] [已完成] [待评价]  │
├──────────────────────────────────────────┤
│  UITableView                              │
│  ┌──────────────────────────────────────┐ │
│  │ OrderCardCell                        │ │
│  │ 德好·慢病逆转            [使用中]      │ │
│  │ 三好共管                              │ │
│  │ 2026-03-15 — 2026-09-15   ¥9,800     │ │
│  │ ⏱ 剩余 45 天                         │ │
│  ├──────────────────────────────────────┤ │
│  │ OrderCardCell ...                    │ │
│  └──────────────────────────────────────┘ │
│  (or Empty State if no orders)            │
└──────────────────────────────────────────┘
```

---

## Data Models

```swift
enum OrderStatus: String {
    case pendingUse = "pending_use"       // 待使用
    case inProgress = "in_progress"       // 使用中
    case completed = "completed"          // 已完成
    case pendingReview = "pending_review" // 待评价
}

struct ServiceOrder {
    let id: String
    let serviceName: String   // "德好·慢病逆转"
    let serviceTag: String    // "三好共管"
    let status: OrderStatus
    let statusLabel: String   // "使用中"
    let startDate: String     // "2026-03-15"
    let endDate: String       // "2026-09-15"
    let price: Int            // 9800
    let daysLeft: Int         // 45
}
```

---

## Requirements

### Requirement: Tab Filtering
SHALL 支持 5 个 Tab 筛选订单。

#### Scenario: Tab 列表
- **WHEN** 页面渲染
- **THEN** 展示 UISegmentedControl：全部 / 待使用 / 使用中 / 已完成 / 待评价
- **AND** 默认选中「全部」

#### Scenario: Tab 切换
- **WHEN** 用户点击 Tab
- **THEN** 过滤订单列表并 reload TableView

---

### Requirement: Order Card
SHALL 展示订单卡片，参考 funde `order-card`。

#### Scenario: 卡片布局
- **WHEN** Card 渲染
- **THEN** fdSurface 背景（圆角 24pt，阴影），padding 16pt，卡片间距 12pt

#### Scenario: Header Row
- **WHEN** Card 渲染
- **THEN** 左侧 serviceName（16pt bold fdText），右侧 statusLabel tag（colored bg + text pill）

#### Scenario: Service Tag
- **WHEN** Card 渲染
- **THEN** 服务标签 serviceTag（12pt fdSubtext）

#### Scenario: Meta Row
- **WHEN** Card 渲染
- **THEN** 左侧日期区间 "startDate — endDate"（13pt fdSubtext），右侧 price ¥\`N\`（16pt bold fdPrimary）

#### Scenario: Days Left (conditional)
- **WHEN** `daysLeft > 0`
- **THEN** 展示 clock icon（SF Symbol `clock`，14pt fdPrimary）+ "剩余 N 天"（13pt fdPrimary）

#### Scenario: Status Color
| status | bg | text |
|--------|-----|------|
| `pending_use` | `#FFF3EE`（fdPrimarySoft） | `#FF7A50`（fdPrimary） |
| `in_progress` | `#EEF6FF` | `#3D6FB8` |
| `completed` | `#F0FAF4` | `#52B96A` |
| `pending_review` | `#FFF8E8` | `#B47300` |

---

### Requirement: Empty State
SHALL 在筛选结果为空时展示空状态。

#### Scenario: 空状态
- **WHEN** 当前 Tab 下无订单
- **THEN** 居中展示「暂无订单」（icon + 13pt fdMuted 文字），min-height 300pt

---

### Requirement: Card Tap
SHALL 支持点击卡片跳转订单详情。

#### Scenario: 点击跳转
- **WHEN** 用户点击订单卡片
- **THEN** push `/orders/{orderId}`（订单详情页，Deferred 占位）

---

## Component Inventory

| Component | Type | 说明 |
|-----------|------|------|
| `OrderListViewController` | UIViewController | 5 Tab + TableView |
| `OrderCardCell` | UITableViewCell | 订单卡片（复用） |

## Acceptance Checklist

- [ ] 导航栏标题 "我的订单"
- [ ] UISegmentedControl 5 个 Tab，默认「全部」
- [ ] Tab 切换过滤正确
- [ ] 卡片：serviceName + statusLabel tag + serviceTag + date + price
- [ ] daysLeft > 0 时显示剩余天数行
- [ ] 状态颜色映射正确（4 种状态 4 种配色）
- [ ] 空状态展示正确
- [ ] 点击卡片 push /orders/:id
- [ ] 颜色通过 Token 引用
