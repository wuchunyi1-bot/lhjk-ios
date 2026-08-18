# Order Confirm Delta — 订单列表待支付展示

## MODIFIED Requirements

### Requirement: 确认订单页结构

#### Scenario: 默认确认订单（购物车 / 套餐下单）

- **WHEN** `entry` 缺省或为 `cart`
- **THEN** 导航标题为「确认订单」
- **AND** **不展示**顶部状态头与底部订单信息卡

#### Scenario: 我的订单待支付进入

- **WHEN** 用户从「我的订单」全部/待支付 Tab 点击待支付订单或「去支付」
- **THEN** 进入 `/orders/confirm?orderId=&entry=order_pay`
- **AND** 导航标题为「**订单详情**」
- **AND** 顶部展示待支付状态卡（主文案「待支付」+ primary 图标样式，**无**卡片内副文案）
- **AND** 中间区域与默认确认页一致（履约、地址/自提、套餐、备注、优惠、费用、支付方式）
- **AND** 底部展示「订单信息」卡（订单号、下单时间、订单备注；展开见支付状态）
- **AND** 底栏展示「取消订单」+「去支付」（主按钮文案「去支付」）
- **AND** 并行请求 `getAppOrderDetail` 填充订单信息；结算仍用 `getOrderSettlement`

### Requirement: 确认订单履约方式与地址卡

确认订单 SHALL 将机构自提作为始终可用的履约方式；`supportsExpress == true` 时同时展示「机构自提」与「快递配送」，`supportsExpress == false` 时默认使用机构自提且**不展示「收货方式」选择卡**。

#### Scenario: 机构自提 + 快递配送

- **WHEN** 结算支持快递配送
- **THEN** 展示 343pt 宽、129pt 高的「收货方式」卡，卡内边距 16pt，标题 16pt Medium `#1F2942`
- **AND** 两个选项均为 149×58pt、圆角 12pt、间距 13pt，底色 `#FDF6F3`
- **AND** 当前选项使用 1pt `#FF7A50` 描边与 Figma 选中角标；图标圆底为 `#FF9D45`，文案 14pt Medium
- **AND** 选中机构自提时展示 343×158pt「自提地址」卡；选中快递时展示快递收货地址卡

#### Scenario: 仅机构自提

- **WHEN** 结算不支持快递配送
- **THEN** 不展示「收货方式」卡
- **AND** 直接展示机构自提地址卡，不因为隐藏快递选项产生空白或半宽布局

#### Scenario: 机构自提地址卡

- **THEN** 卡片使用 Figma 独立背景节点 `3566:7680` 导出的 @2x/@3x 图片，尺寸为 343×158pt，白底 16pt 圆角与右上地图背景均由切图提供
- **AND** 标题「自提地址」16pt Medium；机构名 16pt Regular；地址 14pt Regular `#8591AB`
- **AND** 左侧使用 16×16pt `#FFF2E6` 定位图标，提示条贴右边、宽 156pt、高 23pt，文字 10pt `#FF7015`
- **AND** 底部展示 46pt 横向渐变联系机构栏，文字 12pt Medium `#FF7A50`

#### Scenario: 快递收货地址

- **WHEN** 已有默认收货地址
- **THEN** 展示 343×80pt 地址卡，姓名和手机号均为 16pt Medium，地址为 14pt Regular `#8591AB`
- **AND** 左侧定位图标容器为 44×44pt，右侧展示 18pt 圆形箭头，整卡可点击切换地址
- **WHEN** 没有默认收货地址
- **THEN** 展示 343×72pt 地址卡，文案为「暂无默认地址」，右侧显示 70×28pt、0.5pt `#FF7950` 描边的「去选择」按钮

#### Scenario: 待支付详情取消订单

- **WHEN** `entry=order_pay` 用户点击「取消订单」
- **THEN** 走与列表相同的待支付取消流程（二次确认 → status=8）
- **AND** 成功后返回订单列表并刷新

#### Scenario: 优惠券行文案

- **WHEN** 已绑定优惠券且抵扣金额 > 0
- **THEN** 展示 `已使用一张，共优惠¥{amount}`
- **WHEN** 有可用券未选
- **THEN** 展示 `有{n}张可用`
- **WHEN** 无可用券
- **THEN** 展示 `暂无可用`

#### Scenario: 订单列表待支付导航

- **WHEN** `entry=order_pay` 用户点击返回
- **THEN** `pop` 回订单列表（**不得**跨 Tab）
- **WHEN** 支付成功
- **THEN** 与 `default` 相同，当前 Nav 替换为订单列表「全部」
