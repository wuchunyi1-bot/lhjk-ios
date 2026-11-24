## Context

`GET /v1/cabin/medicalConfigList?businessType=2` 的列表项包含 `id`、`name`、`navigateUrl`、`imgUrls`、`description`（HTML）、`price`、`payType`、`packageId`、`duration`、`notice`。分页字段是 `list`、`totalCount`、`pageSize`、`totalPage`、`currPage`。详情仍走 `GET /v1/serviceItem/detail`。

## Goals / Non-Goals

**Goals:**

- 列表卡片对齐 Vue 可预约套餐：96 封面、两行标题、两行简介、价格、「去预约」。
- 封面用 `navigateUrl`，没有再用 `imgUrls` 第一张。简介去掉 HTML。
- `payType = 2` 确认后进入套包购买。

**Non-Goals:**

- 使用记录走 `GET /v1/cabin/appointments`。体检 `businessType=2`，就医协助 `businessType=3`。
- 不接工作人员群聊分配。免费预约确认后只提示工作人员会联系。

## Decisions

1. 列表封面用 `navigateUrl`，与康养配置列表一致。`imgUrls` 只作封面兜底，详情画廊仍用详情接口。
2. 价格用 `fdFont`，10.00 显示为 ¥10。
3. 卡片左右各 16，白底圆角 8，行间 1px 分割。空列表保持「暂无可预约体检套餐」。
4. 接口没有权益名称，不展示权益胶囊。

## Risks / Trade-offs

- 免费预约确认后没有真实下单接口，只做提示，避免跳进假会话。
