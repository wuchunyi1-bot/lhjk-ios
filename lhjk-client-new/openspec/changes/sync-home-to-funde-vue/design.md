## Context

- Vue 现行首页：品牌头 → Banner 轮播 → 快捷四宫格 → 会员健康服务（1+2）→ 团队 → 今日任务 → 健康陪伴
- iOS 仍为 adapt-fundee-home 旧稿（健康快照 + 旧快捷 + 服务 Banner）
- page-spec `scope.out`：服务权益进度 banner；任务仅展示不操作

## Goals / Non-Goals

**Goals:**

- UI/区块顺序/文案/快捷路由与 `HomeView.vue` 一致
- 会员区 mock 展示前 3 条（一主二副）；点击进 `/services/pkg` + id
- 去掉服务权益 Banner 与健康快照 Hero

**Non-Goals:**

- 首页聚合真实 API（仍 mock，对齐 home.json / 会员 mock）
- 文章详情、任务打卡、实时在线状态
- 不改其它 Tab

## Decisions

1. **权威**：布局以 Vue 为准；与 yaml 冲突时（健康快照）跟 Vue。
2. **Banner**：原型为四色占位轮播（橙/蓝/绿/紫），iOS 用 `UIScrollView`/`UIPageControl` 或简易 timer 轮播；高度 140、圆角 18。
3. **快捷路由**：`/messages`（切 Tab）、`/appointments/exams`、`/services/medical-assist`、`/activate`；缺路由则注册占位/WebView。
4. **会员更多**：`/services/membership` → 占位或已有会员相关页（优先 Placeholder「会员专区」若无专页）。
5. **数据**：团队/任务/文章继续用现有 mock；会员三条用本地 mock（名称/简介/价格/角标）。
6. **Hero/ServiceBanner Cell**：从 DataSource 移除；源文件可不删以免无用改 pbxproj。

## Risks / Trade-offs

- [预约体检无原生页] → 注册到现有 `/web/appointments` 或同 WebView
- [会员专区未做] → Placeholder，不阻塞首页布局

## Open Questions

- 无（聚合 API 后续另 change）
