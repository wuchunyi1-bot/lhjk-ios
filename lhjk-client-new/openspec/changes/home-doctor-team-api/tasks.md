## 1. BLL 模型与接口

- [x] 1.1 新增 `MyDoctorTeamVO`（flexible 解码 + 角色/展示映射）
- [x] 1.2 `HomeService.getUserParticipateAllTeam(userId:)` → `APIResponse<[[MyDoctorTeamVO]]>`

## 2. PL 绑定

- [x] 2.1 `HomeTeamCardCell.Member` 增加 `groupId` / `imageUrl`；空 status 时隐藏 badge 与 onlineDot；Kingfisher 头像
- [x] 2.2 `HomeViewModel`：`loadDoctorTeam()`、删 mock、空列表不展示 team section
- [x] 2.3 `HomeViewController`：`viewWillAppear` 触发加载；发消息带 `groupId`
- [x] 2.4 `HomeViewController`：发消息 → `/conversations/:id`，`id` = `groupId`；无 groupId 不跳转

## 3. 服务剩余时间

- [x] 3.1 `HomeService.getRemainServiceTime()` + `RemainServiceTimeVO`
- [x] 3.2 `HomeViewModel.teamServiceDaysLeft`；与团队接口并行拉取
- [x] 3.3 `HomeTeamCardCell` 标题右侧「服务剩余 N 天」（无箭头、不可点）；`remainDays <= 0` 隐藏
- [x] 3.4 点击跳转 `/orders` + `tab=in_progress`
