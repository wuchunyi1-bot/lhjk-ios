## ADDED Requirements

### Requirement: 「我的」Hub 页面结构（funde-client 原型）

「我的」Tab 首页（`/me`）SHALL 按下列自上而下结构渲染，对齐 `MeView.vue`：

```
Hero（渐变 + 身份 + 会员卡）→ 服务履约 → 健康管理
```

MUST NOT 展示：常用功能宫格、Hub 底部退出登录、「个人信息」独立 pill。

#### Scenario: 首屏结构

- **WHEN** 用户进入「我的」Tab
- **THEN** 依次可见：Hero（含会员卡）、服务履约、健康管理
- **AND** **不得**出现 8 项常用功能宫格
- **AND** **不得**在 Hub 底部展示退出登录

---

### Requirement: Hero 区

Hero SHALL 使用暖色渐变背景（`#FFF7F1` → `#FFE9DC`）。

#### Scenario: 头像与姓名

- **WHEN** 渲染 Hero
- **THEN** 左侧 64×64 圆形头像（有 `imageUrl` 用 Kingfisher，否则姓名首字）
- **AND** 点击头像或姓名 push `/me/profile`

#### Scenario: 设置与健康档案

- **WHEN** 渲染 Hero
- **THEN** 右上角齿轮 → `/me/settings`
- **AND** 「健康档案」品牌色 pill → `/me/health-profile`
- **AND** **不得**展示「个人信息」pill

---

### Requirement: 健康大会员资产卡

Hero 内 SHALL 展示暖橙浅色会员卡，含标题与四格资产。

#### Scenario: 标题与兑换

- **WHEN** 渲染会员卡
- **THEN** 左侧「健康大会员」→ `/me/member-level`
- **AND** 右侧「会员兑换 ›」→ `/me/redemptions`

#### Scenario: 四格资产

| label | route | 说明 |
|-------|-------|------|
| 会员等级 | `/me/member-level` | accent 样式，默认 V1 |
| 健康积分 | `/me/points` | 默认 mock 892，待会员 API |
| 富德币 | `/me/member-level` | 默认 mock 200 |
| 权益卡券 | `/me/vouchers` | 走 `VoucherService` 实时计数 |

---

### Requirement: 服务履约

SHALL 展示「服务履约」标题 + 右侧「全部订单 ›」，卡片内四格统计。

#### Scenario: 四格与跳转

| label | tab query | accent |
|-------|-----------|--------|
| 待支付 | `pending_payment` | 是 |
| 待收货 | `pending_receipt` | 否 |
| 使用中 | `in_progress` | 否 |
| 已完成 | `completed` | 否 |

- **WHEN** 点击某一格
- **THEN** push `/orders` 并带 `tab` 参数
- **WHEN** 点击「全部订单 ›」
- **THEN** push `/orders`

数量待订单统计 API；未接入前展示 `0`，MUST NOT 用假数字填充。

---

### Requirement: 健康管理功能组

SHALL 展示 6 项功能行，对齐 `me.json` → `healthManagementActions`（**不含**健康档案）。

| label | route |
|-------|-------|
| 健康报告 | `/me/health-report` |
| 体检报告单 | `/me/medical-reports` |
| 监测方案 | `/me/monitoring-plan` |
| 饮食方案 | `/me/diet-plan` |
| 健康评估 | `/me/health-assessment` |
| 健康测评 | `/me/health-evaluations` |

未接 API 时 detail 副文案留空，MUST NOT 用 mock 文案顶替。

---

## REMOVED Requirements

### Requirement: 常用功能宫格 on Hub

**Reason**: 原型移除；地址/设备迁入设置页。  
**Migration**: 订单/卡券等入口通过会员卡、履约、设置页访问。

### Requirement: Hub 退出登录

**Reason**: 原型将登出移至设置页。  
**Migration**: 仅在 `/me/settings` 底部提供。

### Requirement: 「我的」Hub 无会员卡（adapt-fundee-me-hub-no-membership）

**Reason**: 原型恢复会员卡资产区。  
**Migration**: 以本 spec 为准。
