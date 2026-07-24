# 订单列表按钮 insertOrEdit 矩阵

## Why

各状态订单卡片/详情底栏操作需统一对接 `POST /v1/order/insertOrEdit`，Body 字段以线上实测为准（`remark`、`shipmentTime`）。

## What

- 规范 7 类操作的 status 与 Body
- `refundReasons` 统一改为 `remark`
- 新增待发货「确认发货」、待收货「退款/售后」

## API 矩阵

| 订单状态 | 按钮 | status | 额外字段 |
|---------|------|--------|---------|
| 待支付 | 取消订单 | 8 | `remark`（可选） |
| 待发货 | 确认发货 | 3 | `shipmentTime` |
| 待发货 | 取消订单 | 9 | `remark` |
| 待收货 | 退款/售后 | 9 | `remark` |
| 待收货 | 确认收货 | 4 | — |
| 使用中 | 结算订单 | 9 | `remark` |
| 已逾期 | 结算订单 | 9 | `remark` |

公共字段：`id`（字符串）、`hospitalId`（字符串）
