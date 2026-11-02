## ADDED Requirements

### Requirement: 个人信息三组字段

`/me/profile` SHALL 在头像下方以分组列表展示三组字段，对齐 `ProfileView.vue` → `profileSections`。

#### Scenario: 个人基础信息

- **WHEN** 页面渲染
- **THEN** 展示：姓名（只读）、昵称（可编辑 text，最长 20 字）、性别（可编辑 select）、出生日期（可编辑 date，须满 18 周岁）、手机号（只读，脱敏）、邮箱（可编辑 text）
- **AND** 保存昵称时 Body 传 `nickname`，成功后刷新当前用户；「我的」顶部展示该昵称，昵称为空时回退姓名

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
- **WHEN** 出生日期未满 18 周岁
- **THEN** 日期滚轮最晚停在「今天往前 18 年」当天；点保存时 toast「用户年龄需满18岁」，不关闭弹层，不调用 `updateCurrentProfile`

#### Scenario: 保存成功

- **WHEN** 校验通过
- **THEN** 更新本地展示 → 调用 `updateCurrentProfile`（映射字段）→ 成功 toast「{字段}已保存」并 `refreshUserInfo`
- **AND** 详细地址读写 `addressStreet`（不再使用 `address`）

### Requirement: 居中头像区

页面顶部 SHALL 展示居中头像区。

#### Scenario: 样式与交互

- **WHEN** 渲染头像区
- **THEN** 头像约 80×80、圆角约 24；无 `imageUrl` 或加载失败时展示默认头像 `chat_im_avatar`，不得用姓名首字/末字代替；下方文案「点击更换头像」
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

### Requirement: 个人信息档案加密

个人信息页 SHALL 在导航栏右侧提供档案加密开关。健康档案与体检报告为 H5，本页不处理。

#### Scenario: 进入即加密

- **WHEN** 用户进入个人信息页
- **THEN** 开关为打开，表示加密
- **AND** 字段左侧名称与右侧内容展示为 `****`
- **AND** 分组标题、头像和行箭头保持原样
- **AND** 不读取、不写入上次开关状态

#### Scenario: 关闭加密后可见

- **WHEN** 用户关闭开关
- **THEN** 字段左右恢复明文，必填项恢复红色星号
- **WHEN** 用户再次打开开关
- **THEN** 左右重新打码为 `****`

#### Scenario: 加密时不可编辑

- **WHEN** 页面处于加密
- **THEN** 点击字段行不打开编辑弹层，不展示编辑箭头
- **AND** 点击头像不打开相册，不展示「点击更换头像」
- **WHEN** 用户关闭加密
- **THEN** 字段与头像恢复可编辑

## REMOVED Requirements

### Requirement: 账号资料中的富德 ID / 收货地址入口

**Reason**: 个人信息页不展示富德 ID 与收货地址入口。昵称重新作为可编辑项，并展示在「我的」顶部。  
**Migration**: 收货地址仍从地址管理进入 `/me/address`。
