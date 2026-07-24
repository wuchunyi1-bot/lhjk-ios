## Context

对齐 funde 续费链路：原订单 id 作为 `parentId` 提交；套餐明细续费价字段为 `reprice`。

## Decisions

1. **路由**：`/services/pkg`，params：`id`（packageId）、`orderId`（续费父订单）、可选 `hospitalId` / `categoryServiceId`
2. **续费态判定**：`orderId` 有效即 `isRenewalMode`
3. **价格**：`HospitalPackageDetailMapper` 在续费态用 `reprice ?? price` 填充 `ServicePackageComboItem.priceValue`；底栏合计为已选明细续费价之和
4. **提交**：`SaveShoppingCartRequest.parentId` = 路由 `orderId`；`flag = 1` 成功后进 `/orders/confirm`
5. **取消**：续费态左侧按钮 `navigationController?.popViewController`
6. **packageId 来源**：优先列表/详情 `packageId`；列表缺失时拉 `getAppOrderDetail` 再跳转
7. **续费按钮资格**：仅 `packageType == 1`（租赁套餐）展示「续费订单」；售卖/虚拟/体验及缺失类型不展示

## Risks

| Risk | Mitigation |
|------|------------|
| 列表无 packageId | 详情接口补全；仍无则 Toast |
| reprice 为空 | 回退 `price` |
