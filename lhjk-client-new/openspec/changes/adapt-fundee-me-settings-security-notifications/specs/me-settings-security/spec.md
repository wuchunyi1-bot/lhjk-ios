## ADDED Requirements

### Requirement: 安全中心布局

`/me/settings/security` SHALL 按「账号状态 / 安全设置 / 账号管理」三组展示，对齐 PRD-202 与 `SecuritySettingsView.vue`。

#### Scenario: 账号状态卡

- **WHEN** 用户进入安全中心
- **THEN** 标题为「安全中心」
- **AND** 展示 tip 卡：标题「账号安全状态良好」，说明「已绑定手机号，建议定期更新登录密码，保护账号与健康数据安全。」
- **AND** 左侧安全图标软底

#### Scenario: 安全设置三行

- **WHEN** 渲染安全设置
- **THEN** 依次为：
  - 修改手机号 → 右侧脱敏手机号 → `/me/settings/security/change-phone`
  - 登录密码 → 「已设置」或「去设置」→ `/me/settings/security/password`
  - 微信授权 → 调用 `GET /v1/users/getWechatBindStatus`，展示「已绑定」或「未绑定」→ `/me/settings/security/wechat`
- **AND** 本页点击仅跳转，不直接绑定/解绑微信或改密码

#### Scenario: 账号管理

- **WHEN** 渲染账号管理
- **THEN** 注销账号行右侧展示警告色「谨慎操作」，跳转 `/me/settings/security/cancel-account`

#### Scenario: 禁止项

- **WHEN** 渲染安全中心
- **THEN** 不展示实名认证、登录设备管理
