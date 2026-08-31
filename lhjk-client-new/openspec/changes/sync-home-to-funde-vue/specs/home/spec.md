## MODIFIED Requirements

### Requirement: 首页 Hub 信息架构

`/home` SHALL 按现行 `HomeView.vue` 区块顺序展示，并作为登录后默认 Tab。

#### Scenario: 区块顺序

- **WHEN** 用户进入首页
- **THEN** 自上而下依次为：
  1. 品牌头（「富德联好健康」+「健康生命 · 美好生活」）
  2. Banner 轮播（圆角卡片，多帧占位）
  3. 快捷入口四宫格卡片
  4. 会员健康服务（一主二副，可空则隐藏整区）
  5. 我的富德联好健康管家团队
  6. 今日健康任务
  7. 健康陪伴
- **AND** 导航栏隐藏，底部 Tab Bar 当前为首页

#### Scenario: 禁止项

- **WHEN** 渲染首页
- **THEN** 不展示健康快照 Hero（评分环 / 风险文案 / 四体征 chip）
- **AND** 不展示服务权益进度 Banner

### Requirement: 快捷入口

首页 SHALL 展示四个快捷入口，文案与路由对齐 Vue。

#### Scenario: 四入口

- **WHEN** 渲染快捷区
- **THEN** 依次为：
  - 咨询健管师 → `/messages`（可切换消息 Tab）
  - 预约体检 → `/appointments/exams`
  - 就医协助 → `/services/medical-assist`
  - 激活兑换 → `/activate`

### Requirement: 会员健康服务

首页 SHALL 展示最多 3 个会员综合服务套餐：一张主卡 + 两张并列小卡。

#### Scenario: 卡片内容与跳转

- **WHEN** 有套餐数据
- **THEN** 卡片展示名称、短介绍、底部「¥价格」+「元起」；推荐/热销角标在右上（无则不显示）
- **AND** 点击卡片进入 `/services/pkg`（携带套餐 id）
- **AND**「查看更多」进入 `/services/membership`

#### Scenario: 空态

- **WHEN** 无套餐
- **THEN** 整区不展示

### Requirement: 健管团队 / 今日任务 / 健康陪伴

团队、任务、文章区块 SHALL 保持列表展示；任务本期仅展示不提供打卡操作；文章详情可暂不跳转。

#### Scenario: 区块标题

- **WHEN** 渲染团队区
- **THEN** 标题「我的富德联好健康管家团队」，右侧「服务剩余 N 天 ›」
- **WHEN** 渲染任务区
- **THEN** 标题「今日健康任务」，右侧完成进度文案（如「已完成 1 / 3 · +10 分 ›」）
- **WHEN** 渲染文章区
- **THEN** 标题「健康陪伴」，右侧「更多 ›」
