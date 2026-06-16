# Health Record / 健康档案

## Purpose

定义「健康档案」页面的 UI 布局与交互行为。参考 funde-client `HealthProfileView.vue`，通过 UIKit + SnapKit 适配到 iOS。

页面从「健康 Tab → 健康档案」入口进入，也可从「我的 → 健康档案」进入。

> **Reference**: funde-client `/prototype/src/views/me/HealthProfileView.vue`、`/prototype/src/mock/health.json`、`/prototype/src/mock/me.json`
> **Deferred**: 子页面编辑功能、API 数据接入、家庭成员档案切换、渐变/动画

---

## 模块结构

```
健康档案
├── HealthRecordViewController (主页)        ← 本次实现
│   ├── Section 0: 用户信息 + 档案完整度
│   ├── Section 1: 人形图 + 风险等级 + 顾问批注
│   ├── Section 2: 健康监测最新数据（6 行）
│   ├── Section 3: 生活习惯（2×1 grid）
│   └── Section 4: 健康史（2×2 grid）
├── HealthRecordProfileViewController       ← 占位
├── HealthRecordHistoryViewController       ← 占位
├── HealthRecordLifestyleViewController     ← 占位
└── HealthRecordConditionViewController     ← 占位
```

---

## Layout Architecture

**实现方案**: `UITableView` (plain style)，5 个 section，每个 section 1 row（custom Cell）。

```
┌──────────────────────────────────────────┐
│  UINavigationBar: "健康档案" + back        │
├──────────────────────────────────────────┤
│  UITableView (fdBg background)            │
│  ┌──────────────────────────────────────┐ │
│  │ Section 0: HealthRecordUserInfoCell  │ │
│  │ [avatar] 姓名 · 本人                  │ │
│  │ 档案完整度 72%  ████████░░░░           │ │
│  │                          [六维评测]   │ │
│  ├──────────────────────────────────────┤ │
│  │ Section 1: HealthRecordBodyCardCell  │ │
│  │ 高风险 0   [SVG人形]   无高风险疾病     │ │
│  │ 中风险 1               ✓              │ │
│  │ 低风险 2                              │ │
│  │ ──────────────────────────────        │ │
│  │ [王] 王顾问 · 健管师批注               │ │
│  │ 血压连续 7 天 > 135...                │ │
│  ├──────────────────────────────────────┤ │
│  │ Section 2: HealthRecordMetricRowCell │ │
│  │ 血压    今天 07:32 [偏高] 138/88 mmHg │ │
│  │ 血糖    昨天 08:10 [正常] 5.8 mmol/L  │ │
│  │ ... (6 items, StackView vertical)    │ │
│  ├──────────────────────────────────────┤ │
│  │ Section 3: HealthRecordLifestyleCell │ │
│  │ ┌──────────┐ ┌──────────┐           │ │
│  │ │ 🍽 饮食习惯│ │ 🏃 运动习惯│           │ │
│  │ │ 低盐低脂   │ │ 每周3-4次  │           │ │
│  │ └──────────┘ └──────────┘           │ │
│  ├──────────────────────────────────────┤ │
│  │ Section 4: HealthRecordHistoryCell  │ │
│  │ ┌──────────┐ ┌──────────┐           │ │
│  │ │ 过敏史     │ │ 既往史     │           │ │
│  │ │ 暂无过敏史  │ │ 高血压确诊  │           │ │
│  │ ├──────────┤ ├──────────┤           │ │
│  │ │ 家族史     │ │ 用药史     │           │ │
│  │ │ 父亲:高血压 │ │ 氨氯地平... │           │ │
│  │ └──────────┘ └──────────┘           │ │
│  └──────────────────────────────────────┘ │
└──────────────────────────────────────────┘
```

**Cell 注册**:
| Cell Class | Reuse ID | Section |
|-----------|----------|---------|
| `HealthRecordUserInfoCell` | `HealthRecordUserInfoCell` | 0 |
| `HealthRecordBodyCardCell` | `HealthRecordBodyCardCell` | 1 |
| `HealthRecordMetricRowCell` | `HealthRecordMetricRowCell` | 2 |
| `HealthRecordLifestyleCell` | `HealthRecordLifestyleCell` | 3 |
| `HealthRecordHistoryCell` | `HealthRecordHistoryCell` | 4 |

---

## Data Models

```swift
/// 风险等级信息
struct RiskItem {
    let label: String       // "高风险" / "中风险" / "低风险"
    let count: Int          // 数量
    let color: UIColor      // 显示颜色
}

/// 体征监测行
struct MetricRowItem {
    let label: String       // "血压"
    let value: String       // "138/88"
    let unit: String        // "mmHg"
    let status: String      // "偏高" / "正常"
    let statusType: MetricStatusType
    let time: String        // "今天 07:32"
}

enum MetricStatusType {
    case normal   // 正常 → 绿色 badge
    case warning  // 偏高/偏低 → 黄色 badge
}

/// 生活习惯
struct LifestyleItem {
    let label: String       // "饮食习惯"
    let icon: String        // SF Symbol 名
    let summary: String     // "低盐低脂，少食多餐"
}

/// 健康史
struct HealthHistoryItem {
    let label: String       // "过敏史" / "既往史" / "家族史" / "用药史"
    let summary: String     // "暂无过敏史" / "高血压确诊"
    let status: HistoryItemStatus
}

enum HistoryItemStatus {
    case filled    // 有数据 → 正常文字色
    case empty     // 暂无 → muted 色
}
```

---

## Requirements

### Requirement: Page Navigation
SHALL 作为导航栏子页面，显示系统导航栏。

#### Scenario: 导航栏样式
- **WHEN** HealthRecordViewController 渲染
- **THEN** 显示系统导航栏，title 为 "健康档案"，左侧系统 back 按钮
- **AND** `hidesBottomBarWhenPushed = true`（隐藏 TabBar）

#### Scenario: 入口方式
- **WHEN** 用户从健康 Hub 点击 "去补全" 或 "健康档案" 入口
- **THEN** push `/health/record`

---

### Requirement: User Info Card (Section 0)
SHALL 展示用户基础信息与档案完整度，参考 funde `hp-header-card`。

#### Scenario: 头像 + 姓名
- **WHEN** 卡片渲染
- **THEN** 左侧 48×48pt 圆形头像（渐变色背景 `#F4ECE3→#E8DAC8` + 姓名字符 + 白色 2pt 边框）
- **AND** 右侧 "姓名"（17pt bold fdText）+ "本人" tag（10pt primary 背景 primary 文字，圆角 pill）

#### Scenario: 档案完整度进度条
- **WHEN** 卡片渲染
- **THEN** 姓名下方显示 "档案完整度 {N}%"（11pt subtext label + 14pt bold primary 百分比数字）
- **AND** 下方 8pt 高圆角进度条（primary 14% 底 + primary 填充），宽度按 `archiveProgress / 100`

#### Scenario: 六维评测按钮
- **WHEN** 卡片渲染
- **THEN** 右侧 primary 色 pill 按钮 "六维评测 ›"（12pt bold white 文字）
- **AND** 点击 push `/health/assessment/six-dim`

---

### Requirement: Body / Risk Card (Section 1)
SHALL 展示身体风险可视化 + 健管师批注，参考 funde `hp-body-card`。

#### Scenario: 风险等级三列
- **WHEN** 卡片渲染
- **THEN** 左侧竖排 3 行：高风险（红 #E53935）、中风险（橙 #F57C00）、低风险（绿 #43A047）
- **AND** 每行显示 label（11pt）+ 数字（26pt bold monospace）

#### Scenario: 人形图占位
- **WHEN** 卡片渲染
- **THEN** 中央展示简化人形轮廓（UIView 自定义绘制，浅蓝填充 #DAEEFF + 蓝色描边 #8EC5F5）
- **AND** 尺寸约 88×180pt（与 funde SVG viewBox 一致）

#### Scenario: 综合结论
- **WHEN** 卡片渲染
- **THEN** 右侧展示绿色 ✓ 图标（SF Symbol `checkmark.circle.fill`，26pt `fdSuccess`）+ "无高风险\n疾病"（11pt bold `fdSuccess`，居中）

#### Scenario: 健管师批注
- **WHEN** 卡片渲染
- **THEN** 卡片底部 primary-soft 背景圆角区域：左侧头像圆圈（28pt，显示 "王"）+ 右侧 bold "王顾问 · 健管师批注"（title block）+ 批注正文（12pt `fdText2`，1.6 行距）

---

### Requirement: Health Monitoring Data (Section 2)
SHALL 展示最新体征监测数据 6 行，参考 funde `hp-metric-row`。

#### Scenario: Section Header
- **WHEN** section header 渲染
- **THEN** 左侧 "健康监测"（14pt subtext bold），右侧 "更多 ›" 可点击

#### Scenario: 数据行样式
- **WHEN** 数据行渲染
- **THEN** 每行水平排列：label（14pt fdText） + time（11pt fdMuted，flex 填充） + status badge（conditional） + value（16pt bold monospace fdText） + unit（11pt fdSubtext）
- **AND** 行间有 `fdBorder` 分割线（最后一行无分割线）

#### Scenario: Status Badge
- **WHEN** statusType 为 "normal" → 绿色 `fd-badge-success`
- **WHEN** statusType 为 "warning" → 黄色 `fd-badge-warning`

#### Scenario: "更多 ›" 点击
- **WHEN** 用户点击 "更多 ›"
- **THEN** push `/health/metrics`

---

### Requirement: Lifestyle Habits (Section 3)
SHALL 以 2 列 grid 展示生活习惯，参考 funde `hp-lifestyle-grid`。

#### Scenario: Section Header
- **WHEN** section header 渲染
- **THEN** 左侧 "生活习惯"（14pt subtext bold），右侧 "更多 ›"

#### Scenario: Lifestyle Card
- **WHEN** 卡片渲染
- **THEN** 白色 surface 卡片（圆角 14pt，padding 14pt），header：primary 色 icon（15pt SF Symbol）+ label（13pt bold fdText），body：summary（12pt fdText2，1.6 行距）
- **AND** 2 列等宽（horizontal StackView `.fillEqually`，spacing 10pt）

| label | SF Symbol | summary |
|-------|-----------|---------|
| 饮食习惯 | `fork.knife` | 饮食规律，低盐低脂，少食多餐 |
| 运动习惯 | `figure.run` | 走路，每周 3～4 次，30～60 分钟 |

---

### Requirement: Health History (Section 4)
SHALL 以 2×2 grid 展示健康史，参考 funde `hp-history-grid`。

#### Scenario: Section Header
- **WHEN** section header 渲染
- **THEN** 左侧 "健康史"（14pt subtext bold），右侧 "更多 ›"

#### Scenario: History Item
- **WHEN** 卡片渲染
- **THEN** 白色 surface 卡片内 2×2 grid（`UIStackView` vertical + horizontal）
- **AND** 每格：label（13pt bold fdText）+ summary（12pt fdText2/fdMuted if empty）
- **AND** 垂直分割线（`fdBorder`）在行间，水平分割线在列间

| label | summary | status |
|-------|---------|--------|
| 过敏史 | 暂无过敏史 | empty（muted 色） |
| 既往史 | 高血压（2019 年确诊） | filled（正常色） |
| 家族史 | 父亲：高血压 | filled |
| 用药史 | 苯磺酸氨氯地平，每日 1 次 | filled |

#### Scenario: Empty State
- **WHEN** item status 为 "empty"
- **THEN** summary 文字颜色使用 `fdMuted`，其他为 `fdText2`

---

## Sub-Pages (Deferred)

| Route | Page | Status |
|-------|------|--------|
| `/health/record/profile` | 基础信息编辑 | Placeholder（Deferred） |
| `/health/record/history` | 健康史详情/编辑 | Placeholder（Deferred） |
| `/health/record/lifestyle` | 生活习惯详情/编辑 | Placeholder（Deferred） |
| `/health/record/condition` | 慢病标签 | Placeholder（Deferred） |

---

## Route Registration

| Route | Target | Status |
|-------|--------|--------|
| `/health/record` | `HealthRecordViewController` | ✅ 本次实现 |
| `/health/record/profile` | `PlaceholderViewController` | 🚧 |
| `/health/record/history` | `PlaceholderViewController` | 🚧 |
| `/health/record/lifestyle` | `PlaceholderViewController` | 🚧 |
| `/health/record/condition` | `PlaceholderViewController` | 🚧 |

---

## Component Inventory

| Component | Type | funde ref | 说明 |
|-----------|------|-----------|------|
| `HealthRecordViewController` | UIViewController | hp-screen | 健康档案主页面，UITableView 5 sections |
| `HealthRecordUserInfoCell` | UITableViewCell | hp-header-card | 用户信息 + 档案完整度 + 六维评测按钮 |
| `HealthRecordBodyCardCell` | UITableViewCell | hp-body-card | 人形图 + 风险等级 + 顾问批注 |
| `HealthRecordMetricRowCell` | UITableViewCell | hp-metric-row | 体征监测数据行（内嵌 StackView 6 行） |
| `HealthRecordLifestyleCell` | UITableViewCell | hp-lifestyle-card | 生活习惯 2×1 grid |
| `HealthRecordHistoryCell` | UITableViewCell | hp-history-item | 健康史 2×2 grid |
| `BodyFigureView` | UIView | body-svg | 简化人形轮廓自定义绘制 |
| `RiskBarView` | UIView | hp-risk-col | 风险等级竖排显示 |

## States

| State | 表现 |
|-------|------|
| **默认** | Mock 数据渲染完整 5 sections |
| **档案完整度 < 100%** | 进度条显示实际百分比，"去补全"引导（与 Hub 一致） |
| **健康史 empty** | 对应格子文字变 muted 色（"暂无过敏史"） |
| **体征 warning** | 对应行显示黄色 status badge |

## Acceptance Checklist

- [ ] 导航栏显示 "健康档案" + 系统 back 按钮
- [ ] TabBar 隐藏（hidesBottomBarWhenPushed）
- [ ] Section 0 — 用户信息卡：头像 + 姓名 + "本人" tag + 档案完整度进度 + 六维评测按钮
- [ ] Section 1 — 身体风险卡：三级风险数字 + 人形图 + 综合结论 + 顾问批注
- [ ] Section 2 — 健康监测：6 行数据 + status badge（normal/warning 双色）
- [ ] Section 3 — 生活习惯：2 列卡片（饮食 + 运动）
- [ ] Section 4 — 健康史：2×2 grid（过敏/既往/家族/用药）
- [ ] 所有颜色通过 `UIColor.fd*` Token 引用
- [ ] 从 `/health` 点击 "去补全" 正确跳转到 `/health/record`
- [ ] 六维评测按钮跳转到 `/health/assessment/six-dim`
