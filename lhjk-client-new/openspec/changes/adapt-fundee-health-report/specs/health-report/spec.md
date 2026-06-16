# Health Report / 我的报告

## Purpose

定义「我的报告」页面的 UI 布局与交互行为。参考 funde-client `HealthReportView.vue`，通过 UIKit + SnapKit 适配到 iOS。

页面包含双 Tab 切换（周报 / 阶段小结），阶段小结额外展示量化改善指标 2×2 grid。

> **Reference**: funde-client `/prototype/src/views/me/HealthReportView.vue`、`/prototype/src/mock/health-report.json`
> **Deferred**: 报告详情页、API 数据接入

---

## Layout Architecture

### 双 TableView 架构

**方案**: 两个独立 `UITableView`（`weeklyTableView` + `stageTableView`），通过 Tab 切换控制 `isHidden`。

```
┌──────────────────────────────────────────┐
│  UINavigationBar: "健康报告" + back        │
├──────────────────────────────────────────┤
│  UISegmentedControl: [周报] [阶段小结]     │
├──────────────────────────────────────────┤
│  ┌─ weeklyTableView ──────────────────┐  │
│  │  WeeklyReportCell                   │  │
│  │  ┌──────────────────────────────┐   │  │
│  │  │ title + tag                  │   │  │
│  │  │ date                         │   │  │
│  │  │ summary                      │   │  │
│  │  │ [查看报告详情] button         │   │  │
│  │  └──────────────────────────────┘   │  │
│  │  WeeklyReportCell ...               │  │
│  └─────────────────────────────────────┘  │
│  ┌─ stageTableView (hidden by default) ─┐  │
│  │  StageReportCell                     │  │
│  │  ┌──────────────────────────────┐   │  │
│  │  │ title + tag                  │   │  │
│  │  │ date                         │   │  │
│  │  │ summary                      │   │  │
│  │  │ [StageMetricsCardView] ← 条件 │   │  │
│  │  │ [查看报告详情] button         │   │  │
│  │  └──────────────────────────────┘   │  │
│  │  StageReportCell ...                 │  │
│  └─────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

### 为什么用双 TableView 而非 UIScrollView + StackView？

| 维度 | UIScrollView + StackView | 双 UITableView |
|------|--------------------------|----------------|
| **内存** | 所有卡片一次性创建并常驻内存，数据量大时（如 100+ 条周报）内存飙升 | Cell 复用，仅屏幕可见的 ~3-5 个 cell 存于内存 |
| **滚动性能** | 卡片多时首帧渲染卡顿 | 按需出队，平滑 60fps |
| **代码复杂度** | 简单（StackView addArrangedSubview） | 中等（需 DataSource + Delegate） |
| **适用场景** | 少量固定卡片（≤10） | 不定长列表、后期数据增长 |

**结论**: 健康报告后期可能积累数月/数年数据，选择双 TableView 避免内存膨胀。

### 双 TableView 的切换逻辑

- 两个 TableView 使用**相同约束**（top/bottom/leading/trailing 对齐到 SegmentedControl 下方和 safeArea 底部）
- Tab 切换时只改 `isHidden`，不重建、不 reload
- 首次切换到某一 Tab 时其 TableView 已就绪，无需等待

**Cell 注册**:
| Cell Class | Reuse ID | TableView | Section |
|-----------|----------|-----------|---------|
| `WeeklyReportCell` | `WeeklyReportCell` | weeklyTableView | 0 |
| `StageReportCell` | `StageReportCell` | stageTableView | 0 |

---

## Data Models

```swift
/// 周报
struct WeeklyReport {
    let id: String
    let title: String       // "第 21 周健康周报"
    let date: String        // "2026-05-20"
    let tag: String         // "本周已读" / "已归档"
    let summary: String     // 摘要
}

/// 阶段小结
struct StageReport {
    let id: String
    let title: String       // "慢病逆转 8 周阶段小结"
    let date: String
    let tag: String         // "健管师确认" / "基线报告"
    let summary: String
    let metrics: [StageMetric]  // 量化改善指标
}

/// 量化改善指标
struct StageMetric {
    let label: String       // "血压达标率"
    let before: String      // "52%"
    let after: String       // "85%"
    let unit: String        // "" / "分"
    let isGood: Bool        // true → after 绿色高亮
}
```

---

## Requirements

### Requirement: Tab Switching
SHALL 支持「周报」和「阶段小结」两个 Tab 切换，通过两个 TableView 的 `isHidden` 控制。

#### Scenario: 默认 Tab
- **WHEN** 页面首次渲染
- **THEN** `weeklyTableView.isHidden = false`，`stageTableView.isHidden = true`

#### Scenario: Tab 切换到阶段小结
- **WHEN** 用户点击「阶段小结」
- **THEN** `weeklyTableView.isHidden = true`，`stageTableView.isHidden = false`
- **AND** 不重新创建 TableView，不触发 reloadData

#### Scenario: SegmentedControl 样式
- **WHEN** 控件渲染
- **THEN** 选中段 fdPrimary 背景 + 白色文字（13pt semibold），未选中段 fdBg2 背景 + fdSubtext 文字（13pt）

---

### Requirement: Weekly Report Cell
SHALL 使用 `WeeklyReportCell` 展示周报卡片，支持 Cell 复用。

#### Scenario: Cell 注册
- **WHEN** weeklyTableView 初始化
- **THEN** 注册 `WeeklyReportCell`，reuse identifier 为 `WeeklyReportCell`

#### Scenario: 卡片结构
- **WHEN** Cell 渲染
- **THEN** fdSurface 背景（圆角 24pt，阴影），内边距 16pt
- **AND** 顶部行：标题（16pt bold fdText）+ 右侧 tag pill
- **AND** 日期（12pt fdSubtext）
- **AND** 摘要（14pt fdText2，多行）
- **AND** 底部全宽按钮 "查看报告详情"（15pt bold fdPrimary，primarySoft 背景，圆角 12pt，高 40pt）

#### Scenario: Cell 复用
- **WHEN** TableView 滚动
- **THEN** `prepareForReuse` 清空旧数据，`configure(weeklyReport:)` 填充新数据

---

### Requirement: Stage Report Cell
SHALL 使用 `StageReportCell` 展示阶段小结卡片，支持条件渲染 metrics grid，支持 Cell 复用。

#### Scenario: Cell 注册
- **WHEN** stageTableView 初始化
- **THEN** 注册 `StageReportCell`，reuse identifier 为 `StageReportCell`

#### Scenario: 卡片结构（有 metrics）
- **WHEN** `metrics` 非空
- **THEN** 标题 + tag + 日期 + 摘要 + `StageMetricsCardView`（2×2 grid）+ 按钮

#### Scenario: 卡片结构（无 metrics）
- **WHEN** `metrics` 为空
- **THEN** `StageMetricsCardView.isHidden = true`，布局与周报卡片一致

#### Scenario: Metrics Grid (StageMetricsCardView)
- **WHEN** `metrics` 数组非空
- **THEN** 摘要下方展示 2×2 grid：
  - 浅暖背景 `#FAF8F6`，圆角 12pt，padding 12pt
  - 每格：label（11pt fdSubtext）+ before（12pt 灰色 #bbb）→ after（14pt bold fdText/fdSuccess if good）

#### Scenario: Cell 复用
- **WHEN** TableView 滚动
- **THEN** `prepareForReuse` 中重置 `StageMetricsCardView`（`subviews.forEach { $0.removeFromSuperview() }`），避免上一次的 metrics 残留

---

### Requirement: Report Detail Button
SHALL 提供「查看报告详情」按钮。

#### Scenario: 按钮点击
- **WHEN** 用户点击「查看报告详情」
- **THEN** 暂展示 placeholder 提示（后续实现报告详情页）

---

## Component Inventory

| Component | Type | funde ref | 说明 |
|-----------|------|-----------|------|
| `HealthReportViewController` | UIViewController | report-list | 双 Tab + 双 TableView（isHidden 切换） |
| `WeeklyReportCell` | UITableViewCell | report-card | 周报卡片（新增，替代 StackView 直接创建） |
| `StageReportCell` | UITableViewCell | report-card + metrics-grid | 阶段小结卡片 + 条件 metrics grid（新增） |
| `StageMetricsCardView` | UIView | metrics-grid | 量化改善指标 2×2 grid（已存在） |

## States

| State | 表现 |
|-------|------|
| **默认 (周报)** | weeklyTableView 可见，stageTableView 隐藏 |
| **阶段小结** | stageTableView 可见，weeklyTableView 隐藏 |
| **阶段小结 (无 metrics)** | StageMetricsCardView.isHidden = true |
| **查看详情点击** | placeholder 提示 |
| **大量数据（100+）** | TableView Cell 复用仅 3-5 个 cell 在内存 |

## Acceptance Checklist

- [ ] 导航栏标题 "健康报告" + back 按钮
- [ ] UISegmentedControl 双 Tab，默认选中「周报」
- [ ] 两个 TableView 使用相同约束，Tab 切换仅改变 isHidden
- [ ] 周报 Tab：WeeklyReportCell 展示标题 + tag + 日期 + 摘要 + 按钮
- [ ] 阶段小结 Tab：StageReportCell 展示同周报 + 条件 metrics grid
- [ ] Metrics before/after 正确显示，正向指标 after 绿色高亮
- [ ] Cell 复用不会导致 metrics grid 残留（prepareForReuse 清理）
- [ ] 颜色通过 `UIColor.fd*` Token 引用
- [ ] 路由 `/health/assessment/report` → `HealthReportViewController`
