## Why

首次注册用户提交完善个人信息后直接进入首页，没有说明首页页签、体征监测和健康档案怎么用。产品要求在这次提交成功后先询问长辈模式，再用镂空引导顺着真实页面走完六步。

## What Changes

- 完善个人信息提交成功后开始新手引导：先出长辈模式询问层，再在真实页面上播放六步镂空引导。
- 引导层只压暗并镂空，红框里露出的是下层页面本身，不在引导层重画入口或底栏。
- 「下一步」调用下层已有的页签或底栏点击，页面跟着切换后重新量孔。
- 第 6 步镂空「我的健康」金刚区里名称为「健康档案」的那一格；「去完善」走该格现有打开逻辑并结束引导。
- 已完善资料的再次登录、冷启动不播放。引导中杀掉进程则本次结束，下次不再播。

## Capabilities

### New Capabilities

- `new-user-guide`：完善资料提交成功后的长辈模式询问与六步镂空页面引导。

### Modified Capabilities

## Impact

- `PL/RegisterLogin/Onboarding/OnboardingViewController.swift`：提交成功后进入引导，而不是只关掉资料页。
- 新增盖在主界面上的引导层：遮罩镂空、说明卡片、跳过。
- 首页页签 `HomeViewController.showShelf`、底栏 `RootTabBarController`、健康金刚区 `HealthQuickEntriesCell`：提供被点击的目标和镂空 frame。
- 长辈模式仍用现有 `UIFont.isSeniorMode`，询问层的选择与设置页是同一个开关。
