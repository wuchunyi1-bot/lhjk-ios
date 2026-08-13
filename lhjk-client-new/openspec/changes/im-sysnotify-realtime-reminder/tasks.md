## 1. Spec

- [x] 1.1 本 change proposal / design / delta spec
- [x] 1.2 同步主规格 `message-cards.md` / `message-types.md`

## 2. Resolver

- [x] 2.1 `IMCardVariant.monitorReminder`；判定优先 `extra.type=realTime`
- [x] 2.2 tag 默认「监测任务」；`clickable` / `tapAction` 打开录入路由
- [x] 2.3 `IMMonitorReminderRoute` 映射 urlKey / monitorType

## 3. UI

- [x] 3.1 `SysNotifyCell` 渲染提醒卡（content + rows + CTA）
- [x] 3.2 `ChatViewController` 处理 `cellDidTapIMCard` 跳转
