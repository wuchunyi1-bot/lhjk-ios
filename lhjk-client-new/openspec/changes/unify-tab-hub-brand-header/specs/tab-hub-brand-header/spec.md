## ADDED Requirements

### Requirement: Tab 根页品牌顶栏统一

首页、健康、服务、消息四个 Tab 根页顶部的「主标题 + 副标题」SHALL 使用同一组件与同一几何规范，保证切换 Tab 时字号与屏幕位置一致。

#### Scenario: 排版 Token

- **WHEN** 渲染任一 Tab 根页顶栏
- **THEN** 主标题字体为 `fdH2`（标准 22pt bold）
- **AND** 副标题为 12pt regular、颜色 `.fdSubtext`
- **AND** 主标题与副标题间距为 2pt
- **AND** 水平边距为 16pt

#### Scenario: 屏幕位置

- **WHEN** 页面布局完成（导航栏隐藏）
- **THEN** 顶栏贴齐 `safeAreaLayoutGuide.top`，其内主标题距该顶边 12pt
- **AND** 四 Tab 在相同设备上主标题基线/起始 y 一致（允许首页标题色为品牌橙）

#### Scenario: 文案与颜色

- **WHEN** 首页
- **THEN** 标题「富德联好健康」、副标题「健康生命 · 美好生活」、标题色 `.fdPrimary`
- **WHEN** 健康
- **THEN** 标题「我的健康」、副标题含档案完整度与风险等级、标题色 `.fdText`
- **WHEN** 服务
- **THEN** 标题「健康服务」、副标题「德系健康管理 · 9 大产品线」、标题色 `.fdText`
- **WHEN** 消息
- **THEN** 标题「消息」、副标题「您的健管团队 7×24 在线」、标题色 `.fdText`
