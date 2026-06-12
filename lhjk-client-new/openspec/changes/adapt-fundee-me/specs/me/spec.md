# Me / 我的

## Purpose

定义「我的」Tab 页面（Hub）的 UI 布局、交互行为。参考 funde-client `MeView.vue` + `me.json`，通过 UIKit + SnapKit 适配到 iOS 项目。

页面是 App 第五个 Tab，使用 `hero-scroll` 布局，从上到下分为：Hero 区 → 会员卡 → 统计条 → 服务履约 → 功能列表分组 → 退出登录。

> **Reference**: funde-client `prototype/src/views/me/MeView.vue`、`prototype/src/mock/me.json`

---

## Layout Architecture

```
┌──────────────────────────────────────────────┐
│  UIScrollView (fdBg background)              │
│  ┌────────────────────────────────────────────┐
│  │  Hero Section                             │
│  │  ┌──────┐  用户名          [⚙ settings]   │
│  │  │ 头像 │  [编辑资料]  [健康档案]           │
│  │  └──────┘                                 │
│  ├────────────────────────────────────────────┤
│  │  Membership Card                          │
│  │  会员中心 · 等级                   查看更多 ›│
│  ├────────────────────────────────────────────┤
│  │  Stats Strip (4 equally-spaced columns)    │
│  │  892  |  4   |  2   |  Lv.3              │
│  │  健康积分|家庭成员|我的保单|健康等级          │
│  ├────────────────────────────────────────────┤
│  │  Section: 服务履约                         │
│  │  [待使用] [使用中] [已完成] [待评价]        │
│  │  ┌ ServiceRow (icon + name + badge + ›)┐  │
│  │  └ ServiceRow ...                      ┘  │
│  ├────────────────────────────────────────────┤
│  │  Section: 健康管理                         │
│  │  ┌ FuncRow (icon + label + detail + ›) ┐  │
│  │  └ FuncRow ... (7 items)               ┘  │
│  ├────────────────────────────────────────────┤
│  │  Section: 账号与设置                       │
│  │  ┌ FuncRow (icon + label + detail + ›) ┐  │
│  │  └ FuncRow ... (4 items)               ┘  │
│  ├────────────────────────────────────────────┤
│  │  Section: 关于                             │
│  │  ┌ FuncRow (icon + label + detail + ›) ┐  │
│  │  └ FuncRow ... (3 items)               ┘  │
│  ├────────────────────────────────────────────┤
│  │  [退出登录] (card style, red text)         │
│  └────────────────────────────────────────────┘
└──────────────────────────────────────────────┘
```

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

### Requirement: Hero Section
顶部 SHALL 展示用户头像、昵称、设置按钮和快捷操作入口。

#### Scenario: 头像
- **WHEN** 页面渲染 Hero 区
- **THEN** 左侧展示 64×64pt 圆形头像，背景色 `#F4ECE3`，文字色 `#7B5E40`，显示用户名首字（22pt bold）

#### Scenario: 用户名 + 设置按钮
- **WHEN** 页面渲染 Hero 区
- **THEN** 头像右侧展示用户名（20pt bold `UIColor.fdText`），右侧展示设置齿轮按钮（32×32pt 圆形，半透明白底，SF Symbol `gearshape` 18pt）

#### Scenario: 快捷操作按钮
- **WHEN** 页面渲染 Hero 区
- **THEN** 用户名列下方展示两个 pill 按钮：
  - "编辑资料"：半透明白底 + 边框 + `chevron.right` icon → push `/me/profile`
  - "健康档案"：品牌色底白字 + `heart` icon → push `/me/health-profile`

#### Scenario: Hero 顶部间距
- **WHEN** 页面渲染
- **THEN** Hero profile 区顶部与 safe area top 间距约 52pt（预留状态栏）

---

### Requirement: Membership Card
Hero 区下方 SHALL 展示会员卡入口卡片。

#### Scenario: 卡片样式
- **WHEN** 页面渲染
- **THEN** 展示圆角卡片（`fd-radius-md`），暖色渐变背景（`#FFF7F1` → `#FFE9DC`，暂用纯色 `#FFF7F1`），1pt 品牌色 20% 透明度描边

#### Scenario: 卡片内容
- **WHEN** 会员卡渲染
- **THEN** 左侧显示「会员中心」标题（12pt subtext）+ 会员等级（13pt bold，品牌色），右侧显示「查看更多 ›」

#### Scenario: 点击跳转
- **WHEN** 用户点击会员卡
- **THEN** push `/me/membership` 页面

---

### Requirement: Stats Strip
会员卡下方 SHALL 展示 4 列统计数据。

#### Scenario: 统计列
- **WHEN** 页面渲染统计条
- **THEN** 4 列等宽显示：健康积分（892，品牌色突出）、家庭成员（4）、我的保单（2）、健康等级（Lv.3）。数值使用 monospace 字体 22pt bold，标签 11pt subtext。列间用 1pt 分割线

#### Scenario: 点击跳转
- **WHEN** 用户点击某统计列
- **THEN** 跳转到对应子页面（`/me/points`、`/me/family`、`/me/policy`、`/me/membership`）

---

### Requirement: Service Fulfillment Section
统计条下方 SHALL 展示「服务履约」区块。

#### Scenario: 区块标题
- **WHEN** 渲染服务履约区块
- **THEN** 左侧标题「服务履约」（14pt subtext bold），右侧「全部订单 ›」（可点击 → push `/orders`）

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

### Requirement: Function Groups
服务履约下方 SHALL 展示三个功能列表分组（健康管理、账号与设置、关于）。

#### Scenario: 分组标题
- **WHEN** 渲染功能分组
- **THEN** 每个分组上方有 `fd-section-title`：标题（14pt subtext bold）

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

#### Scenario: 账号与设置分组 (4 items)
| icon (SF Symbol) | label | detail |
|-----------------|-------|--------|
| `bell` | 消息通知 | 已开启 |
| `textformat.size` | 显示与辅助 | 大字 / 简洁操作 |
| `hand.raised` | 隐私与权限 | — |
| `lock.shield` | 账号安全 | — |

#### Scenario: 关于分组 (3 items)
| icon (SF Symbol) | label | detail |
|-----------------|-------|--------|
| `headphones` | 帮助中心 · 7×24 客服 | — |
| `info.circle` | 关于富德健康 | — |
| `checkmark.circle` | 当前版本 | v 2.6.1 |

---

### Requirement: Logout Button
页面底部 SHALL 展示退出登录按钮。

#### Scenario: 按钮样式
- **WHEN** 页面渲染
- **THEN** 全宽卡片式按钮：白色背景 + 圆角 18pt + 卡片阴影，红色文字「退出登录」（16pt medium），居中

#### Scenario: 点击退出
- **WHEN** 用户点击退出登录
- **THEN** 弹出确认弹窗，确认后跳转登录页（`fullScreen` present `LoginViewController`）

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
| `MeHeroView` | UIView | `me-hero` + `me-hero__profile` | Hero 区（头像 + 名称 + 按钮行） |
| `MembershipCardView` | UIView | `membership-card` | 会员卡入口 |
| `MeStatsView` | UIView | `me-stats` | 4 列统计条 |
| `FuncRowView` | UIView | `fd-func-row` | 通用功能行（icon + label + detail + arrow） |
| `ServiceRowView` | UIView | `me-svc-row` | 服务履约行 |
| `SectionTitleView` | UIView | `fd-section-title` | 区块标题行 |

---

## Sub-Pages (本次实现)

### 已实现

| Page | Route | 说明 |
|------|-------|------|
| `SettingsViewController` | `/me/settings` | 分组设置列表（通知/隐私/安全/关于/退出登录） |
| `ProfileViewController` | `/me/profile` | 个人信息（avatar + 字段列表） |
| `PolicyViewController` | `/me/policy` | 我的保单列表（卡片式、含关联权益） |
| `HealthReportViewController` | `/me/health-report` | 健康报告（Tab 切换周报/阶段小结，含报告卡片） |
| `AppointmentsViewController` | `/me/appointments` | 我的预约（Tab 切换即将到来/历史记录） |
| `DevicesViewController` | `/me/devices` | 我的设备（已配对列表 + 解绑 + 添加设备入口 + 连接说明） |
| `DietPlanViewController` | `/me/diet-plan` | 饮食方案（热量推荐 + 营养占比 + 三餐列表） |
| `MonitoringPlanViewController` | `/me/monitoring-plan` | 监测方案（当前方案 + AI/模板切换 + 监测项列表） |
| `HealthEvaluationsViewController` | `/me/health-evaluations` | 健康评估（待完成提示条 + 评估卡片列表） |

### 延迟实现

| Page | Route | funde 参考 |
|------|-------|-----------|
| FamilyView | `/me/family` | 家庭成员列表 + 添加 |
| MembershipView | `/me/membership` | 会员权益详情 + 升级套餐 |
| PointsView | `/me/points` | 积分明细列表 |
| HealthProfileView | `/me/health-profile` | 健康档案详情（人体图 + 风险 + 指标 + 生活习惯） |
| MedicalReportsView | `/me/medical-reports` | 体检报告单列表 |
| NotificationSettingsView | `/me/settings/notifications` | 通知设置 |
| PrivacySettingsView | `/me/settings/privacy` | 隐私设置 |
| SecuritySettingsView | `/me/settings/security` | 账号安全 |
| AboutSettingsView | `/me/settings/about` | 关于 |
| AccessibilitySettingsView | `/me/settings/accessibility` | 大字显示（老年模式延迟） |

---

## States

| State | 表现 |
|-------|------|
| **默认** | Mock 数据渲染完整 Hub |
| **空态** | 无（Hub 页不涉及数据加载空态） |
| **加载** | 暂不需要（纯 mock） |

## Acceptance Checklist

- [ ] Tab 栏第五个「我的」Tab 正确展示
- [ ] 首页导航栏隐藏，子页面导航栏显示（push 进入显示、pop 返回隐藏）
- [ ] Hero 区头像、用户名、设置按钮、编辑资料/健康档案按钮
- [ ] 会员卡入口卡片（品牌色描边、等级显示）
- [ ] 4 列统计条（积分/家庭/保单/等级）等宽 + 分割线
- [ ] 服务履约区：4 数字统计 + 服务行（icon + badge + arrow）
- [ ] 健康管理分组 7 行功能列表
- [ ] 账号与设置分组 4 行功能列表
- [ ] 关于分组 3 行功能列表
- [ ] 退出登录按钮 + 确认弹窗
- [ ] 所有颜色通过 `UIColor.fd*` Token 引用
- [ ] 可点击行 push 到对应子页面（保单/报告/预约/设备/方案/评估 + toast 占位）
