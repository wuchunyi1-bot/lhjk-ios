## 交互（对齐 OrderSettlementDialog.vue）

1. 点击「结算订单」→ 打开底部 `OrderSettlementSheet`
2. 展示：标题「确认结算订单？」、说明「提交后该订单将进入退款审核。」、套餐简卡、申请退款原因（必填，≤20 字）
3. 「再想想」关闭；「确认结算」校验原因后调 API
4. 成功 Toast「已提交结算」，刷新列表

## API

```json
{
  "status": 9,
  "hospitalId": "<机构id>",
  "id": "<订单id>",
  "remark": "<申请退款原因>"
}
```

## 架构

```
OrderTabViewController / OrderDetailViewController
  → OrderStatusActionFlow.settle
    → OrderSettlementSheet (PL)
      → OrderService.settleOrder (BLL)
```
