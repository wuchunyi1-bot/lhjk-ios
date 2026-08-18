## Context

体征卡跳转原先假定 `monitorCardMeta` / `getMonitorCardList` **无** `pageUrl`，仅 `cardType` 映射。快捷入口已走 `FundePageURL`。编辑页 `maxVisibleCards = 6`。

## Goals / Non-Goals

**Goals:**

- 合法 `pageUrl`（`FundeH5:` / `FundeApp:`，即 `FundePageURL.canOpen`）优先打开
- 无合法 `pageUrl` 时保持 `cardType` 兜底
- 编辑页可展示全部已选卡片，从隐藏区加入不再被 6 张拦截

**Non-Goals:**

- 不改快捷入口逻辑
- 不扩展 `cardType` 枚举表（未知类型仍走既有兜底 key）
- 不改保存接口字段

## Decisions

### 1. 合法 pageUrl = `FundePageURL.canOpen`

与快捷入口同一套前缀规则。空串、无前缀、无法解析 → 视为不合法，走 `cardType`。

### 2. 两处 VO 都解码 pageUrl

`MonitorCardMetaVO`（CMS 空壳）与 `MonitorHealthCardVO`（列表）均增加可选 `pageUrl`，传入 `HealthMetricDisplayItem`。

### 3. 取消 6 张上限

删除加载截断与 `showCard` 拦截；不再使用 `maxVisibleCards`。

## Risks / Trade-offs

- [Risk] 运营配了错误 pageUrl → 打开失败或白屏 → 前缀合法才会走 FundePageURL，其余仍兜底
- [Trade-off] Hub 卡片变多后行高随行数增高（现有 `height(for: count)` 已按行计算）

## Migration Plan

1. Spec
2. VO + 点击 + 编辑 VM
3. 真机点带 pageUrl 的卡与超过 6 张的编辑

## Open Questions

无。
