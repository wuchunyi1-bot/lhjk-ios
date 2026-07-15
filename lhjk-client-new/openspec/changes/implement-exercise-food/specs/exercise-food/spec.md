# Exercise Food / 饮食运动

## Purpose

从 jumper-angel-doctor `FoodAndMotion` 模块移植饮食与运动记录能力到 lhjk-client iOS。保持接口路径与参数字段不变，UI 对齐源项目主流程。模块归属 **Health Tab**（`BLL/Health`、`PL/Health/Metrics/ExerciseFood`）。

> **Reference**: `AngelDoctor/Classes(业务)/Me/FoodAndMotion/`

---

## Module Flow

```
健康 Hub / 体征网格
    └── /health/metrics/exercise  →  饮食运动首页（当日记录）
            ├── 日期切换（不可选未来）
            ├── 热量摘要头（还可摄入 / 食物摄入 / 运动消耗）
            ├── 按餐次分区列表（早餐…晚加餐）
            ├── 运动分区列表
            ├── 底部栏：+早餐 +午餐 +晚餐 +加餐 +运动
            ├── /add-diet?timeType=&date=  →  添加饮食（左分类 + 右食材）
            │       └── /search?type=2  →  搜索食材
            └── /add-motion?date=  →  添加运动
                    └── /search?type=1  →  搜索运动

点击已有记录 → 数量/时间编辑弹层 → 修改（saveSportDietData）或删除（delMonitorDataByMonitorId）
```

---

## Business Constants

| 常量 | 值 |
|------|-----|
| 保存运动 `businessId` | 8 |
| 保存饮食 `businessId` | 9 |
| `getDefinitionCommonByParam.type` 运动 | 1 |
| `getDefinitionCommonByParam.type` 食材 | 2 |
| 食材分类字典 `parentId` | `1373093850922487808` |
| 默认分页 `pageSize` | 20 |

### 餐次 timeType

| 值 | 文案 |
|----|------|
| 1 | 早餐 |
| 2 | 早加餐 |
| 3 | 午餐 |
| 4 | 午加餐 |
| 5 | 晚餐 |
| 6 | 晚加餐 |

---

## API Contract

所有接口经 `APIManager`，base 已含 `/mobile`。

### 1. 当日饮食运动汇总

- **Path**: `POST /v1/sportDiet/getSportDietListByToday`
- **Request**:

```json
{ "date": "yyyy-MM-dd" }
```

- **Response** (`ExerciseFoodDaySummary`):

| 字段 | 说明 |
|------|------|
| remainingIntake | 还可摄入 / 实际摄入（kcal，字符串） |
| recommendCalories | 运动建议文案；`null` 表示无方案 |
| intake | 食物摄入量 kcal |
| status | 状态（偏高/偏低/达标） |
| sport | `{ consumeNum, list[] }` |
| diet | `[{ timeType, consumeNum, list[] }]` 按餐次 |

`list[]` 项字段（`ExerciseFoodRecordItem`）：`id`, `name`, `imgSmallUrl`, `quantity`, `showQuantity`, `showCalorie`, `calorie`, `monitorId`, `timeType`, `dateStr`, `unit`, `coefficient`, `maxNum`, `dataSource`

### 2. 日历打点（有记录日期）

- **Path**: `POST /v1/sportDiet/getSportDietCalendar`
- **Request**: `{ "dates": "逗号分隔日期或月份范围，与源项目 scroll 回调一致" }`
- **Response**: 日期字符串数组（有记录的日期）

### 3. 保存 / 修改饮食或运动

- **Path**: `POST /v1/sportDiet/saveSportDietData`
- **Request**:

```json
{
  "beginTime": "毫秒时间戳",
  "endTime": "毫秒时间戳",
  "description": "",
  "businessId": 8,
  "timeType": 1,
  "data": [
    {
      "id": 123,
      "name": "米饭",
      "quantity": 100,
      "calorie": "116",
      "description": "",
      "timeType": 1
    }
  ]
}
```

- `businessId`: `8` 运动，`9` 饮食
- 饮食添加：`beginTime`/`endTime` 为选中日期 + 当前时分
- 运动添加：可带运动开始时间 `yyyy-MM-dd HH:mm`
- 修改单条：传 `timeType` + 更新后的 `data` 单项；源项目修改饮食时 `businessId=9`，运动 `businessId=8`

### 4. 食材/运动字典列表

- **Path**: `POST /v1/definitionCommon/getDefinitionCommonByParam`
- **Request**:

```json
{
  "type": 1,
  "pageNum": 1,
  "pageSize": 20,
  "status": 1,
  "category": 0,
  "name": "可选，搜索关键字"
}
```

- `type=2` 食材时可传 `category`（食材大类 value）
- **Response**: `{ "list": [ExerciseFoodDefinitionItem] }`

### 5. 食材分类

- **Path**: `POST /v1/dictionary/getDictionaryByParentId2`
- **Request**: `{ "parentIds": [1373093850922487808], "allStatus": true }`
- **Response**: 字典树，`children` 为左侧分类列表（`name`, `value`）

### 6. 删除记录

- **Path**: `DELETE /v1/monitor/delMonitorDataByMonitorId?monitorId={id}`
- 与监测模块共用删除接口

---

## Layout — 饮食运动首页

```
┌──────────────────────────────────────────┐
│  Nav: 饮食运动                            │
├──────────────────────────────────────────┤
│  [←]  2026年07月14日  [→]  （不可未来）    │
├──────────────────────────────────────────┤
│  渐变热量卡（ExerciseFoodCalorieHeaderView）│
│  左：食物摄入  中：还可摄入/多摄入  右：运动消耗│
├──────────────────────────────────────────┤
│  UITableView grouped                      │
│  Section: 早餐 / 早加餐 / … / 运动         │
│  Row: 图标 + 名称 + 份量 + kcal            │
├──────────────────────────────────────────┤
│  底栏：早餐 | 午餐 | 晚餐 | 加餐 | 运动    │
└──────────────────────────────────────────┘
```

- 背景 `#F9F8F8` / `fdBg`
- 空态：当日无记录时展示空态文案
- 左滑删除或点击行编辑后删除

### 热量中心文案逻辑（对齐源 `ADFootRecordHeadView`）

| 条件 | 中心标题 |
|------|----------|
| 无 `recommendCalories` 且 remaining < 0 | 您实际消耗 |
| 无 `recommendCalories` 且 remaining ≥ 0 | 您实际摄入 |
| 有方案且 remaining < 0 | 您多摄入了 |
| 有方案且 remaining ≥ 0 | 您还可摄入 |

---

## Layout — 添加饮食

- 导航「添加饮食」；右侧「拍照记录」入口（**延后实现**，spec 保留）
- 搜索栏 → `/health/metrics/exercise/search?type=2`
- 左侧分类 Table（90pt）+ 右侧食材 Table
- 底部栏：已选 kcal 合计 + 确定
- 点击食材 → `ExerciseFoodQuantitySheet` 选数量 → 加入已选
- 确定 → `saveSportDietData(businessId:9)`

---

## Layout — 添加运动

- 导航「添加运动」
- 搜索栏 → `type=1`
- 运动列表 + 底部合计栏
- 确定 → `saveSportDietData(businessId:8)`

---

## Layout — 搜索

- 共用 `ExerciseFoodSearchViewController`
- `type=1` 运动 / `type=2` 食材
- 搜索框 + 分页列表；选中项回传上一页

---

## Requirements

### Requirement: Architecture
饮食运动模块 SHALL 遵循 PL → BLL → DAL；PL 禁止直连 `APIManager`。

#### Scenario: Service 注入
- **WHEN** ViewModel 初始化
- **THEN** 默认 `AppContainer.shared.exerciseFoodService`

---

### Requirement: Daily Home
系统 SHALL 按日期展示饮食与运动记录及热量摘要。

#### Scenario: 加载当日
- **WHEN** 首页 `viewWillAppear` 或切换日期
- **THEN** 请求 `getSportDietListByToday(date:)` 刷新头图与列表

#### Scenario: 不可选未来
- **WHEN** 用户选择日期
- **THEN** 最大日期为今天

#### Scenario: 底部入口
- **WHEN** 用户点击「+早餐」
- **THEN** push 添加饮食页，`timeType=1`，`date` 为当前选中日期

---

### Requirement: Add Diet / Motion
系统 SHALL 支持从字典库选择食材或运动并批量保存。

#### Scenario: 分类切换
- **WHEN** 用户点击左侧食材分类
- **THEN** 以 `category` 重新请求 `getDefinitionCommonByParam(type:2)`

#### Scenario: 保存校验
- **WHEN** 未选择任何项就点确定
- **THEN** Toast「请添加食物」或「请添加运动」

---

### Requirement: Edit / Delete
系统 SHALL 支持修改单条记录数量与删除。

#### Scenario: 删除
- **WHEN** 用户确认删除
- **THEN** `delMonitorDataByMonitorId`，发送 `exerciseFoodRecordDidChange`，刷新首页

#### Scenario: 修改
- **WHEN** 用户在弹层调整数量并保存
- **THEN** `saveSportDietData` 带 `timeType` 与更新数据

---

### Requirement: Routing

| 路由 | 页面 |
|------|------|
| `/health/metrics/exercise` | 首页 |
| `/health/metrics/exercise/add-diet` | 添加饮食（`timeType`, `date`） |
| `/health/metrics/exercise/add-motion` | 添加运动（`date`） |
| `/health/metrics/exercise/search` | 搜索（`type`, `timeType?`, `date?`） |

---

### Requirement: No Mock Data
接入真实 API 后 SHALL NOT 使用硬编码热量/营养 mock 数据。

---

## Component Inventory

| Component | 说明 |
|-----------|------|
| `ExerciseFoodCalorieHeaderView` | 热量摘要头 |
| `ExerciseFoodDateBarView` | 日期切换条 |
| `ExerciseFoodBottomBarView` | 底部五入口 |
| `ExerciseFoodRecordCell` | 饮食/运动记录行 |
| `ExerciseFoodSectionHeaderView` | 餐次/运动分区头 |
| `ExerciseFoodDefinitionCell` | 字典项行（添加页） |
| `ExerciseFoodCategoryCell` | 左侧分类行 |
| `ExerciseFoodAddBottomBar` | 添加页底部合计 |
| `ExerciseFoodQuantitySheet` | 数量/卡路里编辑弹层 |
| `MetricRulerView` | 刻度尺（复用） |

## Deferred

- 拍照识别食物（`ADAddPhotoFoodViewController`）
- 横滑周历 + `getSportDietCalendar` 打点 UI
- 导航栏跳转健康报告
- 食材详情 Web 页

## Acceptance Checklist

- [ ] 首页展示 API 当日热量摘要与分区列表
- [ ] 添加饮食/运动保存成功并返回刷新
- [ ] 搜索、分页、分类筛选来自真实接口
- [ ] 删除/修改后首页自动刷新
- [ ] 无 mock 热量数据
- [ ] 路由从 Hub 正确进入
- [ ] 新增 Swift 文件已加入 Xcode 工程
