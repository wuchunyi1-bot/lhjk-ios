# Order Detail UI Delta — 对齐 funde-client

参考：`funde-client/prototype/src/views/orders/components/OrderDetailStatusCard.vue`、`OrderDetailInfoSection.vue`、`PendingPaymentOrderDetailView.vue`（pickup-card）。

## MODIFIED Requirements

### Requirement: 订单详情顶部状态卡

从「我的订单」进入的订单详情 / 待支付确认页（`entry=order_pay`）顶部状态 SHALL 对齐 funde `OrderDetailStatusCard`：

- 白底圆角卡片（`fdSurface` + shadow），水平内边距 16
- 左侧 32×32 圆形图标底 + SF Symbol 状态图标
- 右侧主文案 `--fd-h3` / heavy，**卡片内不展示副文案**
- 待支付（`order_pay`）：`tone=primary`（`fdPrimarySoft` 底 + `fdPrimary` 图标），图标 `clock`
- 其它状态按 `orderStatusPresentation` 映射 tone（待发货 warning、待收货 info、已完成 success 等）

副文案（如「商家备货中」）若存在，展示在状态卡下方的独立提示条，**不得**塞入状态卡内。

### Requirement: 订单信息区块

订单信息 SHALL 对齐 `OrderDetailInfoSection`：

- 卡片标题「订单信息」（`fdBody` semibold）
- 行：订单号（可复制）、下单时间、订单备注（空则「无」）
- 展开区：手机号（`detail.phone`）、支付状态等
- 各行等高 40pt，字体 `fdBody`

### Requirement: 机构自提卡

机构自提 SHALL 对齐 `pickup-card`（非快递地址卡样式）：

- 顶栏：左「自提地址」`fdBody` heavy；右提示「请前往以下机构领取商品/设备」`fdCaption` `fdSubtext`
- 机构名：`building.2` 图标 + 名称 `fdBody` semibold
- 地址：`fdCaption` `fdSubtext` 多行
- 底栏「联系机构」：透明底、主色 `fdCaption` semibold，图标 `phone`

### Requirement: 优惠券行文案

已绑定优惠券时，优惠券行文案 SHALL 为：

`已使用一张，共优惠¥{amount}`

（`amount` 为结算抵扣金额，保留两位小数；无券时「暂无可用」；有券未选「有{n}张可用」）

### Requirement: 套餐内容与费用明细样式（全订单详情统一）

所有非待支付确认入口的订单详情页（`OrderDetailViewController`）中，**套餐内容**与**费用明细**区块 SHALL 与待支付订单确认页（`OrderConfirmFeeView` / `OrderConfirmPackageView` 套餐内容区）视觉一致：

**套餐内容**（内嵌于套餐卡，对齐 `OrderConfirmPackageView`）：
- 套餐卡顶部：套餐名 `fdBody` semibold + 卖点 `fdCaption` subtext + 右侧套餐金额 `fdMono` 18 heavy primary
- 横线分隔
- 「套餐内容」标题 `fdBody` semibold
- 每行横向：商品名 `fdCaption` `fdText2` + 数量 `fdCaption` `fdSubtext` + 金额 `fdCaption` `fdSubtext`，行高 ≥ 32pt，行间距 0
- 超过 3 项时底部展示「展开（共 N 项）」/「收起」，居中
- **≤ 3 项时不展示展开/收起按钮，且不保留按钮占位高度**
- **不得**再使用独立「商品明细」卡片或封面图样式

**费用明细**：
- 卡片标题「费用明细」在卡片内，16pt 内边距
- 固定展示：套餐金额、运费、优惠券抵扣、权益卡抵扣（无抵扣也展示 `-¥0.00`）
- 行高 40pt，标签/数值 `fdBody`；标签 `fdSubtext`，抵扣金额有值时 `fdSuccess`
- 合计行上方虚线分隔；合计金额 `fdNumM` `fdPrimary`
- 待支付态合计文案「应付金额」，其余状态「实付金额」
