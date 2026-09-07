# Tasks: order-pay-result-page

- [x] 1. OpenSpec：`payment` / 确认订单支付后导航写入 change delta，并同步主 spec `openspec/specs/payment/`
- [x] 2. 新增 `PL/My/Order/PayResult/` 结果页（成功/失败）与 ViewModel
- [x] 3. 注册 `/orders/pay-result`；`OrderNavigationCoordinator` 承接完成/返回到订单列表
- [x] 4. `OrderConfirmViewModel` 支付成功/失败跳转结果页；取消与 `payRejected` 仍留确认页
- [x] 5. 成功/失败图标改 `pay_success` / `pay_failed`；信息卡 `pay_info_bg`；`getAppOrderDetail` 填字段且不展示支付时间
- [x] 6. 对齐 Figma 视觉细节：金额颜色（#1F2942）、成功态副文案展示、缺口虚线分割线、14pt 字段文字、底栏双按钮（完成 + 查看订单）
- [x] 7. 选择套餐等非购物车入口支付结束同样跨 Tab 重建栈：我的 → 订单列表 → 支付结果；完成/查看订单不再留在服务 Tab
