# 首页我的预约

## ADDED Requirements

### Requirement: 首页我的预约

首页推荐页在「咨询客服」下方展示「我的预约」。数据只来自康养小屋预约记录里的待服务，不使用体检或就医协助使用记录，也不使用本地假数据。

#### Scenario: 拉取待服务

- **WHEN** 首页出现且能解析到当前用户
- **THEN** 调用 `GET /v1/cabin/appointments`（[Apifox](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/529785606e0.md)）
- **AND** Query 传 `status = 3`、`pageNum = 1`、`pageSize = 20`
- **AND** 返回记录按预约日期和开始时间从早到晚排列

#### Scenario: 没有记录

- **WHEN** 未登录、请求失败，或待服务记录为空
- **THEN** 不展示「我的预约」整块
- **AND** 不展示空态，不用假数据顶替

#### Scenario: 卡片

- **WHEN** 至少有一条待服务记录
- **THEN** 区块标题为「我的预约」，卡片横向滑动
- **AND** 卡片展示项目名称、预约日期和时段、门店名称、地址
- **AND** 当天已过结束时间时，底部说明用预约记录的超时文案
- **AND** 其余待服务底部说明为「请提前15分钟到店」
- **AND** 卡片右侧动作为「去查看」

#### Scenario: 去查看

- **WHEN** 点击卡片或「去查看」
- **THEN** 进入预约详情 `/wellness-cabins/appointments/detail`，并带上预约 `id`
- **AND** 记录有 `configId` 时一并带上，供详情里再次预约使用
