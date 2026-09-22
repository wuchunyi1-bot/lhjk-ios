# Order Detail Delta — 已完成订单详情

## ADDED Requirements

### Requirement: 商品行物流字段

#### Scenario: 解码发货状态与预计发货时间

- **WHEN** `getAppOrderDetail` 返回 `shoppingCartPackageDetailList`
- **THEN** 每行解析 `shipmentStatus`（Int：1 待履约 / 2 已履约）与 `presetDeliveryTime`（String）
- **AND** 单行印章 **只** 用该行 `shipmentStatus` + 订单 `typeOrder`，不得用整单 `status` 覆盖
- **AND** 快递（`typeOrder == 1`）：`1` →「待发货」`order_detail_stamp_pending_ship`；`2` →「已发货」`order_detail_stamp_shipped`
- **AND** 自提（`typeOrder == 0`）：`1` →「待自提」`order_detail_stamp_pending_pickup`；`2` →「已自提」`order_detail_stamp_pickuped`
- **AND** 字段缺失时不导致整单解析失败

### Requirement: 收货地址独立卡片

#### Scenario: 快递订单展示收货地址

- **WHEN** `typeOrder == 1` 且存在收件人/手机/地址任一字段
- **THEN** 展示独立「收货地址」卡片
- **AND** 含 location 图标、姓名+手机、详细地址
- **AND** 只读，不可编辑

#### Scenario: 快递订单不展示服务机构卡

- **WHEN** `typeOrder == 1` 且已展示收货地址
- **THEN** 不展示「服务机构」卡片

### Requirement: 物流信息展示

#### Scenario: 物流行过滤

- **WHEN** `shoppingCartPackageDetailList` 中某行 `shipmentStatus == nil`
- **THEN** 该行不出现在物流/自提信息区块，也不计入发货记录条数

#### Scenario: 快递物流信息

- **WHEN** `typeOrder == 1` 且存在 `shipmentStatus != nil` 的商品行
- **THEN** 展示「物流信息」卡片
- **AND** 详情页**仅预览 1 条**商品履约行（对齐 funde `PREVIEW_LIMIT`，用户要求 1 条）
- **AND** 卡片底部展示「发货记录（共 X 条） >」，点击跳转 `/orders/shipment-records?orderId=&type=express`
- **AND** 该行 `shipmentStatus != 2` 时副文案为「商家备货中，预计发货时间 {presetDeliveryTime}」
- **AND** 该行 `shipmentStatus == 2` 且订单级存在物流公司与单号时展示物流信息并可复制单号

#### Scenario: 自提信息

- **WHEN** `typeOrder == 0` 且存在 `shipmentStatus != nil` 的商品行
- **THEN** 展示「自提信息」卡片，预览 1 条 +「自提记录（共 X 条） >」入口
- **AND** 该行 `shipmentStatus != 2` 时副文案为「预计 {presetDeliveryTime} 完成备货，可自提」
- **AND** 该行 `shipmentStatus == 2` 时印章为「已自提」，不得再用「已发货」

#### Scenario: 商品行印章

- **WHEN** 渲染物流/自提 Item 右上角印章
- **THEN** 映射为：

| 履约 | `shipmentStatus` | 文案 | 切图 |
|------|------------------|------|------|
| 快递 | `1` 或空 | 待发货 | `order_detail_stamp_pending_ship` |
| 快递 | `2` | 已发货 | `order_detail_stamp_shipped` |
| 自提 | `1` 或空 | 待自提 | `order_detail_stamp_pending_pickup` |
| 自提 | `2` | 已自提 | `order_detail_stamp_pickuped` |

### Requirement: 发货记录列表页

#### Scenario: 进入发货记录

- **WHEN** 用户点击「发货记录」或「自提记录」
- **THEN** 进入 `OrderShipmentRecordsViewController`
- **AND** 展示全部 `shipmentStatus != nil` 的商品履约行
- **AND** 无数据时展示「暂无发货记录」/「暂无自提记录」

### Requirement: 服务机构卡片

#### Scenario: 自提订单展示机构

- **WHEN** `typeOrder == 0`
- **THEN** 展示「自提地址」卡片：机构名、地址、「联系机构」按钮（图标+文字居中）

### Requirement: 退款/售后信息样式

#### Scenario: 已完成且存在退款记录

- **WHEN** `showsAfterSaleInfoCard == true`
- **THEN** 卡片标题「退款/售后信息」
- **AND** 信息行字体与订单信息一致（`fdBody`、行高 40pt）
- **AND** 退款金额行使用 danger-soft 背景高亮

### Requirement: 订单信息卡退款原因展示

#### Scenario: 根据 refundReasonType 展示退款原因

- **WHEN** 渲染订单信息卡且 `refundReasonType` 有值
- **THEN** 按照以下规则在「下单时间」下方展示退款原因：
  - `refundReasonType == 1`：当存在 `refundReasons` 时，展示「申请退款原因」及对应内容
  - `refundReasonType == 2`：当存在 `refuseReasons` 时，展示「拒绝退款原因」及对应内容
  - `refundReasonType == 0` 或其他：不展示退款原因行
- **AND** 若 `refundReasonType` 为空/未下发，兼容降级为：若存在 `refuseReasons` 且订单非售后流程中，展示「拒绝退款原因」

### Requirement: 特色通知条

#### Scenario: 拒绝退款通知条

- **WHEN** 订单存在 `refuseReasons` 且非退款流程态（如逾期或已驳回退款订单）
- **THEN** 在顶部状态横幅下方展示特色通知条（`OrderDetailNoticeBannerView`）
- **AND** 文案格式为「拒绝退款：{refuseReasons}」
- **AND** 背景采用粉红渐变装饰条（`order_notice_bg_single` / `order_notice_bg_double`），搭配 14×14pt 红色叹号图标（`order_notice_alert_icon`）及 12pt Regular 警告文案（`#F93838`）

### Requirement: 详情区块顺序

#### Scenario: 已完成订单区块顺序

- **WHEN** 用户查看 `status=5`（已完成）订单详情
- **THEN** 区块顺序为：状态 → 提示 → 退款/售后（条件）→ 套餐卡（含套餐内容）→ 收货地址（条件）→ 物流/自提信息（条件）→ 服务机构（条件）→ 费用明细 → 订单信息
- **AND** 底部无操作按钮

### Requirement: 套餐内容与费用明细样式

#### Scenario: 与待支付确认页一致

- **WHEN** 任意状态订单详情展示套餐内容与费用明细
- **THEN** 样式与 `OrderConfirmPackageView` 套餐内容区、`OrderConfirmFeeView` 一致
- **AND** 详见 `adapt-fundee-order-confirm-pay-presentation/specs/order-detail-ui/spec.md`

## MODIFIED Requirements

### Requirement: 其它状态

#### Scenario: 待收货物流

- **WHEN** `status=3` 且商品行 `shipmentStatus=2`
- **THEN** 在「物流信息」卡片展示物流公司与单号（不再挤在履约合并卡内）
