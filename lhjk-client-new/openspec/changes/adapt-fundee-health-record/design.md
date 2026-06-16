## Context

funde-client 的 `HealthProfileView.vue` 是健康档案的完整页面，位于 `me` 模块下（路由 `/health/record`）。它展示了用户健康档案的 5 个核心区块。当前 iOS 项目该路由注册为 `PlaceholderViewController`，需要适配 funde-client 的完整设计。

## Reference Source Analysis

### HealthProfileView.vue 布局结构

```
┌──────────────────────────────────────────┐
│  系统导航栏 (title: "健康档案" + back)       │
├──────────────────────────────────────────┤
│  ① 用户信息 + 档案完整度 + 六维评测入口      │
│  ┌──────────────────────────────────────┐│
│  │ [avatar] 张大伟 · 本人   [六维评测 ›]  ││
│  │ 档案完整度 72%  ████████░░░░          ││
│  └──────────────────────────────────────┘│
├──────────────────────────────────────────┤
│  ② 人形图 + 三级风险 + 顾问批注            │
│  ┌──────────────────────────────────────┐│
│  │ 高风险 0    [SVG  无高风险            ││
│  │ 中风险 1    人形   疾病]               ││
│  │ 低风险 2    轮廓]                     ││
│  │ ──────────────────────────────────   ││
│  │ [avatar] 王顾问 · 健管师批注           ││
│  │ 血压周均值连续 7 天 > 135...           ││
│  └──────────────────────────────────────┘│
├──────────────────────────────────────────┤
│  ③ 健康监测最新数据 (section title + rows)  │
│  ┌──────────────────────────────────────┐│
│  │ 血压  今天 07:32  [偏高]  138/88 mmHg  ││
│  │ 血糖  昨天 08:10  [正常]  5.8 mmol/L   ││
│  │ ... (6 items)                        ││
│  └──────────────────────────────────────┘│
├──────────────────────────────────────────┤
│  ④ 生活习惯 (2×2 grid)                   │
│  ┌──────────┐ ┌──────────┐              │
│  │ 🍽 饮食习惯│ │ 🏃 运动习惯│              │
│  │ 低盐低脂   │ │ 每周3-4次  │              │
│  └──────────┘ └──────────┘              │
├──────────────────────────────────────────┤
│  ⑤ 健康史 (2×2 grid)                     │
│  ┌──────────┐ ┌──────────┐              │
│  │ 过敏史     │ │ 既往史     │              │
│  │ 暂无过敏史  │ │ 高血压确诊  │              │
│  ├──────────┤ ├──────────┤              │
│  │ 家族史     │ │ 用药史     │              │
│  │ 父亲:高血压 │ │ 氨氯地平... │              │
│  └──────────┘ └──────────┘              │
└──────────────────────────────────────────┘
```

### Data Source: health.json + me.json

**health.json** 提供:
- `archiveProgress`: 档案完整度百分比
- `riskScore`, `riskLevel`, `riskHint`: 健康风险评分
- `riskSummary`: 高中低风险计数 + 颜色
- `profileLatestMetrics`: 最新体征数据（6 项）
- `lifestyle`: 生活习惯数据（2 项）
- `healthHistory`: 健康史数据（4 项）

**me.json** 提供:
- `profile.name`: 用户名
- `profile.avatar`: 头像文字

## Decisions

### 1. 布局方案：UITableView 5 sections

**选择**: 使用 `UITableView` (grouped/plain)，将 5 个区块映射为 5 个 section，每个 section 1 row。

**理由**: 与现有 `HealthViewController` 模式一致，自动支持滚动和复用，减少重复代码。

### 2. 文件夹组织：PL/Health/Record/

**选择**: 在 `PL/Health/` 下创建独立的 `Record/` 文件夹，包含：
- `HealthRecordViewController.swift` — 主页面
- `HealthRecordUserInfoCell.swift` — Section 0 用户信息卡片
- `HealthRecordBodyCardCell.swift` — Section 1 人形图+风险卡片
- `HealthRecordMetricRowCell.swift` — Section 2 监测数据行（单行 cell，非 TableView section）
- `HealthRecordLifestyleCell.swift` — Section 3 生活习惯 grid
- `HealthRecordHistoryCell.swift` — Section 4 健康史 grid
- `HealthRecordModels.swift` — 数据模型

**理由**: 与其他模块（RegisterLogin/Components、Health/Cells）的文件夹组织一致；独立文件夹便于维护。

### 3. Section 2 实现方案：单 Cell 内嵌 StackView

**选择**: 监控数据行使用单个 `UITableViewCell` 内嵌 `UIStackView(vertical)` 排列 6 个子行。而非每个数据项一个 Cell。

**理由**: 这些行不可点击、不可滚动，不需要复用，StackView 比 TableView 更轻量；与 funde 的 `.hp-metric-row` 渲染模式一致。

### 4. 人形图方案：自定义 UIView 绘制

**选择**: 用 `CAShapeLayer` + `UIBezierPath` 绘制简化人形轮廓，替代 funde 的 SVG。

**理由**: 无需第三方库，ShapeLayer 绘制简单矢量图形足够；风险等级用彩色数字展示。

### 5. 导航栏方案：系统导航栏

**选择**: 使用系统 UINavigationBar（back 按钮 + title "健康档案"），不做隐藏。

**理由**: 这是子页面（非 Hub），不需要自定义 topbar；与 funde 的 `hp-topbar` 手动 back 按钮效果一致但更原生。

### 6. 颜色 Token 复用

**选择**: 所有颜色通过 `UIColor.fd*` Token 引用（`fdText`、`fdSubtext`、`fdMuted`、`fdPrimary`、`fdBg`、`fdSurface`、`fdBorder` 等）。

**理由**: 与项目现有 Token 体系一致，后续支持深色模式/老年模式自适应。

### 7. 子页面占位策略

**选择**: `/health/record/profile`、`/health/record/history`、`/health/record/lifestyle` 先用 `PlaceholderViewController` 占位，本次不实现。

**理由**: 聚焦主页面实现，子页面编辑/录入功能依赖后端接口，需后续变更处理。

## Risks / Trade-offs

- **人形图简化**: funde 的 SVG 人形图有详细的病理标志点，iOS 用 ShapeLayer 简化绘制 → 视觉精确度下降，但核心风险信息（数字+结论）不受影响
- **Mock 数据**: 当前使用硬编码 Mock 数据（与 funde health.json 一致），后续需替换为 BLL Service + DAL API
- **Sub-page 占位**: 基础信息编辑、健康史详情等子页面暂不实现，点击 "更多 ›" 或 cell 时暂不响应或跳转占位页

## Open Questions

- 是否需要像 funde 一样在 Section ③④⑤ 的 "更多 ›" 点击后跳转子页面？→ 本次暂用 `PlaceholderViewController`
- 人形图是否需要后续集成真实风险标记点？→ 后续变更由设计师提供具体标注位置
- 是否需要支持家庭成员的档案切换？→ funde 的 "本人" tag 暗示支持，但本次仅实现本人档案
