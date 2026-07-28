## 1. Models & BLL

- [x] 1.1 新增 `SaveArchiveHospitalDTO`；`UserService.saveArchiveHospital` → `POST /v1/archive/saveArchiveHospital`
- [x] 1.2 新增 `DoctorVo` + 分页模型；`DoctorService.getDoctorPage` → `GET /v1/doctor/getDoctorPage`（含中英分页 key）

## 2. 业务经理选择页

- [x] 2.1 新增 `ManagerSelectViewController` + ViewModel：按 `hospitalId` 拉列表、搜索、选中回调
- [x] 2.2 列表 Cell：头像字、姓名、经理号、职位、手机号、选中勾

## 3. Onboarding UI 与提交

- [x] 3.1 重排 `OnboardingViewController` 对齐 ProfileSetup 卡片布局（含业务经理行、隐私提示）
- [x] 3.2 业务经理入口：未选机构 Toast；换机构清空；选中回显
- [x] 3.3 提交改走 `saveArchiveHospital`；成功后 patch 门禁 + refresh；去掉本页 `updateCurrentProfile`
