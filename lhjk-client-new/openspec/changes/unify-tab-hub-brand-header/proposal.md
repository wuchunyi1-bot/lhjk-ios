## Why

首页 / 健康 / 服务 / 消息四个 Tab 根页顶部都有「大标题 + 小字描述」，但字号（fdH2 / fdH3 / 硬编码 22）、左右边距（16 / 18）、相对安全区顶部间距不一致，切换 Tab 时顶栏视觉跳动。

## What Changes

- 抽取统一组件 `TabHubBrandHeaderView`
- 四 Tab 根页全部改用该组件；统一字号、边距、标题–副标题间距
- 首页标题色保持品牌橙（对齐 Vue）；其余 Tab 主标题为正文色

## Capabilities

### New Capabilities

- `tab-hub-brand-header`: Tab 根页品牌顶栏统一规范

### Modified Capabilities

- （无独立主 specs 变更归档；本 change 内 delta 即可）

## Impact

- 新增 `Other/Common/Components/TabHubBrandHeaderView.swift`
- `HomeViewController` / `HealthViewController` / `ServiceViewController` / `MessagesViewController`
- `ServiceHubHeaderView` 改为复用或薄封装
- `HomeBrandHeaderCell` 可不再参与首页布局
