## ADDED Requirements

### Requirement: 消息通知设置页

`/me/settings/notifications` SHALL 展示系统通知状态与四类 App 通知偏好，对齐 PRD-208 / `NotificationSettingsView.vue`。

#### Scenario: 页面结构

- **WHEN** 用户进入通知设置
- **THEN** 标题为「消息通知设置」
- **AND** 分组「手机系统通知」含一行：标题、说明「关闭后，App 无法向您推送服务与健康提醒」、右侧状态「已开启」或「未开启」
- **AND** 分组「通知提醒」含四项开关：服务进度提醒、健康任务提醒、预约提醒、活动与优惠（各带说明文案）

#### Scenario: 系统通知点击

- **WHEN** 状态为未开启并点击
- **THEN** toast「请在系统设置中开启“富德联好健康”的通知权限」（并可引导系统设置）
- **WHEN** 状态为已开启并点击
- **THEN** toast「手机系统通知已开启」

#### Scenario: 偏好默认与持久化

- **WHEN** 本地无偏好记录
- **THEN** 服务进度/健康任务/预约提醒默认开，活动与优惠默认关
- **WHEN** 用户切换任一开关
- **THEN** 立即写入本地 `fd_notification_settings`，重新进入回显
- **AND** 切换不额外 toast
