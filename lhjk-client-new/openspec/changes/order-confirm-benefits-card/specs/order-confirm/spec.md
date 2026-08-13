## ADDED Requirements

### Requirement: 确认订单权益卡选择

确认订单页 SHALL 支持权益卡多选抵扣，对齐 funde `OrderConfirmView` / `orders-confirm.page.yaml`。

#### Scenario: 查询可用权益卡

- **WHEN** 确认订单结算加载成功，或用户点击「权益卡」行
- **THEN** 调用 `GET /v1/benefitsTake/getCustomerPage`（[Apifox](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/498029202e0.md)），Query `status=3`（待使用）
- **AND** 仅保留待使用且未处于转赠锁定（`pendingTransferId` 为空）的卡
- **AND** **禁止**用 mock / 假 id 顶替列表；无数据时空态「暂无可用」
- **AND** 本期无「按套餐适用范围」接口时，**不**按业务类本地硬过滤；后端补适用范围后替换列表源

#### Scenario: 入口文案

- **WHEN** 无可用卡
- **THEN** 权益卡行展示「暂无可用」（placeholder）
- **WHEN** 有可用卡且用户未选
- **THEN** 展示「有N张可用」
- **WHEN** 用户已选 ≥1 张且抵扣 > 0
- **THEN** 展示「已使用N张，共优惠¥x」（金额用 `OrderConfirmMoney.yen`）

#### Scenario: 选择弹层

- **WHEN** 用户点击权益卡行
- **THEN** 自底部弹出面板：标题「选择权益卡」、副文案「支持多张同时使用，权益卡不抵扣运费。」、右上「不使用」、卡片列表、底部「完成」
- **AND** 列表项自左至右：多选指示、名称与有效期、右侧面值 ¥
- **AND** 支持多选；「不使用」清空选择；无可用时展示空态与「我知道了」
- **AND** 有可用时展示提示：当前最多可抵扣 / 已抵扣（上限 = 套餐金额 − 优惠券抵扣）

#### Scenario: 抵扣与应付（本期：客户端试算）

- **WHEN** 用户确认选择或不使用
- **THEN** 本地更新已选 `benefitsTake` id 列表并重算费用，**不**调用尚不存在的绑单接口
- **AND** `benefitDiscount = min(max(0, packageAmount − couponDiscount), Σ 已选面值)`
- **AND** 权益卡**不**抵扣运费；优惠券与权益卡可同时使用，先券后卡
- **AND** `payable = max(0, settlementPayable − benefitDiscount)`（结算未含权益抵扣时）
- **AND** 费用明细「权益卡抵扣」与底栏应付使用上述结果；抵扣为 0 仍展示 `-¥0.00`
- **AND** 默认不自动勾选任何权益卡

#### Scenario: 与结算 / 优惠券联动

- **WHEN** `bindCouponTake` 或履约刷新导致结算金额变化
- **THEN** 按新的套餐金额与优惠券抵扣重新计算权益卡上限与应付
- **AND** 若已选卡 id 不在最新可用列表中则剔除

#### Scenario: 绑单与核销（后续）

- **WHEN** Apifox 提供订单绑定权益卡接口且结算返回权益抵扣字段
- **THEN** 选择完成后改为绑单成功 → `getOrderSettlement` 刷新；应付与抵扣以结算为准
- **AND** 支付成功后才核销实际使用的权益卡；待支付不锁定、不占用卡包状态

#### Scenario: API 缺口标注

- **WHEN** 查阅本仓库接口清单
- **THEN** 确认页权益卡列表标注复用 `GET /v1/benefitsTake/getCustomerPage`；绑单 / 结算权益字段标注「文档暂无 / 本期客户端试算」
