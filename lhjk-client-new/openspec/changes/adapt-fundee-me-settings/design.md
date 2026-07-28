## Context

对齐：

- PRD：`02_用户_我的设置_v1.0` §5.1 / §5.9 / §5.10
- Page-spec：`me-settings.page.yaml`、`me-settings-agreement-center.page.yaml`
- Vue：`SettingsView.vue`、`AgreementCenterView.vue`、`AgreementView.vue`

当前 iOS Hub 仍含长辈版与退出登录，与「我的」Hub 已迁出退出登录的策略冲突，且不符合设置主页 scope.out。

## Goals / Non-Goals

**Goals:**

- 设置主页四组六项 UI + 路由
- 协议与说明 6 条静态入口 + 详情只读页
- 清理缓存本页回显

**Non-Goals:**

- 本 change 不重做安全中心 / 隐私 / 通知 / 关于二级页内部逻辑（已有实现，仅保证入口可达）
- 不在设置页放退出登录或适老化开关
- 不接真实协议 CMS；详情用静态文案占位（对齐 Vue 本地 `agreementMap`）

## Decisions

1. **分组标题在卡片外**：与 Vue `.settings-group__title` 一致（次要色、14 semibold）。
2. **行布局**：36×36 圆角图标底（`fdPrimarySoft` + SF Symbol）+ label/desc + chevron；清理缓存的 desc 绑定缓存大小字符串。
3. **缓存**：UserDefaults `fd_settings_cache_size`，默认 `12.8 MB`；清理写 `0 B` 并 toast；同时清 Kingfisher 磁盘缓存（增强真实感，不影响文案回显规则）。
4. **协议详情路由**：`/auth/agreement/{docType}`，docType ∈ `user|privacy|consent|personal-info|third-party-sharing|benefit-card`；未知类型回退 user。
5. **登出**：仅保留在「我的」Hub，设置页不再展示。

## Risks / Trade-offs

- 二级页（通知四类偏好等）若与最新 Vue 仍有差距，另开 change；本 change 以主页 + 协议中心闭环为主。

## Open Questions

- 无
