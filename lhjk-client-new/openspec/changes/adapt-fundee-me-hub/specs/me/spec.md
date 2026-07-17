## ADDED Requirements

### Requirement: 常用功能宫格

「我的」Hub SHALL 在会员卡下方展示「常用功能」区块：标题 + 4 列宫格，数据对齐 `me.json` → `commonActions`（8 项）。

#### Scenario: 宫格内容与跳转

- **WHEN** 渲染常用功能
- **THEN** 按序展示并跳转：
  | label | route（iOS） |
  |-------|-------------|
  | 我的订单 | `/orders` |
  | 我的预约 | `/me/appointments` |
  | 我的卡券 | `/me/vouchers` |
  | 购物车 | `/services/cart` |
  | 智能设备 | `/me/devices` |
  | 我的地址 | `/me/address` |
  | 家庭成员 | `/me/family` |
  | 我的保单 | `/me/policy` |
- **AND** 每项含彩色圆角图标底 + 文案，触控高度 ≥ 44pt

### Requirement: 设置与支持分组

Hub SHALL 展示「设置与支持」功能组（对齐 `me.functionGroups[0]`）。

#### Scenario: 三行入口

- **WHEN** 渲染该分组
- **THEN** 行顺序为：设置 → `/me/settings`；关于富德健康 → `/me/settings/about`；当前版本（只读，展示版本号，无跳转）

### Requirement: Hub 退出登录

Hub 底部 SHALL 提供「退出登录」按钮，行为与设置页退出一致。

#### Scenario: 确认后清理并回登录

- **WHEN** 用户确认退出
- **THEN** 调用 logout API（可失败静默）→ `clearSession` → `IMService.clear` → `ServiceHubCacheService.clear` → `InstitutionSelectionStore.clear` → 断融云 → `UserManager.clear` → `Router.setRoot("/login")`

## MODIFIED Requirements

### Requirement: Hero Section (tableHeaderView)

顶部 tableHeaderView SHALL 包含用户信息区与会员卡；**不再**包含四格统计条。右上角 SHALL 展示设置入口。

#### Scenario: 设置按钮（右上角）

- **WHEN** 页面渲染 Hero 区
- **THEN** 右上角展示设置齿轮按钮：32×32pt 圆形、半透明白底、SF Symbol `gearshape`
- **AND** 点击 push `/me/settings`

#### Scenario: 头像与用户名

- **WHEN** 页面渲染 Hero 区
- **THEN** 左侧 64×64 圆形头像（有 `imageUrl` 用 Kingfisher，否则首字兜底）；右侧用户名

#### Scenario: 快捷操作按钮

- **WHEN** 页面渲染 Hero 区
- **THEN** 展示两个 pill：
  - 「个人信息」→ `/me/profile`
  - 「健康档案」→ `/me/health-profile`

#### Scenario: 渐变背景

- **WHEN** 页面渲染
- **THEN** Hero 使用暖色渐变（`#FFF7F1` → `#FFE9DC`）

### Requirement: Membership Card (in tableHeaderView)

会员卡 SHALL 按会员状态展示（对齐 Vue `membership-card--{status}`），默认 mock 为 `not_opened`。

#### Scenario: 未开通 not_opened

- **WHEN** status = `not_opened`
- **THEN** 品牌标题「健康大会员」；利益文案「仅需 ¥19.9，体验 5 天会员服务」；主按钮「立即开通」
- **AND** 主按钮 / 卡片点击进入会员开通或会员页（`/me/membership` 或 `/me/membership/open`）

#### Scenario: 已开通 active / 即将到期 expiring

- **WHEN** status = `active` 或 `expiring`
- **THEN** 展示计划名称、已开通权益数、有效期（expiring 含剩余天数）
- **AND** 次级按钮「升级会员/续费会员」「我的权益」；卡片点击进 `/me/membership`

#### Scenario: 已过期 expired

- **WHEN** status = `expired`
- **THEN** 展示「会员已过期」与到期日；主按钮「立即续费」

#### Scenario: 不做演示重置

- **WHEN** 渲染会员卡
- **THEN** MUST NOT 展示 Vue 原型「注销演示」按钮

### Requirement: Health Management Function Group

健康管理分组 SHALL 展示 6 项（预约与卡券已迁入常用功能）。

#### Scenario: 六项列表

- **WHEN** 渲染健康管理
- **THEN** 顺序为：健康档案 `/health/record`、健康报告 `/me/health-report`、体检报告单 `/me/medical-reports`、监测方案 `/me/monitoring-plan`、饮食方案 `/me/diet-plan`、健康评估 `/me/health-evaluations`

## REMOVED Requirements

### Requirement: Stats Strip (in tableHeaderView)

**Reason**: Vue `showLegacyStats = false`，Hub 不再展示积分/家庭/保单/等级四格。  
**Migration**: 入口改由「常用功能」与会员卡覆盖；积分等仍可通过常用功能或子页进入。

### Requirement: Service Fulfillment Section

**Reason**: 现行 `MeView.vue` 不再渲染履约/在途服务列表；订单入口改到常用功能「我的订单」。  
**Migration**: 删除 Hub 上「我的订单」履约 Section；订单列表仍由 `/orders` 提供。
