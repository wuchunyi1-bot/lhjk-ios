## Context

参考：

- `funde-client/prototype/src/views/me/MeView.vue`
- `funde-client/prototype/src/mock/me.json`
- `funde-client/docs/page-specs/me-hub.page.yaml`（部分字段落后于 Vue，以 Vue 为准）

当前 iOS Hub：`tableHeaderView`（Hero + 简版会员卡 + 统计条）+ Section「我的订单」履约 + Section「健康管理」8 行。

Vue 现行：Hero + 状态会员卡（无统计条）+ 常用功能宫格 + 健康管理 6 行 + 设置与支持 + 退出登录。

## Goals / Non-Goals

**Goals:**

- Hub 首页信息架构与交互对齐 Vue
- 会员卡按状态展示文案与 CTA（mock 默认 `not_opened`）
- 退出登录与设置页同等清理

**Non-Goals:**

- 不做 Vue「注销演示」按钮
- 不实现真实会员开通/支付 API
- 不改 Profile / Settings 子页 / 订单列表内部
- 不接真实订单/积分接口（仍 mock）

## Decisions

1. **以 MeView.vue 为准，不以过时 me-hub.page.yaml 的 fulfillment/stats 为准**（yaml 仍写履约与四格，Vue 已关 `showLegacyStats` 且未渲染 fulfillment）。
2. **地址路由**用 iOS 已有 `/me/address`，不用 Vue 的 `/me/settings/addresses`。
3. **会员开通**主按钮：`not_opened`/`expired` → push `/me/membership`（或占位 `/me/membership/open`）；`active`/`expiring` 卡片点击进权益，次按钮「升级/续费」「我的权益」。
4. **常用功能**用独立 Cell（4 列 × 2 行），放在 table 第一个 section。
5. **登出**抽与 Settings 相同清理顺序，避免 Hub 与设置行为不一致。

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| yaml 与 Vue 不一致 | Spec 明确「Vue 优先」 |
| 会员开通页未实现 | 先跳 membership / Placeholder |
| Hub 再放退出登录与设置重复 | 对齐 Vue；设置齿轮仍保留 |

## Migration Plan

改 ViewModel 数据源 → 改 Header/Sections → 编译验证。无数据迁移。

## Open Questions

- 无（开通页后续可单独 change）
