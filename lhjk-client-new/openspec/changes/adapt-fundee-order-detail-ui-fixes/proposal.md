# Proposal: 订单详情/列表 UI 修正

## 背景

订单详情各状态页与「我的订单」列表在视觉与交互上与 funde 原型及 `order-detail-ui` 规格存在偏差：状态头插画拉伸、自提提示 chip 位置、套餐/物流图标、物流空态占位，以及列表/详情操作按钮分区。

## 范围

1. 状态头：左 88pt 插画 + 右标题，高度 80pt（待支付 `entry=order_pay` 与详情共用 `OrderDetailStatusView`）
2. 自提地址：提示 chip 对齐确认页 `OrderConfirmPickupView`（标题左、chip 贴右）
3. 套餐内容图标：使用 `order_confirm_package_icon`
4. 物流行图标：使用套餐小图标；无物流数据时仍展示「物流信息/自提信息」标题行
5. 列表卡片：隐藏「取消订单」「退款/售后」「去退货」
6. 详情页：上述三按钮置于滚动内容底部；其余操作保留屏幕底栏

## 参考

- funde-client `PendingPaymentOrderDetailView.vue` / `PendingDeliveryOrderDetailView.vue`
- `openspec/changes/adapt-fundee-order-confirm-pay-presentation/specs/order-detail-ui/spec.md`
