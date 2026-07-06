# 我的卡券 (Vouchers)

## Purpose

展示用户持有的全部三好卡状态（未使用 / 已激活 / 已过期），支持按 Tab 筛选，未使用卡可直接跳转套餐选择页完成激活。对应 Vue 端 `MyVouchersView.vue` 实现。

## Route

| 页面 | 路径 | 参数 |
|------|------|------|
| 我的卡券列表 | `/me/vouchers` | — |
| 套餐选择（激活） | `/activate/choose` | `card: String` (卡号) |

## Data Model

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

- 当前 Tab 无卡券时显示：📭 图标 + "暂无相关卡券"文案

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
- **THEN** 展示 📭 图标和"暂无相关卡券"文案

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
