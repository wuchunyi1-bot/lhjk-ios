## 1. BLL / DAL

- [x] 1.1 新增 `HealthPageService`（CMS / 卡片列表 / 查询配置 / 保存配置）
- [x] 1.2 VO + `HealthFlexible` 柔性解码；`MonitorCardDisplayMapper`
- [x] 1.3 `AppContainer.healthPageService` 注册
- [x] 1.4 `H5Config` 补充 `temperature`

## 2. 健康 Hub

- [x] 2.1 `HealthViewModel`：并行拉 CMS + 卡片列表；合并规则；快捷入口
- [x] 2.2 `HealthViewController`：订阅 metrics / quickEntries；编辑走 `/health/metrics/edit`
- [x] 2.3 `MetricCardCell` 支持 `iconUrl`；快捷入口 CMS 图标
- [x] 2.4 删除 Hub 硬编码 metrics / quickEntries mock
- [x] 2.5 `MonitorHealthCardVO.backgroundUrl` + 展示优先网络背景、回退本地 `metric_*`

## 3. 编辑卡片

- [x] 3.1 `MetricCardEditViewController` + `MetricCardEditViewModel`
- [x] 3.2 最多 6 张、显隐、拖拽、保存 `addCardVOList`
- [x] 3.3 路由 `/health/metrics/edit` 与 `/health/metrics` 指向编辑页

## 4. 文档

- [x] 4.1 OpenSpec change `health-page-vitals-cms-api`
- [x] 4.2 `docs/api-inventory.md` 登记 4 个监测接口
