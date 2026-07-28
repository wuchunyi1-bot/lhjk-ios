## ADDED Requirements

### Requirement: 完善资料页对齐 ProfileSetup 布局

完善个人信息页（`OnboardingViewController`）SHALL 对齐 funde `ProfileSetupView` 的卡片式布局与字段结构。

#### Scenario: 页面结构

- **WHEN** 展示完善个人信息页
- **THEN** 使用暖色页背景 + 白底圆角卡片
- **AND** 卡片顶部展示 Icon、标题「完善个人信息」、副标题「填写基础信息，绑定专属服务机构与业务经理」
- **AND** 字段顺序为：姓名、性别、出生日期、所属机构、业务经理（选填）
- **AND** 必填项标签带红色 `*`；业务经理标签带「(选填)」
- **AND** 卡片底部为主按钮「提交信息」与隐私提示文案

#### Scenario: 性别控件

- **WHEN** 用户选择性别
- **THEN** 展示「♂ 男」「♀ 女」双按钮；选中态为 primary 描边与浅底

### Requirement: 业务经理二级选择

完善资料页 SHALL 支持选填业务经理；列表数据来自 `GET /v1/doctor/getDoctorPage`。

> Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330896e0.md  
> operationId: `getDoctorPage`

#### Scenario: 未选机构拦截

- **WHEN** 用户未选择所属机构即点击业务经理
- **THEN** Toast「请先选择所属机构」且不进入二级页

#### Scenario: 进入选择页

- **WHEN** 已选所属机构并点击业务经理
- **THEN** 进入「选择业务经理」页，顶部展示当前机构名
- **AND** 请求 `GET /v1/doctor/getDoctorPage`，Query 至少含 `hospitalId`、`status=1`、`pageNum`、`pageSize`
- **AND** 搜索框可按姓名等关键词查询（映射 `name`）；列表展示姓名、经理号（`account`）、职位、手机号
- **AND** 禁止使用 mock 假列表

#### Scenario: 选中回填

- **WHEN** 用户点击某位业务经理
- **THEN** 回填显示「姓名（经理号）」，并保存其 `id` 为 `businessManagerId`
- **AND** 不阻断后续提交（业务经理仍为选填）

#### Scenario: 更换机构清空

- **WHEN** 用户更换所属机构
- **THEN** 清空已选业务经理与 `businessManagerId`

### Requirement: 完善资料提交 saveArchiveHospital

完善资料提交 SHALL 调用 `POST /v1/archive/saveArchiveHospital`，**不得**再调用 `POST /v1/users/updateCurrentProfile`。

> Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/491046480e0.md  
> operationId: `saveArchiveHospital`

#### Scenario: 请求体

- **WHEN** 用户点击提交且姓名、性别、出生日期、所属机构均已填写
- **THEN** Body 包含必填：`chineseName`、`sex`（`"1"`/`"2"`）、`birthday`、`hospitalId`（机构 id）
- **AND** 若已选业务经理，额外传 `businessManagerId`（医生 id）；未选则不传该字段
- **AND** 请求参数禁止 mock / 假 id

#### Scenario: 成功

- **WHEN** `saveArchiveHospital` 返回成功
- **THEN** `UserManager.patchLoginUserInfo` 写入 `chineseName`、`sex`、`birthday`、`hospitalId`
- **AND** `refreshUserInfo` 刷新 `currentUser`
- **AND** Toast「个人信息已提交」并关闭完善页进入主流程

#### Scenario: 失败

- **WHEN** 接口失败
- **THEN** 恢复提交按钮，Toast/Alert 展示错误信息，停留本页

#### Scenario: 校验

- **WHEN** 必填项缺失
- **THEN** 按缺失项提示：「请输入您的真实姓名」/「请选择性别」/「请选择出生日期」/「请选择服务机构」
- **AND** 不发起网络请求

## MODIFIED Requirements

### Requirement: 完善资料所属机构与 hospitalId

完善基础信息页 SHALL 采集所属机构并写入 `hospitalId`；门禁字段为 `chineseName`、`sex`、`birthday`、`hospitalId`。业务经理为选填，不参与门禁。

对齐 PRD §5.10 / §5.11 / §5.12、`onboarding-login-userinfo`。

#### Scenario: 字段

- **WHEN** 展示完善资料页
- **THEN** 必填：姓名、性别、出生日期、所属机构（选择入口，不可手输）
- **AND** 选填：业务经理（二级页选择，回填姓名与经理号）
- **AND** **不得**以「所在城市」替代所属机构

#### Scenario: 选择机构

- **WHEN** 用户点击所属机构
- **THEN** 进入选择服务机构子页（仅启用机构）
- **AND** 选中后回显机构名称，并保存对应 `hospitalId`（接口真实 id，禁止 mock）

#### Scenario: 提交

- **WHEN** 用户点击提交且四项必填齐全
- **THEN** 调用 `POST /v1/archive/saveArchiveHospital` 保存档案机构与基本信息
- **AND** 成功后将 `hospitalId` 等写入 `loginUserInfo`
- **AND** `checkNeedOnboarding()` 不再因缺机构拦截
- **AND** 进入首页（或既有成功路径）

#### Scenario: 未选机构

- **WHEN** 未选所属机构点击提交
- **THEN** Toast「请选择服务机构」且不进入首页
