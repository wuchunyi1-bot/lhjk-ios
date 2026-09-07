## Context

- 模块归属：**Health**（与 Service / Home 平级）
- CMS 覆盖范围（已确认）：**仅**体征监测卡片壳 + 下方快捷入口；评分 / 档案仍本地
- 楼层 code：**`column_health`**（APP）；小程序为 `health`（本客户端不传）
- 参考 UX：`funde-client` `MetricCardEditView.vue`（本地 Pinia；本端改真实 API）

## Goals / Non-Goals

**Goals:**

- Hub 体征区：`getMonitorCardList` 有数据则展示监测值；空/失败回退 CMS `monitorCardMeta` 空壳
- Hub 快捷入口：仅 `quickEntryList`；空则隐藏该 section
- 编辑页：查询 / 保存用户卡片配置；不限制可见张数；拖拽排序；返回未保存确认
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
| 14 | 血脂 | `blood-lipid` |

`monitorCardMeta` / 监测列表可含 `pageUrl`；合法时走 `FundePageURL`，否则跳转由 `cardType` 映射。`quickEntryList` 的 `pageUrl`（`FundeH5:` / `FundeApp:`）同样经 `FundePageURL`。

### 4. monitorData 展示

| 类型 | 取值字段 |
|------|----------|
| 血压 | `highBloodPressure` / `lowBloodPressure` + `unit` |
| 血糖等 | `value` + `unit` |
| 体重 | `weight` + `unit` |
| 体温 | `temperature` / `temp` + `unit` |
| 饮食运动 | 见下节「饮食运动卡」；不使用 `steps` 单值 |
| 血脂 | 见下节「血脂卡」；不使用单值 |

无数据展示 `--`；状态用 `result` / `resultType`。

### 4.1 饮食运动卡（cardType = 10）

Hub 网格独立三列布局（标题 12 / 标签 8 / 数字 12 Medium / 圆环 52×3pt）。

| 列 | 字段 | 规则 |
|----|------|------|
| 今日摄入 | `dietSportData.intake` | 整数截断 |
| 还可摄入 | `dietSportData.remainingIntake` | 整数截断；`< 0` 展示 0 |
| 今日消耗 | `sport.consumeNum` | 整数截断 |

推荐摄入 = `calculateCaloricVo.finalIntake`（否则 `totalCalories`）。

圆环：`progress = 1 − clamp(还可摄入 / 推荐摄入, 0, 1)`；推荐 ≤ 0 则 progress=0（全灰）。

标题「饮食运动」在图标下方，不得被三列遮挡。

无数据展示 `--`；状态用 `result` / `resultType`。

### 4.2 血脂卡（cardType = 14）

Hub 网格独立 2×2 布局（Figma 3543:3452）：标题 12 Regular `#717885`；TC/TG/HDL/LDL 标签与数值均为 12 `#1F2430`（标签 Regular、数值 Medium）；时间 12 Regular `#1F2430`。不展示单位。

| 格 | 字段 |
|----|------|
| TC | `monitorData.totalCholesterol` |
| TG | `monitorData.triglycerides` |
| HDL | `monitorData.highDensityLipoprotein` |
| LDL | `monitorData.lowDensityLipoprotein` |

徽标：`abnormalCount > 0` →「N项异常」；否则 `result`（缺省「正常」）。时间只到日期。

无四项数据展示「去记录」。跳转优先 `pageUrl`（`FundeH5:/blood-lipid`）。

### 5. 柔性解码

后端常把 `monitorTime`、id、sortId 以 **字符串** 下发。VO 使用 `HealthFlexible` 解码 Int/Int64（兼容 String / Double）。

### 6. 编辑页保存

- Body：`hospitalId`、`code=column_health`、`addCardVOList[{cardType, cardName?, sortId}]`
- **不传** `hiddenCardVOList`（服务端按 CMS 卡池计算）
- `sortId` 从 0 递增为展示列表全量顺序

### 7. 路由

| Path | 目标 |
|------|------|
| `/health/metrics/edit` | `MetricCardEditViewController` |
| `/health/metrics` | 同上（兼容旧入口） |
| `/health/metrics/{key}` | H5（含新增 `temperature`） |

`FundeH5:` / `FundeApp:` 用于 `quickEntryList.pageUrl` 以及体征卡合法 `pageUrl`（见 `funde-page-url-scheme`）。无合法 pageUrl 时：`cardType` → `/health/metrics/{key}`。

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
