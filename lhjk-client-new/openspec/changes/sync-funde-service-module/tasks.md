## 1. Spec

- [x] 1.1 创建 `sync-funde-service-module` proposal / design / tasks / spec delta

## 2. BLL

- [x] 2.1 新增 `ServiceRetailCategory` 常量（`packageMainCategory = 电商零售`）
- [x] 2.2 `HospitalPackageService` 增加 `fetchRetailPackageItems(pageSize:)`
- [x] 2.3 `ServiceHubCacheService` 增加零售套包缓存；`ServiceHubSnapshot` 改为 `mallPreviewPackages`
- [x] 2.4 `ServiceCatalogService.loadHubSnapshot` 签名对齐

## 3. Hub

- [x] 3.1 `ServiceViewModel`：`mallPreview` section，加载前 6 条零售套包
- [x] 3.2 `ServiceViewController`：去掉类目 Tab 行；标题「富德优选」；跳转 `/services/pkg` 与 `/mall`

## 4. 套餐列表

- [x] 4.1 新增 `ServiceListViewModel`
- [x] 4.2 重构 `ServiceListViewController`：字典类目 + API 套包，去 mock
- [x] 4.3 更新 `CategoryNavCell` / `PackageHeaderCell` / `PackageCardCell` 支持 `HealthPackageItem`

## 5. 商城

- [x] 5.1 新增 `HealthMallViewModel`
- [x] 5.2 重构 `HealthMallViewController`：API 数据 + `/services/pkg`
- [x] 5.3 `MallProductCell` 支持 `HealthPackageItem`

## 6. 路由

- [x] 6.1 `/mall/detail` 重定向至 `ServicePackageDetailViewController`
- [x] 6.2 列表页默认 `code` 改为首类目而非 `德好`

## 7. 验证

- [x] 7.1 编译检查相关文件 linter
- [ ] 7.2 提示开发者将新增 Swift 文件加入 Xcode 工程
