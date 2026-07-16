## 1. Spec

- [x] 1.1 proposal / design / delta spec

## 2. Implementation

- [x] 2.1 `LoginUserInfo` + `OAuthTokenResponse.userInfo`
- [x] 2.2 `UserManager` 持久化登录 userInfo；`checkNeedOnboarding` 改判四字段
- [x] 2.3 `LoginService` 登录成功后写入 userInfo
- [x] 2.4 更新 adapt-fundee-login 门禁描述交叉引用

## 3. Verify

- [ ] 3.1 登录返回缺 hospitalId → 进入 onboarding
- [ ] 3.2 四字段齐全 → 不进入 onboarding
- [ ] 3.3 门禁过程无 getCurrentUserBaseInfo 请求
