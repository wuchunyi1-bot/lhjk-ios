## 1. BLL 层实现：对接零售套包分页接口

- [x] 1.1 在 `ServiceRecommendModels.swift` 中定义 `PaginatedRetailHospitalPackageData` 结构体，映射中文 Key
- [x] 1.2 在 `HospitalPackageService.swift` 中新增 `fetchRetailPackages` 分页请求方法
- [x] 1.3 在 `HospitalPackageService.swift` 中修改 `fetchRetailPackageItems` 方法，支持 `pageNum` 和 `pageSize` 分页参数

## 2. PL 层实现：服务首页无限滚动加载

- [x] 2.1 在 `ServiceViewModel.swift` 中引入分页管理状态（`currentPage`、`totalPages`、`isLoadingMore`、`hasMore`）
- [x] 2.2 在 `ServiceViewModel.swift` 中实现 `loadMore()` 方法，追加下一页的套包数据到 preview
- [x] 2.3 在 `ServiceViewController.swift` 中实现 `scrollViewDidScroll` 滚动监听，触发加载更多
- [x] 2.4 在 `ServiceViewController.swift` 中动态管理 `tableView.tableFooterView` 展示加载状态

## 3. 缓存与 Tab 复用

- [x] 3.1 `ServiceHubCacheService.updateRetailPreview` 同步 loadMore 结果
- [x] 3.2 `ServiceViewModel.load()` Tab 切回不重置已加载分页
