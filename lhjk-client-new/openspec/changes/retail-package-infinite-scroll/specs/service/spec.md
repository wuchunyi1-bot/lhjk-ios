## ADDED Requirements

### Requirement: 零售套包分页查询接口

BLL 层 SHALL 支持通过 `/v1/hospitalPackage/getEnabledRetailHospitalPackagePage` 分页查询医院启用的零售类套包。

**接口文档**：https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/487882770e0

**请求（GET Query）**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `categoryServiceId` | String | 否 | 业务类别 id；不传时查询零售类下所有子类别 |
| `pageNum` | String | 否 | 当前页，默认 `1` |
| `pageSize` | String | 否 | 每页条数，默认 `10` |

**响应 `data`（与推荐套包分页一致，英文 Key）**

| JSON Key | 属性 | 说明 |
|----------|------|------|
| `totalCount` | `totalRecords` | 总条数 |
| `pageSize` | `pageSize` | 页大小 |
| `totalPage` | `totalPages` | 总页数 |
| `currPage` | `currentPage` | 当前页 |
| `list` | `records` | `HospitalPackagePageVO[]` |

> Apifox 文档曾标注中文 Key，实测网关返回 `totalCount` / `list` 等英文字段，复用 `PaginatedHospitalPackageData` 解码。

**列表项 `HospitalPackagePageVO`**

| 字段 | 说明 |
|------|------|
| `id` | 套餐 id（详情 `packageId`） |
| `imageUrl` | 封面图；空 / 加载失败时展示占位图 `mall_product_placeholder` |
| `price` | 参考价 |
| `introduction` | 一句话简介 |
| `recommend` | 角标：`1` = 推荐，`2` = 热销；其它值不展示 |

#### Scenario: 成功分页拉取零售套包

- **WHEN** 调用 `HospitalPackageService.fetchRetailPackages(pageNum:pageSize:)`
- **THEN** 向 `/v1/hospitalPackage/getEnabledRetailHospitalPackagePage` 发送 GET
- **AND** `categoryServiceId` 固定传空字符串 `""`（查询零售类下所有子类别）
- **AND** 使用 `PaginatedHospitalPackageData` 解码（`totalCount` / `list` 等英文 Key）
- **AND** 经 `HospitalPackageMapper.toPackageItem` 转为 `HealthPackageItem`

#### Scenario: 请求失败

- **WHEN** 接口返回 `success == false` 或网络错误
- **THEN** 抛出 `HospitalPackageServiceError.requestFailed`
- **AND** PL 层展示错误提示或保持当前列表，不崩溃

---

### Requirement: 服务首页富德优选预览（最多 6 条）

PL 层在服务模块首页（`ServiceViewController`）「富德优选」Section SHALL 仅展示首屏预览，最多 6 张卡片，不上拉加载更多。完整列表走「查看全部 ›」→ `/mall`。

**数据流**

```
viewWillAppear → ServiceViewModel.load()
  → ServiceHubCacheService.ensureRetailPreview(pageNum=1, pageSize=6)
  → snapshot.mallPreviewPackages（最多 6 条）
```

#### Scenario: 首次加载富德优选

- **WHEN** 服务首页首次进入且本地无富德优选数据
- **THEN** 异步请求第一页（`pageNum = 1`，`pageSize = 6`）
- **AND** 在 9 宫格之后渲染「富德优选」Section
- **AND** 最多展示 6 张套包卡片
- **AND** 卡片点击或「购买」跳转 `/services/pkg`，`id` 为列表 `id`
- **AND** Section 右侧「查看全部 ›」跳转 `/mall`

#### Scenario: 首页不上拉分页

- **WHEN** 用户在服务首页滑动到底部
- **THEN** 不请求下一页
- **AND** 不展示「加载中」或「没有更多数据了」Footer

#### Scenario: 首次加载无数据

- **WHEN** 第一页 `records` 为空
- **THEN** 隐藏整个「富德优选」Section（`rowCount == 0`）

#### Scenario: Tab 切回不重复请求

- **WHEN** 用户已加载富德优选后切换 Tab 再返回服务首页
- **THEN** 复用会话缓存中的预览列表（最多 6 条）
- **AND** 不重新请求第一页
