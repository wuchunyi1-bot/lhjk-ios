# Order Detail (订单详情)

## Purpose

非「待支付」订单的详情展示。数据来自 `GET /v1/order/getAppOrderDetail`，首版对齐 funde **待发货**场景的信息结构与只读交互。

## API Reference

| 接口 | 方法 | 路径 |
|------|------|------|
| 根据订单 id 查询订单详情 | `GET` | `/v1/order/getAppOrderDetail` |

### Request

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `orderId` | Int64 | 是 | 订单 ID |

文档：[Apifox](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330739e0.md)

### Response: `AppOrderDetailBO`（核心字段）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | Int64 | 订单 ID |
| `orderName` | String | 套餐名称 |
| `status` | Int | 1–9，同列表 |
| `payable` | Double | 应付 |
| `price` | Double | 实付 |
| `packageDescription` | String | 卖点 |
| `packageImageUrl` | String | 封面 |
| `hospitalName` | String | 机构 |
| `typeOrder` | Int | 0 自提 / 1 快递 |
| `receiver` / `phone` / `address` | String | 收件或自提信息 |
| `expressAmount` | Double | 运费 |
| `couponAmount` | Double | 优惠券抵扣 |
| `shoppingCartPackageDetailList` | Array | 商品明细 |
| `createTime` | String | 下单时间 |
| `paymentType` | Int | 1 微信 / 2 支付宝 / 3 现金 / 4 银行卡 |
| `description` | String | 订单备注 |
| `logisticsNumber` / `logisticsVendor` | String | 物流（待收货等） |

## Requirements

### Requirement: 列表进入详情

#### Scenario: 待支付不进详情

- **WHEN** 用户在订单列表点击 `status=1` 订单
- **THEN** 进入 `/orders/confirm?orderId=`，**不**调用 `getAppOrderDetail`

#### Scenario: 其它状态进详情

- **WHEN** 用户点击非待支付订单卡片
- **THEN** 进入 `/orders/detail?id={orderId}`
- **AND** 调用 `GET /v1/order/getAppOrderDetail?orderId=`
- **AND** 加载中展示 loading；失败展示错误并可返回

### Requirement: 待发货详情展示

#### Scenario: 状态与履约

- **WHEN** 详情 `status=2`
- **THEN** 状态头展示「待发货」与备货提示
- **AND** 展示履约地址卡（快递/自提只读）
- **AND** 底部展示「取消订单」按钮（本期点击 Toast，不接 API）

#### Scenario: 商品与费用

- **WHEN** 详情加载成功
- **THEN** 展示套餐卡（含内嵌套餐内容）、费用明细、订单元信息
- **AND** 套餐内容与费用明细样式与待支付确认页一致（见 `order-detail-ui` spec「套餐内容与费用明细样式」）
- **AND** 金额展示保留两位小数，禁止 `Int` 四舍五入

### Requirement: 其它状态

#### Scenario: 待收货物流

- **WHEN** `status=3` 且存在 `logisticsNumber`
- **THEN** 在履约/订单区展示物流公司与单号

#### Scenario: 底部操作按钮

- **WHEN** 详情页根据 `status` 渲染底部栏
- **THEN** 按钮集合与列表卡 `OrderListCardAction` 规则一致；除导航外本期可 Toast「功能即将开放」

## File Structure

```
BLL/Service/OrderDetailModels.swift
BLL/Service/OrderService.swift          # +getAppOrderDetail
PL/My/Order/Detail/
├── OrderDetailViewController.swift
├── ViewModels/OrderDetailViewModel.swift
└── Components/OrderDetailComponents.swift
BLL/My/MyRoutes.swift                   # /orders/detail
```
