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
| `imageUrl` | 图标 |
| `price` | 参考价 |
| `introduction` | 一句话简介 |
| `recommend` | 推荐标记（`1` = 推荐） |

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

### Requirement: 服务首页富德优选无限滚动加载

PL 层在服务模块首页（`ServiceViewController`）「富德优选」Section SHALL 支持上拉加载更多，直至无更多数据。

**数据流**

```
ServiceViewController.scrollViewDidScroll (近底部)
  → ServiceViewModel.loadMore()
  → HospitalPackageService.fetchRetailPackages(pageNum + 1)
  → 追加 snapshot.mallPreviewPackages
  → ServiceHubCacheService.updateRetailPreview（同步会话缓存）
  → tableView.reloadData + tableFooterView 状态
```

**首屏**

```
viewWillAppear → ServiceViewModel.load()
  → ServiceHubCacheService.ensureRetailPreview(pageNum=1, pageSize=10)
  → 设置 currentPage / totalPages / hasMore
```

#### Scenario: 首次加载富德优选

- **WHEN** 服务首页首次进入且本地无富德优选数据
- **THEN** 异步请求第一页（`pageNum = 1`，`pageSize = 10`）
- **AND** 在 9 宫格之后渲染「富德优选」Section
- **AND** 卡片点击或「购买」跳转 `/services/pkg`，`id` 为列表 `id`
- **AND** Section 右侧「查看全部 ›」跳转 `/mall`

#### Scenario: 滑动到底部触发加载更多

- **WHEN** `contentOffset.y + frame.height >= contentSize.height - 100`
- **AND** `hasMore == true` 且 `isLoadingMore == false` 且首屏 `isLoading == false`
- **THEN** `loadMore()` 请求 `pageNum = currentPage + 1`
- **AND** 将新数据追加到列表末尾并刷新 TableView
- **AND** `tableFooterView` 展示加载中 Spinner

#### Scenario: 加载到最后一页

- **WHEN** `currentPage >= totalPages` 或下一页 `records` 为空
- **THEN** `hasMore = false`，不再触发加载
- **AND** 列表底部展示「没有更多数据了」（仅当已有至少 1 条数据）

#### Scenario: 首次加载无数据

- **WHEN** 第一页 `records` 为空
- **THEN** 隐藏整个「富德优选」Section（`rowCount == 0`）

#### Scenario: Tab 切回不重置分页

- **WHEN** 用户已上拉加载多页后切换 Tab 再返回服务首页
- **THEN** 保留已加载的套包列表与 `currentPage` / `hasMore` 状态
- **AND** 不重新请求第一页覆盖已追加数据
