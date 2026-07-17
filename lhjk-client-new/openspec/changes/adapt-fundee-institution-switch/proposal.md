## Why

服务模块套餐列表需支持「切换机构」：用户进入统一选择服务机构页，按定位距离排序并搜索医疗机构，选中后写回服务模块机构状态并刷新列表。接口 `GET /v1/hospital/searchPage` 文档标注高德坐标系，但后端实际按腾讯地图坐标系存取，客户端须在 DAL 定位模块提供互转。

## What Changes

- 新增选择服务机构页（对齐 funde `InstitutionSelectView`）
- 接入 `GET /v1/hospital/searchPage` 分页搜索
- 服务模块持久化当前选中机构，替换临时 `hospitalId`
- 套餐列表「切换」跳转选择页，返回后刷新分类与套餐
- DAL `Location`：高德 ⇄ 腾讯经纬度互转；定位结果上报前转为腾讯坐标

## Capabilities

### New Capabilities

- `institution-switch`: 选择/切换服务机构、搜索医院、坐标互转、选中持久化

### Modified Capabilities

- `location`: 补充坐标系互转与单次定位坐标能力

## Impact

- `DAL/Location/`
- `BLL/Service/`（HospitalService、机构选择存储、ServiceCatalogService、ServiceRoutes、ServiceListViewModel）
- `PL/Service/InstitutionSelect/`、`PL/Service/ServiceList/`
