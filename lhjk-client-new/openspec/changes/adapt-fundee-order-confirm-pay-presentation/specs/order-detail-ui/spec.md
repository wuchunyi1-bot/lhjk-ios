# Order Detail UI Delta — 对齐 Figma 3546:4382

参考：[订单详情-优化后](https://www.figma.com/design/JEIKBLlcPpylp8GJ7BVmFd/%F0%9F%8C%9F%E5%BC%80%E5%8F%91%E5%AF%B9%E6%8E%A5-%E9%A1%B9%E7%9B%AE%E6%8F%90%E4%BA%A4?node-id=3546-4382)

覆盖状态：待发货、待支付、待收货、使用中、已逾期、退款/售后、已完成。待支付仍走 `OrderConfirmViewController`（`entry=orderListPay`），仅状态头与订单信息复用详情组件。

## MODIFIED Requirements

### Requirement: 订单详情页面骨架

订单详情页 SHALL 使用暖米底 `#FDF6F3`（`fdBg`），卡片白底 16pt 圆角、卡片间距 12pt、左右内边距 16pt。状态卡下方不再展示独立 hint 条；拒绝退款原因落入订单信息卡。

### Requirement: 订单详情顶部状态卡

从「我的订单」进入的订单详情 / 待支付确认页（`entry=order_pay`）顶部状态 SHALL 对齐 Figma `3546:4549` 等状态头：

- 高度 80pt，16pt 圆角，左白右透明横向渐变
- 左侧状态插画约 88pt（`order_detail_status_*`），按 `AppOrderStatus` 映射
- 右侧主文案 20pt semibold，棕色渐变 `#A15313 → #522B0F`
- 卡片内不展示副文案

插画映射：待支付 `pending_pay`、待发货 `pending_ship`、待收货 `pending_receive`、使用中 `in_use`、已逾期/已取消 `overdue`、退款/售后/审核中 `refund`、已完成 `completed`。

### Requirement: 套餐内容与费用明细样式

套餐卡 SHALL 与确认订单 `OrderConfirmPackageView` 一致：套餐名 16 medium + 卖点 14 `#8591AB` + 右侧金额 ¥16+18；浅橙渐变「套餐内容」容器；超过 3 项展示「展开 (共 N 项)」/「收起」+ 圆形箭头。

费用明细 SHALL：

- 标签 14 `#8591AB`，数值 14 medium `#1F2942`；有抵扣时金额 `#F93838`
- 固定行：套餐金额、运费、优惠券抵扣、权益卡抵扣（无抵扣也展示 `-¥0.00`）
- 合计行上方 0.5pt `#F0F0F0`；合计金额 `#F93838` ¥16+18
- 待支付合计文案「应付金额」，其余「实付金额」

### Requirement: 收货地址 / 自提地址

快递收货地址 SHALL：标题「收货地址」16 medium；16pt 浅橙底定位针；姓名+手机 16；地址 14 `#8591AB` 单行截断。

自提地址 SHALL：左「自提地址」，右提示 chip「请前往以下机构领取商品/设备」；机构名 + 定位针；底栏「联系机构」。

### Requirement: 物流 / 自提信息

物流卡 SHALL 预览最多 2 条、行高约 65pt、底色 `#FDF6F3`：

- 左 16pt 套餐图标 + 名称 14 + 副文案 12 `#8591AB`
- 右倾斜圆形印章（待发货 / 待自提 / 已发货 / 待收货 / 已逾期），文案随订单状态与履约方式变化
- 已发货行可复制物流单号
- 底部居中「发货记录 (共 N 条)」或「自提记录」，12pt 灰色 + 展开箭头

### Requirement: 退款/售后信息

退款/售后状态 SHALL 在套餐卡前展示「退款/售后信息」：申请时间、退款单号、申请退款原因（有则展示）。

### Requirement: 订单信息区块

订单信息 SHALL：

- 标题「订单信息」16 medium
- 主区：订单号（14pt 复制图标）、下单时间、拒绝退款原因（非售后流且有 `refuseReasons`）、订单备注（空则「无」）
- 展开区：支付状态、支付方式、手机号、服务时间等
- 默认展开，底部「收起」/「展开」+ 圆形箭头

### Requirement: 底部操作栏

底栏 SHALL 白底、顶部 16pt 圆角、按钮高 40pt 全宽均分：

- 填充主按钮：去支付 / 确认收货 / 结算订单 / 去退货 / 确认发货（`fdPrimary` 底、白字）
- 描边次按钮：取消订单 / 退款/售后 / 续费订单（0.5pt `fdPrimary` 描边）
- 已完成且无售后入口时不展示底栏
- 按钮显隐仍按 `OrderListCardAction.actions(for:)`（套餐类型与退款历史），不以稿面是否画了按钮覆盖业务规则
