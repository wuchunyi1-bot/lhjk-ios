## Context

- 模块归属：**Health**（与 Service / Home 平级）
- CMS 覆盖范围（已确认）：**仅**体征监测卡片壳 + 下方快捷入口；评分 / 档案仍本地
- 楼层 code：**`column_health`**（APP）；小程序为 `health`（本客户端不传）
- 参考 UX：`funde-client` `MetricCardEditView.vue`（本地 Pinia；本端改真实 API）

## Goals / Non-Goals

**Goals:**

- Hub 体征区：`getMonitorCardList` 有数据则展示监测值；空/失败回退 CMS `monitorCardMeta` 空壳
- Hub 快捷入口：仅 `quickEntryList`；空则隐藏该 section
- 编辑页：查询 / 保存用户卡片配置；最多 6 张；拖拽排序；返回未保存确认
- `hospitalId` 合法数字串；禁止 mock 入参

**Non-Goals:**

- 本轮不接评分 / 档案 API
- 不实现体征原生录入（仍走 H5）
- 不删除 `MetricsViewController.swift` 文件（仅不再作为路由入口）

## Decisions

### 1. hospitalId

优先级：`InstitutionSelectionStore.selectedHospitalId` → `loginUserInfo.hospitalId` → `ServiceCatalogService.selectedApiHospitalId()`（含 `temporaryHospitalId`）。须 `validApiHospitalId`（纯数字）；失败则不请求、对应区块空。

### 2. 数据合并

```
并行 getCmsConfig + getMonitorCardList
  → quickEntries = CMS.quickEntryList（按 sortId）
  → metrics =
      list 非空 → fromMonitorCards(list)
      else      → fromCmsMeta(CMS.monitorCardMeta)
```

卡片背景：`backgroundUrl`（列表项）优先 → 本地 `metric_*` 按 metricKey → 无图仅底色。CMS 空壳无 backgroundUrl，走本地。

### 3. cardType（天使）

| cardType | 含义 | metric key |
|----------|------|------------|
| 2 | 血压 | `blood-pressure` |
| 3 | 血糖 | `blood-sugar` |
| 4 | 体温 | `temperature` |
| 5 | 体重 | `weight` |
| 10 | 饮食运动 | `exercise` |

`monitorCardMeta` **无** `pageUrl`；体征卡 key / 跳转仅由 `cardType` 映射。`pageUrl`（`FundeH5:` / `FundeApp:`）仅出现在 `quickEntryList`。

### 4. monitorData 展示

| 类型 | 取值字段 |
|------|----------|
| 血压 | `highBloodPressure` / `lowBloodPressure` + `unit` |
| 血糖等 | `value` + `unit` |
| 体重 | `weight` + `unit` |
| 体温 | `temperature` / `temp` + `unit` |
| 饮食运动 | `dietSportData.steps` 等 |

无数据展示 `--`；状态用 `result` / `resultType`。

### 5. 柔性解码

后端常把 `monitorTime`、id、sortId 以 **字符串** 下发。VO 使用 `HealthFlexible` 解码 Int/Int64（兼容 String / Double）。

### 6. 编辑页保存

- Body：`hospitalId`、`code=column_health`、`addCardVOList[{cardType, cardName?, sortId}]`
- **不传** `hiddenCardVOList`（服务端按 CMS 卡池计算）
- `sortId` 从 0 递增为展示列表全量顺序
- 上限 `MAX_VISIBLE = 6`

### 7. 路由

| Path | 目标 |
|------|------|
| `/health/metrics/edit` | `MetricCardEditViewController` |
| `/health/metrics` | 同上（兼容旧入口） |
| `/health/metrics/{key}` | H5（含新增 `temperature`） |

`FundeH5:` / `FundeApp:` 仅用于 `quickEntryList.pageUrl`（见 `funde-page-url-scheme`）。体征卡：`cardType` → `/health/metrics/{key}`。

## File map

| 角色 | 路径 |
|------|------|
| BLL Service + VO/Mapper | `BLL/Health/HealthPageService.swift` |
| Hub VM | `PL/Health/ViewModels/HealthViewModel.swift` |
| Hub VC | `PL/Health/HealthViewController.swift` |
| 编辑页 | `PL/Health/MetricCardEdit/` |
| 路由 | `BLL/Health/HealthRoutes.swift` |

## Risks

- Apifox `monitorData` schema 为开放 object；新指标字段需扩展 `extractValueUnit`
- 临时 `hospitalId` 与线上机构不一致时卡片为空或错机构数据
