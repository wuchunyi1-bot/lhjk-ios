## Why

购物车列表需对接 `GET /v1/shoppingCart/getShoppingCartList`。当前 `CartService` 用 UserDefaults + 原型 seed，加购还会本地写入，与真实加购接口脱节，列表会出现 mock / 本地假数据。

## What Changes

- 对接查询购物车列表 API；列表唯一数据源为服务端
- 清空本地 mock seed；移除加购本地缓存（`CartService` 持久化 / `addPackage`）
- 套餐详情仅调 `saveShoppingCartOrPurchase(flag=2)` 成功后跳转购物车；列表靠重新拉取展示
- 勾选态仅内存维护
- 对接删除购物车 API：`DELETE /v1/shoppingCart/deleteShoppingCart`（必填 `serialNumber`）

## Capabilities

### New Capabilities

- `shopping-cart-list`: 购物车列表查询与展示数据源切换

### Modified Capabilities

- `service-cart` / `package-cart-purchase`: 去掉本地加购缓存约定

## Impact

- `BLL/Service/ShoppingCartService`、`ShoppingCartModels`、`CartModels`
- 移除或掏空 `CartService` 本地存储
- `PL/Service/Cart/`、套餐详情加购路径
