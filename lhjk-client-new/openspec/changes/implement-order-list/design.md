## Context

funde-client `OrderListView.vue`：5 个 Tab（全部/待使用/使用中/已完成/待评价），订单卡片含服务名、状态标签、服务标签、日期、价格、剩余天数。空态展示图标+文字。

## Decisions

### 1. 单 TableView + 数据过滤

**选择**: 一个 `UITableView`，根据 `selectedTab` 过滤 `allOrders` 数组后 `reloadData`。

**理由**: 5 个 Tab 共享同一 Card Cell，不需要 5 个独立 TableView；数据量不大（<100 笔），`reloadData` 开销可忽略。

### 2. Tab 实现：UISegmentedControl（滚动式）

**选择**: 5 个 Tab 使用 `UISegmentedControl`，在 `viewDidLoad` 中添加。

**理由**: 与 funde-client 的 `van-tabs` 等价；原生组件无需自定义。

### 3. 订单卡片：OrderCardCell

**选择**: `UITableViewCell` 子类，register reuse identifier `OrderCardCell`。

**布局**:
- Header row: serviceName (16pt bold fdText) + statusLabel (colored tag, right)
- serviceTag (12pt fdSubtext)
- Meta row: date range (13pt fdSubtext) + price (16pt bold fdPrimary, right)
- Conditional: daysLeft > 0 → 橙色 clock icon + "剩余 N 天" (13pt fdPrimary)

### 4. 状态颜色映射

| status | label | bg | text |
|--------|-------|-----|------|
| `pending_use` | 待使用 | `#FFF3EE` | `#FF7A50` |
| `in_progress` | 使用中 | `#EEF6FF` | `#3D6FB8` |
| `completed` | 已完成 | `#F0FAF4` | `#52B96A` |
| `pending_review` | 待评价 | `#FFF8E8` | `#B47300` |

### 5. 空状态

所有 Tab 共用统一空状态：「暂无订单」图标 + 文字，min-height 300pt。

### 6. 点击跳转

点击卡片 push `/orders/:id`（订单详情）— 本次仅实现列表，详情为占位。
