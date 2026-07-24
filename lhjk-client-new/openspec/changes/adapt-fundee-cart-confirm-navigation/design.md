# Design: 购物车确认订单跨 Tab 导航

## 导航结构

```
RootTabBarController
├── [2] 服务 Nav → ServiceVC → CartVC → OrderConfirmVC
└── [4] 我的 Nav → MyVC → OrderListVC(全部)
```

## 入口打标

购物车「去结算」成功后：

```swift
Router.shared.push("/orders/confirm", params: [
    "orderId": String(orderId),
    "entry": "cart",
    "serialNumber": ... // 可选，仅给 getOrderSettlement
])
```

`OrderConfirmEntry`：

| 路由 `entry` | 枚举 | 行为 |
|--------------|------|------|
| `cart` | `.cartCheckout` | 跨 Tab 返回 / 支付成功 |
| 其它 / 缺省 | `.default` | 栈内 pop / replaceWithOrders |

## navigateToMyOrdersAll 执行顺序

1. 取得 `tabBarController`（无则降级 `Router.push("/orders", tab: all)`）
2. **服务 Tab（index=2）**：从导航栈移除 `OrderConfirmViewController`，保留 `[ServiceVC, CartVC, …]`
3. **我的 Tab（index=4）**：`popToRootViewController` 后 `pushViewController(OrderListVC)`（走 `BaseNavigationController` 自动 `hidesBottomBarWhenPushed`）
4. `selectedIndex = 4`

## 确认页触发点（仅 cartCheckout）

| 触发 | 处理 |
|------|------|
| 导航栏返回 | `navigateToMyOrdersAll` |
| 侧滑返回 | `interactivePopGestureRecognizer.isEnabled = false` |
| `navigateBack`（加载失败等） | `navigateToMyOrdersAll` |
| `navigateToOrders`（支付成功） | `navigateToMyOrdersAll` |

## 不变行为

- 订单列表「去支付」、套餐详情「立即下单」：`entry` 缺省，仍 `pop` / 当前 Nav 上 `replaceWithOrders`
- 子页（选地址）仍正常 push/pop
