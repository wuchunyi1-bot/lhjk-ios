## ADDED Requirements

### Requirement: 微信授权页

`/me/settings/security/wechat` SHALL 管理微信快捷登录绑定，对齐 PRD-205 / `WechatAuthorizationView.vue`。

#### Scenario: 未绑定

- **WHEN** 本地无微信昵称
- **THEN** 状态卡展示「尚未绑定微信」与引导文案
- **AND** 主按钮「绑定微信」；成功后昵称回显「富德健康用户」，toast「微信已绑定」

#### Scenario: 已绑定

- **WHEN** 已有昵称
- **THEN** 展示「微信已绑定」与「当前微信：{昵称}」
- **AND** 按钮「解绑微信」；确认弹窗后解绑，toast「微信已解绑」；取消不改变状态
