# Change: adapt-fundee-activate-flow

## Why

首页「激活兑换」仍错误跳入卡券列表；卡包「绑定权益卡 / 去绑定」页与原型 `/activate`、`/activate/bind`、`/activate/redeem` 不一致。需对齐 funde-client 激活兑换双步骤 Hub、绑定表单与兑换专区。

## What Changes

- `/activate`：激活兑换 Hub（先绑定、后兑换双操作卡）
- `/activate/bind`：绑定权益卡页 UI/流程对齐原型（真实 `preCheckByKey` → `bindByKey`；成功页双出口）
- `/activate/redeem`：兑换套餐专区壳页（无待使用卡→绑定引导；有卡暂无适用范围列表→空态文案）
- 卡包绑定入口与「立即兑换」改为路由跳转上述页面
- **不做**：原型专用演示扫码四场景 / 重新演示绑定；扫码入口保留 UI，真机扫码可后续接相机

## Impact

- PL：`Activate*` / `BenefitBind` / `BenefitRedeem`；`ServiceRoutes` / `MyRoutes`；`BenefitTabViewController`
- Spec：`openspec/specs/activate/`
