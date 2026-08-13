## ADDED Requirements

### Requirement: SysNotify 实时提醒变体

当 `objectName` 为 `AD:SysNotify` 且嵌套 `extra.type` 等于 `realTime` 时，系统 SHALL 解析为变体 `monitorReminder`（实时提醒卡），MUST NOT 当作录入成功卡 `monitor`。

#### Scenario: 识别 realTime

- **WHEN** 消息为 AD:SysNotify 且解析后的 `extra.type == "realTime"`
- **THEN** variant 为 `monitorReminder`

#### Scenario: 录入成功仍走 monitor

- **WHEN** `extra.type` 不是 `realTime` 且 `extra.rows` 非空
- **THEN** variant 仍为 `monitor`

### Requirement: 实时提醒卡 UI

`monitorReminder` SHALL 展示：主题色圆图标（按 `monitorType`）、`title`、来源 tag（缺省「监测任务」）、`content` 说明、分隔线、`rows` KV、底部 CTA。

#### Scenario: 未完成

- **WHEN** `extra.completed` 为空或 `"0"` / false
- **THEN** CTA 文案为「去完成 ›」，卡片可点击

#### Scenario: 已完成

- **WHEN** `extra.completed` 为 `"1"` 或 true
- **THEN** CTA 为「已完成」或等价禁用态，MUST NOT 跳转

### Requirement: 去完成跳转

点击未完成的实时提醒卡时，系统 SHALL 根据 `monitorType` 与/或 `urlKey` 打开对应健康指标录入页（对齐 funde-client `monitor-reminder-routes`）。

#### Scenario: weight

- **WHEN** `monitorType` 为 `weight` 或 urlKey 含体重相关 path（如 `tizhong`）
- **THEN** 打开体重录入路由（如 `/health/metrics/weight/add`）
