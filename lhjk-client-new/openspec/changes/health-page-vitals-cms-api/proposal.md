## Why

健康 Tab「体征监测」与下方快捷入口仍为本地硬编码；需接入「我的健康页」CMS / 监测卡片列表 / 用户卡片配置读写接口，并按 funde-client 提供「编辑卡片」页。评分卡与档案卡本轮保持本地现状。

## What Changes

- 新增 `HealthPageService`：4 个 `/v1` 接口（CMS、卡片列表、查询配置、保存配置）
- 健康 Hub：`HealthViewModel` 合并卡片列表与 CMS 壳；快捷入口走 CMS；删除硬编码 metrics/quickEntries
- 「编辑卡片」→ `MetricCardEditViewController`（最多 6 张、显隐、拖拽排序、保存）；不再进入旧 `MetricsViewController` 网格页
- `FundeH5:/…` pageUrl 映射为 App `/health/metrics/{key}`；`cardType` 对齐天使枚举
- 路由：`/health/metrics/edit`、`/health/metrics` → 编辑页；保留 `/health/metrics/{key}` H5

## Capabilities

### New Capabilities

- `health-page-vitals`: 健康首页体征监测区 + 快捷入口 + 编辑卡片配置

### Modified Capabilities

- （无已归档主规格；健康 Hub UI 延续既有 Figma 布局）

## Impact

- `BLL/Health/HealthPageService.swift`、`HealthRoutes.swift`
- `PL/Health/HealthViewController.swift`、`ViewModels/HealthViewModel.swift`
- `PL/Health/Cells/HealthVitalMetricsCell.swift`、`MetricCardCell.swift`、`HealthQuickEntriesCell.swift`
- `PL/Health/MetricCardEdit/*`
- `Other/Common/H5Config.swift`（补充 `temperature`）
- `DAL/AppContainer.swift`（注册 `healthPageService`）
- `docs/api-inventory.md`

Apifox（只读）：

- [CMS](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/495657301e0.md)
- [卡片列表](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/495657300e0.md)
- [查询配置](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/495657299e0.md)
- [保存配置](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/495657298e0.md)
