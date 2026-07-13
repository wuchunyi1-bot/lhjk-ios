## Why

服务模块「富德优选」商品详情目前仍是 `PlaceholderViewController`，无法对齐 Vue `MallProductDetailView.vue` 的信息架构与购买/咨询路径。商城列表已可跳转 `/mall/detail`，需要补齐详情页以跑通转化链路。

## What Changes

- 新增 `/mall/detail` 商品详情页（Hero、标题价格、亮点、适用人群、详情说明、使用步骤、服务承诺、底部下单栏）
- 按 `product.category` 切换分类文案（健康器械 / 功能食品 / 营养补充）
- 底部「咨询」进 IM、「立即购买」进确认订单占位（对齐现行 Vue）
- 扩展 `MallProduct`（emoji）与目录查询；商城 API 未接入前使用与 `services.json` 对齐的本地原型数据（不进入真实 API 参数）
- 商城列表点击商品卡进入详情

## Capabilities

### New Capabilities

- `mall-product-detail`: 富德优选商品详情页 UI、分类 copy、底部操作与路由

### Modified Capabilities

- （无独立已归档 capability；服务模块增量见本 change delta）

## Impact

- `PL/Service/HealthMall/`：新增详情 VC / Components；列表点击跳转
- `BLL/Service/ServiceRoutes.swift`：注册真实详情 VC
- `BLL/Service/ServiceModels.swift` / `ServiceCatalogService.swift`：商品模型与按 id 查询
- 依赖已有路由：`/conversations/:id`、`/orders`（确认订单未实现时降级）
