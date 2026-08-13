# Change: fix-activate-hub-navigation

## Why

激活兑换 Hub（`/activate`）上「去绑定 / 去兑换」点击无跳转。原型整卡与胶囊按钮均应进入 `/activate/bind`、`/activate/redeem`；当前用 `UIControl` 包多层 `UIStackView`，子视图拦截触摸导致 `touchUpInside` 不触发。

## What Changes

- 对齐 funde `ActivateView.vue` / `activate.page.yaml`：整卡与 CTA 均可点
- 操作卡改为可点容器（手势 + 真实 `UIButton` CTA），`Router.push(..., from: self)`
- 路由仍为已注册的 `/activate/bind`、`/activate/redeem`
- 更新 activate OpenSpec

## Impact

- PL：`ActivateViewController.makeActionCard`
- Spec：`openspec/specs/activate/`、本 change delta
