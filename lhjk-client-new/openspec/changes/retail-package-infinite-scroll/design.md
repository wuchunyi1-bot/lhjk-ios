## Context

服务模块首页「富德优选」原先固定展示 6 条零售套包，且走推荐套包接口（`packageMainCategory`）。现需对接零售专用分页接口，并支持上拉无限加载。

**Apifox**：https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/487882770e0  
`GET /v1/hospitalPackage/getEnabledRetailHospitalPackagePage`

## Goals / Non-Goals

**Goals**

- BLL 对接零售分页接口，中文 Key 解码
- Hub 首屏 10 条 + 上拉加载至 `currentPage >= totalPages`
- 加载中 / 无更多 Footer 状态
- Tab 切回不丢失已加载页

**Non-Goals**

- `/mall` 商城页无限滚动（仍首屏 `pageSize=20`）
- `/services/list` 健康管理类目列表分页改造

## Decisions

### 1. 分页模型

零售接口 `data` 实测与推荐套包分页结构一致（`totalCount`、`totalPage`、`currPage`、`list`），复用 `PaginatedHospitalPackageData`，不单独定义中文 Key 模型。

### 2. BLL `HospitalPackageService`

```swift
func fetchRetailPackages(
    pageNum: Int = 1,
    pageSize: Int = 10
) async throws -> PaginatedHospitalPackageData
```

- `fetchRetailPackageItems` 内部改调 `fetchRetailPackages`，不再使用 `fetchRecommendPackages`
- `categoryServiceId`：固定传空字符串 `""`，查询零售类下全部子类别

### 3. 缓存 `ServiceHubCacheService`

- `ensureRetailPreview`：首屏去重 in-flight，返回 `(packages, totalPages)`
- `updateRetailPreview(packages:totalPages:)`：`loadMore` 成功后写回会话缓存，供 `/mall` 与 Tab 复用

### 4. PL `ServiceViewModel`

状态：`currentPage`、`totalPages`、`isLoadingMore`、`hasMore`（`currentPage < totalPages`）

- `load()`：仅当 `mallPreviewPackages` 为空时拉首屏；已有数据时只合并静态层（Banner/矩阵）
- `loadMore()`：追加 `snapshot.mallPreviewPackages`，更新缓存与分页游标

### 5. PL `ServiceViewController`

- `scrollViewDidScroll`：距底部 100pt 触发 `loadMore()`
- `tableFooterView`：`isLoadingMore` → Spinner；`!hasMore && count > 0` →「没有更多数据了」

## Risks / Trade-offs

- **中文 Key 变更** → 已确认网关返回英文 Key，与推荐套包共用 `PaginatedHospitalPackageData`
- **快速滑底重复触发** → `isLoadingMore` 互斥 + `hasMore` 判断
