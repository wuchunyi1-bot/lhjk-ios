## Why

服务 Hub / 套餐详情 /「我的」已有购物车入口，但 `/services/cart` 仍是占位页。需对齐 funde-client `CartView.vue`，跑通「加入购物车 → 列表勾选 → 结算」路径。

## What Changes

- 新增购物车页，对齐 `CartView.vue` + `docs/v0.1/pages/services/cart.md`
- 本地购物车状态（会话内 + UserDefaults）；暂无购物车服务端 API
- 套餐详情「加入购物车」写入购物车并跳转 `/services/cart`
- `/services/cart` 替换占位页

## Capabilities

### New Capabilities

- `service-cart`: 购物车列表、勾选合计、加入购物车、结算跳转、空态

### Modified Capabilities

- （无）

## Impact

- `PL/Service/Cart/`
- `BLL/Service/CartService.swift`、购物车模型
- `ServiceRoutes.swift`、`ServicePackageDetailViewController`
