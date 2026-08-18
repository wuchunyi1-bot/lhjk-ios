## MODIFIED Requirements

### Requirement: 快捷入口仅来自 CMS

系统 SHALL 仅使用 CMS `quickEntryList` 驱动 Hub 下方快捷入口；禁止硬编码入口列表。

#### Scenario: 快捷入口为空

- **WHEN** `quickEntryList` 为空或缺失
- **THEN** 隐藏快捷入口 section

#### Scenario: 点击跳转

- **WHEN** 用户点击快捷入口
- **THEN** 使用 `quickEntryList[].pageUrl`（`FundeH5:` / `FundeApp:`）经 `FundePageURL` 打开

- **WHEN** 用户点击体征卡片且该项 `pageUrl` 可被 `FundePageURL` 解析（`FundeH5:` / `FundeApp:`）
- **THEN** 系统 MUST 经 `FundePageURL.open` 打开，MUST NOT 再用 `cardType` 覆盖该跳转

- **WHEN** 用户点击体征卡片且 `pageUrl` 为空、无前缀或无法解析
- **THEN** 按 `cardType` 映射为 `/health/metrics/{key}` 并打开对应 H5

### Requirement: 编辑卡片配置

系统 SHALL 提供编辑页：查询 `GET /v1/userMonitorCardConfig/getUserMonitorCardConfig`，保存 `POST /v1/userMonitorCardConfig/saveUserMonitorCardConfig`。

#### Scenario: 进入编辑页

- **WHEN** Hub 点击「编辑卡片」或路由 `/health/metrics/edit`（及兼容 `/health/metrics`）
- **THEN** 打开 `MetricCardEditViewController`，展示当前可见卡片与可选卡池
- **AND** MUST NOT 因张数将已显示卡片截断进隐藏区

#### Scenario: 无可见张数上限

- **WHEN** 用户从隐藏区将卡片加入显示区
- **THEN** 系统 MUST 允许加入，MUST NOT 以「不能超过六张」拒绝

#### Scenario: 保存

- **WHEN** 用户确认保存
- **THEN** Body 提交 `hospitalId`、`code=column_health`、`addCardVOList`（含 `cardType`、可选 `cardName`、`sortId` 从 0 递增）；不提交 `hiddenCardVOList`；成功后返回 Hub 并刷新体征区

#### Scenario: 返回未保存

- **WHEN** 用户有未保存修改并返回
- **THEN** 弹出确认；确认丢弃后返回，取消则留在编辑页

## ADDED Requirements

### Requirement: 体征卡解码 pageUrl

系统 SHALL 从 `getCmsConfig.monitorCardMeta[]` 与 `getMonitorCardList[]` 解码可选 `pageUrl`，并带入 Hub 展示模型。MUST NOT 因缺少该字段导致整包解码失败。

#### Scenario: 列表项带 pageUrl

- **WHEN** 监测卡片 JSON 含非空 `pageUrl`
- **THEN** 点击使用该值做 `FundePageURL` 解析

#### Scenario: 无 pageUrl 字段

- **WHEN** JSON 无 `pageUrl` 或为空
- **THEN** 展示仍成功；点击走 `cardType` 兜底
