## API

### 左栏类目

`GET /v1/hospitalPackage/getCategoryServiceListByType`

| 参数 | 值 |
|------|-----|
| `type` | `1`（医院服务 / hospitalService） |
| `hospitalId` | **必传**（登录用户医院 id 或临时常量） |

### 右栏套包

`GET /v1/hospitalPackage/getEnabledHospitalPackagePage`

| 参数 | 值 |
|------|-----|
| `categoryServiceId` | 左栏选中类目 `id` |
| `hospitalId` | 与左栏一致 |
| `pageNum` / `pageSize` | 首版 `1` / `50` |

### hospitalId 解析顺序

1. `UserManager.loginUserInfo.hospitalId`（合法数字字符串）
2. `ServiceCatalogService.selectedApiHospitalId()`
3. `HospitalPackageService.temporaryHospitalId`

## BLL

- `fetchHospitalServiceCategoryList(hospitalId:)`
- `fetchHospitalServicePackageItems(categoryServiceId:hospitalId:pageNum:pageSize:)`
- `fetchCategoryServiceListByType`：`type==1` 时强制写入 `hospitalId`
