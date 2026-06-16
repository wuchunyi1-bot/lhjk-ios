# Me Subpages — 会员中心 / 积分明细 / 家庭成员

## Purpose

实现「我的」模块中 3 个占位页面的完整 UI。参考 funde-client 对应 Vue 文件。

> **Reference**: funde-client `MembershipView.vue`, `PointsView.vue`, `FamilyView.vue` + `family.json`, `me.json`

---

## Architecture Decision: UITableView

**选择**: 三页统一用 `UITableView` (grouped/plain) + `tableHeaderView` 承载 Hero，Cell 复用承载列表项。

**理由** (与 HealthReportViewController 重构决策一致):

| 维度 | UIScrollView + StackView | UITableView |
|------|--------------------------|-------------|
| **内存** | 所有 item 一次性创建 | Cell 复用，仅可见 cell 存于内存 |
| **滚动** | 长列表首帧卡顿 | 60fps 平滑滚动 |
| **代码结构** | 手动管理 subview | DataSource/Delegate 分离，职责清晰 |

**Section 映射**:

| 页面 | tableHeaderView | Section 0 | Section 1 | Section 2 |
|------|----------------|-----------|-----------|-----------|
| 会员中心 | Hero 渐变卡 | 权益清单 (1 row, 内嵌 6 行 StackView) | 升级套餐 (2 rows) | — |
| 积分明细 | Hero 渐变卡 | 勋章 grid (1 row, 内嵌 3×2 grid) | 进行中 (N rows) | 最近明细 (N rows) |
| 家庭成员 | — | 成员卡片 (N rows) | — | — |

---

## 1. 会员中心 (`/me/membership`)

### TableView Structure
```
tableHeaderView: Hero 渐变卡片 (fdPrimary→#FFAA80)
Section 0: 权益清单 — 1 row (BenefitListCell, 内嵌 UIStackView 6 行)
Section 1: 升级套餐 — 2 rows (UpgradePlanCell, 复用)
```

### Cells
| Cell | Reuse ID | Section | 内容 |
|------|---------|---------|------|
| `BenefitListCell` | `BenefitListCell` | 0 | 6 行 benefit row（激活/未激活双态 + 分割线） |
| `UpgradePlanCell` | `UpgradePlanCell` | 1 | 德康/德元套餐卡片 |

### Section Header
- Section 0: "权益清单 · 共 6 项"
- Section 1: "升级解锁更多权益"

### Key Specs
- Hero: gradient fdPrimary→#FFAA80, white text, 半透明 tags, 装饰 blob 120pt
- Benefit: icon 40pt + title/desc + 已激活(green)/未开通(gray) tag
- Upgrade: bordered card, plan name colored, mono price ¥N, pill button, 德康高亮渐变 bg

---

## 2. 积分明细 (`/me/points`)

### TableView Structure
```
tableHeaderView: Hero 渐变卡片 + 积分数字 892
Section 0: 勋章 grid — 1 row (BadgeGridCell, 3×2 grid)
Section 1: 进行中 — 2 rows (ProgressBadgeCell, 复用)
Section 2: 最近明细 — 4 rows (PointRecordCell, 复用)
```

### Cells
| Cell | Reuse ID | Section |
|------|---------|---------|
| `BadgeGridCell` | `BadgeGridCell` | 0 |
| `ProgressBadgeCell` | `ProgressBadgeCell` | 1 |
| `PointRecordCell` | `PointRecordCell` | 2 |

### Section Header
- Section 0: "我的勋章 · 3 枚已获得"
- Section 1: "进行中"
- Section 2: "最近明细"

### Key Specs
- Badge grid: 3 columns, 52pt icon + name
- Progress: 6pt rounded bar + colored fill + "N/M"
- Record: title + date + value (fdPrimary for +N, fdSubtext for -N)

---

## 3. 家庭成员 (`/me/family`)

### TableView Structure
```
Section 0: 成员卡片 — 4 rows (FamilyMemberCell, 复用)
```

### Cells
| Cell | Reuse ID | Section |
|------|---------|---------|
| `FamilyMemberCell` | `FamilyMemberCell` | 0 |

### Key Specs
- Card: fdSurface + shadow, avatar 44×44 gradient 12pt, name + relation tag + phase tag
- Alert: yellow bg #FFFBEB + border #FDE68A + warning icon (conditional)
- Bottom 3-col grid: 2 metrics + checkin dots (done=fdPrimary, undone=#E5E7EB)
- Phase colors: 适应期=#8B8B8B, 见效期=fdPrimary, 巩固期=#1F9A6B, 习惯养成=#7B5E9F
- "添加" 按钮 in topbar rightBarButtonItem

---

## Cell 复用关键点

### prepareForReuse
- `BenefitListCell`: 清除 StackView 子视图
- `BadgeGridCell`: 清除 Grid 子视图
- `ProgressBadgeCell`: 重置 progress bar width
- `PointRecordCell`: 重置文本
- `FamilyMemberCell`: 重置所有 label + 隐藏 alert bar + 清除 checkin dots

### 高度计算
- Hero → `tableHeaderView` + `systemLayoutSizeFitting`
- Grid cells → `UITableView.automaticDimension`
- List cells → `UITableView.automaticDimension`
- 固定高度 rows → 返回具体值

---

## Acceptance Checklist

### 会员中心
- [ ] Hero 渐变卡片 (tableHeaderView)
- [ ] 权益列表 6 行，激活/未激活双态 (Section 0)
- [ ] 升级套餐 2 行 (Section 1)
- [ ] Section headers 正确显示

### 积分明细
- [ ] Hero 渐变 + 积分数字 (tableHeaderView)
- [ ] 勋章 3 列 grid (Section 0)
- [ ] 进行中进度条 (Section 1)
- [ ] 最近明细 (Section 2)

### 家庭成员
- [ ] 4 张成员卡片 (Section 0, Cell 复用)
- [ ] 姓名 + 关系 tag + 阶段 tag + alert bar
- [ ] 3 列底部 grid
- [ ] 阶段颜色 4 色映射
