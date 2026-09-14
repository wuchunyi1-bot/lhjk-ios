# 我的卡券 (Vouchers)

## Purpose

统一管理用户 **权益卡** 与 **优惠券**（原型 `me-vouchers`）。

### 权益卡状态 Tab（对齐 funde 正式态）

权益卡模块 **恰好 5 个** 状态 Tab，顺序与文案：

**全部 → 待使用 → 已兑换 → 已过期 → 转赠记录**

| 约束 | 说明 |
|------|------|
| 对齐原型正式态 | funde `MyVouchersView` 生产 Tab 即上述 5 个；「待使用」可带可用数量 |
| **不得**展示 | 「模拟领取 / 模拟测试」（原型验收入口，非正式状态、非用户资产） |
| **不得**展示 | 「待绑定」「待领取」独立 Tab（等待领取合并进「全部」与「转赠记录」） |
| 默认 | 进入权益卡模块选中「全部」 |

代码：`BenefitListViewController.tabs` / `BenefitStatusFilter`（仅上述 5 个）。后端卡状态 1/2（待绑定 / 待领取）仍可映射到卡片样式，但不单独成 Tab。

### 权益卡 C 端（已接真接口，无 Mock）

| UI | API | 说明 |
|----|-----|------|
| 全部 | `GET /v1/benefitsTake/getCustomerPage` | 无 status；2→等待领取卡样式，3/4/5→卡 |
| 待使用/已兑换/已过期 | 同上 `?status=3/4/5` | |
| 转赠记录 | `GET /v1/benefitsTake/getGiftRecordPage` | PENDING_RECEIVE / TRANSFERRED |
| 角标 | `GET /v1/benefitsTake/getCustomerStatusCount` | value=3 待使用 |
| 绑定 | `preCheckByKey` → `bindByKey` | |
| 赠送 | `POST /v1/benefitsTake/giftBenefit` | 必传 `operationNo`；成功后拉起微信小程序卡片分享，同时返回权益卡列表并定位「转赠记录」 |

代码：`VoucherService` + `BenefitGiftShareBuilder` + `PL/My/Vouchers/Benefit/*`。优惠券见 `CouponService`。  
本期不做：员工转交/发放、App 内领取落地 `open*`/`receive*`（领取在小程序完成）。

### 权益卡使用规则

规则全文：`/auth/agreement/benefit-card`（设置「协议与说明」、绑定页勾选链接同源，正文对齐 Vue `agreementMap['benefit-card']`）。

- **绑定页**（`/activate/bind` / `BenefitBindViewController`）：须勾选「我已阅读并同意《权益卡使用规则》」；未勾选点立即绑定不提交，抖动勾选区并 Toast「请先阅读并同意《权益卡使用规则》」。
- **领取落地**：好友转赠 / 代理人发放的领取页本期在微信小程序完成（`WeChatConfig.benefitClaimPathTemplate`）。日后若做 App 内领取页，可领取态须展示同一勾选项（默认未勾选），未勾选拦截领取（抖动 + 同上 Toast）；赠送人本人查看、已领取、已退回、已失效不展示勾选。

### 转赠微信分享

赠送页点击「立即赠送」后的时序以 **`giftBenefit` 是否成功** 为准，**不以微信分享结果为准**。

1. 未安装微信 → Toast「请先安装微信后再赠送好友」，不调 `giftBenefit`，留在赠送页
2. `giftBenefit` 失败 → 留在赠送页，Toast 错误信息
3. `giftBenefit` 成功且返回非空 `operationNo` → **同一时刻**完成：
   - 拉起 `WeChatSDKManager.shareMiniProgram`（会话，path 带 `operationNo`）
   - pop 关闭赠送页，回到我的卡券权益卡模块（上一页）
   - 权益卡状态 Tab 选中「转赠记录」
   - 刷新「转赠记录」列表，以及会因转赠变化的持卡列表（「全部」「待使用」）与待使用数量角标
4. `giftBenefit` 成功但 `operationNo` 为空 → **不**拉起微信分享；仍 pop、定位「转赠记录」并刷新列表；Toast 提示可在转赠记录查看
5. 微信分享成功 / 取消 / 失败：**不撤销**已创建的转赠批次；取消**不**重复调用 `giftBenefit`；**不**因分享结果再次 pop 或切 Tab（页面已在「转赠记录」）
6. path / 小程序原始 id / 兜底 URL：见 `WeChatConfig`

代码：`BenefitTransferViewController`（赠送页）→ `BenefitListViewController.selectTransferRecordsAfterGift()`（切 Tab + 刷新）→ `BenefitGiftShareBuilder` + `WeChatSDKManager.shareMiniProgram`。

### 确认订单权益卡

确认订单页多选抵扣见变更 `openspec/changes/order-confirm-benefits-card/`：列表复用 `getCustomerPage?status=3`；费用明细优惠券取 `couponAmount` / 结算 `amount`，权益卡取 `benefitsAmount`（未返回时本地试算，不抵运费）；支付核销后续接入。

### 激活兑换

首页「激活兑换」与卡包绑定/兑换见 `openspec/specs/activate/`（`/activate`、`/activate/bind`、`/activate/redeem`）。

## Route

| 页面 | 路径 | 参数 |
|------|------|------|
| 我的卡券列表 | `/me/vouchers` | — |
| 套餐选择（激活） | `/activate/choose` | `card: String` (卡号) |

## Data Model（历史三好卡草案，保留备查）

### MVoucher

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | String | 卡券唯一标识 |
| `cardNo` | String | 卡号，如 "SGHK-2026-0001" |
| `packageName` | String | 套餐名称 |
| `status` | VoucherStatus | 状态：unused / activated / expired |
| `activationDeadline` | String? | 激活截止日期（未使用时显示） |
| `activatedAt` | String? | 激活时间（已激活/已过期时显示） |
| `validUntil` | String? | 有效期至（已激活/已过期时显示） |
| `advisorName` | String? | 专属健管师（已激活时显示） |
| `daysLeft` | Int? | 剩余天数（已激活时显示） |

### VoucherStatus

| 枚举值 | 说明 | 标签颜色 | 背景色 |
|--------|------|----------|--------|
| `unused` | 未使用 | #B47300 | #FFF3DC |
| `activated` | 已激活 | #1F9A6B | #E6F7EF |
| `expired` | 已过期 | #999999 | #F0F0F0 |

## UI Structure

### 页面布局

```
┌─────────────────────────────────┐
│ Navigation Bar: "我的卡券"        │
├─────────────────────────────────┤
│ Tab Bar (SegmentedControl):     │
│ [全部] [未使用] [已激活] [已过期]    │
├─────────────────────────────────┤
│ ScrollView                      │
│ ┌─────────────────────────────┐ │
│ │ VoucherCard × N             │ │
│ │  ┌───────────────────────┐  │ │
│ │  │ 套餐名          [状态] │  │ │
│ │  │ 🔖 卡号      [激活]btn │  │ │
│ │  │ ─────────────────────  │  │ │
│ │  │ 详情区（按状态变化）     │  │ │
│ │  └───────────────────────┘  │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ ➕ 获取更多三好卡健康服务  › │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### Tab 筛选逻辑

- **全部**: 显示所有卡券
- **未使用**: `status == .unused`
- **已激活**: `status == .activated`
- **已过期**: `status == .expired`

Tab 使用 `UISegmentedControl` 实现，置于导航栏下方固定位置（sticky）。

### 卡片状态差异

#### 未使用 (unused)
- 卡号行右侧显示"激活"按钮（pill 样式，主色调背景白字）
- 详情区显示：激活截止日期（橙色警告色 #B47300）
- 点击激活按钮跳转 `/activate/choose?card=<卡号>`

#### 已激活 (activated)
- 卡片背景渐变：#FDFFF9 → #EEF9F3，边框 rgba(31,154,107,0.2)
- 详情区显示：激活时间、有效期至、专属健管师、剩余天数（绿色 #1F9A6B 粗体）
- 无操作按钮

#### 已过期 (expired)
- 整卡透明度降低至 0.72
- 详情区显示：激活时间、到期时间
- 无操作按钮

### 底部"获取更多"

- 样式：白色卡片，左侧 ➕ 图标，右侧 › 箭头
- 点击跳转 `/services`

### 空状态

- 当前 Tab 无卡券时展示默认空态插图 `noData_default`（`FDEmptyStateView`）+ 该 Tab 文案（如「暂无相关权益卡」）
- 权威约定见 `openspec/specs/design-tokens/`「默认无数据空态插图」

## Mock Data

当前使用本地 Mock 数据（5 条），覆盖全状态：

| 卡号 | 套餐 | 状态 |
|------|------|------|
| SGHK-2026-0001 | 三好健康服务卡 | unused |
| SGHK-2026-0512 | 德康·标准版 | unused |
| SGHK-2025-1108 | 德医·就医协助（标准版） | activated |
| SGHK-2024-0318 | 德康·入门版 | expired |
| SGHK-2023-0921 | 体验套餐 | expired |

## Requirements

### Requirement: 卡券列表展示
系统 SHALL 展示用户持有的全部三好卡券，支持按状态 Tab 筛选。

#### Scenario: 进入卡券页面
- **WHEN** 用户从"我的"页面点击"我的卡券"入口
- **THEN** 路由 `/me/vouchers` 打开卡券列表页，隐藏底部 Tab Bar，默认显示"全部"Tab

#### Scenario: Tab 筛选
- **WHEN** 用户切换 Tab（全部/未使用/已激活/已过期）
- **THEN** 列表仅显示对应状态的卡券，Tab 高亮当前选中项

---

### Requirement: 未使用卡激活
系统 SHALL 为未使用状态的卡券提供激活入口。

#### Scenario: 点击激活按钮
- **WHEN** 用户点击未使用卡券的"激活"按钮
- **THEN** 跳转至 `/activate/choose?card=<卡号>`，携带该卡卡号

---

### Requirement: 卡片状态展示
系统 SHALL 根据卡券状态展示不同的详情信息和视觉样式。

#### Scenario: 已激活卡详情
- **WHEN** 用户查看已激活卡券
- **THEN** 显示激活时间、有效期至、专属健管师、剩余天数（绿色），卡片背景为绿色渐变

#### Scenario: 已过期卡样式
- **WHEN** 用户查看已过期卡券
- **THEN** 整卡透明度降低（0.72），显示激活时间和到期时间

---

### Requirement: 获取更多入口
系统 SHALL 在卡券列表底部提供跳转服务页的入口。

#### Scenario: 点击获取更多
- **WHEN** 用户点击底部"获取更多三好卡健康服务"
- **THEN** 跳转至 `/services`

---

### Requirement: 空状态
系统 SHALL 在无卡券数据时展示空状态。

#### Scenario: 当前 Tab 无卡券
- **WHEN** 当前选中 Tab 下无任何卡券
- **THEN** 展示 `noData_default` 与该 Tab 空态文案（权益卡「暂无相关权益卡」等；优惠券可带引导副文案）

---

### Requirement: 权益卡状态 Tab

权益卡模块 SHALL 仅展示 **恰好 5 个** 状态 Tab，顺序为：全部、待使用、已兑换、已过期、转赠记录。SHALL NOT 展示原型验收用的「模拟领取 / 模拟测试」，也 SHALL NOT 展示「待绑定」「待领取」独立 Tab。

#### Scenario: 正式状态 Tab

- **WHEN** 用户进入我的卡券并停留在权益卡模块
- **THEN** 状态 Tab 恰好为：全部、待使用、已兑换、已过期、转赠记录
- **AND** 默认选中「全部」
- **AND** 「待使用」可展示可用数量

#### Scenario: 禁止演示与多余 Tab

- **WHEN** 渲染权益卡状态 Tab 栏
- **THEN** 不出现「模拟领取」「模拟测试」「待绑定」「待领取」
- **AND** 等待领取记录仅出现在「全部」（等待领取）与「转赠记录」列表中，不单独成 Tab

---

### Requirement: 立即赠送成功后的导航与刷新

系统 SHALL 在 `POST /v1/benefitsTake/giftBenefit` 成功后立即拉起微信分享，并返回权益卡列表的「转赠记录」Tab；卡包刷新不依赖微信分享结果。

#### Scenario: 立即赠送成功

- **WHEN** 用户在赠送权益卡页点击「立即赠送」，且已安装微信，且 `giftBenefit` 成功并返回非空 `operationNo`
- **THEN** 拉起微信小程序卡片分享（会话）
- **AND** 关闭赠送页，返回我的卡券权益卡模块
- **AND** 状态 Tab 选中「转赠记录」并刷新该列表
- **AND** 刷新「全部」「待使用」列表及待使用数量，使已转赠卡不再出现在持卡 Tab

#### Scenario: 分享取消或失败

- **WHEN** 微信分享取消或发送失败
- **THEN** 转赠批次保留，不重复调用 `giftBenefit`
- **AND** 用户仍停留在「转赠记录」Tab（不因分享结果再次导航）

#### Scenario: 未返回分享凭证

- **WHEN** `giftBenefit` 成功但 `operationNo` 为空
- **THEN** 不拉起微信分享
- **AND** 仍关闭赠送页、定位「转赠记录」并刷新列表
- **AND** Toast 提示可在转赠记录查看

#### Scenario: 赠送接口失败

- **WHEN** `giftBenefit` 失败
- **THEN** 留在赠送页，Toast 错误，不切 Tab、不拉起分享

## File Structure

```
BLL/My/
├── VoucherModels.swift        # MVoucher 模型 + VoucherStatus 枚举
└── VoucherService.swift       # 卡券服务（当前 Mock，后续对接 API）

PL/My/Vouchers/
├── VoucherListViewController.swift   # 卡券列表页（Tab + TableView）
└── Cells/
    └── VoucherCell.swift            # 卡券卡片 Cell

openspec/specs/vouchers/
└── spec.md                          # 本文档
```
