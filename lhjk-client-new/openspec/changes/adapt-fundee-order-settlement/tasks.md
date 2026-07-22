## 1. Spec

- [x] 1.1 立即下单返回 id → 结算主数据源
- [x] 1.2 套餐金额 / 应付金额取值与展示
- [x] 1.3 收货方式顺序（机构自提在左）
- [x] 1.4 自提卡样式 + 联系机构直拨
- [x] 1.5 订单备注底部弹层 + updateOrderDescription

## 2. API

- [x] 2.1 `saveShoppingCartOrPurchase` 返回订单 id
- [x] 2.2 `OrderService.getOrderSettlement`
- [x] 2.3 `HospitalService.getById`
- [x] 2.4 `OrderService.updateOrderDescription`
- [x] 2.5 `OrderService.updateOrderDelivery`（绑定快递地址）

## 3. UI

- [x] 3.1 收货方式 / 自提卡 / 运费 / 金额展示
- [x] 3.2 `OrderRemarkEditorSheet` 底部备注弹层
- [x] 3.3 快递地址：结算 `appOrderDetailBO` 优先展示，无则入口跳 `/me/address` 选择后绑定
- [x] 3.4 `AddressListViewController` 选择模式（`selectMode` + `onSelect`）
