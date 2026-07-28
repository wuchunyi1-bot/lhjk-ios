## ADDED Requirements

### Requirement: 去退货展示资格

系统 SHALL 依据列表/详情下发的 `canReturnGoods` 与 `refundId` 判断是否展示「去退货」。申请阶段与退款审核阶段均不得展示。

对齐 PRD：`05_用户_我的订单_v1.0.md` §3.5、§5.7.1 / §5.7.2 / §5.7.5。  
列表字段来源：`GET /v1/order/getAppOrderList`（`AppOrderListBO`）。

#### Scenario: 合资格展示

- **WHEN** 同时满足：
  1. 订单主状态为退款/售后处理中（App `status=6`）
  2. `canReturnGoods == true`（服务端是否可去退货）
  3. `refundId` 有效（`> 0`，提交退货必填）
- **THEN** 订单列表卡片与订单详情底部操作区均展示「去退货」
- **AND** 列表与详情使用同一资格判断（详情若未下发 `canReturnGoods`，则以 `status=6` + 有效 `refundId` 作为兼容条件）

#### Scenario: 不展示

- **WHEN** 任一不满足：状态非 `6`；`canReturnGoods != true`；或无有效 `refundId`
- **THEN** **不得**展示「去退货」

#### Scenario: 申请阶段无退货字段

- **WHEN** 用户打开取消订单 / 结算 / 退款/售后申请抽屉（§5.3 / §5.4 / §5.5 / §5.6 / §5.8 → §5.7.4）
- **THEN** 仅采集套餐简卡与申请退款原因
- **AND** **不得**展示退货方式、退货地址、物流名称或物流单号

---

### Requirement: 去退货抽屉（自行送回 / 快递寄回）

用户点击「去退货」后，SHALL 打开底部抽屉完成退货方式选择，并调用真实提交接口。

文档：[提交退货信息](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/493050735e0.md)  
`POST /v1/orderClearing/submitReturnGoods`

#### Scenario: 方式选择

- **WHEN** 打开去退货抽屉
- **THEN** 标题为「去退货」
- **AND** 提供「自行送回」「快递寄回」二选一
- **AND** 未选方式点提交时提示「请选择退货方式」

#### Scenario: 自行送回

- **WHEN** 用户选择自行送回并提交
- **THEN** 调用 `submitReturnGoods`，Body 至少含：
  - `refundId`：列表/详情下发的退款单 ID（**禁止** mock）
  - `returnMethod`：`1`
- **AND** 不得要求物流名称/单号
- **AND** 成功后 Toast「退货信息已提交」，关闭抽屉，刷新列表/详情（`canReturnGoods` 应变为不可展示）

#### Scenario: 快递寄回

- **WHEN** 用户选择快递寄回并提交
- **THEN** 必须填写物流名称与物流单号
- **AND** 缺失时分别提示选择物流名称 / 填写物流单号
- **AND** 调用 `submitReturnGoods`，Body 含：
  - `refundId`（必填）
  - `returnMethod`：`2`
  - `logisticsName`（≤10）
  - `logisticsId`（快递单号，≤80）
- **AND** `sender` / `senderPhone` 可选；当前抽屉不采集时不传
- **AND** 成功后 Toast、关闭、刷新并隐藏「去退货」

#### Scenario: 提交失败

- **WHEN** 接口返回非成功或网络错误
- **THEN** Toast 展示服务端 `msg`（或通用失败文案）
- **AND** 抽屉保持打开，允许重试
- **AND** **禁止**用本地假成功冒充线上

---

### Requirement: 与 5.4–5.9 状态页关系

「去退货」不改变各状态 Tab 的申请入口矩阵；仅在售后处理中闭环内出现。

#### Scenario: 待收货 / 使用中 / 已逾期 / 已完成

- **WHEN** 用户在 §5.4–5.6 / §5.8 发起退款或结算
- **THEN** 提交后进入退款审核（全部 Tab）
- **AND** 审核通过进入退款/售后后再按本 spec 判断「去退货」
- **AND** 上述状态页底部**不**直接展示「去退货」

#### Scenario: 二级页

- **WHEN** 用户查看发货记录 / 自提记录 / 正向物流轨迹（§5.9）
- **THEN** 只读履约信息，**不**作为去退货入口
- **AND** 去退货物流为用户寄回信息，与正向物流轨迹分离
