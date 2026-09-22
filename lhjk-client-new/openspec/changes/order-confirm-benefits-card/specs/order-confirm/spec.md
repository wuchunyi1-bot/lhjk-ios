## ADDED Requirements

### Requirement: 确认订单页面 UI 规范（对齐 Figma 3479:8187）

确认订单页除地址以外的 UI 元素 SHALL 按照 Figma `3479:8187` 设计图实现：

#### Scenario: 页面背景与卡片容器
- **WHEN** 渲染确认订单页面
- **THEN** 页面背景色使用 `#FDF6F3`
- **AND** 卡片容器背景为白色（`#FFFFFF`），圆角为 `16pt`，间距 `12pt`，左右内边距 `16pt`

#### Scenario: 套餐卡片与明细展开/收起
- **WHEN** 渲染套餐卡片（`OrderConfirmPackageView`）
- **THEN** 头部展示套餐标题（16pt medium, `#1F2942`）、副标题（14pt regular, `#8591AB`）与金额（¥ 16pt medium + 数字 18pt medium, `#1F2942`）
- **AND** 套餐内容包含在浅橙色渐变容器中（圆角 12pt），带小冠状图标（`order_confirm_package_icon`，16x16）和「套餐内容」标题
- **AND** 明细列表展示项目名称（12pt regular）、数量（12pt regular）、金额（12pt medium）
- **AND** 底部提供居中的「展开 (共N项)」/「收起」操作按钮，右侧带圆形三角图标（`order_confirm_expand_icon` / `order_confirm_collapse_icon`，14x14）

#### Scenario: 三合一选项卡片（备注、优惠券、权益卡）
- **WHEN** 渲染订单选项区域
- **THEN** 将订单备注、优惠券、权益卡三项收纳在同一个 16pt 圆角白色卡片容器中，行高 48pt，行间设 0.5pt 分割线
- **AND** 订单备注行包含文档图标（`order_confirm_remark_icon`，16x16）和「订单备注」标题，未填展示「请填写」（`#717885`）与右箭头
- **AND** 优惠券行包含礼品图标（`order_confirm_coupon_icon`，16x16）和「优惠券」标题；右侧文案（有可用 / 已使用 / 暂无可用）一律 `#F93838`；有可用券或已抵扣时展示红色「惠」字角标（`order_confirm_coupon_badge`，14x14）
- **AND** 权益卡行包含盾牌图标（`order_confirm_benefit_icon`，16x16）和「权益卡」标题；右侧文案（有可用 / 已使用 / 暂无可用）一律 `#F93838`

#### Scenario: 费用明细卡片
- **WHEN** 渲染费用明细（`OrderConfirmFeeView`）
- **THEN** 卡片标题「费用明细」（16pt medium, `#1F2942`）
- **AND** 包含套餐金额、运费、优惠券抵扣（有抵扣为 `#F93838`）、权益卡抵扣（有抵扣为 `#F93838`）
- **AND** 底部设 0.5pt 分割线，展示「应付金额」（16pt medium）与金额（¥ 16pt medium + 数字 18pt medium, `#F93838`）

#### Scenario: 支付方式卡片
- **WHEN** 渲染支付方式（`OrderConfirmPayMethodView`）
- **THEN** 卡片标题「支付方式」（16pt medium, `#1F2942`）
- **AND** 微信支付行带绿色微信图标（`order_confirm_wechat_icon`，16x16），右侧为单选框（14x14，选中时展示红色圆圈白勾 `order_confirm_radio_selected`，未选中展示 `order_confirm_radio_unselected`）
- **AND** 支付宝支付行带蓝色支付宝图标（`order_confirm_alipay_icon`，16x16），右侧为单选框（14x14）

#### Scenario: 底部提交栏
- **WHEN** 渲染底部提交栏（`OrderConfirmSubmitBar`）
- **THEN** 背景为白色，顶部带 16pt 圆角与轻微投影
- **AND** 左侧展示「应付金额」标签与大字号价格（¥ 14pt medium + 数字 20pt medium, `#F93838`）
- **AND** 右侧展示「立即支付」按钮（宽 112pt，高 40pt，圆角 20pt，背景色 `#FF7A50`，白字 14pt medium）

---

### Requirement: 确认订单权益卡选择

确认订单页 SHALL 支持权益卡多选抵扣，对齐 funde `OrderConfirmView` / `orders-confirm.page.yaml`。

#### Scenario: 查询可用权益卡

- **WHEN** 确认订单结算加载成功，或用户点击「权益卡」行
- **THEN** 调用 `GET /v1/benefitsTake/getCustomerPage`（[Apifox](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/498029202e0.md)），Query `status=3`（待使用）
- **AND** 仅保留待使用且未处于转赠锁定（`pendingTransferId` 为空）的卡
- **AND** **禁止**用 mock / 假 id 顶替列表；无数据时空态「暂无可用」
- **AND** 本期无「按套餐适用范围」接口时，**不**按业务类本地硬过滤；后端补适用范围后替换列表源

#### Scenario: 入口文案

- **WHEN** 订单或结算已使用权益卡（`benefitsAmount` / 结算权益抵扣 > 0）
- **THEN** 展示「已使用N张，共优惠¥x」；订单未给出张数时展示「已使用，共优惠¥x」（金额用 `OrderConfirmMoney.yen`），文案 `#F93838`
- **AND** 之后返回的 `getOrderBenefitsList` **不得**把已使用文案改成「有N张可用」或「暂无可用」
- **WHEN** 订单未使用权益卡，且有可用卡
- **THEN** 展示「有N张可用」，文案 `#F93838`
- **WHEN** 订单未使用权益卡，且无可用卡
- **THEN** 权益卡行展示「暂无可用」，文案 `#F93838`

#### Scenario: 选择弹层

- **WHEN** 用户点击权益卡行或优惠券行
- **THEN** 自底部弹出半透明面板（对齐 Figma 6013:3517 / 6014:4224）：
  - 顶部居中标题（18pt Medium）：「选择权益卡」/「选择优惠券」
  - 顶部居中副标题（14pt Regular `#8591AB`）：「支持多张同时使用，权益卡不抵扣运费」/「默认先领取先使用，可选择不使用」
  - 右上角关闭按钮（20pt 灰色叉号）
  - 顶部下方浅色分割线（0.5pt `#F0F2F5`）
- **AND** 卡片列表项采用统一 79pt 双栏圆角卡片（`#FFF9F6` 底、16pt 圆角）：
  - 左侧：名称（16pt Medium `#1F2942`）与副文案（12pt Regular `#8591AB`，有效期或使用门槛）
  - 中间：0.5pt 垂直虚线（`#FFD9C6`）
  - 右侧：110pt 浅色底块（`#FFF0E6`）+ 居右金额（18pt Medium `#F93838`）
  - 选中状态：卡片边框高亮（1.0pt `#FF7A50`），并在右下角贴边展示专属对勾角标（`order_card_selected_badge`，22×22）
  - 未选状态：细边框（0.5pt `#FFECE2`），隐藏右下角角标
- **AND** 权益卡支持多选；列表下方展示动态抵扣提示「当前最多可抵扣 ¥xxx ，已抵扣 ¥xxx」（12pt Regular `#8591AB`）
- **AND** 底部操作区：
  - 主按钮「完成」（高度 43pt 胶囊形，`#FF7A50` 底，白色文字 16pt Medium）
  - 次级按钮「不使用」（主按钮下方居中文字，14pt Regular `#FF7A50`），点击清空选择并关闭
  - 无可用卡券时主按钮显示「我知道了」，展示空态文案且隐藏「不使用」按钮

#### Scenario: 抵扣与应付（本期：客户端试算）

- **WHEN** 用户确认选择或不使用
- **THEN** 本地更新已选 `benefitsTake` id 列表并重算费用，**不**调用尚不存在的绑单接口
- **AND** `benefitDiscount = min(max(0, packageAmount − couponDiscount), Σ 已选面值)`
- **AND** 权益卡**不**抵扣运费；优惠券与权益卡可同时使用，先券后卡
- **AND** `payable = max(0, settlementPayable − benefitDiscount)`（结算未含权益抵扣时）
- **AND** 费用明细「权益卡抵扣」优先 `benefitsAmount`；未返回时才用本地试算；抵扣为 0 仍展示 `-¥0.00`
- **AND** 默认不自动勾选任何权益卡

#### Scenario: 与结算 / 优惠券联动

- **WHEN** `bindCouponTake` 或履约刷新导致结算金额变化
- **THEN** 按新的套餐金额与优惠券抵扣重新计算权益卡上限与应付
- **AND** 若已选卡 id 不在最新可用列表中则剔除

#### Scenario: 绑单与核销（后续）

- **WHEN** Apifox 提供订单绑定权益卡接口且结算返回权益抵扣字段
- **THEN** 选择完成后刷新 `getOrderSettlement`；应付与抵扣以 `benefitsAmount` / `expectedPayableAmount` 为准
- **AND** 支付成功后才核销实际使用的权益卡；待支付不锁定、不占用卡包状态

#### Scenario: API 缺口标注

- **WHEN** 查阅本仓库接口清单
- **THEN** 确认页权益卡列表标注复用 `GET /v1/benefitsTake/getCustomerPage`；结算权益抵扣取 `benefitsAmount`，优惠券实际抵扣取 `couponAmount` / 结算根级 `amount`
