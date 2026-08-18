# 我的模块对齐 funde-client 原型（Hub + 设置）

## 背景

funde-client 原型 `MeView.vue` / `SettingsView.vue` 对「我的」模块做了较大改版：Hub 从「常用功能宫格 + 健康管理 + Hub 登出」改为「Hero + 会员卡 + 服务履约 + 健康管理」；设置页新增「地址与设备」分组，并将退出登录移至设置页底部。

旧 change `adapt-fundee-me-hub-no-membership` 与现行原型冲突，本变更以 **Vue 实现为准**。

## 范围

- **本期**：我的 Hub 首页、设置主页
- **非本期**：会员等级详情、会员兑换、订单统计 API、健康管理 detail 接真实数据

## 参考

- 原型：`funde-client/prototype/src/views/me/MeView.vue`、`SettingsView.vue`
- Mock：`prototype/src/mock/me.json`、`member-marketing.ts`
- 文档：`docs/v0.1/pages/me/index.md`、`settings/index.md`（以 Vue 为准）
