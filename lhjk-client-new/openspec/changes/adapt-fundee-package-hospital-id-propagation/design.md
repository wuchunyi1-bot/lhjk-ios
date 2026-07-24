## Context

列表项示例（零售 / 医院服务套包分页）：

```json
{
  "id": "2077585288959496192",
  "hospitalId": "1372444113118564352",
  "imageUrl": "",
  "price": 111.00,
  "introduction": "营养液简介",
  "recommend": 1
}
```

详情 `packageInfo` 同样新增 `hospitalId` 字段。

涉及接口：

| 接口 | 用途 |
|------|------|
| `GET /v1/hospitalPackage/getEnabledRetailHospitalPackagePage` | 富德优选零售列表 |
| `GET /v1/hospitalPackage/getEnabledHospitalPackagePage` | 推荐 / 搜索 / 服务列表套包 |
| `GET /v1/hospitalPackage/getHospitalPackageDetail` | 套餐详情（query: `hospitalId` + `packageId`） |
| `POST /v1/shoppingCart/saveShoppingCartOrPurchase` | 加购 / 立即下单（body: `hospitalId`） |

## Goals / Non-Goals

**Goals:**

- 列表返回的 `hospitalId` 贯穿：列表 → 路由 → 详情请求 → 加购/下单
- 详情加载后，以 `packageInfo.hospitalId` 为提交时的权威来源
- 所有套包列表入口（零售、服务列表、搜索、Hub 预览）行为一致

**Non-Goals:**

- 移除 `HospitalPackageService.temporaryHospitalId`（仍作列表项无 `hospitalId` 时的兜底）
- 机构切换页逻辑改造

## Decisions

### 1. 数据模型

- `HospitalPackagePageVO.hospitalId`：列表 DTO
- `HealthPackageItem.hospitalId`：PL 列表展示模型
- `MPackageVO.hospitalId`：详情 DTO
- `ServicePackageDetail.hospitalId`：详情 PL 模型

### 2. 路由参数

跳转 `/services/pkg`（或 `/services/detail`）时：

```
params = {
  id: packageId,           // 列表 id
  hospitalId?: string,      // 列表 hospitalId（有则必传）
  categoryServiceId?: string // 类目上下文（原有逻辑保留）
}
```

统一由 `ServiceRoutes.packageDetailParams(...)` 组装并校验数字 id。

### 3. 详情加载

`ServicePackageDetailViewModel.performLoad()` 调用 `fetchPackageDetail`：

```
hospitalId = routeHospitalId ?? institutionStore.selectedHospitalId
```

不再在 load 阶段优先 institutionStore 覆盖路由入参。

### 4. 加购 / 立即下单 `hospitalId` 解析优先级

```
packageInfo.hospitalId（已加载详情）
  → 路由 hospitalId（列表传入）
  → institutionStore.selectedHospitalId
  → HospitalPackageService.temporaryHospitalId
```

### 5. 列表 Mapper

`HospitalPackageMapper.toPackageItem` 将 `vo.hospitalId` 写入 `HealthPackageItem.hospitalId`。

`HospitalPackageDetailMapper.toServicePackageDetail` 将 `info.hospitalId` 写入 `ServicePackageDetail.hospitalId`。

## Risks

| Risk | Mitigation |
|------|------------|
| 旧接口偶发缺 `hospitalId` | 保留 temporaryHospitalId 与机构选择兜底 |
| 多处跳转遗漏参数 | 集中 `packageDetailParams` + `HealthPackageItem` 扩展方法 |
