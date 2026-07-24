## MODIFIED Requirements

### Requirement: 订单列表 Tab（对齐 funde OrderListView）

「我的订单」页 SHALL 展示 **恰好 8 个** 状态 Tab，顺序与文案与 funde-client 一致，**不得**再展示「已取消」「退款审核中」独立 Tab。

#### Scenario: Tab 顺序与命名

- **WHEN** 用户进入 `/orders`
- **THEN** Tab 从左到右为：全部、待支付、待发货、待收货、使用中、已逾期、退款/售后、已完成
- **AND** Tab **不得**展示数量角标
- **AND** 默认选中「全部」；支持 `initialTab` / query：`pending_payment`、`paid_pending_delivery`（及兼容 `pending_ship`）、`pending_receipt`（及兼容 `pending_receive`）、`in_progress`、`overdue`、`after_sale`（及兼容 `refund`）、`completed`

#### Scenario: Tab → API 筛选

- **WHEN** 用户切换 Tab
- **THEN** 子列表按下表请求 `GET /v1/order/getAppOrderList`：

| Tab | 参数 |
|-----|------|
| 全部 | 不传 status / statusList |
| 待支付 | `status=1` |
| 待发货 | `status=2` |
| 待收货 | `status=3` |
| 使用中 | `status=4` |
| 已逾期 | `status=7` |
| 退款/售后 | `status=6` |
| 已完成 | `status=5` |

- **AND** `status=8`（已取消）仅可能出现在「全部」列表
- **AND** 子 VC 首次加载后缓存；切回已加载 Tab 不重复请求，除非 `refresh()`

### Requirement: 订单列表卡片布局（对齐 OrderListCard）

订单卡片 SHALL 按 funde `OrderListCard` 结构展示，**不得**再使用「标题+描述+日期行」旧布局。

#### Scenario: 卡片结构

- **WHEN** 渲染一条订单
- **THEN** 自上而下为：
  1. 顶栏：左侧机构图标 + 机构名（`hospitalName`，空则「服务机构」）；右侧状态徽章
  2. 主体：左侧 72×72 套餐封面（`packageImageUrl`，无图占位文案「套餐」）；右侧套餐名称（最多 2 行）、一句话卖点（`packageDescription`，空则隐藏）、金额右对齐（优先 `payable` 否则 `price`，`fdMono` + 主色）
  3. 底栏（条件）：当前状态允许的操作按钮，右对齐，最多约 2 个
- **AND** **不得**在卡片主体展示日期范围行作为主信息（对齐 Vue 列表卡）

#### Scenario: 状态文案

- **WHEN** 订单 `status=1`
- **THEN** 徽章文案为「待支付」（非「待付款」）
- **WHEN** `status` 为其它已知值
- **THEN** 使用 `AppOrderStatus.label`（待发货 / 待收货 / 使用中 / 已完成 / 退款/售后 / 已逾期 / 已取消 / 退款审核中）

#### Scenario: 操作按钮（本期 UI）

- **WHEN** 待支付
- **THEN** 展示「取消订单」（次要）+「去支付」（主按钮）
- **WHEN** 待发货
- **THEN** 展示「取消订单」
- **WHEN** 待收货
- **THEN** 展示「确认收货」（主按钮）；若可识别电商零售可额外「退款/售后」（无类型字段时仅确认收货）
- **WHEN** 使用中 / 已逾期
- **THEN** 展示「结算订单」为主按钮
- **AND** 仅当 `packageType == 1`（租赁套餐）时额外展示「续费订单」为次要按钮
- **AND** `packageType` 为 2/3/4 或缺失时不展示「续费订单」
- **WHEN** 用户点击操作按钮且对应 API 未接入
- **THEN** Toast「功能即将开放」，**不得**崩溃
- **WHEN** 用户点击卡片非按钮区域
- **THEN** 进入 `/orders/detail`（params `id`）

### Requirement: 空状态文案

系统 SHALL 按当前 Tab 展示差异化空态文案。

#### Scenario: 分 Tab 空态

- **WHEN** 退款/售后 Tab 无数据 → 「暂无退款/售后记录」
- **WHEN** 待收货 → 「暂无待收货订单」
- **WHEN** 使用中 → 「暂无使用中订单」
- **WHEN** 已完成 → 「暂无已完成订单」
- **WHEN** 已逾期 → 「暂无已逾期订单」
- **WHEN** 全部 / 待支付 / 待发货 → 「暂无订单」

## 参考

- funde-client `OrderListView.vue` tabs L62–71
- `OrderListCard.vue`
- PRD `05_用户_我的订单_v1.0.md`
- `docs/page-specs/orders-list.page.yaml`
