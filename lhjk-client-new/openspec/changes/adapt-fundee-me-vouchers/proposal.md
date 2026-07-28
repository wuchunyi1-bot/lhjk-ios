## Why

iOS「我的卡券」仍是旧版三好卡单列表（未使用/已激活/已过期），与 funde `MyVouchersView` 及 PRD《10_用户_我的卡券》差距大：缺少权益卡/优惠券双 Tab、转赠记录、绑定入口、优惠券票券样式与使用规则展开。

## What Changes

- 对齐 funde 卡包主页能力：权益卡 / 优惠券、状态筛选、绑定入口、转赠记录、票券规则等
- **布局改为订单同构**：Hub + 权益卡/优惠券独立容器；**每个状态 Tab 独立子 VC + 独立 UITableView**（缓存切换）
- 「我的」入口角标 = 待使用权益卡 + 待使用优惠券
- 本轮数据以对齐原型的本地 Mock；真实卡包 API 后续接入
- **暂不实现**完整赠送/分享/领取页与微信分享（入口可 Toast）


## Capabilities

### New Capabilities

- （无；修改既有 `vouchers`）

### Modified Capabilities

- `vouchers`: 按 PRD §5.1–5.3 / `MyVouchersView.vue` 重写卡包主页需求

## Impact

- PL：`VoucherListViewController`、Cells、ViewModel；「我的」角标
- BLL：`VoucherModels` / `VoucherService` 权益卡+优惠券资产模型
- 路由：保留 `/me/vouchers`；绑定/兑换/去使用跳转既有或占位路径
