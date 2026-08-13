## MODIFIED Requirements

### Requirement: 确认订单权益卡

确认订单页「权益卡」行 SHALL 使用订单维度接口选择并绑定权益卡，对齐设计稿「确认订单」权益卡行。

#### Scenario: 加载可选卡

- **WHEN** 确认订单页完成结算加载
- **THEN** 调用 `GET /v1/benefitsTake/getOrderBenefitsList?orderId=`
- **AND** 行文案：已选 →「已使用 N 张，共优惠 ¥x」；有可用未选 →「有 N 张可用」；否则「暂无可用」
- **AND** 抵扣展示优先使用返回的 `deductAmount`；**不再**用全量 `getCustomerPage(status=3)` 作为本行数据源

#### Scenario: 多选弹层与绑单

- **WHEN** 用户点击权益卡行
- **THEN** 展示多选弹层；仅 `available==true` 可选；支持「不使用」
- **AND** 确认后调用 `POST /v1/benefitsTake/updateOrderBenefits`（query：`orderId`、`benefitsTakeIds`；不使用时传空列表）
- **AND** 成功后刷新结算与权益卡列表，更新费用明细与应付金额
- **AND** **禁止**仅本地改选而不调绑单接口
