## ADDED Requirements

### Requirement: 个人信息三组字段

`/me/profile` SHALL 在头像下方以分组列表展示三组字段，对齐 `ProfileView.vue` → `profileSections`。

#### Scenario: 个人基础信息

- **WHEN** 页面渲染
- **THEN** 展示：姓名（只读）、性别（可编辑 select）、出生日期（可编辑 date）、手机号（只读，脱敏）、邮箱（可编辑 text）

#### Scenario: 身份与职业

- **WHEN** 页面渲染
- **THEN** 展示：职业、文化程度、证件类型、证件号码（均可编辑；前三项为 select，证件号码为 text）

#### Scenario: 地区信息

- **WHEN** 页面渲染
- **THEN** 展示：国籍、民族、籍贯、现居地、省/区、详细地址（前五项 select，详细地址 text）

#### Scenario: 空值占位

- **WHEN** 可编辑字段无值
- **THEN** 右侧展示占位文案（如「请选择」「请填写」），样式为 muted；只读空值仍展示占位但不显示箭头

### Requirement: 底部弹层编辑

可编辑字段 SHALL 通过底部弹层编辑，不得使用破坏性全页跳转。

#### Scenario: 打开弹层

- **WHEN** 用户点击非只读行
- **THEN** 弹出底部 sheet：取消 |「编辑{字段名}」| 保存；内容为 text 输入、date 选择或选项列表

#### Scenario: 保存校验

- **WHEN** 用户点保存且内容为空
- **THEN** toast 提示填写；不关闭弹层
- **WHEN** 邮箱不含 `@`
- **THEN** toast「请输入正确的邮箱格式」

#### Scenario: 保存成功

- **WHEN** 校验通过
- **THEN** 更新本地展示 → 调用 `updateCurrentProfile`（映射字段）→ 成功 toast「{字段}已保存」并 `refreshUserInfo`

### Requirement: 居中头像区

页面顶部 SHALL 展示居中头像区。

#### Scenario: 样式与交互

- **WHEN** 渲染头像区
- **THEN** 头像约 80×80、圆角约 24；无图时品牌渐变底 + 首字；下方文案「点击更换头像」
- **AND** 点击打开相册；选图后 OSS 上传并 `updateCurrentProfile(imageUrl:)`（保留现有能力）

## MODIFIED Requirements

### Requirement: Profile Edit & Save

个人信息页 SHALL 按字段分组编辑并持久化；姓名与手机号不可在此页修改。

#### Scenario: 只读字段

- **WHEN** 用户点击姓名或手机号行
- **THEN** 不打开编辑器

#### Scenario: 性别映射

- **WHEN** 用户选择「男」或「女」
- **THEN** UI 显示中文；提交 API 时 `sex` 为 `"1"` / `"2"`

## REMOVED Requirements

### Requirement: 账号资料中的昵称 / 富德 ID / 收货地址入口

**Reason**: 现行 `ProfileView.vue` 不再展示用户昵称、富德 ID、收货地址入口。  
**Migration**: 收货地址仍从 Hub「常用功能」进入 `/me/address`；昵称/ID 若需编辑另开变更。
