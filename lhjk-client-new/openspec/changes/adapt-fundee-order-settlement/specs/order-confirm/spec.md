## ADDED Requirements

### Requirement: 立即下单返回订单 ID

`POST /v1/shoppingCart/saveShoppingCartOrPurchase`（`flag=1` 立即购买）成功后，响应 `data` SHALL 为订单 id（标量 int64 / 数字字符串），**禁止**当作空对象忽略。

#### Scenario: 解析 data

- **WHEN** 立即购买接口成功且 `data` 为数字或数字字符串
- **THEN** BLL 解析为 `Int64` 订单 id
- **AND** 进入确认订单页时 **必须** 将该 id 作为路由参数 `orderId` 传入
- **AND** **不得**再依赖上一页写入的套餐草稿作为确认页主数据源

#### Scenario: 加购

- **WHEN** `flag=2` 加入购物车成功
- **THEN** 仍跳转购物车列表；若返回 id 可忽略

### Requirement: 确认订单结算信息（主数据源）

确认订单页 SHALL **始终**以 `GET /v1/order/getOrderSettlement`（[Apifox](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/490169537e0.md)）为套餐名、明细、金额、运费、`orderExpress`、支付渠道、默认地址等的主数据源。

#### Scenario: 路由与请求

- **WHEN** 用户进入 `/orders/confirm`
- **THEN** 路由必带有效数字 `orderId`（来自立即购买 `data`，或购物车行 `orderId`）
- **AND** Query 必传 `orderId`（int64）
- **AND** 若路由/购物车有 `serialNumber` 则一并传入
- **AND** **禁止**用 mock / 假 orderId；**禁止**用上一页 package 草稿顶替结算结果
- **WHEN** 缺少 `orderId` 或结算请求失败（**不含** `code = M0104`）
- **THEN** Toast 提示并返回上一页
- **WHEN** `GET /v1/order/getOrderSettlement` 返回 `code = M0104`（套餐价格或内容已变化，FDAPP-938）
- **THEN** **不** Toast、**不**自动返回
- **AND** 弹出「提示」Alert，文案优先用接口 `msg`，缺省为「套餐价格或内容已发生变化，请重新选择套餐后下单。」
- **AND** 左侧「取消订单」直接取消该待支付订单（`insertOrEdit` status=8），成功后落到「我的订单 · 全部」
- **AND** 右侧「选择套餐」切到服务 Tab 根页（服务首页），并 pop 当前确认/待支付页

#### Scenario: 响应映射

- **WHEN** 接口成功返回 `ShoppingCartPackageDetailMobileBO`
- **THEN** 用于展示：`packageName`、`details`、`commodityPrice`/`totalPrice`、`expressAmount`、`orderExpress`、`wechat`/`alipay`、`description`、`amount`（优惠券抵扣，缺省 `appOrderDetailBO.couponAmount`）、`benefitsAmount`（权益卡抵扣，缺省 `appOrderDetailBO.benefitsAmount`）、`couponTakeId` 等
- **AND** 解码 `amountVersion`、`expectedPayableAmount`，支付时原样带回 `orderPay`；页面应付优先 `expectedPayableAmount`
- **AND** 结算根级 `address` 字段**已废弃**（恒为空），**禁止**用于快递地址展示；快递地址**仅**读 `appOrderDetailBO.receiver`/`phone`/`address`
- **AND** `orderExpress`：`1` = 支持快递；其它 = 仅医院自提
- **AND** 自提用的 `hospitalId` 优先取 `appOrderDetailBO.hospitalId`（缺省再回退本地已选机构）

### Requirement: 收货方式（按 typeOrder 初始化）

确认订单页 SHALL **展示收货方式**区域，初始选中态由结算 `appOrderDetailBO.typeOrder` 决定。

#### Scenario: 默认与选项

- **WHEN** 用户进入确认订单页且结算成功
- **THEN** 收货方式初始值由 `appOrderDetailBO.typeOrder` 决定：`1` = 快递配送，`0` = 机构自提
- **AND** **禁止**写死默认「机构自提」
- **AND** 收货方式按钮顺序自左向右为「机构自提」「快递配送」
- **WHEN** 结算 `orderExpress == 1`
- **THEN** 展示「机构自提」「快递配送」可切换
- **WHEN** `orderExpress != 1`
- **THEN** **仅**可选「机构自提」（隐藏快递按钮）

#### Scenario: 切换收货方式

- **WHEN** 用户切换到「机构自提」
- **THEN** 调用 `POST /v1/order/updateOrderDelivery`，**仅**传 `orderId` + `typeOrder=0`
- **AND** 成功后重新调用 `getOrderSettlement` 刷新确认页金额/地址/优惠券等
- **WHEN** 用户切换到「快递配送」且当前**无**快递地址信息
- **THEN** 先按「静默绑定默认地址」尝试填充
- **AND** 无默认地址或地址列表失败时，仅本地切到快递并展示地址空态，**不调用**无地址的 `updateOrderDelivery`，**不** Toast
- **AND** 默认地址绑定的 `updateOrderDelivery` 失败时，收货方式回滚到切换前，Toast 服务端文案（如 `M0067`「订单支付处理中，请稍后再试」），并允许再次切换重试
- **AND** 进页静默绑定同一接口失败时不 Toast、不把已是快递的订单改回自提
- **AND** 切换请求未结束前忽略下一次收货方式点击
- **WHEN** 用户切换到「快递配送」且结算/本地已有快递地址
- **THEN** 调用 `updateOrderDelivery` 传 `orderId`、`typeOrder=1` 及地址字段，成功后刷新 `getOrderSettlement`

#### Scenario: 快递地址

- **WHEN** 当前为快递配送
- **THEN** 展示收货地址卡
- **AND** 地址来源**仅**取 `appOrderDetailBO` 中的 `receiver`/`phone`/`address`（**禁止**读取与 `appOrderDetailBO` 平级的根级 `address`，该字段已废弃且恒为空）
- **AND** 上述字段任一非空即构造展示地址，**禁止**再附加 `typeOrder` 等额外判断拦截展示
- **AND** 在「快递配送」Tab 下展示该地址卡；`appOrderDetailBO` 只承载快递配送地址，机构自提地址由 `hospital/getById` 获取
- **WHEN** `appOrderDetailBO` 无快递地址信息
- **THEN** 若当前为快递配送，调用 `GET /v1/address/getAddressList` **仅**查找 `isDefault=1` 的默认地址（确认订单与待支付 `entry=order_pay` 共用此逻辑）
- **AND** 找到有效 `addressId` 时静默调用 `updateOrderDelivery`（`typeOrder=1` + 地址字段），成功后刷新 `getOrderSettlement`；**不得** Toast「已选择收货地址」
- **AND** 不得覆盖订单已有快递快照，也不得覆盖用户本页已手动选中的地址
- **AND** 无默认地址、列表失败或绑定失败时，快递地址卡展示**空态**（「请选择收货地址」+「去选择」），**禁止**回退展示机构自提地址
- **AND** 点击入口跳转 `/me/address`（`selectMode=true`）；**禁止**在本页展示地址列表 UI（列表仍由 `/me/address` 自行加载）
- **WHEN** 用户在地址列表选中一条地址
- **THEN** 回调 `onSelect(address)` 返回确认页，并调用 `POST /v1/order/updateOrderDelivery`（[Apifox](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/490169536e0.md)）绑定：`orderId`、`typeOrder=1`、`addressId`、`receiver`、`phone`、`address`（JSON body）
- **AND** 成功后刷新 `getOrderSettlement` 并 Toast「已选择收货地址」；失败回滚原地址并 Toast 错误
- **WHEN** 快递且无有效地址时点「立即支付」
- **THEN** Toast「请选择收货地址」，不提交

### Requirement: 优惠券选择

确认订单页 SHALL 支持优惠券选择与绑定，对齐 funde `OrderConfirmView` 底部弹层交互。

#### Scenario: 查询可用优惠券

- **WHEN** 用户点击「优惠券」行
- **THEN** 调用 `GET /v1/couponTake/getCouponTakeList`（移动端领用列表；需 `couponTakeId` 供绑定）
- **AND** Query 传 `pageNum`、`pageSize`、`hospitalId`（取自结算 `resolvedHospitalId`）
- **AND** Query 传 `status=1`（待使用）；**不得**展示已领用（`status=2`）与已过期（`status=3`）
- **AND** 参考优惠券模板列表：[getCouponList](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330755e0.md)
- **AND** 自底部弹出选择面板：标题「选择优惠券」、副标题、右上角「不使用」、券列表、底部「完成」
- **WHEN** 无可用券
- **THEN** 展示「暂无可用优惠券」

#### Scenario: 绑定 / 解绑优惠券

- **WHEN** 用户选择一张券并点「完成」，或点「不使用」
- **THEN** 调用 `POST /v1/couponTake/bindCouponTake`（[Apifox](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330751e0.md)）
- **AND** Body 必传 `orderId`；选券时传 `couponTakeId`，不使用时不传 `couponTakeId`
- **AND** 成功后重新调用 `getOrderSettlement` 刷新套餐金额、运费、优惠券抵扣、应付金额
- **AND** 优惠券行与费用明细「优惠券抵扣」优先取结算根级 `amount`，缺省 `appOrderDetailBO.couponAmount`，**禁止** `Int` 四舍五入
- **AND** 费用明细「权益卡抵扣」优先取结算根级 `benefitsAmount`，缺省 `appOrderDetailBO.benefitsAmount`

#### Scenario: 结算刷新

- **WHEN** `updateOrderDelivery` 或 `bindCouponTake` 成功
- **THEN** **必须**再次调用 `getOrderSettlement(orderId)` 作为确认页唯一金额/优惠数据源
- **AND** 刷新后回显 `typeOrder`、快递地址、优惠券抵扣与应付金额

### Requirement: 机构自提地址

机构自提信息 SHALL 通过 `GET /v1/hospital/getById`（[Apifox](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330908e0.md)）按结算解析出的 `hospitalId` 获取。

#### Scenario: 展示

- **WHEN** 当前为机构自提且 `hospitalId` 有效
- **THEN** 请求 `id` = hospitalId
- **AND** 名称用 `name`；地址拼接 `province`+`city`+`area`+`address`
- **AND** 「联系机构」优先 `mobile`，其次 `dutyPhone`
- **WHEN** 接口失败
- **THEN** 可回退结算 `appOrderDetailBO.hospitalName` / 本地选中机构，不得崩溃

#### Scenario: 自提卡样式与联系机构

- **WHEN** 渲染机构自提卡
- **THEN** 卡片样式对齐 funde `OrderConfirmView`：左侧机构图标 + 机构名（粗体）+ 自提地址（多行灰字），右下角「联系机构」按钮
- **AND** 点击「联系机构」**直接**唤起系统拨号（`tel://`），**不得**先弹 Alert 确认
- **AND** 无联系电话时隐藏「联系机构」按钮

### Requirement: 套餐金额展示

确认订单页 SHALL 展示套餐金额。

#### Scenario: 金额取值

- **WHEN** 结算返回 `commodityPrice`
- **THEN** 套餐金额 = `commodityPrice`
- **WHEN** `commodityPrice` 缺省
- **THEN** 退回 `totalPrice` − `expressAmount`；再退回 `appOrderDetailBO.payable` − `expressAmount`
- **AND** 套餐卡片右上角金额、费用明细「套餐金额」行均展示该值（保留小数，禁止取整）

#### Scenario: 应付金额

- **WHEN** 结算返回 `totalPrice`
- **THEN** 应付金额 = `totalPrice`
- **WHEN** `totalPrice` 缺省
- **THEN** 退回 `appOrderDetailBO.payable`；再退回 套餐金额 + 运费
- **AND** 底部「立即支付」与费用明细「应付金额」一致（保留小数，禁止取整）

#### Scenario: 优惠券抵扣金额

- **WHEN** 渲染费用明细「优惠券抵扣」或优惠券行摘要
- **THEN** 抵扣金额 = 结算根级 `amount`；缺省 `appOrderDetailBO.couponAmount`；未绑券或无抵扣时为 0
- **AND** 确认订单页所有金额展示**保留原始小数**（通常两位），**禁止** `Int` 四舍五入
- **AND** 优惠券列表弹层中单张券的抵扣展示亦取该券对象的 `amount` 字段

#### Scenario: 权益卡抵扣金额

- **WHEN** 渲染费用明细「权益卡抵扣」
- **THEN** 抵扣金额 = 结算根级 `benefitsAmount`；缺省 `appOrderDetailBO.benefitsAmount`；无抵扣时为 0
- **AND** 服务端已返回抵扣时，应付以结算为准，不再本地重复扣减

### Requirement: 订单备注

确认订单页 SHALL 支持编辑订单备注，并通过 `POST /v1/order/updateOrderDescription`（[Apifox](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/490169535e0.md)）持久化。

#### Scenario: 弹层样式

- **WHEN** 用户点击「订单备注」行
- **THEN** 自底部弹出对齐 funde 的备注编辑面板（非系统 `UIAlertController`）
- **AND** 面板含：标题「订单备注」、取消 / 保存、多行文本框、字数计数（≤300）
- **AND** 点击遮罩或取消关闭面板

#### Scenario: 保存

- **WHEN** 用户点击保存
- **THEN** 以 Query 形式调用 `updateOrderDescription`：`orderId`（必填）、`description`（≤300）
- **AND** 成功后回显备注（一行省略）；失败回滚原值并 Toast 错误
- **AND** **禁止**用 mock / 假 orderId

## MODIFIED Requirements

### Requirement: 履约与地址

#### Scenario: 纯服务（废止隐藏收货方式）

- **WHEN** 用户进入确认订单页
- **THEN** **仍须展示**收货方式（默认自提）
- **AND** 是否可选快递仅由 `orderExpress` 决定

### Requirement: 订单草稿（降级）

本地 `PackageOrderDraft` SHALL **不再**作为确认页主数据源；仅允许作结算映射后的内存展示模型。进入确认页 **不得**要求上一页先 `save` 草稿。

## 参考

- saveShoppingCartOrPurchase / getOrderSettlement / getById / updateOrderDescription / updateOrderDelivery / getCouponTakeList / bindCouponTake Apifox
- funde `OrderConfirmView.vue`、PRD-605
