## Context

套餐详情 UI 已对齐图示。数据改为真实接口：

- 列表：`GET /v1/hospitalPackage/getEnabledHospitalPackagePage`（须解析 `id`）
- 详情：`GET /v1/hospitalPackage/getPackageDetail?hospitalId=&packageId=`  
  [Apifox](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/485486161e0)

## Goals / Non-Goals

**Goals:**

- 列表 VO 增加 `id`，映射到 `HealthPackageItem.id`
- 详情页用列表 `id` 作 `packageId` 拉详情
- `hospitalId` 临时常量 `1372444113118564352`
- `checkType` / `billingType` 映射到现有组合 UI

**Non-Goals:**

- 机构列表 API（hospitalId 仍临时）
- 购物车持久化
- 德系本地列表改接详情 API（非数字 id 继续原型降级）

## Decisions

1. **临时 hospitalId**：`HospitalPackageService.temporaryHospitalId`；详情必传；列表在无机构 id 时也用该值，保证与详情一致。
2. **id 兼容解码**：雪花 ID 可能为 String / Number，与 `ColumnContentDTO` 相同策略。
3. **分组**：每个 `PackageHospitalDetailListBO` → 一个 combo group；若行含 `children` 则用 children 作为可选行。
4. **总价**：`packageInfo.price` + `checkType=3` 已勾选项 `price` 之和。
5. **PL**：`ServicePackageDetailViewModel` 异步拉详情；VC 订阅后渲染。

## Risks

| Risk | Mitigation |
|------|------------|
| 列表缺 id | fallback `hospital-pkg-{index}`，详情不调 API |
| 临时 hospitalId 与线上数据不一致 | 常量集中；机构 API 接入后替换 |
