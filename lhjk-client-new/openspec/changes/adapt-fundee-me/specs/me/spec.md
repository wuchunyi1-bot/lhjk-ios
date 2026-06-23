# Me / 我的

## Purpose

定义「我的」Tab 页面（Hub）的 UI 布局、交互行为。参考 funde-client `MeView.vue` + `me.json`，通过 UIKit + SnapKit 适配到 iOS 项目。

页面是 App 第五个 Tab，使用 `hero-scroll` 布局，从上到下分为：Hero 区 → 会员卡 → 统计条 → 服务履约 → 功能列表（健康管理）。

> **Reference**: funde-client `prototype/src/views/me/MeView.vue`、`prototype/src/mock/me.json`

---

## Layout Architecture

**实现方案**: `UITableView` (grouped style / plain)，利用 section 分割不同区块，tableHeaderView 承载完整的 Hero 区（用户信息 + 会员卡 + 统计条）。

> **变更 (2026-06-17)**: 将 `MeMembershipCardCell` 和 `MeStatsStripCell` 的内容合并进 `tableHeaderView`，移除这两个 Cell 对应的 section。减少 section 数量，简化布局层级。
>
> **变更 (2026-06-23)**: "账号与设置"、"关于" 分组和退出登录按钮从首页移除，移至「设置」二级页面。首页仅保留服务履约 + 健康管理 2 个 section，匹配 funde-client 原型结构。

```
┌──────────────────────────────────────────────┐
│  UITableView (fdBg background)               │
│  ┌──────────────────────────────────────────┐ │
│  │ tableHeaderView: Hero + Card + Stats    │ │
│  │                              [⚙ 设置]   │ │
│  │  ┌──────┐  用户名                        │ │
│  │  │ 头像 │  [编辑资料]  [健康档案]        │ │
│  │  └──────┘                               │ │
│  │  ┌──────────────────────────────────┐   │ │
│  │  │ 会员卡入口 (原 MeMembershipCard)    │   │ │
│  │  └──────────────────────────────────┘   │ │
│  │  ┌──────────────────────────────────┐   │ │
│  │  │ 统计条 (原 MeStatsStrip)          │   │ │
│  │  └──────────────────────────────────┘   │ │
│  ├──────────────────────────────────────────┤ │
│  │ Section 0: Service Fulfillment (1 row)  │ │
│  │ sectionHeader: "我的订单    全部订单 ›"   │ │
│  │ MeServiceFulfillmentCell                │ │
│  ├──────────────────────────────────────────┤ │
│  │ Section 1: Health Management (7 rows)   │ │
│  │ sectionHeader: "健康管理"                │ │
│  │ MeFuncRowCell × 7                       │ │
│  └──────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘
```

**Cell 注册**:
| Cell Class | Reuse ID | Section(s) |
|-----------|----------|------------|
| `MeServiceFulfillmentCell` | `MeServiceFulfillmentCell` | 0 |
| `MeFuncRowCell` | `MeFuncRowCell` | 1 |

> `MeMembershipCardCell` 和 `MeStatsStripCell` 不再作为独立 Cell 使用，其内容合并到 tableHeaderView 中。

---

## Requirements

### Requirement: Tab Integration
「我的」SHALL 作为 App 第五个 Tab 展示在 RootTabBarController 中。

#### Scenario: Tab 图标与标题
- **WHEN** Tab Bar 渲染
- **THEN** 「我的」tab 标题为"我的"，SF Symbol 为 `person.crop.circle`

#### Scenario: 页面容器
- **WHEN** MyViewController 渲染
- **THEN** 使用 `fd-screen` 对应的布局（UIScrollView，背景色 `UIColor.fdBg`），嵌入在 Tab 中而非全屏 modal

---

### Requirement: Navigation Bar Visibility
「我的」首页 SHALL 隐藏系统导航栏，子页面 SHALL 显示导航栏。

#### Scenario: 首页隐藏导航栏
- **WHEN** MyViewController（我的首页 Hub）渲染
- **THEN** `navigationController?.isNavigationBarHidden = true`，利用 Hero 区域的顶部 padding 替代导航栏空间

#### Scenario: 子页面显示导航栏
- **WHEN** 从首页 push 到任意子页面（设置、个人信息、保单等）
- **THEN** `navigationController?.isNavigationBarHidden = false`，子页面的 `BaseViewController` 使用系统导航栏或自定义 topbar

#### Scenario: 返回首页恢复隐藏
- **WHEN** 从子页面 pop 回到首页
- **THEN** 在 `viewWillAppear` 中重新设置 `isNavigationBarHidden = true`

---

### Requirement: Hero Section (tableHeaderView)
顶部 tableHeaderView SHALL 包含完整的用户信息区、会员卡入口和统计条，作为统一的 Hero 区域。右上角 SHALL 展示设置入口按钮。

#### Scenario: 设置按钮（右上角）
- **WHEN** 页面渲染 Hero 区
- **THEN** 右上角展示设置齿轮按钮：32×32pt 圆形、半透明白底 `rgba(255,255,255,0.6)`、SF Symbol `gearshape`、tintColor `.fdText`
- **AND** 按钮触控区域 ≥ 44×44pt
- **AND** 按钮位于安全区域顶部下方，与头像区域顶部对齐

#### Scenario: 头像
- **WHEN** 页面渲染 Hero 区
- **THEN** 左侧展示 64×64pt 圆形头像，背景色 `#F4ECE3`，文字色 `#7B5E40`，显示用户名首字（22pt bold）

#### Scenario: 用户名
- **WHEN** 页面渲染 Hero 区
- **THEN** 头像右侧展示用户名（20pt bold `UIColor.fdText`）

#### Scenario: 快捷操作按钮
- **WHEN** 页面渲染 Hero 区
- **THEN** 用户名列下方展示两个 pill 按钮：
  - "编辑资料"：半透明白底 + 边框 + `chevron.right` icon → push `/me/profile`
  - "健康档案"：品牌色底白字 + `heart` icon → push `/me/health-profile`

#### Scenario: Hero 顶部间距
- **WHEN** 页面渲染
- **THEN** Hero profile 区顶部与 safe area top 间距约 52pt（预留状态栏）

#### Scenario: 渐变背景
- **WHEN** 页面渲染 Hero 区
- **THEN** 整个 tableHeaderView 使用暖色渐变背景：`#FFF7F1` → `#FFE9DC`，135° 对角方向（CAGradientLayer）

---

### Requirement: Membership Card (in tableHeaderView)
Hero 区下方 SHALL 在 tableHeaderView 内展示会员卡入口卡片。

#### Scenario: 卡片样式
- **WHEN** 页面渲染
- **THEN** 展示圆角卡片（`fd-radius-md`），暖色背景（`#FFF7F1`），1pt 品牌色 20% 透明度描边
- **AND** 卡片左右间距 16pt，与上方用户信息区间距 16pt

#### Scenario: 卡片内容
- **WHEN** 会员卡渲染
- **THEN** 左侧显示「会员中心」标题（12pt subtext）+ 会员等级（13pt bold，品牌色），右侧显示「查看更多 ›」

#### Scenario: 点击跳转
- **WHEN** 用户点击会员卡
- **THEN** push `/me/membership` 页面

---

### Requirement: Stats Strip (in tableHeaderView)
会员卡下方 SHALL 在 tableHeaderView 内展示 4 列统计数据。

#### Scenario: 统计列
- **WHEN** 页面渲染统计条
- **THEN** 4 列等宽显示：健康积分（892，品牌色突出）、家庭成员（4）、我的保单（2）、健康等级（Lv.3）。数值使用系统字体 22pt bold，标签 11pt subtext。列间用 1pt 分割线
- **AND** 卡片左右间距 16pt，与上方会员卡间距 12pt

#### Scenario: 点击跳转
- **WHEN** 用户点击某统计列
- **THEN** 跳转到对应子页面（`/me/points`、`/me/family`、`/me/policy`、`/me/membership`）

---

### Requirement: Service Fulfillment Section
统计条下方 SHALL 展示「我的订单」区块。

#### Scenario: 区块标题
- **WHEN** 渲染服务履约区块
- **THEN** 左侧标题「我的订单」（14pt subtext bold），右侧「全部订单 ›」（可点击 → push `/orders`）

#### Scenario: 数字统计
- **WHEN** 渲染服务履约卡
- **THEN** 4 列等宽展示：待使用（2，品牌色）、使用中（1）、已完成（3）、待评价（1）。数值 22pt bold monospace，标签 11pt subtext

#### Scenario: 服务列表行
- **WHEN** 存在进行中的服务
- **THEN** 每行展示：左侧 icon（40×40pt 圆角方块，自定义背景色 + 文字/图标）、服务名（13pt bold）+ 状态 badge、描述文字（11pt subtext）、右侧 `chevron.right` arrow

#### Scenario: 状态 Badge
- **WHEN** 服务有状态
- **THEN** 使用 `fd-badge-success` 风格（绿底绿字）展示「进行中」，`fd-badge-warning` 风格（黄底黄字）展示「待使用」

---

### Requirement: Health Management Function Group
服务履约下方 SHALL 展示「健康管理」功能列表分组。

#### Scenario: 分组标题
- **WHEN** 渲染功能分组
- **THEN** 分组上方有 `fd-section-title`：标题"健康管理"（14pt subtext bold）

#### Scenario: 功能行
- **WHEN** 渲染功能行
- **THEN** 每行展示（`fd-func-row` 样式）：
  - 左侧 icon 方块（32×32pt，圆角 10pt，自定义背景色 10% 透明度 + 前景色）
  - 主标签（15pt `fdText`）
  - 右侧副文字（12pt `fdMuted`，可选）
  - `chevron.right` arrow

#### Scenario: 点击跳转
- **WHEN** 用户点击某功能行
- **THEN** push 到对应子页面路由

#### Scenario: 健康管理分组 (7 items)
| icon (SF Symbol) | label | detail |
|-----------------|-------|--------|
| `doc.text` | 健康档案 | 完整度 72% |
| `heart.text.square` | 健康报告 | 周报 / 阶段小结 |
| `cross.case` | 体检报告单 | 3 份已上传 |
| `calendar` | 监测方案 | 当前方案生效中 |
| `fork.knife` | 饮食方案 | 可按档案生成 |
| `checklist` | 健康评估 | 2 项待完成 |
| `clock` | 我的预约 | 1 个待到店 |

---

### Requirement: Settings Entry
「我的」首页 SHALL 通过 Hero 区右上角设置齿轮按钮进入「设置」页面。账号与设置相关功能（账号安全、隐私、通知、长辈版、缓存、合规清单、关于、退出登录）集中在设置二级页面中。

#### Scenario: 进入设置
- **WHEN** 用户点击 Hero 区右上角设置齿轮按钮
- **THEN** push `/me/settings`（SettingsViewController）

---

## Settings Page Spec

「设置」页面（`/me/settings`）SHALL 使用 UIScrollView + 卡片式布局，按以下分组展示：

### Card 1: 账号与隐私
- 「账号安全」行 → push `/me/settings/security`
- 「隐私设置」行 → push `/me/settings/privacy`

### Card 2: 通知与显示
- 「消息通知」行 → push `/me/settings/notifications`
- 「长辈版」行 — UISwitch toggle，切换全局适老化模式，开关状态持久化到 UserDefaults，切换时 Toast 提示
- 「清理缓存」行 — 展示当前缓存大小，点击清理并 Toast 提示成功

### Card 3: 合规清单
- 「个人信息收集清单」行 → 弹出 dialog 展示清单内容
- 「第三方信息共享清单」行 → 弹出 dialog 展示清单内容

### Card 4: 关于
- 「关于我们」行 → push `/me/settings/about`

### Bottom: 退出登录
- 红色描边 pill 按钮，全宽，点击后二次确认弹窗
- 确认后清理登录态并跳转登录页

---

### Requirement: Mock Data
页面暂用 mock 数据渲染（与 funde-client `me.json` 一致），不做网络请求。

#### Scenario: 用户信息
- **WHEN** 页面加载
- **THEN** 显示 mock 用户：姓名"李秀英"、头像首字"英"、等级"健康大会员"

---

## Component Inventory

| Component | Type | funde ref | 说明 |
|-----------|------|-----------|------|
| `tableHeaderView` | UIView | `me-hero` + membership-card + me-stats | Hero 区 + 会员卡 + 统计条（合并为一个 header view） |
| `MeServiceFulfillmentCell` | UITableViewCell | me-svc-section | 服务履约区块 |
| `MeFuncRowCell` | UITableViewCell | `fd-func-row` | 通用功能行（icon + label + detail + arrow） |
| `SectionTitleView` | UIView | `fd-section-title` | 区块标题行（复用，作为 section header） |

> `MeMembershipCardCell` 和 `MeStatsStripCell` 不再作为独立 Cell 使用，保留文件以备后续需要。

---

## Sub-Pages

### 已实现

| Page | Route | 说明 |
|------|-------|------|
| `SettingsViewController` | `/me/settings` | 设置主页（卡片式布局：账号安全、隐私、通知、长辈版、缓存、清单、关于、退出登录） |
| `NotificationSettingsViewController` | `/me/settings/notifications` | 消息通知设置（4 个开关行） |
| `AccessibilitySettingsViewController` | `/me/settings/accessibility` | 大字显示与简洁操作（Hero 卡片 + 4 个开关行） |
| `PrivacySettingsViewController` | `/me/settings/privacy` | 隐私设置（系统权限 + 业务授权开关） |
| `SecuritySettingsViewController` | `/me/settings/security` | 账号安全（状态卡片 + 手机号/密码/认证/设备） |
| `AboutSettingsViewController` | `/me/settings/about` | 关于（Logo + 版本 + 协议/客服/备案链接） |
| `ProfileViewController` | `/me/profile` | 个人信息（avatar + 字段列表） |
| `PolicyViewController` | `/me/policy` | 我的保单列表（卡片式、含关联权益） |
| `HealthReportViewController` | `/me/health-report` | 健康报告（Tab 切换周报/阶段小结，含报告卡片） |
| `AppointmentsViewController` | `/me/appointments` | 我的预约（Tab 切换即将到来/历史记录） |
| `DevicesViewController` | `/me/devices` | 我的设备（已配对列表 + 解绑 + 添加设备入口 + 连接说明） |
| `DietPlanViewController` | `/me/diet-plan` | 饮食方案（热量推荐 + 营养占比 + 三餐列表） |
| `MonitoringPlanViewController` | `/me/monitoring-plan` | 监测方案（当前方案 + AI/模板切换 + 监测项列表） |
| `HealthEvaluationsViewController` | `/me/health-evaluations` | 健康评估（待完成提示条 + 评估卡片列表） |
| `FamilyViewController` | `/me/family` | 家庭成员列表 + 添加 |
| `MembershipViewController` | `/me/membership` | 会员权益详情 + 升级套餐（占位） |
| `PointsViewController` | `/me/points` | 积分明细列表（占位） |

### 延迟实现

| Page | Route | funde 参考 |
|------|-------|-----------|
| HealthProfileView | `/me/health-profile` | 健康档案详情（人体图 + 风险 + 指标 + 生活习惯） |
| MedicalReportsView | `/me/medical-reports` | 体检报告单列表 |
| CancelAccountView | `/me/settings/cancel-account` | 注销账户流程 |
| ChangePhoneView | `/me/change-phone` | 更换手机号流程 |
| AddressListView | `/me/address` | 收货地址列表 + 编辑 |

---

## States

| State | 表现 |
|-------|------|
| **默认** | Mock 数据渲染完整 Hub，UITableView 2 sections + tableHeaderView |
| **空态** | 无（Hub 页不涉及数据加载空态） |
| **加载** | 暂不需要（纯 mock） |

## Acceptance Checklist

- [ ] Tab 栏第五个「我的」Tab 正确展示
- [ ] UITableView 2 sections + tableHeaderView 结构渲染完整
- [ ] 首页导航栏隐藏，子页面导航栏显示（push 进入显示、pop 返回隐藏）
- [ ] tableHeaderView — Hero 区暖色渐变背景、头像、用户名、右上角设置按钮、编辑资料/健康档案按钮
- [ ] tableHeaderView — 会员卡入口卡片（品牌色描边、等级显示、点击跳转）
- [ ] tableHeaderView — 4 列统计条（积分/家庭/保单/等级）等宽 + 分割线 + 可点击跳转
- [ ] Section 0 — 我的订单区：4 数字统计 + 服务行（icon + badge + arrow）
- [ ] Section 1 — 健康管理分组 7 行（MeFuncRowCell）
- [ ] 原"账号与设置"、"关于"分组和退出登录已移至设置页面
- [ ] 设置页 — 4 张卡片布局：账号与隐私 / 通知与显示 / 合规清单 / 关于
- [ ] 设置页 — 长辈版 toggle 可切换并 Toast 提示
- [ ] 设置页 — 清理缓存可点击并 Toast 提示
- [ ] 设置页 — 合规清单点击弹出 dialog
- [ ] 设置页 — 退出登录按钮 + 二次确认弹窗
- [ ] 所有颜色通过 `UIColor.fd*` Token 引用
- [ ] 可点击行 push 到对应子页面
