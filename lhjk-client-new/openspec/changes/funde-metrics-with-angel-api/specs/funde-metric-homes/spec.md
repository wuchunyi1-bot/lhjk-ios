# Funde Metric Homes / Funde 体征 Hub + Angel API

## Purpose

Hub 入口使用 Funde 风格单页 UI；数据来自 jumper-angel-doctor 对应监测/饮食运动接口。录入与详情继续走已实现的 Angel 子页面。

---

## Module Entry Points

| 路由 | Funde VC | BLL Service | 子页（保留） |
|------|----------|-------------|--------------|
| `/health/metrics/blood-pressure` | `BloodPressureViewController` | `BloodPressureService` | `/manual` `/history` `/detail` |
| `/health/metrics/blood-sugar` | `BloodSugarViewController` | `BloodSugarService` | `/manual` `/history` `/detail` |
| `/health/metrics/weight` | `WeightViewController` | `WeightService` | `/manual` `/history` `/detail` |
| `/health/metrics/exercise` | `ExerciseFoodViewController` | `ExerciseFoodService` | `/add-diet` `/add-motion` `/search` |

---

## Shared Requirements

### Requirement: Funde UI + Real API

各 Hub 页 SHALL 保持 Funde 布局（分段、图表卡、统计卡、近期记录卡），SHALL NOT 使用硬编码监测 mock 填充图表或列表。

#### Scenario: 有数据

- **WHEN** Service 返回非空历史/当日数据
- **THEN** 图表、统计、记录列表绑定真实字段

#### Scenario: 无数据

- **WHEN** 接口空列表或失败（失败 Toast）
- **THEN** 展示空态或 `--`，不填假曲线点

### Requirement: Architecture

PL Hub VC SHALL 通过 ViewModel 调用 BLL Service；禁止 VC 直连 `APIManager`。

#### Scenario: 注入

- **WHEN** ViewModel `init`
- **THEN** 默认 `AppContainer.shared.*Service`

### Requirement: Navigation to Angel Sub-flows

Funde Hub SHALL 提供进入录入/历史的入口（导航栏按钮或列表「添加」）。

#### Scenario: 添加

- **WHEN** 用户点添加
- **THEN** push 对应 `/manual` 或饮食/运动 add 路由

---

## Blood Pressure

### UI（Funde）

- 标题「血压管理」；Segment 日 / 周 / 月
- 双折线：收缩压 `#FF7A50`、舒张压 `#6B9FE4`
- 统计：平均收缩 / 平均舒张 / 脉压差（可由均差值推导）
- 近期记录：时间、`sys/dia`、来源

### API

- 趋势：`POST /v1/monitor/selectPressureHistoryData`，`dateType=2`，`timeType` 映射 1|7|30，`pageSize=1000`
- 可选最新：`getPressureHomePageData` 用于顶部补充（可不展示圆环）

### Requirement: BP Period Reload

#### Scenario: 切换时段

- **WHEN** 用户切换 Segment
- **THEN** 以新 `timeType` 请求并刷新图与统计

---

## Blood Sugar

### UI（Funde）

- 标题「血糖管理」；可保留「指血血糖」Tab（「动态血糖」暂无同源或提示）
- 折线：优先空腹 + 餐后 2h；若餐次无法区分则单线「血糖」
- 统计：最高 / 最低 / 波动
- 记录：时间、数值、餐次、来源

### API

- `getSugarHistory`（`dateType=5`，`timeType`，可选 `type`）
- `getSugarRecords` 用于近期列表（当月分页首屏）
- `getSugarTypes` 用于匹配空腹/餐后 type

### Requirement: Sugar Chart Source

#### Scenario: 分餐次曲线

- **WHEN** 历史 monitors 含多种餐次
- **THEN** 尽量拆为空腹与餐后序列；否则一条序列 + 图例「血糖」

---

## Weight

### UI（Funde）

- 标题「体重管理」；Segment 日/周/月（客户端过滤）
- 进度卡：当前体重 / 距离目标（无目标接口时仅当前 + BMI，目标文案隐藏或用服务端 recommend）
- 单折线体重；可选推荐区间不强制画 Angel 点色
- 统计：起始 / 当前 / 变化 / BMI
- 记录列表

### API

- `selectWeightHistoryData`（`dateType=4`，`type=2`）
- `getWeightHomePageData` 取最新 BMI/建议
- `getWeightRecords` 近期日志

### Requirement: Weight Client Filter

#### Scenario: 月切换

- **WHEN** 用户选「月」
- **THEN** 在 chart 全量结果中按近 30 天过滤后刷新

---

## Exercise / Food

### UI（Funde）

- 标题「饮食运动」
- 热量卡：今日摄入 / 还可摄入（`intake`、`remainingIntake`；有方案用推荐文案）
- **营养摄入卡**：接口无碳水/脂肪/蛋白 → **隐藏整块**，不得填 mock g 数
- 运动卡：展示「运动消耗 {consumeNum} kcal」（无步数接口时不展示假步数）
- 入口：「记录饮食」「记录运动」→ Angel 添加页；AI 拍照 Toast 延后

### API

- `getSportDietListByToday(date: today)`
- 日期可选切换（与 ExerciseFoodHome 一致时可简化为仅今日）

### Requirement: No Fake Nutrition

#### Scenario: 无营养字段

- **WHEN** DaySummary 不含三大营养素
- **THEN** 营养卡不显示

---

## Acceptance Checklist

- [ ] 四 Hub 路由指向 Funde VC
- [ ] 四页无 mock 进入图表/列表
- [ ] 血压/血糖 period 或体重过滤切换会重新拉数
- [ ] 可从 Hub 进入手动/历史或饮食运动添加
- [ ] Spec 与代码一致；新增/恢复文件提示加入 Xcode
