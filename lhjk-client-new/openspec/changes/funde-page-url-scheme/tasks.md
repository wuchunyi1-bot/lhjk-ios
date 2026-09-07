## 1. Spec / 公共能力

- [x] 1.1 新增 `Other/Common/FundePageURL.swift`：`parse` + `open`（FundeH5 → H5Config/WebView，FundeApp → Router）
- [x] 1.2 更新本 change 的 proposal / design / delta spec

## 2. 接入

- [x] 2.1 `HomeViewController.handleColumnContentPageUrl` 调用 `FundePageURL.open`
- [x] 2.2 `HealthViewController` 体征卡 / 快捷入口优先 `FundePageURL.open`；体征无前缀时 cardType 兜底
- [x] 2.3 `MonitorCardDisplayMapper` 的 FundeH5 解析与公共规则对齐（metricKey 可复用 parse）
- [x] 2.4 同步修订 `home-news` 等「解析另定」表述为指向本规则
- [x] 2.5 服务 Tab Banner、健康快捷入口、IM 卡片 / 通知中心的 `FundeH5:` 与体征卡同一套 `FundePageURL` 规则
