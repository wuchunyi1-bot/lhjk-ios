## Why

套餐详情「加入购物车」「立即下单」需对接真实接口 `POST /v1/shoppingCart/saveShoppingCartOrPurchase`，按 `flag` 分支：加购写入购物车、立即购买进入下单链路。当前仅本地 CartService / 占位确认页，无法与后端选中明细对齐。

## What Changes

- 对接 `saveShoppingCartOrPurchase`（flag=2 加购，flag=1 立即购买）
  - 文档：https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330718e0.md
- 提交体携带 `hospitalId`、`packageId`、当前已选 `packageHospitalDetailList`
- 明细模型保留详情行 id 等字段，供提交编码
- 详情页底部栏调用真实接口；成功后加购进购物车页，立即下单进确认订单

## Capabilities

### New Capabilities

- `package-cart-purchase`: 套餐详情加购 / 立即下单 API 与选中明细组装

### Modified Capabilities

- `service-package-detail` / `service-cart`：底部操作改为服务端提交

## Impact

- `BLL/Service/`（ShoppingCart 模型与 Service、HospitalPackageDetail 映射、ServicePackageComboItem）
- `PL/Service/ServicePackageDetail/`
- 可选：本地 `CartService` 仍作列表展示缓存
