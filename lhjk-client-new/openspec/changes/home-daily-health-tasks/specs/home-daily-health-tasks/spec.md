## ADDED Requirements

### Requirement: 首页今日健康任务区

系统 SHALL 在首页展示「今日健康任务」区块，对齐 funde-client `HomeView.vue`：进度摘要、最多三条任务行、「去完成」与进入详情入口；不展示积分。

#### Scenario: 区块标题

- **WHEN** 渲染任务区
- **THEN** 左侧标题「今日健康任务」
- **AND** 右侧「查看全部 ›」，点击进入 `/home/tasks`

#### Scenario: 进度摘要

- **WHEN** 存在今日任务
- **THEN** 卡片顶部展示「今日进度」与 `done / total`（total 为全日任务数）
- **AND** 展示进度条，宽度为 done/total 百分比
- **AND** 不展示积分文案

#### Scenario: 任务行（首页）

- **WHEN** 渲染任务列表
- **THEN** 最多展示 3 条
- **AND** 每行含：状态图标（完成打勾 / 未完成分类色块）、短标题、计划时间、分类标签
- **AND** 未完成显示「去完成」按钮；已完成显示「已完成」且标题可删除线样式
- **WHEN** 全日任务数大于 3
- **THEN** 卡片底部展示「查看全部 N 项任务」入口

#### Scenario: 去完成（首页）

- **WHEN** 用户点击未完成任务的「去完成」
- **THEN** 跳转该任务 `actionRoute`（无则 `/health/metrics`）
- **WHEN** 任务已完成
- **THEN** 不可再次触发去完成

#### Scenario: 空态

- **WHEN** 今日无任务
- **THEN** 展示轻量空态文案「今日暂无健康任务」

### Requirement: 今日健康任务详情页

系统 SHALL 提供路由 `/home/tasks` 的详情页，对齐 `DailyTasksView.vue` / `home-daily-tasks.page.yaml`。

#### Scenario: 导航

- **WHEN** 进入 `/home/tasks`
- **THEN** 导航标题为「今日健康任务」，支持返回
- **AND** 不显示底部 Tab Bar（push 二级页）

#### Scenario: 进度 Hero

- **WHEN** 页面加载
- **THEN** 顶部橙色渐变 Hero 展示「今日完成进度」、`done / total`、说明文案与进度条
- **AND** 不展示积分

#### Scenario: 任务详情卡片

- **WHEN** 渲染任务列表
- **THEN** 展示全部今日任务
- **AND** 每卡含：勾选态、标题、分类标签、去完成/已完成、描述、detailRows（标签-值）、完成状态、可选完成时间、可选「监测说明」多行文本

#### Scenario: 去完成（详情）

- **WHEN** 用户点击未完成任务「去完成」
- **THEN** 跳转 `actionRoute`
- **WHEN** 任务已完成
- **THEN** 展示「已完成」不可再点

#### Scenario: 温馨提示

- **WHEN** 页面底部
- **THEN** 展示温馨提示卡片，文案提示按时完成任务及不适时联系健管师

#### Scenario: 空态

- **WHEN** 无任务
- **THEN** 展示「暂无今日健康任务」
