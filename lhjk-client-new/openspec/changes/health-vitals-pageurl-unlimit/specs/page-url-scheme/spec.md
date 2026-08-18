## MODIFIED Requirements

### Requirement: 健康 getCmsConfig 点击使用公共解析

`getCmsConfig` 中 `quickEntryList[].pageUrl` 以及体征监测卡（`monitorCardMeta` / `getMonitorCardList`）的 `pageUrl` SHALL 在合法时经 `FundePageURL` 打开。

合法指可解析为 `FundeH5:` 或 `FundeApp:`。体征卡无合法 `pageUrl` 时 SHALL 按 `cardType` → `/health/metrics/{key}` 兜底。

#### Scenario: 快捷入口

- **WHEN** 用户点击快捷入口且 `pageUrl` 为 FundeH5 / FundeApp
- **THEN** 按规则打开 H5 或本地路由

#### Scenario: 体征卡有合法 pageUrl

- **WHEN** 用户点击体征监测卡且 `pageUrl` 为 `FundeH5:` 或 `FundeApp:`
- **THEN** 系统经 `FundePageURL.open` 打开

#### Scenario: 体征卡无合法 pageUrl

- **WHEN** 用户点击体征监测卡且 `pageUrl` 为空或无法解析
- **THEN** 系统按 `cardType` 打开对应指标页
