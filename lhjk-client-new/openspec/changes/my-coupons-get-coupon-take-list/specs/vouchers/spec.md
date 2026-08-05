## MODIFIED Requirements

### Requirement: 优惠券模块列表

优惠券各状态 Tab SHALL 使用独立 TableView 展示票券；列表数据来自 `GET /v1/couponTake/getCouponTakeList`（[Apifox](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330752e0.md)）。卡包按 Tab 传 `status`；确认订单选券可继续按机构等条件查询，二者共享 BLL，互不写回对方本地假状态。

#### Scenario: 按状态请求

- **WHEN** 用户打开或刷新优惠券某状态 Tab
- **THEN** 调用 `GET /v1/couponTake/getCouponTakeList`
- **AND** 「待使用」传 `status=1`，「已领用」传 `status=2`，「已过期」传 `status=3`
- **AND** 「全部」**不传** `status`
- **AND** 分页传 `pageNum` / `pageSize`（字符串）；**禁止** mock / 假 id 入参

#### Scenario: 待使用数量

- **WHEN** 展示优惠券状态 Tab 栏或需要角标
- **THEN** 「待使用」数量取接口 `status=1` 的总条数（如响应 `total`）
- **AND** 不得用本地 Mock 计数

#### Scenario: 票券主信息

- **WHEN** 渲染优惠券卡片
- **THEN** 展示名称（`name`）、有效期至（`endTime`）、状态角标
- **AND** 响应 `status`：`1`→「待使用」且可「去使用」；`2`→「已领用」；`3`→「已过期」
- **AND** `type`：`1` 满减 / `2` 减价 / `3` 折扣
- **AND** 左侧力度：满减用 `amount`；减价优先 `couponAmount` 否则 `amount`；折扣用 `discountRatio`
- **AND** 门槛文案取 `conditionPrice`（空或 ≤0 为「无门槛」）

#### Scenario: 使用规则展开（按返回字段）

- **WHEN** 用户展开使用规则
- **THEN** 仅渲染接口返回的非空字段，标题遵循：
  - `categoryServiceName`：`rule=1`→「适用业务」；`rule=0`→「不适用业务」
  - `packageNames`：`rule=1`→「适用套餐」；`rule=0`→「不适用套餐」（顿号分隔多名）
  - `hospitalNames`：标题固定「适用机构」
  - `commodityNames`：标题固定「不参与折扣的商品」
  - `description`：直接展示使用规则说明（无额外标题亦可）
- **AND** `rule` **不得**改变机构/排除商品的标题文案
- **AND** 若上述字段均为空，**不展示**「使用规则」折叠入口

#### Scenario: 去使用

- **WHEN** 点击去使用
- **THEN** 进入服务列表，不预筛选、不自动选券

#### Scenario: 空态与失败

- **WHEN** 当前状态 Tab 无券或请求失败
- **THEN** 展示空态（如「暂无相关优惠券」），**不得**用 Mock 顶替

### Requirement: 我的页卡券角标

「我的」常用功能「我的卡券」SHALL 展示可用资产数量角标。

#### Scenario: 角标计算

- **WHEN** 渲染我的页
- **THEN** 角标 = 待使用权益卡数 + 待使用优惠券数（优惠券数为接口 `status=1` 总量或其缓存）
- **AND** 为 0 时不展示；超过 99 展示「99+」

## ADDED Requirements

### Requirement: CouponTaskListBO 字段映射

系统 SHALL 按 Apifox `CouponTaskListBO` 语义将列表项映射到卡包 UI（及订单选券共用 DTO），不得用 Mock 字段顶替。

#### Scenario: 核心标识与状态

- **WHEN** 解码单条领用记录
- **THEN** 使用 `id` 作为领用主键；`couponId` 为券模板 id
- **AND** `status` 取值 1/2/3 分别对应已领取（UI 待使用）/ 已使用（UI 已领用）/ 已过期

#### Scenario: 力度与门槛字段

- **WHEN** `type=1`（满减）
- **THEN** 力度取 `amount`，门槛取 `conditionPrice`
- **WHEN** `type=2`（减价）
- **THEN** 力度取 `couponAmount`，若为空则取 `amount`
- **WHEN** `type=3`（折扣）
- **THEN** 力度取 `discountRatio` 并格式化为「x折」

#### Scenario: 空值不展示

- **WHEN** `categoryServiceName` / `packageNames` / `hospitalNames` / `commodityNames` / `description` 为 null 或空串
- **THEN** 对应规则行不渲染

## REMOVED Requirements

### Requirement: 卡包数据与 Mock 边界

**Reason**: 卡包优惠券已接入真实 `getCouponTakeList`，继续保留 Mock 边界与禁止使用该接口作为数据源的约束已过时。

**Migration**: 删除 `VoucherService` 优惠券 Mock；列表与角标一律走 `CouponService`；权益卡仍可暂用 Mock，直至权益卡接口就绪。
