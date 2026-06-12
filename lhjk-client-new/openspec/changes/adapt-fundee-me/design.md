## Context

funde-client 的 MeView 是一个 `hub` 类型的一级 Tab 页面，使用 `hero-scroll` 布局。iOS 项目当前 `MyViewController.swift` 仅占位实现，需要按 Funde 设计完整重写。

> **Deferred**: 老年模式（Dynamic Type）、页面渐变背景（CAGradientLayer）沿用 RegisterLogin 模块的决策。

## Reference Source Analysis

### MeView.vue 布局结构

```
┌──────────────────────────────────────────────┐
│  fd-screen (scrollable)                       │
│  ┌────────────────────────────────────────────┐
│  │  Hero Section (warm gradient bg)           │
│  │  ┌──────┐  李秀英       [⚙]               │
│  │  │  英  │  [编辑资料 ›] [♥ 健康档案]        │
│  │  └──────┘                                  │
│  ├────────────────────────────────────────────┤
│  │  Membership Card                           │
│  │  会员中心  健康大会员               查看更多 ›│
│  ├────────────────────────────────────────────┤
│  │  Stats Strip (4 stats)                     │
│  │  892  |  4   |  2   |  Lv.3               │
│  │  健康积分|家庭成员|我的保单|健康等级          │
│  ├────────────────────────────────────────────┤
│  │  Section: 服务履约                          │
│  │  ┌──┬──┬──┬──┐                            │
│  │  │2 │1 │3 │1 │ 待使用/使用中/已完成/待评价  │
│  │  └──┴──┴──┴──┘                            │
│  │  ┌──────────────────────────────┐          │
│  │  │ 慢病逆转管理     进行中       ›│          │
│  │  │ 慈铭高端体检     待使用       ›│          │
│  │  └──────────────────────────────┘          │
│  ├────────────────────────────────────────────┤
│  │  Section: 健康管理                          │
│  │  ┌──────────────────────────────┐          │
│  │  │ 📄 健康档案        完整度72% ›│          │
│  │  │ 💓 健康报告      周报/阶段小结›│          │
│  │  │ ... (7 items)                │          │
│  │  └──────────────────────────────┘          │
│  ├────────────────────────────────────────────┤
│  │  Section: 账号与设置                        │
│  │  ┌──────────────────────────────┐          │
│  │  │ 🔔 消息通知          已开启  ›│          │
│  │  │ ... (4 items)                │          │
│  │  └──────────────────────────────┘          │
│  ├────────────────────────────────────────────┤
│  │  Section: 关于                              │
│  │  ┌──────────────────────────────┐          │
│  │  │ 🎧 帮助中心 · 7×24客服       ›│          │
│  │  │ ℹ️ 关于富德健康               ›│          │
│  │  │ ✅ 当前版本         v 2.6.1  │          │
│  │  └──────────────────────────────┘          │
│  ├────────────────────────────────────────────┤
│  │  [退出登录]                                 │
│  └────────────────────────────────────────────┘
└──────────────────────────────────────────────┘
```

### 子页面清单

| Route | Vue View | 用途 | iOS 是否需要 |
|-------|----------|------|------------|
| `/me/profile` | ProfileView | 个人信息 | ✅ |
| `/me/health-profile` | HealthProfileView | 健康档案编辑 | ✅ |
| `/me/settings` | SettingsView | 设置入口 | ✅ |
| `/me/settings/notifications` | NotificationSettingsView | 通知设置 | ✅ |
| `/me/settings/accessibility` | AccessibilitySettingsView | 大字/辅助 | ⏸️ 延迟 |
| `/me/settings/privacy` | PrivacySettingsView | 隐私设置 | ✅ |
| `/me/settings/security` | SecuritySettingsView | 账号安全 | ✅ |
| `/me/settings/about` | AboutSettingsView | 关于 | ✅ |
| `/me/membership` | MembershipView | 会员权益 | ⏸️ 后续迭代 |
| `/me/points` | PointsView | 积分明细 | ⏸️ 后续迭代 |
| `/me/family` | FamilyView | 家庭成员 | ✅ |
| `/me/policy` | PolicyView | 保单 | ⏸️ 后续迭代 |
| `/me/devices` | DevicesView | 设备管理 | ⏸️ 后续迭代 |
| `/me/health-report` | HealthReportView | 健康报告 | ✅ |
| `/me/medical-reports` | MedicalReportsView | 体检报告 | ⏸️ 后续迭代 |
| `/me/monitoring-plan` | MonitoringPlanView | 监测方案 | ⏸️ 后续迭代 |
| `/me/diet-plan` | DietPlanView | 饮食方案 | ⏸️ 后续迭代 |
| `/me/health-evaluations` | HealthEvaluationsView | 健康评估 | ⏸️ 后续迭代 |
| `/me/appointments` | AppointmentsView | 预约 | ⏸️ 后续迭代 |

### Mock 数据模型 (me.json)

```json
{
  "profile": { "name", "phone", "fundeId", "advisor", "avatar" },
  "membership": { "title", "level", "levelColor", "benefits" },
  "stats": [{ "label", "value", "accent", "route" }],
  "fulfillment": {
    "stats": [{ "label", "value", "accent", "route" }],
    "services": [{ "icon", "iconBg", "iconColor", "name", "status", "statusType", "detail", "route" }]
  },
  "functionGroups": [{
    "title": "健康管理",
    "rows": [{ "icon", "color", "label", "detail", "route" }]
  }]
}
```

## Adaptation Analysis

### 可直接适配

| funde element | iOS 方案 |
|--------------|---------|
| `fd-screen` scroll | `UIScrollView` in Tab page |
| Hero profile row | Horizontal `UIStackView` |
| Avatar circle | `UIView` + `layer.cornerRadius` (64×64) |
| Membership card | `UIView` in `fd-section`, tap → push |
| Stats strip (4 col) | `UIStackView` distribution `.fillEqually` |
| Service fulfillment stats + list | Stats row + `fd-func-row` style cells |
| Function groups | `fd-section` × N, each with `fd-card` + `fd-func-row` |
| Logout button | `UIButton` (red text, card style) |

### 需改造

| funde element | iOS 差异 | 方案 |
|--------------|---------|------|
| `--fd-gradient-hero` 暖色渐变 | 无 CSS gradient | Hero 背景用纯色 `UIColor.fdBg` + 顶部暖色 `UIView`（或 CAGradientLayer 延迟） |
| `mingcute` icon 图标 | 无 iconify | 用 SF Symbols 替代 |
| `van-nav-bar` / `van-cell-group` | 无 Vant | 自定义 topbar + cell |
| `van-tag` badge | 无 Vant | 自定义 `UILabel` badge |

### Deferred

- Hero 暖色渐变 → 暂用纯色背景
- 会员权益详情页 (MembershipView) → 后续迭代
- 积分明细 (PointsView) → 后续迭代
- 老年模式 → 全局延迟

## Decisions

### 1. Hub 页用 UITableViewController vs UIScrollView + UIStackView

**选择**: `UIScrollView` + 手动布局。原因：Hub 页内容多样（Hero、card、stats、function rows），Table View 需要处理多种 cell 类型的注册和复用，而 StackView 更直接，与 funde-client 的 `fd-section` 堆叠结构一致。

### 2. 功能列表行复用 fd-func-row 样式

**选择**: 沿用 funde-client 的 `fd-func-row` 样式（icon + label + detail + arrow），封装为 `FuncRowView` 组件。这与 RegisterLogin 模块的组件化思路一致。

### 3. Sub-pages 用 TableView

**选择**: Settings 等子页面用 `UITableViewController` + `.insetGrouped` style，与 iOS 原生设置风格一致。
