## Why

funde-client `ProfileView.vue` 已从「账号资料 + 基础资料 + 收货地址」改为：顶部大头像 + 三组字段（个人基础信息 / 身份与职业 / 地区信息），可编辑项用底部弹层编辑；姓名与手机号只读。iOS `ProfileViewController` 仍为旧结构，需对齐。

## What Changes

- 重做 `/me/profile` 布局与字段分组，对齐 `ProfileView.vue`
- 姓名、手机号只读；其余字段底部弹层编辑（text / select / date）
- 移除：用户昵称行、富德 ID 行、收货地址入口、基础资料缺失 hint（Vue 已无）
- 头像改为居中大图区（圆角方）+「点击更换头像」；保留 OSS 上传
- 扩展 `SUsersOnboardingPayload` 以提交邮箱/职业/学历/证件/地区等与 `SUsers` 对齐的字段
- **仅**「我的」模块个人信息页；不改 Hub / 设置 / Onboarding

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `me`: 个人信息页（`/me/profile`）布局与编辑交互

## Impact

- `PL/My/Profile/ProfileViewController.swift`（重写）
- 可能新增 `ProfileFieldEditorSheet`、`ProfileViewModel`
- `BLL/User/UserModels.swift` — 扩展 `SUsersOnboardingPayload`
