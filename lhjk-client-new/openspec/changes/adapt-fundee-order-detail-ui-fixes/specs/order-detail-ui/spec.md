# Order Detail UI Delta — 操作按钮分区与视觉修正

## MODIFIED Requirements

### Requirement: 订单详情顶部状态卡

订单详情 / 待支付确认（`entry=order_pay`）状态头 SHALL 使用整图 Banner（`order_detail_status_*`，`scaleAspectFill`，高度 80pt），状态头与下方首卡间距 **4pt**（待支付确认页）。

### Requirement: 收货地址 / 自提地址

自提地址卡标题行 SHALL 对齐 `OrderConfirmPickupView`：

- 左「自提地址」16 medium
- 右提示 chip「请前往以下机构领取商品/设备」**贴卡片右缘**，仅左侧圆角，尺寸约 156×23pt
- chip 与标题同一水平线（top 16pt），不得与标题挤在同一 `UIStackView` 行内换行错位

### Requirement: 套餐内容与费用明细样式

「套餐内容」标题前 SHALL 展示 `order_confirm_package_icon`（16×16），与确认订单页一致。

### Requirement: 物流 / 自提信息

物流任务行左侧图标 SHALL 使用 `order_confirm_package_icon`（**20×20**），行高 **≥ 65pt**。

当快递/自提履约方式成立但 **尚无发货任务行** 时，SHALL 仍展示对应卡片，并至少占位 **「物流信息」或「自提信息」标题行**；无记录时不展示预览行与「发货记录」链接。

### Requirement: 底部操作栏

订单详情操作 SHALL 分为两区：

| 区域 | 按钮 | 位置 |
|------|------|------|
| 滚动内容底部 | 取消订单、退款/售后、去退货 | `contentStack` 末行（订单信息卡之后），**随内容滚动**，滚到底可见 |
| 屏幕固定底栏 | 去支付、确认收货、续费订单、结算订单、确认发货等 | `OrderDetailActionBar` 贴屏底 |

- 仅存在滚动区按钮时，不展示固定底栏
- 两类按钮可同时存在（如待收货：滚到底见「退款/售后」+ 底栏固定「确认收货」）

## ADDED Requirements

### Requirement: 列表卡片操作隐藏规则

「我的订单」列表卡片 SHALL **不展示** 以下按钮（任意 Tab / 状态）：

- 取消订单
- 退款/售后
- 去退货

其余按钮（去支付、确认收货、续费订单、结算订单等）按 `OrderListCardAction` 矩阵正常展示。

用户如需取消/售后/退货，SHALL 进入订单详情后操作。
