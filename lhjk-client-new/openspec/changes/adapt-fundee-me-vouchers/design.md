## Context

权威参考：
- Vue：`prototype/src/views/me/MyVouchersView.vue`
- PRD：`app端prd初稿/10_用户_我的卡券_v1.0.md` §5.1–5.3
- **布局范式**：对齐订单模块 `OrderListViewController` + `OrderTabViewController`（容器 + 每状态独立 TableView）

上一轮卡包主页用单一 TableView 切换筛选，需拆成与订单同构的多 VC / 多 TableView。

## Goals / Non-Goals

**Goals:**
- 权益卡、优惠券为独立模块（独立容器 VC + 独立布局）
- 各状态筛选对应**独立子 VC + 独立 UITableView**（与订单一致）
- 保留业务规则（排序、转赠合并、角标、票券规则展开等）

**Non-Goals:**
- 赠送/分享/领取完整页、微信 SDK
- 订单选券 API 复用为卡包唯一数据源
- 绑定/兑换页本体

## Decisions

### 1. 页面拆分（对齐 Order）

```
VoucherListViewController          // Hub：顶栏「权益卡 | 优惠券」，切换子模块
├── BenefitListViewController      // 权益卡容器：横向状态 Tab + 子 VC 切换
│   └── BenefitTabViewController × N   // 每状态一个 TableView（缓存实例）
└── CouponListViewController       // 优惠券容器：横向状态 Tab + 子 VC 切换
    └── CouponTabViewController × M    // 每状态一个 TableView（缓存实例）
```

| 模块 | 状态 Tab | 对应子 VC |
|------|----------|-----------|
| 权益卡 | 全部 / 待使用 / 已兑换 / 已过期 / 转赠记录 | 5 个 `BenefitTabViewController` |
| 优惠券 | 全部 / 待使用 / 已领用 / 已过期 | 4 个 `CouponTabViewController` |

行为对齐订单：
- 每个状态 Tab **预创建**子 VC，切换时 `addChild` / 替换容器，**不销毁**已创建实例
- 子 VC 各自持有 `UITableView`；首次 `viewWillAppear` 加载数据，切回用缓存
- Hub / 容器 **禁止**用单一 TableView 靠 filter 伪装多 Tab

### 2. 子 VC 职责

**BenefitTabViewController**
- 入参：`BenefitStatusFilter`
- 「全部 / 待使用 / …」列表顶部固定「绑定权益卡」入口（除「转赠记录」可按产品决定：全部与持卡 Tab 显示绑定）
- 列表项：`BenefitListEntry`（卡 / 转赠）
- 等待领取：本 VC 内倒计时刷新

**CouponTabViewController**
- 入参：`CouponStatusFilter`
- 仅优惠券票券 Cell；规则展开状态留在该 Tab VC 内

### 3. Hub 切换

`VoucherListViewController` 顶层 Segmented 只切换 `BenefitListViewController` ↔ `CouponListViewController`（同样 child VC 缓存），不混用一张表。

路由：`/me/vouchers?tab=coupon` 默认展示优惠券模块。

### 4. 数据

仍由 `VoucherService` 提供 Mock；筛选/排序逻辑可下沉为 Service 或轻量 Helper，供各 Tab VC 调用。不要求每 Tab 独立网络（Mock 阶段），但 **TableView 实例必须按 Tab 独立**。

### 5. 角标

「我的」入口：`availableBenefit + availableCoupon`。待使用 Tab 标题可带数量。

## Risks / Trade-offs

- [子 VC 数量增加] → 与订单一致，可接受；注意 appearance 转发（`shouldAutomaticallyForwardAppearanceMethods = false`）
- [绑定入口重复] → 各持卡 Tab 顶部均展示，与 Vue「列表上方固定入口」一致

## Open Questions

- 无
