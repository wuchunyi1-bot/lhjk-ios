## ADDED Requirements

### Requirement: 结算订单入口

「使用中」「已逾期」综合服务订单 SHALL 展示「结算订单」按钮；点击后打开结算申请底部弹窗（非 Alert）。

#### Scenario: 列表点击结算

- **WHEN** 用户在订单列表点击「结算订单」
- **THEN** 展示 `OrderSettlementSheet`（对齐 `OrderSettlementDialog.vue`）
- **AND** 不直接调用接口

#### Scenario: 详情点击结算

- **WHEN** 用户在订单详情底栏点击「结算订单」
- **THEN** 行为与列表一致

---

### Requirement: 结算申请弹窗内容

弹窗 SHALL 包含套餐简卡与必填退款原因。

#### Scenario: 弹窗结构

- **WHEN** 弹窗展示
- **THEN** 标题为「确认结算订单？」
- **AND** 说明文案为「提交后该订单将进入退款审核。」
- **AND** 展示套餐图片、名称、卖点、金额（只读）
- **AND** 展示「申请退款原因 *」多行输入，最多 20 字
- **AND** 底部按钮为「再想想」「确认结算」

#### Scenario: 原因校验

- **WHEN** 用户未填写原因点击「确认结算」
- **THEN** Toast「请填写申请退款原因」，不提交

#### Scenario: 取消

- **WHEN** 用户点击「再想想」或点击遮罩
- **THEN** 关闭弹窗，不请求

---

### Requirement: 结算提交接口

#### Scenario: insertOrEdit Body

- **WHEN** 用户填写原因并确认结算
- **THEN** 调用 `POST /v1/order/insertOrEdit`
- **AND** Body：`status=9`、`id`（字符串）、`hospitalId`（字符串）、`remark`（用户填写原因）
- **AND** 成功后 Toast「已提交结算」并刷新订单列表

#### Scenario: 提交失败

- **WHEN** 接口失败
- **THEN** Toast 服务端 `msg` 或通用失败文案
- **AND** 保留用户已填原因
