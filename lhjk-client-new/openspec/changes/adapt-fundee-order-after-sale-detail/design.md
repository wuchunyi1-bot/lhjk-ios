# Design: 退款/售后订单详情

## 页面结构（对齐 funde）

```
OrderDetailViewController
├── 状态区（大标题 + hint；驳回时 hint =「退款未通过：{原因}」）
├── 履约地址卡
├── 套餐卡
├── 商品明细卡（有数据时）
├── 费用明细卡
├── 退款/售后信息卡（售后态或有售后字段时）  ← 新增
├── 订单信息卡
└── 底部操作栏（售后态隐藏）
```

## 售后信息卡字段

| UI 字段 | API 字段 | 规则 |
|---------|----------|------|
| 申请时间 | `refundApplyTime` | 有值展示 |
| 退款单号 | `refundId` | 有值展示，支持复制 |
| 申请退款原因 | `refundReasons` | 有值展示 |
| 退款金额 | `applyRefund` | 有值且 > 0 时高亮展示 |

展示条件（对齐 `OrderAfterSaleInfoCard.vue`）：
- `status` 为 6（退款/售后）或 9（退款审核）
- 或存在 `refundApplyTime` / `refundReasons` / `refundId`

审核驳回后（`refuseReasons` 有值且不在售后流程态）：隐藏售后信息卡，状态区展示拒绝原因。

## 状态文案

| status | 标题 | hint |
|--------|------|------|
| 9 | 退款审核 | 退款申请审核中，请耐心等待 |
| 6 | 退款/售后 | 退款处理中，请耐心等待 |

## 空白页根因与修复

1. **解码失败**：售后订单商品行 `quantity` 等字段可能为字符串/浮点，严格 `Int` 解码导致 `shoppingCartPackageDetailList` 整段失败 → 使用弹性解码 + 明细数组逐项容错
2. **加载态**：`isLoading=false` 时未根据 `detail` 恢复 `scrollView` 可见 → 合并 `detail`/`isLoading` 驱动渲染；**禁止隐藏 `scrollView`**，改用半透明 loading 遮罩，并在渲染后 `layoutIfNeeded()`
