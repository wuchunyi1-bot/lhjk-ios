## 1. Spec / DAL 坐标

- [x] 1.1 撰写 institution-switch + location delta spec
- [x] 1.2 `MapCoordinateConverter` 高德 ⇄ 腾讯
- [x] 1.3 `LocationManager` 增加单次定位（坐标 + 逆地理标签）

## 2. BLL 医院搜索与选中态

- [x] 2.1 `HospitalSearchModels` + `HospitalService.searchPage`
- [x] 2.2 `InstitutionSelectionStore` 读写选中机构
- [x] 2.3 `ServiceCatalogService.selectedApiHospitalId` 优先读选中态
- [x] 2.4 注册路由 `/services/institution`

## 3. PL 选择页与列表接线

- [x] 3.1 `InstitutionSelectViewController` + ViewModel + Cell
- [x] 3.2 套餐列表「切换」跳转；返回后刷新机构卡/分类/套餐
- [x] 3.3 AppContainer 注册 HospitalService
