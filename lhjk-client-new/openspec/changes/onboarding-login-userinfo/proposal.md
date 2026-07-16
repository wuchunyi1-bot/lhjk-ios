## Why

`checkNeedOnboarding()` 当前通过 `getCurrentUserBaseInfo`（信息详情）判断姓名/性别/生日是否完整。产品要求改以**登录接口返回的 `userInfo` 为主体**，并增加 **`hospitalId`（所属机构）** 完整性判断，与完善个人信息（姓名、性别、出生日期、所属机构）门禁对齐。

## What Changes

- 解析 `/auth/oauth2/token` 响应中的 `userInfo`，登录成功后持久化
- `checkNeedOnboarding()` **不再**请求 `getCurrentUserBaseInfo`
- 判定字段：`chineseName`、`sex`、`birthday`、`hospitalId`（任一为空则需引导）
- 登出清除登录态 `userInfo`；资料完善后可 patch 更新本地缓存

## Capabilities

### Modified Capabilities

- `register-login`: onboarding 门禁数据源与判定字段

## Impact

- `DAL/Networking/OAuthCredential.swift`（`OAuthTokenResponse` + `LoginUserInfo`）
- `BLL/User/UserManager.swift`
- `BLL/RegisterLogin/LoginService.swift`
- `openspec/changes/adapt-fundee-login` 相关描述以本变更为准
