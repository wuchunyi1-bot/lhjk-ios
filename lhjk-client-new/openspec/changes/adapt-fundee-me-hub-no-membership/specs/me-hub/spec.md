## ADDED Requirements

### Requirement: 「我的」Hub 页面结构

「我的」Tab 首页（`/me`）SHALL 按下列自上而下结构渲染，且 MUST NOT 展示「健康大会员」会员卡、四格统计条、服务履约卡。

对齐：`MeView.vue`（布局）+ 产品决议（去掉会员卡）。`me-hub.page.yaml` 中 membership / stats / fulfillment 区域对本 Hub **不生效**。

```
Hero → 常用功能 → 健康管理 → 退出登录
```

#### Scenario: 首屏结构

- **WHEN** 用户进入「我的」Tab
- **THEN** 依次可见：Hero、常用功能、健康管理、退出登录
- **AND** **不得**出现「健康大会员」标题或会员开通/续费/权益 CTA
- **AND** **不得**出现积分/家庭/保单/等级四格
- **AND** **不得**出现「服务履约」区块
- **AND** **不得**出现「设置与支持」列表分组（设置仅 Hero 齿轮）

---

### Requirement: Hero 区

Hero SHALL 使用暖色渐变背景，展示身份与快捷入口。

#### Scenario: 头像与姓名

- **WHEN** 渲染 Hero
- **THEN** 左侧 64×64 圆形头像（有 `imageUrl` 用 Kingfisher，否则姓名首字兜底）
- **AND** 右侧展示用户姓名（来自 `UserManager.currentUser`）

#### Scenario: 设置齿轮

- **WHEN** 渲染 Hero
- **THEN** 右上角 32×32 半透明白底齿轮
- **AND** 点击 push `/me/settings`

#### Scenario: 快捷 pill

- **WHEN** 渲染 Hero
- **THEN** 「个人信息」→ `/me/profile`
- **AND** 「健康档案」→ `/me/health-profile`（品牌色填充 pill）

---

### Requirement: 常用功能宫格

SHALL 展示标题「常用功能」+ 4 列宫格，数据对齐 `me.json` → `commonActions`。

#### Scenario: 八项与跳转

- **WHEN** 渲染常用功能
- **THEN** 按序：

| label | iOS route |
|-------|-----------|
| 我的订单 | `/orders` |
| 我的预约 | `/me/appointments` |
| 我的卡券 | `/me/vouchers` |
| 购物车 | `/services/cart` |
| 智能设备 | `/me/devices` |
| 我的地址 | `/me/address` |
| 家庭成员 | `/me/family` |
| 我的保单 | `/me/policy` |

- **AND** 「我的卡券」在有待处理数量时展示角标（0 隐藏，>99 为 `99+`）
- **AND** 触控高度 ≥ 44pt

---

### Requirement: 健康管理功能组

SHALL 展示标题「健康管理」+ 功能行列表，对齐 `me.json` → `healthManagementActions`。

#### Scenario: 七项列表

- **WHEN** 渲染健康管理
- **THEN** 按序：

| label | detail（可 mock） | route |
|-------|-------------------|-------|
| 健康档案 | 完整度文案 | `/health/record` |
| 健康报告 | 周报 / 阶段小结 | `/me/health-report` |
| 体检报告单 | 上传数量文案 | `/me/medical-reports` |
| 监测方案 | 方案状态文案 | `/me/monitoring-plan` |
| 饮食方案 | 可按档案生成 | `/me/diet-plan` |
| 健康评估 | 评估版本文案 | `/me/health-assessment` |
| 健康测评 | 待完成文案 | `/me/health-evaluations` |

- **AND** 每行含彩色图标底、标题、detail、右箭头；行高触控 ≥ 44pt

---

### Requirement: 退出登录

Hub 底部 SHALL 提供「退出登录」，行为与设置页一致。

#### Scenario: 确认后清理

- **WHEN** 用户确认退出
- **THEN** logout API（可失败静默）→ `clearSession` → 清 IM / 服务 Hub 缓存 / 机构选择 → 断融云 → `UserManager.clear` → `Router.setRoot("/login")`

---

## REMOVED Requirements

### Requirement: Membership Card on Hub

**Reason**: 产品决议下线 Hub「健康大会员」；Vue/PRD 暂未改，以本 spec 为准。  
**Migration**: Hub 不再挂载会员卡；`/me/membership` 子页可保留但无 Hub 入口。

### Requirement: 设置与支持分组 on Hub

**Reason**: 现行 `MeView.vue` 无该 Section；设置入口仅为 Hero 齿轮。  
**Migration**: 删除 Hub 上设置/关于/版本列表行。
