## MODIFIED Requirements

### Requirement: 设置主页分组与入口

设置主页（`/me/settings`）SHALL 按固定五组展示入口，对齐 `SettingsView.vue`。

#### Scenario: 分组与入口

- **WHEN** 用户进入设置页
- **THEN** 依次展示：
  - 账号与安全 → 安全中心 → `/me/settings/security`
  - 地址与设备 → 我的地址 → `/me/settings/addresses`
  - 地址与设备 → 智能设备 → `/me/devices`
  - 消息提醒 → 通知设置 → `/me/settings/notifications`
  - 隐私与协议 → 隐私设置 → `/me/settings/privacy`
  - 隐私与协议 → 协议与说明 → `/me/settings/agreement-center`
  - 通用与支持 → 清理缓存（本页 action）
  - 通用与支持 → 关于富德联好健康 → `/me/settings/about`
- **AND** 底部独立「退出登录」按钮（危险色）

#### Scenario: 禁止项

- **WHEN** 渲染设置主页
- **THEN** 不展示适老化/长辈版开关

#### Scenario: 退出登录

- **WHEN** 用户点击退出登录并确认
- **THEN** 执行与旧 Hub 相同的 logout 清理流程 → `Router.setRoot("/login")`

#### Scenario: 清理缓存

- **WHEN** 用户点击清理缓存
- **THEN** toast「清理成功」，说明文案更新为 `0 B`

#### Scenario: 地址路由别名

- **WHEN** 打开 `/me/settings/addresses`
- **THEN** 与 `/me/address` 等价，进入 `AddressListViewController`
