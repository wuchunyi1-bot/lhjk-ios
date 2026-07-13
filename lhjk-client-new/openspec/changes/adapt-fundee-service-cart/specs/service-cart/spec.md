## ADDED Requirements

### Requirement: 购物车页布局

`/services/cart` SHALL 展示对齐 `CartView.vue` 的购物车列表与底部结算栏。

#### Scenario: 有商品时列表

- **WHEN** 购物车非空
- **THEN** 导航标题为「购物车」
- **AND** 每条卡片展示：勾选圆点、名称、副标题、行价（单价×数量）、元信息网格（服务对象 / 履约或收货方式 / 数量 / 优惠）、服务周期文案、「去结算」按钮
- **AND** 未勾选卡片降低透明度（约 0.62）

#### Scenario: 底部栏

- **WHEN** 用户查看底部栏
- **THEN** 左侧展示「已选 N 项」与已选合计金额（橙色 mono）
- **AND** 右侧「结算」按钮；已选为 0 时禁用

#### Scenario: 空态

- **WHEN** 购物车无商品
- **THEN** 展示空态文案「购物车空空如也」与「去逛逛」按钮
- **AND** 点击「去逛逛」跳转 `/mall`

### Requirement: 勾选与合计

#### Scenario: 切换勾选

- **WHEN** 用户点击卡片勾选圆点
- **THEN** 切换该条目 `selected`
- **AND** 「已选 N 项」与合计金额实时更新（Σ selected.price × quantity）

### Requirement: 删除商品

对齐 PRD「滑动删除/垃圾桶图标」；Vue `CartView.vue` 尚未实现，iOS 先行补齐。

#### Scenario: 垃圾桶删除

- **WHEN** 用户点击卡片右上角垃圾桶图标
- **THEN** 弹出确认弹窗「删除后不可恢复，确定从购物车移除该商品？」
- **AND** 用户确认后从本地购物车移除该条目并刷新列表与底部合计
- **AND** 最后一项删除后展示空态

#### Scenario: 滑动删除

- **WHEN** 用户左滑购物车条目
- **THEN** 展示「删除」操作；确认逻辑与垃圾桶一致（系统滑动删除直接移除，无需二次弹窗）

### Requirement: 结算跳转

#### Scenario: 卡片去结算

- **WHEN** 用户点击某卡片「去结算」
- **THEN** `Router.push("/orders/confirm", params: ["id": targetId])`

#### Scenario: 底栏结算

- **WHEN** 已选 ≥ 1 且用户点击底栏「结算」
- **THEN** 以已选列表第一项的 `targetId` 跳转 `/orders/confirm`

### Requirement: 加入购物车

#### Scenario: 套餐详情加入

- **WHEN** 用户在套餐详情点击「加入购物车」
- **THEN** 将当前套餐写入本地购物车（同 `targetId` 则 quantity +1）
- **AND** 跳转 `/services/cart`

### Requirement: 入口

#### Scenario: 服务 Hub / 我的

- **WHEN** 用户从服务顶栏购物车图标或「我的」常用功能进入
- **THEN** 打开 `/services/cart` 真实购物车页（非占位）
