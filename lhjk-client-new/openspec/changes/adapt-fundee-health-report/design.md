## Context

funde-client 的 `HealthReportView.vue` 是健康报告页面，位于 `me` 模块下（路由 `/me/health-report`）。iOS 侧已有基础骨架但使用 `UIScrollView + UIStackView` 方案，所有卡片一次性创建，报告数据多时会导致内存问题。

## Reference Source Analysis

### HealthReportView.vue 布局结构

```
┌──────────────────────────────────────────┐
│  系统导航栏: "健康报告" + back              │
├──────────────────────────────────────────┤
│  [周报] [阶段小结]  ← UISegmentedControl  │
├──────────────────────────────────────────┤
│  Weekly Report Card 1                    │
│  Weekly Report Card 2 ...                │
│  ── 切换到阶段小结 ──                      │
│  Stage Report Card 1 (含 metrics grid)    │
│  Stage Report Card 2 ...                 │
└──────────────────────────────────────────┘
```

### Data Source: health-report.json

- `weeklyReports`: 周报列表（id, title, date, tag, summary）
- `stageReports`: 阶段小结列表（id, title, date, tag, summary, metrics[]）

## Decisions

### 1. 架构升级：双 UITableView 替代 UIScrollView + StackView ← 本次核心变更

**选择**: 用两个独立 `UITableView`（`weeklyTableView` + `stageTableView`）替换原有的 `UIScrollView + UIStackView` 方案。

**旧方案问题**:
```
UIScrollView
  └── UIStackView
       ├── Card View 1  ← 一次性创建，全部在内存
       ├── Card View 2
       ├── ... (如果有 200 条周报，就是 200 个 View)
       └── Card View N
```

**新方案**:
```
weeklyTableView (isHidden: false by default)
  └── Cell queue → 只保留屏幕可见的 ~4 个 WeeklyReportCell

stageTableView (isHidden: true by default)
  └── Cell queue → 只保留屏幕可见的 ~4 个 StageReportCell
```

**理由**:
- **内存安全**: Cell 复用机制使内存占用恒定（不随数据量增长），后期积累数月/数年报告数据也不出问题
- **滚动性能**: 按需出队渲染，60fps 平滑滚动
- **两个独立 TableView**: 各自持有独立 DataSource，Tab 切换仅需 `isHidden` toggle，无需 reload/重建
- **代码清晰**: WeeklyReportCell 和 StageReportCell 各自封装，职责单一

### 2. Cell 设计：WeeklyReportCell + StageReportCell

**选择**: 创建两个 `UITableViewCell` 子类，替代在 ViewController 中手写 `buildCard()`。

| Cell | Dequeue ID | 特有逻辑 |
|------|-----------|---------|
| `WeeklyReportCell` | `WeeklyReportCell` | 标准卡片布局（title/tag/date/summary/button） |
| `StageReportCell` | `StageReportCell` | 同 WeeklyReportCell + 条件嵌入 StageMetricsCardView |

**prepareForReuse 关键清理**:
- `StageReportCell.prepareForReuse()` 中调用 `metricsCardView.subviews.forEach { $0.removeFromSuperview() }` 防止 metrics grid 残留
- `WeeklyReportCell` 无需特殊清理（纯文本替换）

### 3. Tab 切换：isHidden 而非 removeFromSuperview

**选择**: 两个 TableView 同时 add 到 view，使用相同 SnapKit 约束。Tab 切换只改 `isHidden`。

```swift
weeklyTableView.isHidden = (activeTab != 0)
stageTableView.isHidden = (activeTab == 0)
```

**理由**: 避免反复创建/销毁 TableView 的开销；用户切 Tab 后再切回来，TableView 保持原滚动位置。

### 4. StageMetricsCardView 复用

**选择**: 保留现有 `StageMetricsCardView` 组件，在 `StageReportCell.configure()` 中条件嵌入。

**理由**: 组件逻辑已正确，无需重写。在 Cell 的 `contentView` 中动态添加/移除，配合 `prepareForReuse` 清理。

### 5. 颜色 Token

**选择**: 所有颜色通过 `UIColor.fd*` Token 引用。

## Risks / Trade-offs

- **双 TableView 内存**: 两个 TableView 同时持有 ~4×2=8 个 Cell → 与单 TableView + 双 DataSource 相比多 ~50KB，可忽略
- **报告详情页未实现**: "查看报告详情" 按钮暂触发 placeholder alert
- **滚动位置**: 两个 TableView 各自独立滚动位置，切 Tab 不会重置 → 符合预期
