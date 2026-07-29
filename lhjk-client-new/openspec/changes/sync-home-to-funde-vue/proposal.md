## Why

iOS 首页仍为旧「健康快照 Hero + 四快捷（录入体征/查看权益）+ 服务权益 Banner」结构；funde-client 现行 `HomeView.vue` 已改为「品牌头 + 轮播 Banner + 四快捷（就医协助/激活兑换）+ 会员健康服务一上二下 + 团队 + 任务 + 健康陪伴」，且 page-spec 明确不展示服务权益进度 banner。需对齐以免与原型/PRD 验收不一致。

## What Changes

- **首页信息架构**对齐现行 Vue：去掉健康快照 Hero、去掉服务权益 Banner；新增品牌标题区、Banner 轮播、会员健康服务区
- **快捷入口**改为：咨询健管师 / 预约体检 / 就医协助 / 激活兑换（路由对齐 Vue）
- **会员健康服务**：一主二副套餐卡 +「查看更多」→ `/services/membership`
- **权威优先级**：布局以 `HomeView.vue` 为准；`home.page.yaml` 中仍写健康快照但 Vue 已移除 → 本 change 按 Vue；yaml 中「不展示服务权益 banner」生效

## Capabilities

### New Capabilities

- （无独立新 capability 名；本 change 用 `home` delta）

### Modified Capabilities

- `home`: 首页区块结构、快捷入口、会员卡区与禁止项

## Impact

- `PL/Home/HomeViewController.swift`、`HomeViewModel.swift`
- 新增：`HomeBrandHeaderCell`、`HomeBannerCell`、`HomeMembershipCell`（或等效）
- 停用/移除首页对 `HomeHeroCell`、`HomeServiceBannerCell` 的引用（文件可暂留）
- 路由：注册 `/services/membership`、`/appointments/exams`（若缺失则占位或复用已有页）
- 参考：`HomeView.vue`、`home.page.yaml`、`home.json`、`docs/v0.1/modules/home.md`
