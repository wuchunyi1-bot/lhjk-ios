## Why

安全中心与通知设置仍停留在旧布局（橙色大状态卡、本页直接绑微信、仅系统通知一行），与 PRD-202 / PRD-208 及最新 Vue 不一致。

## What Changes

- **安全中心**：账号状态 tip 卡（固定文案）+ 安全设置三行（修改手机号 / 登录密码 / 微信授权）+ 账号管理（注销账号 · 谨慎操作）；本页不直接改绑定态，仅跳转
- **微信授权**：独立三级页（绑定 / 解绑二次确认）
- **路由对齐**：`/me/settings/security/change-phone|password|wechat|cancel-account`
- **通知设置**：标题「消息通知设置」；系统通知状态行 + 四类偏好开关（本地持久化）

## Capabilities

### New Capabilities

- `me-settings-security`: 安全中心列表与下钻
- `me-settings-wechat`: 微信授权页
- `me-settings-notifications`: 系统通知 + 四类偏好

### Modified Capabilities

- （无）

## Impact

- `SecuritySettingsViewController.swift`
- `NotificationSettingsViewController.swift`
- 新增 `WechatAuthorizationViewController.swift`
- `MyRoutes.swift`
- 参考：`02_用户_我的设置_v1.0.md` §5.2/§5.5/§5.8，`SecuritySettingsView.vue`，`WechatAuthorizationView.vue`，`NotificationSettingsView.vue`
