## ADDED Requirements

### Requirement: 微信授权与绑定管理

`/me/settings/security/wechat` SHALL 管理微信快捷登录绑定，对齐 PRD-205 / `WechatAuthorizationView.vue` 及后端用户管理接口规范。

#### Scenario: 查询绑定状态

- **WHEN** 进入安全中心（`/me/settings/security`）或微信授权页（`/me/settings/security/wechat`）
- **THEN** 调用 `GET /v1/users/getWechatBindStatus`
- **AND** 安全中心微信授权行回显「已绑定」或「未绑定」

#### Scenario: 微信未绑定状态展示与绑定流程

- **WHEN** 微信绑定状态为 `bound == false`（未绑定）
- **THEN** 状态卡展示「尚未绑定微信」与文案「绑定后可使用微信快捷登录富德联好健康。」
- **AND** 操作卡展示「微信快捷登录」与文案「绑定微信后，下次可直接使用微信登录，无需重复输入手机号。」
- **AND** 主按钮为实心高亮「绑定微信」
- **WHEN** 用户点击「绑定微信」
- **THEN** 调起微信 Open SDK（`WeChatSDKManager.sendAuth`）获取授权 `code`
- **AND** 授权成功后调用 `POST /v1/users/bindWechat?code={code}` 提交绑定
- **AND** 绑定成功后提示「微信绑定成功」，刷新绑定状态与当前用户信息

#### Scenario: 微信已绑定状态展示与解绑流程

- **WHEN** 微信绑定状态为 `bound == true`（已绑定）
- **THEN** 状态卡展示「微信已绑定」与文案「绑定后可使用微信快捷登录富德联好健康。」
- **AND** 操作卡展示「微信快捷登录」与文案「如不再使用当前微信快捷登录，可解除绑定。」
- **AND** 主按钮为线框样式「解绑微信」
- **WHEN** 用户点击「解绑微信」
- **THEN** 弹出二次确认弹窗（标题「确认解绑微信？」，说明「解绑后，将不能使用当前微信快捷登录富德联好健康。」，选项「暂不解绑」/「确认解绑」）
- **WHEN** 用户确认解绑
- **THEN** 调用 `POST /v1/users/unbindWechat` 解除微信账号绑定
- **AND** 解绑成功后提示「微信已解绑」，刷新绑定状态与当前用户信息；点击「暂不解绑」则取消操作，保持原状态

