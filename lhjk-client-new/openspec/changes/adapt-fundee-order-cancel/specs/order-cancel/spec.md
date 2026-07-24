# Order Cancel

## Requirements

### Requirement: 待支付订单取消

用户可在待支付订单列表卡片或详情底部点击「取消订单」，经二次确认后直接关闭订单。

#### Scenario: 确认取消待支付订单

- **WHEN** 用户对 `status=1` 订单点击「取消订单」并在弹窗确认
- **THEN** 调用 `POST /v1/order/insertOrEdit`，Body 包含 `id`（字符串）、`hospitalId`（字符串）、`status=8`
- **AND** 成功后 Toast「订单已取消」
- **AND** 订单列表各 Tab 刷新
- **AND** 若在详情页则返回上一页

#### Scenario: 用户放弃取消

- **WHEN** 用户在二次确认弹窗选择「暂不取消」或关闭弹窗
- **THEN** 不发起网络请求，订单状态不变

### Requirement: 待发货订单取消与退款申请

用户可在待发货订单列表或详情点击「取消订单」，经确认后填写退款原因并进入退款审核。

#### Scenario: 提交待发货取消申请

- **WHEN** 用户对 `status=2` 订单点击「取消订单」、通过二次确认、在弹层填写申请退款原因并提交
- **THEN** 调用 `POST /v1/order/insertOrEdit`，Body 包含 `id`（字符串）、`hospitalId`（字符串）、`status=9`、`remark`（退款原因，非空）
- **AND** 成功后 Toast「已提交退款审核」
- **AND** 订单从待发货 Tab 消失，可在全部 Tab 看到退款审核状态
- **AND** 详情页取消成功后返回上一页

#### Scenario: 退款原因校验

- **WHEN** 用户未填写申请退款原因即点击「提交申请」
- **THEN** 阻止提交并提示「请填写申请退款原因」
- **WHEN** 退款原因超过 20 个字符
- **THEN** 输入框限制最多 20 字

### Requirement: 取消入口可见性

#### Scenario: 操作按钮矩阵

- **WHEN** 订单 `status=1`（待支付）
- **THEN** 展示「取消订单」与「去支付」
- **WHEN** 订单 `status=2`（待发货）
- **THEN** 仅展示「取消订单」
- **WHEN** 订单为其他状态
- **THEN** 不展示「取消订单」（与 `OrderListCardAction` 矩阵一致）

### Requirement: 提交防重与错误提示

#### Scenario: 重复提交

- **WHEN** 取消或退款申请请求进行中
- **THEN** 主操作按钮不可再次点击

#### Scenario: 接口失败

- **WHEN** `insertOrEdit` 返回失败
- **THEN** Toast 展示服务端 `msg` 或「请稍后重试」
- **AND** 待发货场景保留用户已填退款原因
