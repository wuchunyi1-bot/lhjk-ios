# Design: fix-activate-hub-navigation

## Context

funde-client：

- `ActivateView.vue`：整张 button 卡片 `@click="router.push('/activate/bind'|'/activate/redeem')"`
- `activate.page.yaml`：整卡及右侧胶囊均可点击；无可用卡时兑换入口仍可进兑换页

iOS 已注册路由，但 Hub 卡用 `UIControl` + 嵌套 Stack，子视图 `userInteractionEnabled` 默认真，导致控件收不到 `touchUpInside`。

## Decision

1. 操作卡用 `UIView` + `UITapGestureRecognizer`（整卡）
2. CTA 用 `UIButton`（胶囊独立可点，命中优先于手势）
3. `Router.shared.push(path, from: self)`，避免 `topViewController` 解析偏差
4. 不改路由 path；不 mock 数据

## Routes

| 操作 | Path | VC |
|------|------|-----|
| 去绑定 / 整卡绑定 | `/activate/bind` | `BenefitBindViewController` |
| 去兑换 / 整卡兑换 | `/activate/redeem` | `BenefitRedeemViewController` |
