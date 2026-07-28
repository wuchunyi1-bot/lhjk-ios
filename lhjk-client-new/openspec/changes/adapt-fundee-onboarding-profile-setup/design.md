## Context

完善个人信息页已有姓名/性别/生日/所属机构 UI，提交走 `UserService.updateCurrentProfile`，`hospitalId` 仅本地 `patchLoginUserInfo`，业务经理缺失。funde `ProfileSetupView` 为卡片式布局且含业务经理选填。

Apifox：
- 业务经理列表：`GET /v1/doctor/getDoctorPage`（api-472330896）
- 保存档案机构+基本信息：`POST /v1/archive/saveArchiveHospital`（api-491046480）

## Goals / Non-Goals

**Goals:**
- Onboarding UI 对齐 funde ProfileSetup 结构与交互文案
- 业务经理二级页按 `hospitalId` 拉医生分页列表并回填
- 提交改走 `saveArchiveHospital`，携带必填四字段 + 可选 `businessManagerId`

**Non-Goals:**
- 不改「我的-个人信息」的 `updateCurrentProfile` 路径
- 不实现业务经理扫码/手输
- 不改冷启动门禁字段集合（仍为 name/sex/birthday/hospitalId；业务经理不参与门禁）

## Decisions

### 1. 提交 API 切换

| 选择 | 理由 |
|------|------|
| Onboarding → `saveArchiveHospital` | 文档明确含 `hospitalId` + `businessManagerId`；`updateCurrentProfile` 无机构字段 |
| Profile 页保留 `updateCurrentProfile` | 职责分离：档案机构绑定 vs 日常资料编辑 |

Body（`SaveArchiveHospitalDTO`）：
- `chineseName` / `sex` / `birthday` / `hospitalId`（必填）
- `businessManagerId`（选填，医生 `id`）
- `sex` 传 `"1"`/`"2"`；`birthday` 传 `yyyy-MM-dd`（与现网其它接口一致；若后端要求 date-time 再补 `T00:00:00`）
- `hospitalId` / `businessManagerId` 以 int64 编码（与订单等模块一致，可用字符串再由 encoder 处理，或直接传 Number）

成功后：`patchLoginUserInfo` + `refreshUserInfo` + Toast + dismiss（保持现逻辑）。

### 2. 业务经理 = 医生分页

产品「业务经理」对应机构下医生列表接口。调用约定：
- `hospitalId` = 已选机构 id（必传）
- `status=1`（启用）
- 搜索词映射 `name`（姓名）；本地可再按 `account`/`position` 过滤以贴近原型「经理号/职位」
- 展示：`chineseName`、`account`（经理号）、`position`/`roleName`、脱敏 `mobile`
- 选中写入：`businessManagerId = doctor.id`，回显 `姓名（account）`

### 3. UI 结构

参考 `ProfileSetupView.vue`：
- 页背景暖色 `fdBg`；白卡片圆角阴影
- Hero：渐变 Icon +「完善个人信息」+ 副标题含「业务经理」
- 字段顺序：姓名 → 性别（♂/♀ 双按钮）→ 出生日期 → 分隔线 → 所属机构 → 业务经理（选填）
- 提交按钮在卡片内；底部隐私一句
- 未选机构点业务经理 → Toast「请先选择所属机构」
- 换机构时清空已选业务经理

### 4. 分层

```
OnboardingViewController
  → UserService.saveArchiveHospital
  → DoctorService.getDoctorPage（ManagerSelect）
```

PL 不直连 APIManager。

## Risks / Trade-offs

- [业务经理角色过滤] 接口有 `roleId`，文档未标明业务经理角色值 → 先不传 roleId，仅按 hospitalId+status；若列表过宽再补角色
- [生日格式] schema 为 date-time → 优先 `yyyy-MM-dd`，联调失败再补时间后缀
- [分页中文 key] 沿用 `HospitalSearchModels` 双语 key 解码策略

## Open Questions

- 业务经理是否必须过滤特定 `roleId`：待后端确认；当前不传
