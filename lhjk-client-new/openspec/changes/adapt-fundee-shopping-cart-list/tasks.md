## 1. Spec

- [x] 1.1 shopping-cart-list proposal / design / tasks / spec
- [x] 1.2 更新 package-cart-purchase：加购不再写本地缓存
- [x] 1.3 删除购物车：`deleteShoppingCart` 写入 spec / design

## 2. API

- [x] 2.1 `ShoppingCartListBO` + 分页模型
- [x] 2.2 `ShoppingCartService.getShoppingCartList`
- [x] 2.3 映射 `CartLineDisplay`
- [x] 2.4 `ShoppingCartService.deleteShoppingCart(serialNumber:)`
- [x] 2.5 `CartLineDisplay` 携带 `serialNumber`

## 3. PL / 清理

- [x] 3.1 `ServiceCartViewModel` 异步拉列表；勾选内存化
- [x] 3.2 套餐详情去掉 `cartService.addPackage`
- [x] 3.3 删除 `CartService` 本地 mock/seed/持久化（及 AppContainer 注册）
- [x] 3.4 垃圾桶 / 滑动删除改为调服务端；成功后刷新行与合计；缺 serialNumber / 失败 Toast
