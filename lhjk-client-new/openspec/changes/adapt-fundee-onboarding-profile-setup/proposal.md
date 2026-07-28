## Why

完善个人信息页（`OnboardingViewController`）布局仍偏离 funde `ProfileSetupView`，且提交仍走 `POST /v1/users/updateCurrentProfile`，无法写入所属机构与业务经理；业务经理选择也尚未接入真实列表接口。

## What Changes

- 对齐 funde `ProfileSetupView` 卡片式布局：头图 Icon、标题/副标题、必填星标、性别 ♂/♀、机构/业务经理选择行、隐私提示
- 新增业务经理二级选择页：按所属机构调用 `GET /v1/doctor/getDoctorPage` 搜索并选中
- **BREAKING（Onboarding 提交路径）**：完善资料提交改为 `POST /v1/archive/saveArchiveHospital`（含 `hospitalId`、可选 `businessManagerId`），不再调用 `updateCurrentProfile`
- 提交成功后仍写 `loginUserInfo` 四门禁字段并刷新 `currentUser`

## Capabilities

### New Capabilities

- （无；以 delta 扩展既有 register-login）

### Modified Capabilities

- `register-login`: 完善资料 UI、业务经理选填、提交改走 `saveArchiveHospital`、业务经理列表走 `getDoctorPage`

## Impact

- PL：`OnboardingViewController`、新增 `ManagerSelectViewController`（及 Cell/ViewModel）
- BLL：`UserService.saveArchiveHospital`；`DoctorService.getDoctorPage`（或等价命名）
- DAL/Models：`SaveArchiveHospitalDTO`、`DoctorVo` / 分页模型
- 我的资料页等仍可继续使用 `updateCurrentProfile`（本变更不改）
