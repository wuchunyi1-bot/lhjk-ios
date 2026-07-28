## Why

iOS「设置」主页仍为旧四卡片结构（含长辈版、退出登录、清单弹窗），与 funde PRD `02_用户_我的设置_v1.0` §5.1 及 `SettingsView.vue` / `me-settings.page.yaml` 的「四组六项」不一致；且缺少「协议与说明」入口。

## What Changes

- **设置主页**重排为：账号与安全 / 消息提醒 / 隐私与协议 / 通用与支持（共 6 项）
- 每项：左侧图标软底 + 标题 + 说明文案 + 右箭头（清理缓存说明为缓存大小）
- **移除**：适老化开关、退出登录、旧清单弹窗入口
- **新增**：「协议与说明」二级页及六类协议详情入口（对齐 AgreementCenter / AgreementView）
- 清理缓存：成功 toast「清理成功」，本行回显 `0 B`

## Capabilities

### New Capabilities

- `me-settings`: 设置主页四组六项与清理缓存
- `me-settings-agreement-center`: 协议与说明列表及详情跳转

### Modified Capabilities

- （无已归档主规格需改）

## Impact

- `PL/My/Settings/SettingsViewController.swift`
- 新增：`AgreementCenterViewController`、`AgreementDetailViewController`（及可选行组件）
- `BLL/My/MyRoutes.swift`：注册 `/me/settings/agreement-center`、`/auth/agreement/:docType`
- 参考：`app端prd初稿/02_用户_我的设置_v1.0.md`、`docs/page-specs/me-settings*.page.yaml`、`SettingsView.vue`、`AgreementCenterView.vue`
