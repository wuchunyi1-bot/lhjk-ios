## Why

体征监测卡接口已下发 `pageUrl`（`FundeH5:` / `FundeApp:`），客户端却只按 `cardType` 跳转，导致用药、营养补剂、血氧等 CMS 配置无法生效。编辑卡片仍硬限制最多 6 张，与运营可配卡数不符。

## What Changes

- 体征卡解码 `pageUrl`；合法则 `FundePageURL.open`，否则仍按 `cardType` → `/health/metrics/{key}`
- 编辑页去掉「最多 6 张」拦截与加载时截断

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `health-page-vitals`：体征卡点击走 pageUrl；编辑页取消可见张数上限
- `page-url-scheme`：`getCmsConfig` / 监测列表的体征卡 `pageUrl` 纳入公共解析

## Impact

- `BLL/Health/HealthPageService.swift`（VO / 展示模型）
- `PL/Health/HealthViewController.swift`
- `PL/Health/MetricCardEdit/ViewModels/MetricCardEditViewModel.swift`
