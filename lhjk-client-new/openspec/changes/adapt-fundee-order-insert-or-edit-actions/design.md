## 接口

`POST /v1/order/insertOrEdit`

| 场景 | status | 必填字段 | 可选字段 |
|------|--------|----------|----------|
| 取消订单 | `8` | `id`（字符串）、`hospitalId` | — |
| 确认收货 | `4` | `id`、`hospitalId` | — |
| 退款/售后 | `9` | `id`、`hospitalId`、`remark` | — |
| 结算订单 | `9` | `id`、`hospitalId`、`remark` | — |
| 确认发货 | `3` | `id`、`hospitalId`、`shipmentTime` | — |
| 购物车去结算 | `1` | `id` | `hospitalId`（有则传） |

- `id`：订单主键，JSON **字符串**（大整数）
- `hospitalId`：机构 id，JSON **字符串**
- `remark`：取消/退款/结算原因（**非** `refundReasons`）
- `shipmentTime`：确认发货时间

## 架构

```
OrderTabViewController / OrderDetailViewController
  → OrderCancelFlow / OrderStatusActionFlow (PL)
    → OrderService.insertOrEditOrder (BLL)
```

`hospitalId` 解析：订单 `hospitalId` → Toast「机构信息缺失」
