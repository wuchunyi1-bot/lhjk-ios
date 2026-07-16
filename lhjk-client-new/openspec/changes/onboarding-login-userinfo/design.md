## Context

PRD §5.10：未完善基础信息（姓名、性别、出生日期、所属机构）的用户登录后须进入完善页。所属机构对应后端 `hospitalId`。

登录 token 响应除 `access_token` 等外携带 `userInfo`（或 `user_info`），其中含资料字段与 `hospitalId`。信息详情接口 `getCurrentUserBaseInfo` 仍用于个人中心等，**不作为** onboarding 门禁主体。

## Decisions

### 1. 两套数据并存

| 字段 | 来源 | 用途 |
|------|------|------|
| `loginUserInfo` | 登录 `userInfo` | **仅** Onboarding 门禁 |
| `currentUser` | `getCurrentUserBaseInfo` | App 其它所有业务 |

二者同时存在；门禁不读详情，业务不读登录摘要。

### 2. 启动 / 登录编排

```
并行:
  checkNeedOnboarding()  // 本地 loginUserInfo，无网络
  fetchUserInfo()        // GET getCurrentUserBaseInfo → currentUser
```

### 3. 判定字段（loginUserInfo）

`chineseName` / `sex` / `birthday` / `hospitalId` 任一为空 → 需要 Onboarding。

## Risks

- 若后端暂未下发 `userInfo`，门禁不会拦截（冷启动同理）；需联调确认字段名与是否始终返回
- Onboarding 页若尚未采集 `hospitalId`，用户填完姓名性别生日后仍可能再次进入引导，直至机构字段写入登录缓存
