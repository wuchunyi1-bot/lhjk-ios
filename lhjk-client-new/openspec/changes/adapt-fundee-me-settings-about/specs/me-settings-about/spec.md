## ADDED Requirements

### Requirement: 关于富德联好健康页

`/me/settings/about` SHALL 展示品牌、版本、评分入口、客服、版权与备案，对齐 PRD-213、`AboutSettingsView.vue` 与 `me-settings-about.page.yaml`。

#### Scenario: 页面结构

- **WHEN** 用户进入关于页
- **THEN** 导航标题为「关于富德联好健康」
- **AND** 品牌区居中展示：橙色渐变圆角 Logo（「富」）、标题「富德联好健康」、口号「健康生命 · 美好生活」
- **AND** 信息卡依次三行：
  - 当前版本 → 右侧版本号（`v` + Bundle 短版本）+ 箭头
  - 去应用市场评分 → 右侧「去评分」+ 箭头
  - 联系我们 → 右侧「400-888-6520」，无箭头
- **AND** 页脚居中展示「Copyright © 2026 富德联好健康」与「粤ICP备2023016723号-1」

#### Scenario: 当前版本点击

- **WHEN** 用户点击「当前版本」行
- **THEN** toast「当前已经是最新版本」

#### Scenario: 应用市场评分点击

- **WHEN** 用户点击「去应用市场评分」行
- **THEN** toast「暂无法打开应用市场」

#### Scenario: 联系我们只读

- **WHEN** 渲染「联系我们」行
- **THEN** 展示电话「400-888-6520」且不可点击（无拨号、无跳转）

#### Scenario: 禁止协议入口

- **WHEN** 渲染关于页
- **THEN** 不展示用户服务协议、隐私政策、知情同意书或其它协议入口
