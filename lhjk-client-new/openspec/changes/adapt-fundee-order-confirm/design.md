## Context

权威来源：

1. [orders-confirm.page.yaml](file:///Users/chunyi/Desktop/new/funde-code/funde/funde-client/docs/page-specs/orders-confirm.page.yaml)
2. `OrderConfirmView.vue`（原型实现，本地草稿 + mock 支付演示）
3. PRD-605《确认订单页》（`06_用户_套餐购买支付链路_v1.0.md`）

路由：`/orders/confirm`，params：`id` = packageId（对齐 `/orders/confirm/:id`）。

入口：

| 来源 | 行为 |
|------|------|
| 套餐详情「立即下单」 | 写内容/金额快照 → 确认页（可先调 flag=1 接口） |
| 购物车「去结算」 | 按卡片写快照 → 确认页（服务端删除该购物车行可选本期做） |

## Goals / Non-Goals

**Goals（本期）：**

- 页面结构对齐 PRD 线框：履约（条件）→ 地址/自提（互斥）→ 套餐卡+内容 → 备注 → 优惠券/权益卡行 → 费用明细 → 支付方式 → 底栏立即支付
- 必须有有效草稿；无草稿且无法拉取套餐时提示「订单信息已失效，请重新下单」并返回
- 套餐内容只读，默认 3 条可展开；不展示购买数量
- 支付方式仅微信 / 支付宝，默认微信
- 费用：应付 = 套餐金额 + 运费(0) - 券(0) - 权益卡(0)；0 抵扣行仍展示
- 快递配送未选地址时阻止支付：「请选择收货地址」
- Design Token + SnapKit；模块归属「我的/订单」路由下 PL

**Non-Goals（本期）：**

- 真实创单锁券、支付 SDK 唤起、支付结果页完整态
- 优惠券/权益卡真实列表与抵扣计算（仅空态入口）
- 续费确认标题与续费金额链路
- 银行卡支付
- 运费模板真实计算（运费固定 0）

## Decisions

1. **草稿**：`PackageOrderDraftStore`，UserDefaults key `lhjk.packageOrderDraft.v1`，字段对齐 Vue snapshot（packageId、name、subtitle、amount、selectedItems、hospitalId、hospitalName、contractedFulfillmentMethod、hasPhysicalGoods 等）
2. **履约**：`hasPhysicalGoods == true` 或分类绑定自提时展示收货方式；默认优先草稿 `contractedFulfillmentMethod`，否则 `express`；纯服务不展示履约/地址
3. **地址**：快递时加载 `AddressService.getAddressList`，默认选默认地址；点击跳转 `/me/address`，`viewWillAppear` 刷新
4. **立即支付**：校验 → Toast「订单已提交，支付功能即将开放」→ `Router.setRoot` 或 push `/orders`（避免回确认页重复提交可用 replace）；创单 API 后续接
5. **详情入口**：立即下单成功后，除原有 API 外写入草稿再 push confirm；购物车结算写入草稿后 push（列表行信息映射）

## Risks

| Risk | Mitigation |
|------|------------|
| 无真实创单 API | 明确 Non-Goals；UI 与校验先落地 |
| 购物车行缺明细 | 用列表字段拼草稿；金额用 totalPrice |
