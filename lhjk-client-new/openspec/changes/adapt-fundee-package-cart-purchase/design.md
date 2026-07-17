## Context

接口文档（Markdown / OpenAPI）：[添加购物车/一键购买](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330718e0.md)

```
POST /v1/shoppingCart/saveShoppingCartOrPurchase
operationId: saveShoppingCart
tags: App端/商城/购物车管理
```

**SaveShoppingCartVO（必填 hospitalId、packageId）**

| 字段 | 类型 | 说明 |
|------|------|------|
| hospitalId | int64 | 医院 ID（必填） |
| packageId | int64 | 套包 ID（必填） |
| categoryServiceId | int64 | 服务类别 ID（必填） |
| flag | int32 | **2** 添加购物车；**1** 立即购买 |
| packageHospitalDetailList | PackageHospitalDetailBO[] | 选中的套餐明细 |
| doctorId / userId / archiveId / angetId / parentId / couponTakeId | int64 | 可选 |
| instruction / authCode / receiver / phone / address | string | 可选 |
| orderChannel | int32 | 可选 |

**PackageHospitalDetailBO**：id、sortId、packageId、hospitalId、packageDetailId、parentId、commodityId、billingType（1天/2月/3次/4件）、quantity、price、checkType（1单选/2强制/3可选）、defaultCheck、name、children、categoryId、categoryName 等。

**Result**：`code` / `data`（object）/ `msg` / `success` / `failed`。

## Goals / Non-Goals

**Goals:**

- 按当前勾选组装 `packageHospitalDetailList` 并提交
- 必传 `hospitalId`、`packageId`、`categoryServiceId`（详情 packageInfo → 路由入参）
- flag=2 → Toast + `/services/cart`；列表靠 `getShoppingCartList` 刷新（不写本地缓存）
- flag=1 → `/orders/confirm`
- 明细模型保留服务端 id，可编码回传
**Non-Goals:**

- 确认订单页完整改造、购物车列表纯服务端拉取
- 优惠券 / 收货地址本接口完整联调（字段预留）

## Decisions

1. ComboItem 保留 `detailId` 及提交字段；Mapper 从详情 BO 写入；子项带 `parentId`
2. `SaveShoppingCartRequest` + `PackageHospitalDetailSubmitItem`（Encodable）→ `asDict()` → `postAsync`
3. `ShoppingCartService` BLL 单例，注册 `AppContainer`
4. 非数字 packageId 不调 API，本地降级

## Risks

| Risk | Mitigation |
|------|------------|
| data 结构不定 | 宽松解码 / EmptyResponse；确认页靠 packageId |
| 明细缺 id | 过滤无效项；全无则 Toast 不请求 |
