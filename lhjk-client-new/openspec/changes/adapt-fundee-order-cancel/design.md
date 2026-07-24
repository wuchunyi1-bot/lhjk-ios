# Design: 取消订单

## 接口

`POST /v1/order/insertOrEdit`，Body 为 `MOrder` 子集：

| 场景 | 必填字段 | 目标 status |
|------|----------|-------------|
| 待支付取消 | `id`（字符串）、`hospitalId` | `8` 已取消 |
| 待发货取消 | `id`、`hospitalId`、`remark` | `9` 退款审核 |

- `id`、`hospitalId`：JSON 字符串
- `remark`：退款申请原因，待发货取消必填

## 交互（对齐 funde PRD）

### 待支付（status=1）

1. 用户点击「取消订单」
2. `UIAlertController` 二次确认：标题「取消订单？」，说明「取消后可重新购买」
3. 确认后调用 `insertOrEdit`，`status=8`
4. 成功 Toast「订单已取消」，发送 `orderListNeedsRefresh`，详情页 `pop`

### 待发货（status=2）

1. 用户点击「取消订单」
2. 二次确认：标题「确认取消订单？」，说明「取消后订单将进入退款审核，是否确认取消？」
3. （可选）部分发货时额外提示文案——首版无发货任务字段时按普通确认处理
4. 打开 `OrderCancelRefundSheet`：套餐简卡 + 申请退款原因（必填，≤20 字，对齐 PRD）
5. 提交 `insertOrEdit`，`status=9`，`remark=原因`
6. 成功 Toast「已提交退款审核」，刷新列表；详情页 `pop`

### 异常

| 场景 | 表现 |
|------|------|
| 用户点「再想想/暂不取消」 | 关闭弹窗，不请求 |
| 提交中 | 主按钮 loading，禁止重复提交 |
| 接口失败 | Toast 服务端 `msg` 或「请稍后重试」，保留已填退款原因 |
| 订单状态已变 | Toast「订单状态已更新」，刷新列表/详情 |

## 架构

```
OrderTabViewController / OrderDetailViewController
  → OrderCancelFlow (PL)
    → OrderService.insertOrEditOrder (BLL)
      → APIManager.postAsync (DAL)
```

列表刷新：`Notification.Name.orderListNeedsRefresh`，`OrderListViewController` 监听后对所有 Tab 子 VC 调用 `refresh()`。
