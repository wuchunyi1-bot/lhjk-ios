## ADDED Requirements

### Requirement: 确认订单页结构

`/orders/confirm` SHALL 展示对齐 funde-client `OrderConfirmView` / PRD-605 的确认订单页，**不得**再使用 Placeholder。

#### Scenario: 导航与顺序

- **WHEN** 用户进入确认订单页且草稿有效
- **THEN** 导航标题为「确认订单」，不展示 Tab Bar
- **AND** 纵向顺序为：收货方式（条件）→ 收货地址或自提地址（互斥、条件）→ 套餐卡片（含套餐内容）→ 订单备注 → 优惠券行 → 权益卡行 → 费用明细 → 支付方式 → 底部立即支付栏

#### Scenario: 套餐卡片与内容

- **WHEN** 渲染套餐区
- **THEN** 展示套餐名称、一句话卖点（空则隐藏）、右侧套餐金额（不展示「套餐金额」字段名）
- **AND** 「套餐内容」只读列表，默认最多 3 条，超过可展开/收起
- **AND** **不得**展示购买数量步进器或内容编辑入口
- **AND** **不得**展示套餐推荐角标与套餐大图（对齐 PRD-605-AC-01）

### Requirement: 订单草稿

系统 SHALL 使用本地订单草稿承载确认页数据（对齐 funde `package-order-draft`）。

#### Scenario: 写入

- **WHEN** 用户从套餐详情「立即下单」成功进入确认页
- **THEN** 先写入包含 `packageId`、名称、卖点、金额、已选明细、hospitalId 等字段的草稿
- **WHEN** 用户从购物车「去结算」/「结算」
- **THEN** 按该行写入草稿（至少 packageId、名称、金额、数量）后进入确认页

#### Scenario: 读取失败

- **WHEN** 进入确认页时草稿缺失或 packageId 与路由 `id` 不一致，且无法通过详情接口补全
- **THEN** Toast「订单信息已失效，请重新下单」并返回上一页

### Requirement: 履约与地址

#### Scenario: 纯服务

- **WHEN** 草稿判定为纯服务（无实物/设备履约需求）
- **THEN** **不展示**收货方式、收货地址、自提地址

#### Scenario: 可切换履约

- **WHEN** 草稿 `hasPhysicalGoods` 或需履约选择
- **THEN** 展示「机构自提 / 快递配送」；默认取草稿 `contractedFulfillmentMethod`，缺省快递
- **WHEN** 当前为快递配送
- **THEN** 展示收货地址卡；无地址展示「请选择收货地址」；点击进入 `/me/address`
- **WHEN** 当前为机构自提
- **THEN** 展示自提机构名称与地址（来自草稿 hospitalName / 选中机构）；可「联系机构」拨打服务热线

#### Scenario: 支付前地址校验

- **WHEN** 当前履约为快递且未选有效地址，用户点「立即支付」
- **THEN** Toast「请选择收货地址」，不提交

### Requirement: 备注 / 优惠 / 费用 / 支付

#### Scenario: 订单备注

- **WHEN** 用户点击订单备注
- **THEN** 底部弹窗编辑，最多 200 字；确认后一行省略回显

#### Scenario: 优惠券与权益卡（本期）

- **WHEN** 用户查看优惠券 / 权益卡行
- **THEN** 展示「暂无可用」空态入口（真实列表与抵扣后续迭代）
- **AND** 费用明细中优惠券抵扣、权益卡抵扣行展示 ¥0

#### Scenario: 费用明细

- **WHEN** 渲染费用明细
- **THEN** 固定五行：套餐金额、运费、优惠券抵扣、权益卡抵扣、应付金额
- **AND** 应付 = 套餐金额 + 运费 − 优惠券 − 权益卡（本期运费与抵扣为 0）

#### Scenario: 支付方式

- **WHEN** 用户选择支付方式
- **THEN** 仅「微信支付」「支付宝支付」单选，默认微信
- **AND** **不得**展示银行卡

#### Scenario: 立即支付（本期）

- **WHEN** 校验通过且用户点击「立即支付」
- **THEN** 按钮进入提交中禁用态防重
- **AND** 本期不强制接入支付 SDK；成功反馈后进入 `/orders`（订单列表）
- **AND** 真实创单锁券与唤起支付列为后续任务

## 参考

- funde-client `OrderConfirmView.vue`
- `docs/page-specs/orders-confirm.page.yaml`
- PRD-605
