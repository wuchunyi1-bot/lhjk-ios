# Me Module — Bug Fixes & UI Optimization

## Purpose

修复「我的」模块中与 funde-client `MeView.vue` 对比发现的缺失功能和 UI 差距。

---

## Fix 1: Hero 区域 — 暖色渐变背景

### Gap
funde-client 的 `.me-hero` 有 `var(--fd-gradient-hero)` 渐变背景，iOS 为纯色 `fdBg`。

### Fix
在 `buildTableHeader()` 中，header 添加 `CAGradientLayer`：`#FFF7F1` → `#FFE9DC`，方向 135° 对角。

### Acceptance
- [ ] Hero 区域有 funde 同款暖色渐变
- [ ] 下方 Stats Strip 的白色半透明卡片在渐变背景下正常显示

---

## Fix 2: "健康档案" 按钮无响应

### Gap
`healthBtn` 声明了但没有 `.addTarget`，点击无效。

### Fix
```swift
b.addTarget(self, action: #selector(pushHealthRecord), for: .touchUpInside)
```
`pushHealthRecord` → `Router.shared.push("/health/record")`

### Acceptance
- [ ] 点击 "健康档案" pill 按钮跳转到 `/health/record`

---

## Fix 3: "全部订单 ›" 导航无效

### Gap
Section header "服务履约" 的 "全部订单 ›" 点击调用 `showToast("全部订单")` 而非导航。

### Fix
```swift
titleView.onMoreTapped = { [weak self] in Router.shared.push("/orders") }
```

### Acceptance
- [ ] 点击 "全部订单 ›" push `/orders`（OrderListViewController）

---

## Fix 4: 服务履约统计数字可点击

### Gap
funde-client `me-order-stat` 每个统计数字可点击跳转到对应 Tab 的订单列表（如 `/orders?tab=pending_use`）。iOS 的 stat 列没有 tap 手势。

### Fix
`MeServiceFulfillmentCell`:
- 每个 stat 列添加 `UITapGestureRecognizer`
- 新增 `onStatTap: ((Int) -> Void)?` 回调
- `MyViewController` 中实现回调：根据 index 跳转 `/orders?tab=xxx`

### Route mapping
| stat index | label | route | 
|-----------|-------|-------|
| 0 | 待使用 | `/orders?tab=pending_use` |
| 1 | 使用中 | `/orders?tab=in_progress` |
| 2 | 已完成 | `/orders?tab=completed` |
| 3 | 待评价 | `/orders?tab=pending_review` |

### Acceptance
- [ ] 点击 "待使用(2)" push `/orders`（带 tab 参数）
- [ ] 其余 3 个 stat 同样可点击

---

## Fix 5: 其他交互对齐

### "编辑资料" 按钮
- 已有 `.addTarget` → push `/me/profile` ✅

### "设置" 按钮（右上角齿轮）
- 已有 `.addTarget` → push `/me/settings` ✅

### 会员卡入口
- 已有 tap → push `/me/membership` ✅

### Stats Strip（健康积分/家庭成员/我的保单/健康等级）
- 已有 onStatTap → push 对应路由 ✅

---

## Acceptance Checklist

- [ ] Hero 区域暖色渐变显示正确
- [ ] "健康档案" 按钮点击跳转 `/health/record`
- [ ] "全部订单 ›" 点击跳转 `/orders`
- [ ] 服务履约 4 个统计数字均可点击跳转对应 Tab
- [ ] 所有修改不影响已有功能
