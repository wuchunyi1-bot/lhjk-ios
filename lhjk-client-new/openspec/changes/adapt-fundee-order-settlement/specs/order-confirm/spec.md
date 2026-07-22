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
- **WHEN** 缺少 `orderId` 或结算请求失败
- **THEN** Toast 提示并返回上一页

#### Scenario: 响应映射

- **WHEN** 接口成功返回 `ShoppingCartPackageDetailMobileBO`
- **THEN** 用于展示：`packageName`、`details`、`commodityPrice`/`totalPrice`、`expressAmount`、`orderExpress`、`wechat`/`alipay`、`address`、`description` 等
- **AND** `orderExpress`：`1` = 支持快递；其它 = 仅医院自提
- **AND** 自提用的 `hospitalId` 优先取 `appOrderDetailBO.hospitalId`（缺省再回退本地已选机构）

### Requirement: 收货方式（默认自提）

确认订单页 SHALL **展示收货方式**区域。

#### Scenario: 默认与选项

- **WHEN** 用户进入确认订单页
- **THEN** 默认选中「机构自提」
- **AND** 收货方式按钮顺序自左向右为「机构自提」「快递配送」
- **WHEN** 结算 `orderExpress == 1`
- **THEN** 展示「机构自提」「快递配送」可切换；默认仍为机构自提
- **WHEN** `orderExpress != 1`
- **THEN** **仅**可选「机构自提」（隐藏快递按钮）

#### Scenario: 快递地址

- **WHEN** 当前为快递配送
- **THEN** 展示收货地址卡
- **AND** 地址来源**仅**取结算 `appOrderDetailBO` 中的 `receiver`/`phone`/`address`，且仅当 `appOrderDetailBO.typeOrder == 1`（快递）且 `hasDeliveryAddress` 为真时展示
- **AND** `appOrderDetailBO` 只承载快递配送地址；**机构自提地址永远不在 `appOrderDetailBO` 中**，机构地址由 `hospital/getById` 单独获取
- **WHEN** `appOrderDetailBO` 无快递地址信息
- **THEN** 快递地址卡展示**空态**（「请选择收货地址」入口 + chevron），**禁止**回退展示机构自提地址
- **AND** 点击入口跳转 `/me/address`（`selectMode=true`）
- **AND** **本页禁止**调用获取地址列表接口；地址列表由 `/me/address` 自行加载
- **WHEN** 用户在地址列表选中一条地址
- **THEN** 回调 `onSelect(address)` 返回确认页，并调用 `POST /v1/order/updateOrderDelivery`（[Apifox](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/490169536e0.md)）绑定：`orderId`、`typeOrder=1`、`addressId`、`receiver`、`phone`、`address`（JSON body）
- **AND** 成功后乐观更新地址卡并 Toast「已选择收货地址」；失败回滚原地址并 Toast 错误
- **WHEN** 快递且无有效地址时点「立即支付」
- **THEN** Toast「请选择收货地址」，不提交

#### Scenario: 切换收货方式不同步后端

- **WHEN** 用户在「机构自提」「快递配送」间切换
- **THEN** 仅本地切换 UI，**不调用** `updateOrderDelivery`
- **AND** `updateOrderDelivery` **仅**在用户从地址列表选中地址后调用一次（绑定快递地址 + `typeOrder=1`）

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
- **THEN** 套餐金额 = `commodityPrice`（取整）
- **WHEN** `commodityPrice` 缺省
- **THEN** 退回 `totalPrice` − `expressAmount`；再退回 `appOrderDetailBO.payable` − `expressAmount`
- **AND** 套餐卡片右上角金额、费用明细「套餐金额」行均展示该值，**不得**为空或恒为 ¥0

#### Scenario: 应付金额

- **WHEN** 结算返回 `totalPrice`
- **THEN** 应付金额 = `totalPrice`（取整）
- **WHEN** `totalPrice` 缺省
- **THEN** 退回 `appOrderDetailBO.payable`；再退回 套餐金额 + 运费
- **AND** 底部「立即支付」与费用明细「应付金额」一致

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

- saveShoppingCartOrPurchase / getOrderSettlement / getById / updateOrderDescription / updateOrderDelivery Apifox
- funde `OrderConfirmView.vue`、PRD-605
