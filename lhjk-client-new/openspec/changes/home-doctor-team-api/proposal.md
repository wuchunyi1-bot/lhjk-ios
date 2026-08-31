## Why

首页「我的富德联好健康管家团队」仍使用本地 mock 成员；需接入 `GET /v1/session/getUserParticipateAllTeam`，用真实团队成员驱动卡片列表，并在无数据时展示空态。

## What Changes

- 新增 Home 模块 BLL：拉取用户参与团队（`MyDoctorTeamVO` 嵌套数组）并映射为 `HomeTeamCardCell.Member`
- 首页加载真实团队成员；失败或无数据时清空列表、不回落 mock
- **删除** `HomeViewModel.defaultTeamMembers` 注入路径
- 团队卡片支持头像 URL（Kingfisher）；无在线态字段时不强行展示虚假「在线」
- 「发消息」优先带 `groupId` 进入消息/会话；UI 版式沿用现有团队卡

## Capabilities

### New Capabilities

- `home-doctor-team`: 首页富德联好健康管家团队 API 接入与列表绑定

### Modified Capabilities

- （无已归档主规格；延续 `adapt-fundee-home` / `sync-home-to-funde-vue` 团队区 UI）

## Impact

- `BLL/Home/`：`HomeService`、`MyDoctorTeamVO`
- `PL/Home/ViewModels/HomeViewModel.swift`
- `PL/Home/Cells/HomeTeamCardCell.swift`
- `PL/Home/HomeViewController.swift`
- Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/495580451e0.md
- 服务剩余天数：`GET /v1/schemeArchive/getRemainServiceTime`（`RemainServiceTimeVO.remainDays`）驱动标题右侧「服务剩余 N 天 ›」
