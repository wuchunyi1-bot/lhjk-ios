## ADDED Requirements

### Requirement: 卡包 Order 式多 TableView 架构

我的卡券 SHALL 按订单列表同构拆分：**Hub → 资产模块容器 → 每状态独立子 VC/TableView**，不得用单一 TableView 仅靠筛选模拟多状态页。

#### Scenario: 模块拆分

- **WHEN** 进入 `/me/vouchers`
- **THEN** Hub（`VoucherListViewController`）仅负责顶层「权益卡 | 优惠券」切换
- **AND** 权益卡由独立容器 VC（`BenefitListViewController`）承载布局与状态 Tab
- **AND** 优惠券由独立容器 VC（`CouponListViewController`）承载布局与状态 Tab

#### Scenario: 状态 Tab 独立 TableView

- **WHEN** 权益卡容器展示
- **THEN** 状态 Tab 为：全部、待使用、已兑换、已过期、转赠记录
- **AND** 每个状态对应一个已缓存的 `BenefitTabViewController`，各自持有独立 `UITableView`
- **WHEN** 优惠券容器展示
- **THEN** 状态 Tab 为：全部、待使用、已领用、已过期
- **AND** 每个状态对应一个已缓存的 `CouponTabViewController`，各自持有独立 `UITableView`

#### Scenario: 切换缓存

- **WHEN** 用户在同一模块内切换状态 Tab 或在 Hub 切换资产模块
- **THEN** 使用预创建子 VC 切换显示（addChild / 替换容器），不销毁已加载实例
- **AND** 子 VC 首次出现时加载数据，再次出现可直接展示已有列表（对齐订单 Tab 缓存行为）

### Requirement: 卡包双模块入口

我的卡券页 SHALL 提供顶层「权益卡」「优惠券」双模块，默认权益卡；对齐 funde `MyVouchersView`。

#### Scenario: 进入卡包

- **WHEN** 用户从「我的」进入 `/me/vouchers`
- **THEN** 标题为「我的卡券」，默认展示权益卡模块
- **AND** 不展示底部 Tab Bar

#### Scenario: 切换优惠券

- **WHEN** 用户切换到优惠券（或路由 `tab=coupon`）
- **THEN** 展示优惠券容器及其状态 Tab / 独立列表

### Requirement: 权益卡模块列表

权益卡各状态 Tab SHALL 展示绑定入口（转赠记录除外）、权益卡与转赠记录及状态匹配操作。

#### Scenario: 待使用数量

- **WHEN** 展示权益卡状态 Tab 栏
- **THEN** 「待使用」可展示可用数量（未核销、未过期、非转赠锁定）

#### Scenario: 绑定入口

- **WHEN** 状态为全部 / 待使用 / 已兑换 / 已过期
- **THEN** 列表顶部展示「绑定权益卡」入口
- **AND** 「转赠记录」Tab 不展示绑定入口

#### Scenario: 卡片与操作

- **WHEN** 待使用权益卡
- **THEN** 展示名称、面值、有效期、印章；临近到期提示；可「赠送好友」「立即兑换」
- **WHEN** 已兑换
- **THEN** 可「查看订单」
- **WHEN** 已过期
- **THEN** 低饱和、无操作

#### Scenario: 转赠记录

- **WHEN** 「全部」含等待领取，或「转赠记录」Tab
- **THEN** 等待领取展示倒计时；已转赠展示受赠人与领取时间
- **AND** 转赠中原卡不出现在持卡 Tab

#### Scenario: 空态

- **WHEN** 当前状态 Tab 无条目
- **THEN** 「暂无相关权益卡」

### Requirement: 优惠券模块列表

优惠券各状态 Tab SHALL 使用独立 TableView 展示票券；卡包券与订单选券独立。

#### Scenario: 待使用数量

- **WHEN** 展示优惠券状态 Tab 栏
- **THEN** 「待使用」（内部已领取）可展示可用数量

#### Scenario: 票券与规则

- **WHEN** 渲染优惠券
- **THEN** 展示力度、门槛、名称、有效期、状态角标；待使用有「去使用」
- **AND** 使用规则可在本 Tab 内展开/收起

#### Scenario: 去使用

- **WHEN** 点击去使用
- **THEN** 进入服务列表，不预筛选、不自动选券

#### Scenario: 空态

- **WHEN** 当前状态 Tab 无券
- **THEN** 「暂无相关优惠券」及引导文案

### Requirement: 我的页卡券角标

「我的」常用功能「我的卡券」SHALL 展示可用资产数量角标。

#### Scenario: 角标计算

- **WHEN** 渲染我的页
- **THEN** 角标 = 待使用权益卡数 + 待使用优惠券数
- **AND** 为 0 时不展示；超过 99 展示「99+」

### Requirement: 卡包数据与 Mock 边界

卡包主页本期 SHALL 使用对齐 funde 原型的本地 Mock；接真实 API 前禁止把订单 `getCouponTakeList` 结果直接当作卡包唯一数据源。

#### Scenario: 独立维护

- **WHEN** 用户在确认订单勾选/取消优惠券
- **THEN** 不得改变卡包优惠券 Tab 中的券状态展示（Mock 阶段保持本地资产不变）
