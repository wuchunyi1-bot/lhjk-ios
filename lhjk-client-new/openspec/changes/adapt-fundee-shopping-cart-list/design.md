## Context

接口文档：[查询购物车列表](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330722e0.md)

```
GET /v1/shoppingCart/getShoppingCartList
operationId: getShoppingCartList
```

**Query（均可选）**

| 参数 | 说明 |
|------|------|
| userId | 用户 id |
| hospitalId | 医院 id |
| type | 套餐类别 1租赁/2售卖/3虚拟/4体验 |
| mobileOrUsername | 用户名或手机号 |
| beginCode / endCode | int64 |
| pageNum / pageSize | 分页，默认 1 / 10 |

**响应 data**：标准分页（兼容中英文字段名）→ `ShoppingCartListBO[]`

| 字段 | 说明 |
|------|------|
| packageId / packageName | 套包 |
| hospitalId / hospitalName | 医院 |
| totalQuantity / totalPrice | 数量 / 总价 |
| introduction / imgUrl / type / categoryServiceId | 简介、图、类型、业务类别 |
| serialNumber / createTime / status / orderId | 组编号、时间、状态（1已生成/2未生成/3已失效）、订单 |

| userId / username / mobile | 用户信息 |

加购仍走已有 `POST .../saveShoppingCartOrPurchase`（flag=2）。

删除接口文档：[删除购物车](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330724e0.md)

```
DELETE /v1/shoppingCart/deleteShoppingCart
operationId: deleteShoppingCart
Query 必填: serialNumber (int32) — 列表行「组编号」
```

## Goals / Non-Goals

**Goals:**

- 购物车页 `viewWillAppear` / 首次进入拉取列表；空数组展示空态
- **禁止** UserDefaults 购物车持久化、禁止原型 seed、禁止加购写本地
- **禁止** 传 `hospitalId`（列表展示全部医疗机构下的套餐）
- **禁止** 把 mock userId 传入 Query
- 垃圾桶 / 滑动删除走 `deleteShoppingCart`，成功后更新列表

**Non-Goals:**

- 购物车改数量服务端 API
- 确认订单页改造

## Decisions

1. **数据源**：`ShoppingCartService.getShoppingCartList`；映射为 `CartLineDisplay` 供现有 Cell 复用
2. **行 id**：`packageId` + `hospitalId` + `serialNumber`（缺省用空）拼接，供勾选
3. **价格**：`totalPrice` 为行总价；`quantity = max(1, totalQuantity)`；展示行价直接取 `totalPrice` 取整
4. **加购**：详情成功后只跳转 `/services/cart`，由列表接口刷新；去掉本地 `addPackage`
5. **CartService**：已删除本地读写与 seed
6. **勾选**：ViewModel 内存 `Set`；刷新后默认全选
7. **删除**：`DELETE /v1/shoppingCart/deleteShoppingCart?serialNumber=`（[文档](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330724e0.md)）；`CartLineDisplay` 须保留 `serialNumber`；成功后再从本页 `lines` 移除（或重新 `load`）

## Risks

| Risk | Mitigation |
|------|------------|
| 分页字段中英文混用 | 与医院搜索相同，双 key 解码 |
| totalPrice 与数量除不尽 | 展示用总价优先：`linePrice` 直接取 totalPrice 取整 |
| 列表行缺 serialNumber | 禁用删除 / Toast，不调接口 |
