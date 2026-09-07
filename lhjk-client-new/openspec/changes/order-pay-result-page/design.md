# Design: order-pay-result-page

## 视觉来源

Figma：[支付结果 `3506:9196`](https://www.figma.com/design/JEIKBLlcPpylp8GJ7BVmFd/%F0%9F%8C%9F%E5%BC%80%E5%8F%91%E5%AF%B9%E6%8E%A5-%E9%A1%B9%E7%9B%AE%E6%8F%90%E4%BA%A4?node-id=3506-9196)

对齐 funde 原型 `PaymentConfirmView` 的结果英雄区（图标 + 标题 + 金额/说明），底栏仅「完成」（本期不提供「查看订单」）。失败态为同页变体，非独立路由。

## 支付结束后的页面分流

```text
确认订单 submitPay
  ├─ SDK / 0 元单成功          → 支付结果（成功）
  ├─ PaymentError 非取消       → 支付结果（失败，展示原因）
  ├─ 其它发起支付错误          → 支付结果（失败）
  ├─ userCancelled             → 留确认页 Toast「已取消支付」
  └─ OrderServiceError.payRejected → 留确认页 Toast msg + 刷新结算
```

用户取消与金额版本不一致均未完成一次「支付尝试的终态」，不进结果页，便于原地改券/改金额或再次调起。

## 结果页结构

| 区域 | 成功 | 失败 |
|------|------|------|
| 导航标题 | 支付结果 | 同左 |
| 图标 | `pay_success`（80pt） | `pay_failed`（80pt） |
| 主文案 | 支付成功（18pt Regular，#1F2942） | 支付失败（18pt Regular，#1F2942） |
| 金额 | 详情应付（¥ 24pt，数值 32pt Medium，#1F2942） | 不展示 |
| 说明 | 「订单已提交，我们将尽快为您处理」（14pt Regular，#8591AB） | 失败原因（缺省「支付失败，请稍后重试」） |
| 信息卡 | `pay_info_bg` 背景；含缺口灰色虚线；`GET /v1/order/getAppOrderDetail` | 同左 |
| 底栏 | 左「完成」（白底橙框），右「查看订单」（橙底实心） | 同左 |

信息卡字段（**不展示支付时间**）：

| 字段 | 来源 |
|------|------|
| 订单号 | `id`，可复制（14x14 复制图标） |
| 下单时间 | `createTime` |
| 支付方式 | `paymentType` 字典文案，缺省确认页所选渠道 |
| 订单状态 | `status` → `AppOrderStatus.label` |

- 页面背景 `fdBg`；图标直接铺在底上，不用白底圆
- 信息卡宽 = 屏宽 − 32，高按 `pay_info_bg` 宽高比（783/732）；缺口中心穿过虚线（对齐 Figma Vector 1791）
- 底栏按钮：等宽双按钮，高 40pt、胶囊圆角 20pt，左右 16pt，间距 10pt
- 禁用侧滑返回；自定义返回箭头与左按钮「完成」行为一致：返回订单列表「全部」Tab；右按钮「查看订单」进入该订单详情
- 详情请求失败不造假数据，隐藏信息卡

## 支付结束即重建栈

无论入口是购物车、选择套餐（服务 Tab）还是订单列表待支付，支付成功或失败进入结果页时都调用 `presentPayResultOnMyOrders`：

```text
服务 Tab（及来源 Tab）  popToRoot
我的 Tab               [我的, 订单列表全部, 支付结果]
selectedIndex          我的
```

不得把结果页 push 在选择套餐 / 套餐详情 / 确认订单之上。

## 离开结果页

不得 `pop` 回确认订单或选择套餐。

| 操作 | 目标栈 |
|------|--------|
| 返回箭头 / 「完成」 | `[我的, 订单列表全部]`（`leavePayResultToOrderList`） |
| 「查看订单」 | `[我的, 订单列表全部, 订单详情]`（`leavePayResultToOrderDetail`） |

成功进入结果页前 `NotificationCenter.post(.orderListNeedsRefresh)`。

## 路由

`/orders/pay-result`

参数：`outcome`（`success` / `failure`）、`orderId`、`amountYuan`、`payMethodTitle`、`message`（失败原因）、`entry`。

由确认页在支付结束后构造 `OrderPayResultPayload` 再 push。结果页进入后请求 `getAppOrderDetail` 填充信息卡；不再请求支付接口。

## 非目标

- 支付结果确认中轮询 / 服务端二次验单页
- 失败页提供「重新支付」（回列表后从待支付入口再付）
