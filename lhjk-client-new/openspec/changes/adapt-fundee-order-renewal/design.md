## Context

对齐 funde 续费链路：原订单 id 作为 `parentId` 提交；套餐明细续费价字段为 `reprice`。
续费开关字段以 Apifox `renewed`（1 允许 / 0 不允许）为准，不自造参数。

## Decisions

1. **路由**：`/services/pkg`，params：`id`（packageId）、`orderId`（续费父订单）、可选 `hospitalId` / `categoryServiceId`
2. **续费态判定**：`orderId` 有效即 `isRenewalMode`
3. **价格**：`HospitalPackageDetailMapper` 在续费态用 `reprice ?? price` 填充 `ServicePackageComboItem.priceValue`；底栏合计为已选明细续费价之和
4. **提交**：`SaveShoppingCartRequest.parentId` = 路由 `orderId`；`flag = 1` 成功后进 `/orders/confirm`
5. **取消**：续费态左侧按钮 `navigationController?.popViewController`
6. **packageId 来源**：优先列表/详情 `packageId`；列表缺失时拉 `getAppOrderDetail` 再跳转
7. **续费按钮资格**（Apifox + PRD 状态窗口）：
   - 基础：`packageType == 1`
   - `renewed == 1`（文档字段；0 / 缺失隐藏）
   - 使用中可续费；已逾期仅由 `endTime` 推算天数 ∈ [0,5]
   - **不**使用未文档化字段：`renewalEligible` / `renewedOnce` / `renewPendingChildId` / 订单级 `overdueDays`
8. **确认收货终态**：是否进入已完成由后端处理，客户端不改写目标 status 规则

## Risks

| Risk | Mitigation |
|------|------------|
| 列表无 packageId | 详情接口补全；仍无则 Toast |
| reprice 为空 | 回退 `price` |
| 待支付续费子单无文档字段 | 由后端将父单 `renewed` 置 0，或在下单接口拦截；App 不臆造子单 id |
