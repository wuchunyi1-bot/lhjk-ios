## Why

「我的」Hub 需对齐 funde-client 现行 `MeView.vue` 信息架构；产品已决定**下线「健康大会员」区块**（PRD / Vue 尚未同步删除，以本变更为 iOS 权威）。同时去掉与 Vue 不符的「设置与支持」分组，设置仅保留 Hero 右上角齿轮。

## What Changes

- **BREAKING（Hub UI）**：移除「健康大会员」会员卡及 Hub 上所有会员状态 CTA
- Hero：头像 / 姓名 / 个人信息 / 健康档案 / 设置齿轮（保留）
- 常用功能：8 宫格（对齐 `me.json` → `commonActions`）
- 健康管理：对齐 `me.json` → `healthManagementActions`（含健康评估与健康测评分行）
- 底部「退出登录」（保留）
- **移除** Hub「设置与支持」列表（设置入口仅齿轮 → `/me/settings`）
- **不展示**四格统计条、服务履约卡（与 Vue `showLegacyStats=false`、未渲染 fulfillment 一致）

## Capabilities

### New Capabilities

- `me-hub`: 「我的」Tab 首页信息架构与交互（无会员卡版）

### Modified Capabilities

- （无已归档主 specs 中的独立 me-hub；本 change 以 ADDED `me-hub` 为准，并 supersede `adapt-fundee-me-hub` 中会员卡相关要求）

## Impact

- PL：`MyViewController`、`MyViewModel`；会员卡组件不再挂到 Hub
- 路由：注册 `/me/health-assessment` 占位（对齐 Vue）
- `/me/membership` 子页路由可保留，但 Hub 不再入口
- 参考：`MeView.vue`、`me.json`、`docs/page-specs/me-hub.page.yaml`（yaml 仍含会员/履约，**以 Vue + 本产品决议为准**）
