# Health / 健康

## Purpose

定义「健康」Tab 页面（Hub）及子页面的 UI 布局与交互行为。参考 funde-client 健康模块全部 17 个 Vue 视图，通过 UIKit + SnapKit 适配到 iOS。

页面是 App 第二个 Tab，使用 `topbar-scroll` 布局。

> **Reference**: funde-client `/prototype/src/views/health/HealthView.vue`、`/prototype/src/mock/health.json`
> **Deferred**: 渐变背景、老年模式（全局延迟）

---

## 模块结构

```
健康 Tab
├── HealthViewController (Hub)         ← 本次实现
├── HealthRecordView                   ← 占位
├── MetricsView                        ← 占位
│   ├── BloodPressureView              ← 占位
│   ├── BloodSugarView                 ← 占位
│   ├── WeightView                     ← 占位
│   ├── HeartRateView                  ← 占位
│   ├── SleepView                      ← 占位
│   ├── SpO2View                       ← 占位
│   ├── EcgView                        ← 占位
│   ├── ExerciseFoodView               ← 占位
│   ├── FundusView                     ← 占位
│   ├── DigestiveView                  ← 占位
│   └── MetricAddView                  ← 占位
├── SixDimView                         ← 占位
├── ReportView                         ← 占位
└── RiskAssessmentView                 ← 占位
```

---

## Layout Architecture (Hub)

**实现方案**: `UITableView` (plain style)，利用 section 分割不同卡片区块，自动支持滚动和复用。

```
┌──────────────────────────────────────────┐
│  UITableView (fdBg background)            │
│  ┌──────────────────────────────────────┐ │
│  │ tableHeaderView: Custom Topbar       │ │
│  │  "我的健康" · 档案完整度 72% · 中风险  │ │
│  ├──────────────────────────────────────┤ │
│  │ Section 0: Score Card (1 row)        │ │
│  │ HealthScoreCardCell                  │ │
│  ├──────────────────────────────────────┤ │
│  │ Section 1: Archive Card (1 row)      │ │
│  │ HealthArchiveCardCell                │ │
│  ├──────────────────────────────────────┤ │
│  │ Section 2: Vital Metrics (1 row)     │ │
│  │ sectionHeader: "体征监测    编辑卡片 ›"│ │
│  │ HealthVitalMetricsCell               │ │
│  │   └── UICollectionView (2×N grid)    │ │
│  │       ├ MetricCardCell               │ │
│  │       ├ MetricCardCell               │ │
│  │       └ ... (10 items)               │ │
│  ├──────────────────────────────────────┤ │
│  │ Section 3: Quick Entries (1 row)     │ │
│  │ HealthQuickEntriesCell               │ │
│  └──────────────────────────────────────┘ │
└──────────────────────────────────────────┘
```

**Cell 注册**:
| Cell Class | Reuse ID | Section |
|-----------|----------|---------|
| `HealthScoreCardCell` | `HealthScoreCardCell` | 0 |
| `HealthArchiveCardCell` | `HealthArchiveCardCell` | 1 |
| `HealthVitalMetricsCell` | `HealthVitalMetricsCell` | 2 |
| `HealthQuickEntriesCell` | `HealthQuickEntriesCell` | 3 |

---

## Requirements

### Requirement: Tab Integration
SHALL 作为 App 第二个 Tab，导航栏首页隐藏、子页面显示。

#### Scenario: Tab 位置
- **WHEN** Tab Bar 渲染
- **THEN** 第二个 Tab 标题为"健康"，SF Symbol 为 `heart`

#### Scenario: 首页隐藏系统导航栏
- **WHEN** HealthViewController 渲染
- **THEN** `navigationController?.setNavigationBarHidden(true)`，用自定义 topbar 替代

#### Scenario: 子页面恢复导航栏
- **WHEN** push 到子页面
- **THEN** `viewWillDisappear` 中恢复 `setNavigationBarHidden(false)`

---

### Requirement: Custom Topbar
SHALL 渲染自定义顶栏替代系统导航栏。

#### Scenario: 标题
- **WHEN** Hub 页渲染
- **THEN** 显示 "我的健康"（22pt bold `fdText`）

#### Scenario: 副标题
- **WHEN** Hub 页渲染
- **THEN** 标题下方显示 "档案完整度 {N}% · {风险等级}"（12pt `fdSubtext`）

#### Scenario: 顶部间距
- **WHEN** 页面渲染
- **THEN** topbar 顶部与 safeAreaLayoutGuide.top 间距约 54pt

---

### Requirement: Health Score Card
SHALL 展示综合健康评分卡片。

#### Scenario: 评分圆环
- **WHEN** 卡片渲染
- **THEN** 左侧 78pt 圆环（`fdPrimary` 30% 透明边框 + "SCORE" 微标签 + 数字 62 + 趋势 "↓ 3 周前 65"）
- **NOTE**: 完整 SVG 环形仪表盘延迟到后续迭代，本次用简化纯色圆环

#### Scenario: 评分详情
- **WHEN** 卡片渲染
- **THEN** 右侧展示 "综合健康评分"（12pt subtext）、大数字 "62"（40pt bold）+ "中风险" badge（黄底）、提示文字（12pt text2）

#### Scenario: 健管师批注
- **WHEN** 卡片渲染
- **THEN** 底部展示浅橙背景 note：左侧头像圆圈 + 右侧 bold 名称 + 批注正文（12pt）

---

### Requirement: Archive Completeness Card
SHALL 展示健康档案完整度卡片。

#### Scenario: 进度展示
- **WHEN** 卡片渲染
- **THEN** 左侧 "健康档案完整度"（14pt semibold）+"缺：心电图 / 家族病史"（11pt subtext），右侧百分比 "72%"（22pt bold primary）

#### Scenario: 进度条
- **WHEN** 卡片渲染
- **THEN** 8pt 高圆角进度条（主色 14% 透明底 + 主色填充），宽度按百分比

#### Scenario: 操作按钮
- **WHEN** 卡片渲染
- **THEN** 底部 "补全后 +20 健康分 · 解锁家族风险图谱"（11pt muted）+ "去补全" pill 按钮（浅橙底橙字）→ push `/health/record`

---

### Requirement: Vital Metrics Grid
SHALL 以 2×N 网格展示体征监测指标卡片（来源 `health.json` metrics 数组，共 10 项）。

**实现方案**: `HealthVitalMetricsCell`（UITableViewCell 子类）内嵌 `UICollectionView` + `UICollectionViewCompositionalLayout`
- Cell 注册为 `HealthVitalMetricsCell`，内部持有独立的 UICollectionView
- CollectionView Cell: `MetricCardCell`，注册 reuse identifier `MetricCardCell`
- CollectionView Layout: `.fractionalWidth(0.5)` × `.estimated(140)`, inter-group spacing 10pt
- CollectionView `isScrollEnabled = false`，Cell 高度动态计算 = rows × 140 + gaps，通过 `tableView(_:heightForRowAt:)` 返回
- **理由**: cell 复用减少内存、CompositionalLayout 处理 2 列网格更简洁、后续指标数量增加无需改布局代码；将 CollectionView 嵌入 TableViewCell 解耦度量网格与页面其他区块

#### Scenario: 区块标题
- **WHEN** 区块渲染
- **THEN** 左侧 "体征监测"（14pt subtext bold），右侧 "更多 ›" → push `/health/metrics`

#### Scenario: 指标卡片（正常）
- **WHEN** 指标 statusType 为 "success"
- **THEN** 白色卡片：icon（绿底绿字 30×30）+ status badge（绿底绿字） + label（13pt subtext） + value（24pt bold monospace） + unit（11pt） + trend arrow（SF Symbol）+ time（11pt muted）

#### Scenario: 指标卡片（异常）
- **WHEN** 指标 statusType 为 "warning"
- **THEN** 卡片添加 1pt `fdPrimaryEdge` 边框（与 funde 的 `metric-card--warning` 一致）

#### Scenario: 趋势箭头
- **WHEN** trend 为 "up" → SF Symbol `arrow.up.right`，红色 `fdDanger`
- **WHEN** trend 为 "down" → SF Symbol `arrow.down.right`，绿色 `fdSuccess`
- **WHEN** trend 为 "flat" → SF Symbol `minus`，灰色 `fdMuted`

#### Scenario: 点击跳转
- **WHEN** 用户点击指标卡片
- **THEN** push `/health/metrics/{key}`（如 `/health/metrics/blood-pressure`）

---

### Requirement: Quick Entries
SHALL 展示 4 个快速入口。

#### Scenario: 入口样式
- **WHEN** 区块渲染
- **THEN** 4 列等宽，每列：上方 48×48pt 圆角 icon 方块（自定义背景色 + SF Symbol） + 下方 label（12pt text2）

#### Scenario: 入口配置
| label | SF Symbol | bgColor | fgColor | route |
|-------|-----------|---------|---------|-------|
| 健康档案 | `doc.text` | `#FFF3DC` | `#B47300` | `/health/record` |
| 体征监测 | `heart.text.square` | `#FFE9DF` | `fdPrimary` | `/health/metrics` |
| 六维评测 | `clipboard` | `#E6F7EF` | `#1F9A6B` | `/health/assessment/six-dim` |
| 我的报告 | `chart.bar` | `#F3EFFC` | `#7B5E9F` | `/health/assessment/report` |

---

## Sub-Pages (参照 funde-client)

### 共性模式（所有指标详情页）

每个指标详情页遵循统一模板：

```
┌──────────────────────────────────────────┐
│  系统导航栏 (title + back)                 │
├──────────────────────────────────────────┤
│  蓝牙设备连接状态 Banner                   │  ← MetricBtBanner (暂占位)
├──────────────────────────────────────────┤
│  时段切换 (日/周/月 pill tabs)              │
│  日期导航 (‹ 日期范围 ›)                    │
├──────────────────────────────────────────┤
│  折线图卡片                                │  ← SVG polyline → DGCharts
│  · Y 轴刻度 + 参考区间                      │
│  · 1-2 条折线 + 数据点                      │
│  · X 轴日期标签                             │
├──────────────────────────────────────────┤
│  统计摘要 (2-4 个数字卡片)                  │
├──────────────────────────────────────────┤
│  近期记录列表 (时间 + 数值 + 来源)          │
├──────────────────────────────────────────┤
│  [+录入数据] 按钮                          │  → /health/metrics/:key/add
└──────────────────────────────────────────┘
```

---

### 10 个指标详情页 — Funde vs iOS 对照

#### 1. 血压 (`/health/metrics/blood-pressure`) — BloodPressureView.vue

| 特性 | funde | iOS |
|------|-------|-----|
| 折线图 | SVG 双折线 (收缩压 橙#FF7A50 + 舒张压 蓝#6B9FE4) | DGCharts `LineChartDataSet` × 2 |
| 参考区间 | 90–140 mmHg 浅橙背景 | `ChartLimitLine` 或自定义 fill |
| 时段 | 日/周/月 | `UISegmentedControl` |
| 统计 | 平均收缩压/舒张压/心率 3 列 | `UIStackView` 3 卡片 |
| 记录 | 4 行 (时间+数值+来源) | TableView rows |
| Mock | `blood-pressure.json` (history 数组) | 同 mock 结构 |

#### 2. 血糖 (`/health/metrics/blood-sugar`) — BloodSugarView.vue

| 特性 | funde | iOS |
|------|-------|-----|
| 子类型切换 | 指血血糖 / 动态血糖 pill tabs | 额外 `UISegmentedControl` |
| 折线图 | 空腹+餐后双线散点图 | DGCharts scatter + line combined |
| 统计 | 最高/最低/波动幅度 3 列 | 3 卡片 |
| Mock | `blood-sugar.json` | 同 |

#### 3. 体重 (`/health/metrics/weight`) — WeightView.vue

| 特性 | funde | iOS |
|------|-------|-----|
| 折线图 | 单线 + 目标线 (虚线) | `LineChartDataSet` + `ChartLimitLine` |
| 进度 | "距离目标还有 X kg" + 进度条 | `UIProgressView` |
| 统计 | 起始/当前/变化/BMI 4 列 | 4 卡片 |
| Mock | `weight.json` (含 target) | 同 |

#### 4. 心率 (`/health/metrics/heart-rate`) — HeartRateView.vue

| 特性 | funde | iOS |
|------|-------|-----|
| 折线图 | 静息+运动双线 + SVG 参考 band | DGCharts 双线 + fill |
| 统计 | 平均静息/最高运动/最低静息 3 列 | 3 卡片 |
| 心率分区 | 热身/有氧/心肺/极限 4 区色条 | 自定义 color bar |
| Mock | `heart-rate.json` | 同 |

#### 5. 睡眠 (`/health/metrics/sleep`) — SleepView.vue

| 特性 | funde | iOS |
|------|-------|-----|
| 昨晚摘要卡 | 深蓝渐变背景(#2D4A8A→#4A6FB5) + 时长 + 入睡/起床时间 + 睡眠分圆环 | 纯色深蓝 `#2D4A8A` 卡片 + 圆环（同 Funde） |
| 睡眠分圆环 | 64×64 圆环, 3pt 边框, 颜色按分数: ≥80绿 #52B96A / ≥60黄 #F5A623 / <60红 #E45454 | UIView circle + border |
| 睡眠结构条 | 4 段水平色条 (深睡/浅睡/REM/清醒) flex 比例 | 4 个 `UIView` 在 `UIStackView` 中按小时比例分配宽度 |
| 柱状图 | SVG 竖条: 20px 宽, 颜色按分数, 圆角 rx=4, 分数标签+日期标签, 80分参考线 | DGCharts `BarChartView` + `BarChartDataSet` |
| 统计行 | 3 列: 总时长/深度睡眠/睡眠评分 | `UIStackView` 3 卡片 |
| 记录列表 | 时间+数值·评分 + 蓝牙/手动 tag | 自定义 row |
| 健管师批注 | 白底卡 + 左侧蓝色 3px 边框 | UIView + left border 3pt #2D4A8A |
| 柱状图 color map | ≥80: #52B96A, ≥60: #F5A623, <60: #E45454 | 同 |
| 睡眠阶段颜色 | 深睡#2D4A8A / 浅睡#6B9FE4 / REM#9B7DEA / 清醒#E8E8E8 | 同 |

**结论**: 柱状图用 DGCharts `BarChartView`（已集成），睡眠结构条用原生 `UIStackView`，**无需额外第三方库**。

#### 6. 血氧 (`/health/metrics/spo2`) — SpO2View.vue
#### 7. 心电 (`/health/metrics/ecg`) — EcgView.vue
#### 8. 饮食运动 (`/health/metrics/exercise`) — ExerciseFoodView.vue
#### 9. 鹰瞳眼底 (`/health/metrics/fundus`) — FundusView.vue
#### 10. 消化道 (`/health/metrics/digestive`) — DigestiveView.vue

> 第 5-10 个指标详情页遵循相同模板，差异仅在图表数据类型和统计指标，暂列占位。

---

### 图表库选型：DGCharts

| 库 | Stars | License | 优势 | 劣势 |
|----|-------|---------|------|------|
| **DGCharts** | 27k+ | Apache 2.0 | 功能最全、社区最大、双线/散点/限制线原生支持 | API 偏 ObjC 风格、包体积较大 |
| AAInfographics | 5k | MIT | 轻量、Swift 友好 API | 功能较少、社区小 |
| SwiftCharts | 2.5k | MIT | 纯 Swift、高度可定制 | 文档少、学习曲线陡 |

**选择 DGCharts**：
- 血压双折线 (`LineChartDataSet` × 2) 原生支持
- 血糖散点+折线混合图 (`CombinedChartView`) 原生支持
- 体重目标虚线 (`ChartLimitLine`) 原生支持
- CocoaPods 依赖：`pod 'DGCharts'`（需开发者手动添加）

> **ATTENTION**: 开发者需在 Podfile 中添加 `pod 'DGCharts'` 并执行 `pod install`

---

### Metrics Overview (`/health/metrics`) — MetricsView.vue

| 特性 | funde | iOS |
|------|-------|-----|
| 2×N 卡片网格 | 10 张卡片 + 设备连接状态点 | `UICollectionView` (复用 Hub 的 `MetricCardCell`) |
| 底部蓝牙入口 | "管理蓝牙设备 · N 台在线" | `fd-card` row → `/me/devices` |

### Health Record (`/health/record`) — HealthRecordView.vue

| 特性 | funde | iOS |
|------|-------|-----|
| Tab 切换 | `van-tabs`: 基础信息 / 健康史 | `UISegmentedControl` |
| 基础信息 | `van-cell-group` 9 字段 | TableView inset style |
| 健康史分组 | 过敏史/既往史/家族史 | TableView sections |

### Assessment Pages

| Page | funde | iOS |
|------|-------|-----|
| 六维评测 (`/health/assessment/six-dim`) | 6 维度选择题 + 进度条 + 提交 | 占位 |
| 评估报告 (`/health/assessment/report`) | 雷达图 + 维度得分 | 占位 |
| 风险评估 (`/health/assessment/risk`) | 风险等级 + 建议 | 占位 |

---

### Metric Add (`/health/metrics/:key/add`) — MetricAddView.vue

#### Layout

```
┌──────────────────────────────────────────┐
│  系统导航栏: "手动输入数据" + back          │
├──────────────────────────────────────────┤
│  Date/Time Card                          │
│  日期    2026-06-12 ›                     │
│  测量时间 08:32 ›                         │
├──────────────────────────────────────────┤
│  Extra Selectors (条件展示)               │
│  测量时机: [空腹] [餐后2小时] [随机血糖]    │
│  测量场景: [静息状态] [运动后]             │
├──────────────────────────────────────────┤
│  Fields Card                             │
│  ▎血压记录                                │
│  ┌──────────────────────────────────────┐│
│  │ 收缩压              120 mmHg         ││
│  │ ├──┼──┼──┼──[120]──┼──┼──┤  (Ruler) ││
│  │ 80  100  120  140  160  180  200 220 ││
│  ├──────────────────────────────────────┤│
│  │ 舒张压              80 mmHg          ││
│  │ 同上 ruler...                         ││
│  ├──────────────────────────────────────┤│
│  │ 脉搏                72 次/分钟        ││
│  │ 同上 ruler...                         ││
│  └──────────────────────────────────────┘│
├──────────────────────────────────────────┤
│  [保存] 按钮 (品牌色全宽圆角)              │
└──────────────────────────────────────────┘
```

#### 各指标字段配置对照

| metric key | 字段 | 范围 | 步长 | 默认值 | 额外选项 |
|-----------|------|------|------|--------|---------|
| `blood-pressure` | 收缩压 / 舒张压 / 脉搏 | 80-220 / 40-140 / 40-180 | 1 / 1 / 1 | 120 / 80 / 72 | — |
| `blood-sugar` | 血糖值 | 1-30 | 0.1 | 5.5 | 空腹 / 餐后2小时 / 随机血糖 |
| `weight` | 体重 | 30-180 | 0.1 | 65 | — |
| `heart-rate` | 心率 | 40-220 | 1 | 75 | 静息状态 / 运动后 |
| `spo2` | 血氧饱和度 | 70-100 | 1 | 98 | — |
| `sleep` | 睡眠时长 | 1-14 | 0.5 | 7 | — |
| `ecg` | 平均心率 | 40-180 | 1 | 75 | — |

#### Ruler 控件（MetricRuler.vue）

| 特性 | funde 实现 | iOS 方案 |
|------|-----------|---------|
| 水平刻度尺 | HTML `scroll-snap` + CSS 伪元素刻度 | 自定义 `MetricRulerView`（UIScrollView 子类）|
| 中心红色指针 | `position:absolute; left:50%` 2px 红线 | `UIView` 2pt 宽, 居中添加 |
| 刻度线 | `::before` 伪元素 1px × 10px（小）/ 18px（大） | `CAShapeLayer` 绘制刻度线 |
| 标签 | 大刻度下方数字 label | `UILabel` 动态布局 |
| scroll-snap | CSS `scroll-snap-align: center` | `UIScrollViewDelegate` + `scrollViewDidEndDecelerating` 计算最近刻度 |
| 刻度间距 | 12px/刻度 | 12pt/刻度 |
| 选中高亮 | `ruler-tick--selected` 品牌色 | 中心值高亮色 |

**选型结论**：不用第三方库，自定义 `MetricRulerView`。原因：
1. 控件逻辑简单（~200 行），第三方库反而过度抽象
2. 可以精确匹配 Funde 设计（刻度间距、颜色、指针样式）
3. 避免引入不必要的依赖

> `UIPickerView` 是 iOS 原生可选方案，但竖向滚轮与 Funde 水平刻度尺设计差异大，不采用。

---

## Route Registration

| Route | Target | Status |
|-------|--------|--------|
| `/health` | HealthViewController | ✅ 已实现 |
| `/health/record` | Placeholder | 🚧 |
| `/health/metrics` | Placeholder | 🚧 |
| `/health/metrics/{key}` | Placeholder (10 keys) | 🚧 |
| `/health/metrics/:key/add` | Placeholder | 🚧 |
| `/health/assessment/six-dim` | Placeholder | 🚧 |
| `/health/assessment/report` | Placeholder | 🚧 |
| `/health/assessment/risk` | Placeholder | 🚧 |

---

## Component Inventory

| Component | Type | funde ref | 说明 |
|-----------|------|-----------|------|
| `HealthScoreCardCell` | UITableViewCell | score-card | 综合健康评分卡片 |
| `HealthArchiveCardCell` | UITableViewCell | archive-card | 健康档案完整度卡片 |
| `HealthVitalMetricsCell` | UITableViewCell | metrics-grid | 体征监测 — 内嵌 UICollectionView |
| `HealthQuickEntriesCell` | UITableViewCell | quick-entries | 快速入口 4 列 |
| `MetricCardCell` | UICollectionViewCell | metric-card | 体征指标卡片（复用） |
| `SectionTitleView` | UIView | fd-section-title | 区块标题行（复用） |

## States

| State | 表现 |
|-------|------|
| **默认** | Mock 数据渲染完整 Hub，UITableView 4 sections |
| **指标点击** | push 到对应指标详情（占位页） |
| **快速入口点击** | push 到对应页面（占位页） |

## Acceptance Checklist

- [ ] Tab 栏第二个 "健康" Tab 正确展示
- [ ] UITableView 4 sections 结构渲染完整
- [ ] tableHeaderView: 自定义 topbar "我的健康" + 档案完整度副标题
- [ ] 导航栏首页隐藏，push 子页面显示
- [ ] Section 0 — 评分卡：圆环 + 数字 + badge + 提示 + 健管师批注
- [ ] Section 1 — 档案卡：进度条 + 百分比 + "去补全"按钮
- [ ] Section 2 — 体征监测：section header 标题 + HealthVitalMetricsCell 内嵌 CollectionView 展示 10 个 2×N 卡片
- [ ] 异常指标卡片有边框高亮
- [ ] Section 3 — 快速入口 4 个（icon 方块 + label）
- [ ] 10 个指标 + 4 个快速入口 click → 正确路由 push
- [ ] 所有颜色通过 `UIColor.fd*` Token 引用
