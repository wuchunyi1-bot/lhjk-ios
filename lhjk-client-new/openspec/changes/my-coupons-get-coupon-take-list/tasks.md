## 1. OpenSpec

- [x] 1.1 编写 proposal / design / delta specs（含 CouponTaskListBO 映射）
- [x] 1.2 按返回字段补充「票券主信息 / 规则展开」场景

## 2. BLL 模型与服务

- [x] 2.1 扩展 `CouponTakeItem` 展示相关字段
- [x] 2.2 按 `type` 映射力度（满减 `amount` / 减价 `couponAmount` / 折扣 `discountRatio`）
- [x] 2.3 `CouponService.getCouponTakeList` 支持 `status`；待使用总数缓存
- [x] 2.4 删除优惠券 Mock

## 3. PL 列表

- [x] 3.1 `CouponTabViewController` 异步按 filter 请求
- [x] 3.2 `CouponCardCell` 规则标题对齐文档；无内容隐藏「使用规则」
- [x] 3.3 「我的」角标刷新待使用数

## 4. 验证

- [x] 4.1 四 Tab 传参与空态；订单选券 `.items`
- [x] 4.2 无优惠券 mock 残留
