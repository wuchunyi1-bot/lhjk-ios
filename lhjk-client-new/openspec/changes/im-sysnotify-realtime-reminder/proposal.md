# Change: AD:SysNotify 实时提醒卡（extra.type=realTime）

## Why

生产下发的监测「实时提醒」使用 `AD:SysNotify`，且嵌套 `extra.type=realTime`。当前 iOS 仅按 `extra.rows` 非空判为 C-monitor（录入成功卡），会隐藏 `content`、无「去完成」、不可点，与截图 / funde-client `monitor-reminder` 不符。

## What Changes

- 新增 SysNotify 变体：`monitorReminder`（实时提醒）
- 判定优先：`extra.type == realTime`
- UI：圆标 + 标题 +「监测任务」tag + 说明文案 + KV rows +「去完成 ›」
- 点击：按 `urlKey` / `monitorType` 进健康指标录入路由；`completed` 已完成则不可点
- 更新 `openspec/specs/im/message-cards.md` / `message-types.md`

## Impact

- `IMCardVariant` / `IMCardResolver` / `SysNotifyCell` / `ChatViewController`
- IM OpenSpec
