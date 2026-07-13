## Context

权威参考：`funde-client/prototype/src/views/services/MallProductDetailView.vue`（辅以 `docs/v0.1/pages/services/mall-product-detail.md`、`docs/page-specs/mall-product-detail.page.yaml`）。以 **现行 Vue** 为准：立即购买跳转 `/orders/confirm/:id`（yaml 旧写 `/orders` 已过时）。

当前 iOS：`/mall/detail` → Placeholder；`MallProduct` 无 emoji；`loadMallProducts()` 返回空（商城 API 未接）。

## Goals / Non-Goals

**Goals:**

- UI/分区/分类 copy/底部栏对齐 Vue
- 路由 `/mall/detail` + `id`；咨询 → IM；购买 → 确认订单（无页则占位或 `/orders`）
- 按 id 查商品；未知 id 展示空态（不静默 fallback 到第一件，生产更合理；与 Vue 原型 fallback 差异在 design 注明）

**Non-Goals:**

- 评价 / 分享 / 购物车 / 规格选择 / 真实支付
- 商城商品真实 API（仍用本地原型目录，接 API 后删除）

## Decisions

1. **Vue 优先于 yaml**：购买 → `/orders/confirm` + `id`；若未注册则 `PlaceholderViewController` 或降级 `/orders`。
2. **目录数据**：`ServiceCatalogService` 提供与 `services.json` mall 对齐的本地列表 + `product(id:)`；标注「待 API」。
3. **分类 copy**：PL 层静态表（器械/功能食品/营养补充），不进 BLL。
4. **主题色**：`product.accent` 用于 Hero 渐变、勾选、人群标签、步骤编号、价格。
5. **结构**：`MallProductDetailViewController` + 可选底部栏 Component；ViewModel 可选（数据简单可先 VC 内）。
6. **未知商品**：空态「商品不存在」+ 返回（优于 Vue fallback）。

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| 本地 mall 数据与未来 API 字段不一致 | 模型贴近 Vue；接 API 时替换 `loadMallProducts` |
| 确认订单页未实现 | 注册占位路由，避免死链 |
| 咨询会话 id 硬编码 | 对齐 Vue `conv-001`；后续接真实客服会话 |

## Migration Plan

写 spec → 扩模型/目录 → 详情 VC → 改路由 → 列表点击 → 编译。

## Open Questions

- 无
