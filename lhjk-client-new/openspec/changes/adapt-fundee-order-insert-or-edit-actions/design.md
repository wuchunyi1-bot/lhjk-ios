## 接口

`POST /v1/order/insertOrEdit`  
文档：[insertOrEdit](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330734e0.md)（Body=`MOrder`）

| 场景 | status | 必填字段 | 可选字段 |
|------|--------|----------|----------|
| 取消订单 | `8` | `id`（字符串）、`hospitalId` | — |
| 确认收货 | `4` | `id`、`hospitalId` | —（**终态是否进已完成由后端处理**） |
| 退款/售后 | `9` | `id`、`hospitalId`、`remark` | — |
| 结算订单 | `9` | `id`、`hospitalId`、`remark` | — |
| 确认发货 | `3` | `id`、`hospitalId`、`shipmentTime` | —（**非 App 用户入口**；待发货仅展示取消） |
| 购物车去结算 | `1` | `id` | `hospitalId`（有则传） |

- `id` / `hospitalId`：Apifox schema 为 int64；客户端按线上兼容以 **字符串** 编码
- `remark`：取消/退款/结算原因（`MOrder.remark`）
- `shipmentTime`：确认发货时间（`MOrder.shipmentTime`）
- `description` / `serialNumber`：文档有定义，按场景按需传

## 架构

```
OrderTabViewController / OrderDetailViewController
  → OrderCancelFlow / OrderStatusActionFlow (PL)
    → OrderService.insertOrEditOrder (BLL)
```

`hospitalId` 解析：订单 `hospitalId` → Toast「机构信息缺失」
