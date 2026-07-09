# Service / 推荐服务 & 搜索套餐（商城）

## Purpose

**服务 Tab（商城模块）** 套包相关能力：

1. **推荐服务**（服务首页底部区块）：横向类目 Tab 来自数据字典，Tab 下套包列表来自医院套包分页接口
2. **搜索套餐**（服务首页顶栏搜索入口）：同一套包分页接口，按关键字 `name` 查询

> 本能力归属 **Service / 商城模块**，不得放入 `BLL/Health` 或 `PL/Health`。
>
> **Tab 字典 Apifox**: `POST /v1/dictionary/getDictionaryByParentId2`（与德系 9 宫格相同接口，parentId 不同）
> **套包列表 Apifox**: [分页查询医院启用的套包](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/484150836e0)

---

## 套包分页接口（共用）

`GET /v1/hospitalPackage/getEnabledHospitalPackagePage`

两种业务场景共用同一接口，**必传字段不同**：

| 场景 | 必传 Query | 可选 Query | 说明 |
|------|-----------|-----------|------|
| **推荐服务** | `packageMainCategory` | `hospitalId` | 由字典 Tab 的 `value` 映射；**仅**在有后端医院 id（`Long` 纯数字字符串）时传 |
| **搜索套餐** | `name` | `hospitalId` | `name` 为用户输入的关键字；**仅**在有后端医院 id 时传 |

`hospitalId` **不得**使用 mock 机构本地 id。机构列表 API 接入前不传 `hospitalId`。

**Mock 禁用**：服务首页已接字典、Banner、套包等真实 API，相关 BLL **不得**再保留 mock 机构/商品数据，不得将 mock 值传入请求参数。

两种场景均传分页参数：`pageNum`、`pageSize`。

#### Scenario: 推荐服务 — 按类目查询

- **WHEN** 服务首页已选中某个推荐服务 Tab
- **THEN** BLL 调用 `GET /v1/hospitalPackage/getEnabledHospitalPackagePage`
- **AND** **必传** `packageMainCategory` = 当前 Tab 字典 `value`
- **AND** 若当前机构有后端 `hospitalId`（`Long` 纯数字字符串），则传递；mock 机构或无有效 id 时**不传**
- **AND** `pageNum` = `"1"`（Hub 首屏）、`pageSize` = `"10"`

#### Scenario: 推荐服务 — 缺少 packageMainCategory

- **WHEN** 字典 Tab 的 `value` 为空
- **THEN** BLL 不发起请求，该 Tab 下套包列表为空

#### Scenario: 搜索套餐 — 按关键字查询

- **WHEN** 用户在搜索页输入关键字并触发搜索（回车或防抖输入）
- **THEN** BLL 调用同一接口 `GET /v1/hospitalPackage/getEnabledHospitalPackagePage`
- **AND** **必传** `name` = 用户输入的关键字（trim 后非空）
- **AND** 若路由带入或当前机构有后端 `hospitalId`（`Long` 纯数字），则传递；否则不传
- **AND** `pageNum` = `"1"`、`pageSize` = `"10"`（首版仅第一页）

#### Scenario: 搜索套餐 — 空关键字

- **WHEN** 搜索关键字为空或仅空白
- **THEN** 不发起请求，清空结果列表

---

## Layout（服务首页 Section: recommend）

在德系 9 宫格之后：

```
Section recommend: 推荐服务
├── sectionHeader: "推荐服务"
├── Row 0: HealthPackageCategoryCell（横向 Tab，来自字典 children）
└── Row 1..N: HealthPackageCardCell（套包卡片，来自分页接口 list）
```

---

## Requirements

### Requirement: 推荐服务类目 Tab

系统 SHALL 通过字典接口加载推荐服务横向 Tab 栏。

#### Scenario: 加载类目

- **WHEN** 服务首页 `viewWillAppear` 或用户触发刷新
- **THEN** BLL 调用 `POST /v1/dictionary/getDictionaryByParentId2`
- **AND** 请求体 `{ "parentIds": [2074711807339139072], "allStatus": true }`
- **AND** 取返回节点的 `children` 作为 Tab 列表，完整映射为 `ServiceRecommendCategory`
- **AND** 按 `sortId` 升序、`status == 1` 过滤

| 字典字段 | `ServiceRecommendCategory` | 套包查询（推荐服务） |
|----------|---------------------------|---------------------|
| `id` | `id` | — |
| `name` | `name` | —（仅 Tab 展示） |
| `value` | `value` | **`packageMainCategory`（必传）** |
| `english` | `english` | — |
| `description` | `description` | —（Tab 展示降级） |
| `sortId` | `sortId` | —（排序） |
| `parentId` | `parentId` | — |
| `status` | `status` | —（`== 1` 才展示） |

#### Scenario: 切换 Tab

- **WHEN** 用户点击其他 Tab
- **THEN** 以当前 Tab 的 `packageMainCategory`（`value`）重新请求套包分页（pageNum=1）

#### Scenario: 加载失败

- **WHEN** 字典接口失败
- **THEN** 隐藏「推荐服务」整个 Section，不影响服务首页其他区块

---

### Requirement: 搜索套餐页

系统 SHALL 提供服务首页顶栏「搜索套餐」入口，跳转搜索页并按关键字查询套包。

#### Scenario: 进入搜索页

- **WHEN** 用户点击服务首页顶栏搜索按钮
- **THEN** 跳转 `ServicePackageSearchViewController`（路由 `/services/search`）
- **AND** 仅当当前机构有后端 `hospitalId` 时带入搜索页

#### Scenario: 展示结果

- **WHEN** 搜索成功且有数据
- **THEN** 使用 `HealthPackageCardCell` 展示套包列表

#### Scenario: 无结果

- **WHEN** 搜索成功但 `list` 为空
- **THEN** 展示「未找到相关套餐」

---

## Architecture

```
PL/Service/ServiceViewController → ServiceViewModel
  → DictionaryService.fetchRecommendCategories()
  → HospitalPackageService.fetchPackageItems(category:hospitalId:)

PL/Service/PackageSearch/ServicePackageSearchViewController → ServicePackageSearchViewModel
  → HospitalPackageService.searchPackageItems(keyword:hospitalId:)
```

| 层 | 路径 | 职责 |
|----|------|------|
| PL | `PL/Service/ViewModels/ServiceViewModel.swift` | 服务首页编排 |
| PL | `PL/Service/ViewModels/ServicePackageSearchViewModel.swift` | 搜索防抖与结果 |
| PL | `PL/Service/PackageSearch/ServicePackageSearchViewController.swift` | 搜索页 UI |
| PL | `PL/Service/ServiceViewController.swift` | 推荐区 UI |
| BLL | `BLL/Service/DictionaryService.swift` | 字典类目 |
| BLL | `BLL/Service/HospitalPackageService.swift` | 套包分页 API（推荐 + 搜索） |
| BLL | `BLL/Service/ServiceRecommendModels.swift` | DTO + 映射 |

---

## Constants

| 常量 | 值 | 说明 |
|------|-----|------|
| `serviceRecommendCategoryParentId` | `2074711807339139072` | 推荐服务字典父级 id |
| `productLineParentId` | `2074711686115364864` | 德系 9 宫格 parentId |
