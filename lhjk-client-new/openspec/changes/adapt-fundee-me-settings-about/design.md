## Context

- 权威：PRD-213（`02_用户_我的设置_v1.0` §5.11）、`me-settings-about.page.yaml`、`AboutSettingsView.vue`
- 现状：`AboutSettingsViewController` 仍为旧布局（标题「关于我们」、品牌下重复版本、协议三入口、备案/版权为第三张卡）
- 协议入口已在「协议与说明」；关于页 acceptance 明确「不展示协议入口」

## Goals / Non-Goals

**Goals:**

- 关于页 UI / 文案 / 交互对齐 PRD-213 与 Vue
- 纯 PL 静态页，无网络

**Non-Goals:**

- 真实检查更新 / App Store 评分跳转（原型 toast）
- 客服电话拨号（PRD：只读不可点）
- 协议详情（不在本页）
- 不改设置主页入口（已有「关于富德健康」→ `/me/settings/about`）

## Decisions

1. **结构**：品牌 Hero → 单卡三行 → 页脚两行文本；去掉第二、三张卡与品牌下版本 Label。
2. **版本号**：`Bundle.main` 的 `CFBundleShortVersionString`，展示为 `v{version}`；点击仅 toast「当前已经是最新版本」，不做比对。
3. **评分**：点击 toast「暂无法打开应用市场」，不调 StoreKit / 外链。
4. **联系我们**：右侧 `400-888-6520`，无箭头、无 tap。
5. **页脚**：`Copyright © 2026 富德健康` + `粤ICP备xxxxx号`（与 Vue 一致占位；正式备案号待法务替换）。
6. **视觉**：顶区浅橙到 `fdBg` 渐变；Logo 68×68、圆角 18、`fdPrimary`→浅橙渐变、「富」白字；卡用 `fdSurface` + 圆角/轻阴影，行高 ≥52。
7. **实现范围**：仅重写 `AboutSettingsViewController`；路由已注册。

## Risks / Trade-offs

- [备案号占位] → 与 Vue/PRD 一致；上线前替换正式 ICP
- [评分未接商店] → 产品确认后接 `itms-apps` / `SKStoreReviewController`

## Open Questions

- 无
