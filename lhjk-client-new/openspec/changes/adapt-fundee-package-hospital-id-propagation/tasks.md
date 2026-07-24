## 1. Spec & Models

- [x] 1.1 OpenSpec change `adapt-fundee-package-hospital-id-propagation`
- [x] 1.2 `HospitalPackagePageVO` / `HealthPackageItem` 增加 `hospitalId`
- [x] 1.3 `MPackageVO` / `ServicePackageDetail` 增加 `hospitalId`

## 2. Mapper & BLL

- [x] 2.1 `HospitalPackageMapper` 映射列表 `hospitalId`
- [x] 2.2 `HospitalPackageDetailMapper` 映射 `packageInfo.hospitalId`
- [x] 2.3 `ServiceRoutes.packageDetailParams` 统一路由参数

## 3. PL 跳转

- [x] 3.1 `PackageCardCell` / `MallProductCell` 跳转携带 `hospitalId`
- [x] 3.2 `ServiceListViewController` / `HealthMallViewController` / `ServiceViewController` / 搜索页

## 4. 详情提交

- [x] 4.1 `ServicePackageDetailViewModel.resolvedHospitalId` 优先级调整
- [x] 4.2 详情 load 使用路由 `hospitalId` 优先于机构选择
