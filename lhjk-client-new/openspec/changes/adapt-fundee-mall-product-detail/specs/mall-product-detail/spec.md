## ADDED Requirements

### Requirement: 商品详情页布局

`/mall/detail` SHALL 展示对齐 `MallProductDetailView.vue` 的滚动详情与底部固定下单栏。

#### Scenario: 页面分区

- **WHEN** 用户携带有效 `id` 进入详情
- **THEN** 依次展示：Hero（主题色渐变、emoji、分类标签、名称、描述、可选角标）→ 标题价格区 → 商品亮点 → 适用人群 → 详情说明 → 使用步骤 → 服务承诺（正品保障 / 快速发货 / 售后无忧）
- **AND** 底部固定栏显示「优选价」、价格、「咨询」、「立即购买」；内容区底部预留下单栏高度避免遮挡

#### Scenario: 导航标题

- **WHEN** 页面展示商品
- **THEN** 导航栏标题为商品名称，支持返回

### Requirement: 分类差异化文案

亮点、适用人群、场景与详情文案 SHALL 按 `product.category` 切换。

#### Scenario: 三类 copy

- **WHEN** category 为「健康器械」
- **THEN** 使用器械类 label / highlights / audience / scenario / detail
- **WHEN** category 为「功能食品」
- **THEN** 使用功能食品类文案
- **WHEN** 其他（含「营养补充」）
- **THEN** 使用营养补充默认文案
- **AND** 使用步骤固定 3 步，第一步描述拼接商品名

### Requirement: 底部操作

#### Scenario: 咨询

- **WHEN** 用户点击「咨询」
- **THEN** 跳转 IM 会话（对齐 Vue：`/conversations/conv-001`）

#### Scenario: 立即购买

- **WHEN** 用户点击「立即购买」
- **THEN** 跳转确认订单路径（对齐 Vue：`/orders/confirm` + 商品 `id`）；若确认页未实现则展示占位页

### Requirement: 商品数据与空态

#### Scenario: 按 id 加载

- **WHEN** 传入 `id`
- **THEN** 从 `ServiceCatalogService` 查询商品（商城 API 未接入前可为本地原型目录）

#### Scenario: 商品不存在

- **WHEN** id 无匹配
- **THEN** 展示「商品不存在」空态，不展示下单栏

### Requirement: 商城列表进入详情

#### Scenario: 点击商品卡

- **WHEN** 用户在 `/mall` 点击商品卡片（或购买按钮）
- **THEN** `Router.push("/mall/detail", params: ["id": id])`
