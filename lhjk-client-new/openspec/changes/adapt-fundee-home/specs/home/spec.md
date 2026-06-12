# Home / 首页

## Purpose

定义「首页」Tab（Hub）的 UI 布局与交互行为。参考 funde-client `HomeView.vue` + `home.json`，通过 UIKit + SnapKit 适配到 iOS。

首页是 App 首个 Tab，使用 `hero-scroll` 布局（Hero 全宽渐变背景 + 下方内容滚动）。

> **Reference**: funde-client `prototype/src/views/home/HomeView.vue`、`prototype/src/mock/home.json`
> **Deferred**: 渐变背景用纯色替代、老年模式全局延迟

---

## Layout Architecture

```
┌──────────────────────────────────────────┐
│  Hero (fdPrimary 纯色背景替代渐变)         │
│  ┌──────────────────────────────────────┐│
│  │ 你好，李秀英            [富德健康] pill ││
│  │ 健管师 · 王顾问 | 服务剩 45 天         ││
│  ├──────────────────────────────────────┤│
│  │  ┌──────┐  中风险                    ││
│  │  │SCORE │  血压持续偏高...            ││
│  │  │  62  │                           ││
│  │  └──────┘                           ││
│  ├──────────────────────────────────────┤│
│  │ [血压138/88] [血糖5.8] [体重68.5] [心率76]││
│  └──────────────────────────────────────┘│
├──────────────────────────────────────────┤
│  Quick Actions (4 卡片，与 Hero 重叠)      │
│  [咨询健管师] [预约体检] [录入体征] [查看权益] │
├──────────────────────────────────────────┤
│  Section: 我的富德健康管家团队              │
│  3 行：张建国(医师) / 陈梅(营养师) / 王顾问(健管师) │
│  每行：avatar + online dot + name + title + 发消息 btn │
├──────────────────────────────────────────┤
│  Section: 今日健康任务                     │
│  3 任务：check circle + title + desc + pts │
├──────────────────────────────────────────┤
│  Service Progress Banner                 │
│  "德好·慢病逆转管理" + 进度条 + 剩45天      │
├──────────────────────────────────────────┤
│  Section: 健康陪伴                        │
│  5 文章：占位图 + tag + title + author     │
└──────────────────────────────────────────┘
```

---

## Requirements

### Requirement: Tab Integration
SHALL 作为 App 第一个 Tab，导航栏首页隐藏。

#### Scenario: Tab 位置
- **WHEN** Tab Bar 渲染
- **THEN** 第一个 Tab 标题为"首页"，SF Symbol 为 `house`

#### Scenario: 导航栏
- **WHEN** HomeViewController 渲染
- **THEN** `navigationController?.setNavigationBarHidden(true)`

---

### Requirement: Hero Section
SHALL 展示品牌色 Hero 区域（`fdPrimary` 纯色 bg，渐变延迟）。

#### Scenario: Topbar
- **WHEN** Hero 渲染
- **THEN** 左侧: "你好，{name}"（22pt white semibold）+ "健管师 · {advisor} | 服务剩 {N} 天"（12pt white 0.85）
- **THEN** 右侧: "富德健康" pill（半透明白底 + 白字，圆角 999）

#### Scenario: Health Score Ring
- **WHEN** Hero 渲染
- **THEN** 86×86pt 半透明白圆环 + "SCORE" 微标签 + 数字 "62" (38pt white bold mono)
- **THEN** 右侧: 风险 badge（橙黄底 "中风险"）+ 提示文字 (14pt white)

#### Scenario: Metric Chips
- **WHEN** Hero 渲染
- **THEN** 4 列等宽 chip：label + status + value + unit，半透明白底，圆角 14pt
- **THEN** warning chip 背景稍亮（0.22 vs 0.18 透明度）

---

### Requirement: Quick Actions
SHALL 展示 4 个快捷入口卡片（与 Hero 底部重叠 -6pt）。

| icon (SF Symbol) | label | bgColor | fgColor | route |
|-----------------|-------|---------|---------|-------|
| `bubble.left.and.bubble.right` | 咨询健管师 | `#FFF3EE` | `#FF7A50` | `/messages` |
| `calendar.badge.clock` | 预约体检 | `#EAF3FF` | `#3D6FB8` | `/appointments/exams` |
| `heart` | 录入体征 | `#E6F7EF` | `#1F9A6B` | `/health/metrics` |
| `gift` | 查看权益 | `#FFF3DC` | `#B47300` | `/me/membership` |

---

### Requirement: Health Team
SHALL 展示 3 行健管团队成员。

#### Scenario: Team Member Row
- **WHEN** 行渲染
- **THEN**: 左侧 46×46pt 角色色头像 + 绿色在线点（11pt），中间姓名(15pt bold) + 职称(11pt) + 专长标签 + 在线状态，右侧 "发消息" pill 按钮

#### Scenario: 发消息
- **WHEN** 点击发消息
- **THEN** push `/conversations/conv-00{N}`

---

### Requirement: Today's Tasks
SHALL 展示 3 个今日健康任务。

#### Scenario: Task Row
- **WHEN** 行渲染
- **THEN**: 左侧 26pt check circle（未完成=灰圈，已完成=绿底✓）+ title(14pt bold) + desc(11pt) + 右侧积分 badge

#### Scenario: 完成任务样式
- **WHEN** task.done = true
- **THEN** title 添加删除线并变灰，check circle 变绿底白✓，积分 badge 变绿底绿字

---

### Requirement: Service Banner
SHALL 展示"德好·慢病逆转管理"服务进度条。

#### Scenario: Banner
- **WHEN** 渲染
- **THEN** 暖色背景（`#FFE7D9`）+ "进行中" tag + title(17pt bold) + desc + 进度条(5/12) + "剩 45 天"

---

### Requirement: Health Articles
SHALL 展示 5 篇健康文章列表。

#### Scenario: Article Row
- **WHEN** 行渲染
- **THEN**: 左侧 84×84pt 占位图 + 右侧 tag badge + title(14pt) + author · readCount(11pt muted)

---

## States

| State | 表现 |
|-------|------|
| **默认** | Mock 数据渲染全部 6 个区域 |
| **滚动** | Hero 下方内容在 UIScrollView 中滚动 |

## Acceptance Checklist

- [ ] Tab 栏第一个"首页"Tab，导航栏隐藏
- [ ] Hero: topbar + score ring + 4 metric chips
- [ ] Quick Actions: 4 入口与 Hero 底部重叠
- [ ] Team: 3 成员行（头像 + online 点 + 发消息按钮）
- [ ] Tasks: 3 任务（check circle + 积分 badge，完成/未完成样式区）
- [ ] Service banner: 进度条 + 天数
- [ ] Articles: 5 篇文章行
- [ ] 所有颜色通过 `UIColor.fd*` Token
