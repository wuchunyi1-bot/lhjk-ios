## Context

- API：`GET /v1/session/getUserParticipateAllTeam?userId=`（Apifox 495580451）
- 模块归属：**Home**（首页 Section「我的富德联好健康管家团队」）
- UI：已有 `HomeTeamCardCell` / `HomeViewModel.teamMembers`（当前为 mock）
- 响应 `data` 类型为 `MyDoctorTeamVO[][]`（团队列表，每项为该团队成员数组）

### API 摘要

| 项 | 值 |
|----|-----|
| Method | GET |
| Path | `/v1/session/getUserParticipateAllTeam` |
| Query | `userId`（必填，int64 / 雪花字符串均可） |
| Auth | Bearer（`APIManager` 拦截器） |
| `data` | `[[MyDoctorTeamVO]]` |

`MyDoctorTeamVO` 字段：

| 字段 | 含义 |
|------|------|
| `groupId` | 群组 Id |
| `identity` | 成员身份（int；文档未展开枚举） |
| `userId` | 成员用户 Id |
| `userName` | 名字 |
| `imageUrl` | 头像 |
| `openBusiness` | 医生开通业务 code，逗号分隔（仅医生） |
| `openBusinessName` | 业务名称 |
| `position` | 职称 |

## Goals / Non-Goals

**Goals:**

- 登录用户拉取参与团队，扁平化后驱动首页团队卡片
- 过滤当前用户本人；按 `userId` 去重
- `identity` / `openBusiness` / 文案启发式映射角色色（doctor / nutrition / manager）
- 失败或空数据：空列表 + 隐藏团队 Section（或不展示成员行）；**禁止 mock 顶替**

**Non-Goals:**

- 不接团队详情页 / 改版式
- 不实现真实在线状态（接口无此字段）
- 不做跨进程磁盘缓存（与今日任务类似，可会话内简单刷新）
- 服务剩余天数由 `getRemainServiceTime` 单独接口提供，与团队成员接口并行拉取

## Decisions

1. **分层**：BLL `HomeService.getUserParticipateAllTeam` + `MyDoctorTeamVO`；PL `HomeViewModel` 映射为 `HomeTeamCardCell.Member`。归属 Home，不放入 Message/IM（虽接口在 IM 文件夹，消费方是首页）。

2. **userId**：优先 `loginUserInfo.id`，否则 `currentUser.id`；缺失则不请求、团队为空。

3. **data 解析**：`APIResponse<[[MyDoctorTeamVO]]>`。展示策略：
   - 取**第一个非空团队**的成员列表（首页只展示一组管家团队）
   - 若需跨团队去重，再按 `userId` 合并；当前以首团队为准，避免多服务包成员混排

4. **过滤**：
   - 去掉 `userId` 与当前登录用户相同的成员
   - `userName` 为空的跳过

5. **角色映射**（文档未给 identity 枚举，采用可回退策略）：

| 优先级 | 条件 | role |
|--------|------|------|
| 1 | `openBusiness` / `openBusinessName` 非空 | `doctor` |
| 2 | `position`/`userName` 含「营养」 | `nutrition` |
| 3 | `position`/`userName` 含「健管」「顾问」 | `manager` |
| 4 | `identity`：`1`→doctor，`2`→manager，`3`→nutrition（约定，可调） | 对应 role |
| 5 | 其它 | `manager`（默认健管侧） |

6. **UI 字段映射**：

| API | UI `Member` |
|-----|-------------|
| `userName` | `name`；`initial` = 首字 |
| `position` | `title`（空则按 role 默认职称文案） |
| `openBusinessName` 首段 / 截断 | `tags`（空则用 role 默认标签） |
| — | `status`：接口无在线态 → 空字符串；Cell 隐藏 status badge 与 onlineDot |
| `imageUrl` | Cell Kingfisher 加载；失败回落文字头像 |
| `groupId` | Member 增加 `groupId`，发消息跳转参数 |

7. **发消息**：`Router.push("/conversations/:id", params: ["id": groupId])`，其中 `id` = 成员 `groupId`（与消息列表点进会话一致：`ChatViewController(conversationId:)`）。无 `groupId` 时不跳转。不经 `/messages` 中转。

8. **加载时机**：首页 `viewWillAppear` 与今日任务一并触发 `loadDoctorTeam()`；`.userDidUpdate` 时若 userId 变化再拉。

9. **空态**：`teamMembers` 为空时 snapshot **不 append** team section（或 section 无 items），避免空白标题区；有数据才显示「我的富德联好健康管家团队」。

10. **解码**：`userId`/`groupId` 等用 flexible String/Int64（对齐 `UserTodayMonitorTask`）。

## Risks / Trade-offs

- [identity 枚举不确定] → 以 `openBusiness` + 文案启发式为主，identity 为辅；联调后可改常量表  
- [多团队用户只展示首团队] → 符合首页摘要；若产品要「全部合并」再改 flatten 策略  
- [无在线态] → 不展示虚假「在线」，避免误导  

## Open Questions

- `identity` 正式枚举值（待后端/联调确认）

### 服务剩余时间 API

| 项 | 值 |
|----|-----|
| Method | GET |
| Path | `/v1/schemeArchive/getRemainServiceTime` |
| Query | 无（Bearer 鉴权识别当前用户） |
| `data` | `RemainServiceTimeVO` |

| 字段 | 含义 |
|------|------|
| `remainDays` | 剩余天数 |
| `endTime` | 服务结束时间 |

- 与 `getUserParticipateAllTeam` 并行请求；`remainDays > 0` 时展示「服务剩余 N 天」（无箭头、不可点）
- 剩余时间请求失败时静默，仅隐藏右侧文案，不影响团队列表展示
