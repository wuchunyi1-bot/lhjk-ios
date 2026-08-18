## 1. Spec

- [x] 1.1 同步更新 `health-page-vitals-cms-api` / `funde-page-url-scheme` 中对应条文（点击 pageUrl、取消 6 张上限）

## 2. 体征卡 pageUrl

- [x] 2.1 `MonitorCardMetaVO` / `MonitorHealthCardVO` 解码可选 `pageUrl`
- [x] 2.2 `HealthMetricDisplayItem` 携带 `pageUrl`；mapper 从列表与 CMS 空壳填入
- [x] 2.3 Hub 点击：`FundePageURL.canOpen` → `open`，否则 `cardType` 路由兜底

## 3. 编辑页上限

- [x] 3.1 去掉加载截断与 `showCard` 六张拦截；删除 `maxVisibleCards` 使用
