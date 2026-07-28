## ADDED Requirements

### Requirement: 设置主页四组六项

设置主页（`/me/settings`）SHALL 按固定四组展示六项入口，对齐 PRD-201 与 `SettingsView.vue`。

#### Scenario: 分组与入口

- **WHEN** 用户进入设置页
- **THEN** 依次展示分组：
  - 账号与安全 → 安全中心（说明：手机号、密码与账号管理）→ `/me/settings/security`
  - 消息提醒 → 通知设置（说明：服务、健康与预约提醒）→ `/me/settings/notifications`
  - 隐私与协议 → 隐私设置（说明：系统权限与业务授权）→ `/me/settings/privacy`
  - 隐私与协议 → 协议与说明（说明：协议、清单与权益卡规则）→ `/me/settings/agreement-center`
  - 通用与支持 → 清理缓存（说明为当前缓存大小）→ 本页清理
  - 通用与支持 → 关于富德健康（说明：品牌、版本与客服信息）→ `/me/settings/about`
- **AND** 每项右侧有箭头；行含左侧图标软底

#### Scenario: 禁止项

- **WHEN** 渲染设置主页
- **THEN** 不展示我的地址、适老化/长辈版开关、退出登录入口

#### Scenario: 清理缓存

- **WHEN** 用户点击清理缓存
- **THEN** toast「清理成功」
- **AND** 该行说明文案更新为 `0 B`
- **WHEN** 首次进入且本地无记录
- **THEN** 缓存大小默认展示 `12.8 MB`
