## MODIFIED Requirements

### Requirement: 激活兑换 Hub

`/activate` SHALL 对齐 funde `ActivateView` / 设计稿「激活兑换」，作为首页「激活兑换」落地页。

#### Scenario: 结构与入口

- **WHEN** 用户进入 `/activate`
- **THEN** 导航标题为「激活兑换」，不展示 Tab Bar
- **AND** 展示「权益卡服务」标题与说明「先绑定企业发放的权益卡，再兑换健康服务套餐。」
- **AND** 按序展示两张操作卡：第一步「绑定权益卡」、第二步「兑换健康服务套餐」
- **AND** 绑定卡跳转 `/activate/bind`；兑换卡跳转 `/activate/redeem`
- **AND** **不得**再进入「我的卡券」列表作为该路由落地页
- **AND** **不得**展示购买权益卡入口

#### Scenario: 待使用数量

- **WHEN** Hub 展示兑换卡
- **THEN** 副文案在有待使用卡时为「当前有 N 张权益卡可用」，否则「暂无可用权益卡，先去绑定」
- **AND** N 来自 `GET /v1/benefitsTake/getActivationOverview` 的 `availableBenefitsCount`（失败时可回退状态计数缓存）

### Requirement: 兑换套餐专区

`/activate/redeem` SHALL 对齐设计稿「兑换套餐」：机构头、分类 Tab、可兑套餐列表。

#### Scenario: 页面基础数据

- **WHEN** 用户进入 `/activate/redeem`
- **THEN** 调用 `GET /v1/benefitsTake/getRedeemPageInfo` 展示机构名称、地址、品牌标识与分类 Tab（含「全部」）
- **AND** 提示文案说明套餐可用权益卡抵扣、具体金额以兑换/下单页为准

#### Scenario: 套餐列表

- **WHEN** 用户切换分类或首次进入
- **THEN** 调用 `GET /v1/benefitsTake/getRedeemPackagePage`（全部不传 `categoryServiceId`；其它传分类 id；支持分页）
- **AND** 每项展示图标、标题、简介、参考价「¥x 起」、按钮「去兑换」
- **AND** 「去兑换」进入套餐详情 `/services/pkg`（携带套餐 id 与 `hospitalId`）
- **AND** **禁止** mock 套餐；无数据时展示空态

#### Scenario: 卡包立即兑换

- **WHEN** 用户在待使用权益卡点击「立即兑换」
- **THEN** 进入 `/activate/redeem`
