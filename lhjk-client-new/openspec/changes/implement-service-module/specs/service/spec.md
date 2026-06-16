# Service Module / 服务模块

## Purpose

定义「服务」Tab 模块全部页面的 UI 布局与交互行为。参考 funde-client 服务模块 6 个 Vue 视图 + `services.json` mock 数据。

> **Reference**: funde-client `ServicesView.vue`, `ServiceListView.vue`, `ServiceDetailView.vue`, `HealthMallView.vue`, `MallProductDetailView.vue`, `HealthPackageDetailView.vue` + `services.json`
> **Priority**: Phase 1 = Hub 页, Phase 2 = 子页面 (Deferred)

---

## Architecture: TableView First

**原则**: 能用 TableView 的尽量用 TableView。每个 section 1 row 承载一个自定义 Cell（内嵌 StackView/CollectionView），列表项用独立 Cell 复用。

| 页面 | TableView Style | tableHeaderView | Section 映射 |
|------|----------------|-----------------|-------------|
| **ServicesHub** | plain | 自定义 Topbar | S0: FeaturedCardsCell (x2) · S1: MedicalAssistCell · S2: MatrixGridCell (3×3) · S3: MallGridCell (2×N) |
| **ServiceList** | plain | — | 无（左侧 UITableView 做分类导航 + 右侧 UITableView 做套餐列表） |
| **ServiceDetail** | grouped | 轮播 Banner | S0: 标题+价格 · S1: 权益清单 · S2: 适用人群 · S3: 详情+特性 · S4: 用户评价 · S5: 服务承诺 |
| **HealthMall** | — | — | UICollectionView 2 列 grid（不用 TableView） |

---

## 1. Services Hub (`/services`) — Phase 1 优先

### Layout
```
┌──────────────────────────────────────────┐
│  Custom Topbar: "健康服务"               │
│  "德系健康管理 · 9 大产品线"              │
├──────────────────────────────────────────┤
│  Section 0: Featured Service Cards       │
│  ┌ 德好·慢病逆转  [进行中]      ┐        │
│  │ 三好共管 · 12周专属方案       │        │
│  │ [12周] [咨询] [用药指导]      │        │
│  │ ¥2,980/年        [查看进度]   │        │
│  ├──────────────────────────────┤        │
│  │ 德尊·长寿医学  [为您推荐]     │        │
│  │ ...                          │        │
│  └──────────────────────────────┘        │
├──────────────────────────────────────────┤
│  Section 1: Medical Assist Card          │
│  🏥 就医协助服务              [申请]     │
│  三甲挂号 · 陪诊 · 绿通转诊              │
├──────────────────────────────────────────┤
│  Section 2: 德系产品矩阵 (3×3 grid)      │
│  [德康] [德好] [德护]                    │
│  [德元] [德愈] [德医]                    │
│  [德甄] [德际] [德尊]                    │
├──────────────────────────────────────────┤
│  Section 3: 富德优选 (2×N grid, 6 items) │
│  [商品1] [商品2]                          │
│  [商品3] [商品4]                          │
│  [商品5] [商品6]                          │
└──────────────────────────────────────────┘
```

### TableView Sections & Cells

| Section | Cell | Reuse ID | Rows | 说明 |
|---------|------|----------|------|------|
| 0 | `FeaturedCardCell` | `FeaturedCardCell` | 2 | 推荐套餐卡片，高亮卡有渐变 bg + 装饰 blob |
| 1 | `MedicalAssistCell` | `MedicalAssistCell` | 1 | 就医协助引导卡，icon + 描述 + tags + 申请按钮 |
| 2 | `MatrixGridCell` | `MatrixGridCell` | 1 | 9 格产品矩阵，内嵌 3×3 grid |
| 3 | `MallGridCell` | `MallGridCell` | 1 | 富德优选商品，内嵌 2×N grid，最多 6 项 |

### Section Headers
- Section 2: "德系产品矩阵" + "了解品牌故事 ›"
- Section 3: "富德优选" + "查看全部 ›"

### Key Specs
- Featured card: 48pt code 方块 + name + status badge + benefits tags + mono price + footer button
- Highlight card: warm gradient bg `#FFF7F1→#FFE9DC` + decorative blob 100pt
- Matrix tile: 44pt icon (colored accent bg) + name + desc + tier, 3 columns
- Mall card: 90pt placeholder image area + name + desc + mono price + buy button

### Empty / Loading States
- Matrix items without packages → show "套餐即将开放" placeholder
- Mall empty → hide section

---

## Route Parameter Fix (Critical)

**问题**: Router 做精确路径匹配（`routes[context.path]`），`/services/list/德好` 找不到 `/services/list/:code` → fallback 到 `/home`。

**修复**: 路径参数改用 `params` 字典传递，Router 通过 `extraParameters` 合并到 factory 闭包。

```swift
// 注册（路径不带参数）
r.register(path: "/services/list") { params in
    let code = params["code"] as? String ?? ""
    return ServiceListViewController(productCode: code)
}

// 调用（参数通过 params 字典）
Router.shared.push("/services/list", params: ["code": "德好"])
```

**影响范围**: 所有带参数的 push 调用都需用此模式（矩阵 tile、商品卡片、订单详情等）。

---

## 2. Service List (`/services/list`) — Phase 1

### Layout (双列表架构)
```
┌──────────────────┬──────────────────────┐
│  左侧分类导航     │  右侧套餐列表          │
│  (78pt 宽)       │                      │
│                  │  ┌ 产品头 ──────────┐ │
│  ● 德康 健康基础  │  │ [德好] 向好逆转   │ │
│    德好 向好逆转  │  │ 慢病逆转·达标     │ │
│    德护 专病管护  │  │ [主推] tag       │ │
│    ...           │  └─────────────────┘ │
│                  │  ┌ 入门版 ──────────┐ │
│                  │  │ 慢病逆转基础方案   │ │
│                  │  │ [benefit1] [b2]  │ │
│                  │  │ ¥1,580/年 [详情] │ │
│                  │  └─────────────────┘ │
│                  │  ┌ 标准版 [热销] ───┐ │
│                  │  │ ...              │ │
└──────────────────┴──────────────────────┘
```

### Two TableView Architecture
- 左侧: `UITableView` (78pt 宽, fdBg2), category items with accent dot, active state highlighted
- 右侧: `UITableView` (flex 宽), package header + package cards
- 初始化: `ServiceListViewController(productCode: String)` — 参数通过 `Router.push` 的 `params` 传递
- 点击左 item → 更新 `activeCode` → 右侧 reload

### Cells
| Cell | Reuse ID | TableView |
|------|----------|-----------|
| `CategoryNavCell` | `CategoryNavCell` | 左侧 (9 rows) |
| `PackageHeaderCell` | `PackageHeaderCell` | 右侧 (1 row) |
| `PackageCardCell` | `PackageCardCell` | 右侧 (N rows) |

### Mock Data
- 9 个分类 items 来自 `services.json` matrix
- 套餐数据来自 `services.json` packages，按 `productCode` 过滤
- 空状态: 无套餐时显示 "套餐即将开放" placeholder

### Benefits Tag 流式布局

**方案**: `UICollectionView` + 自定义 `LeftAlignedFlowLayout`（无第三方库）。

**组件**:
| 组件 | 类型 | 说明 |
|------|------|------|
| `LeftAlignedFlowLayout` | UICollectionViewFlowLayout | 重写 `layoutAttributesForElements` 逐行左对齐 x 偏移 |
| `SelfSizingCollectionView` | UICollectionView | 重写 `intrinsicContentSize` 返回 `collectionViewContentSize`，`layoutSubviews` 自动 invalidate |
| `BenefitTagCell` | UICollectionViewCell | pill 样式，见下方详述 |

**BenefitTagCell 样式**:
- 背景色: `fdBg2`，圆角: 999（全圆 pill）
- 内边距: 上下 3pt，左右 8pt（通过 Auto Layout inset）
- 文字: 11pt `fdText2`，`textAlignment = .center`
- 自适应宽度: 重写 `preferredLayoutAttributesFitting(_:)`，用 `systemLayoutSizeFitting` 计算实际尺寸，确保文字不被截断
- 高度: 固定由 Auto Layout 约束撑开（label + inset = ~17pt）

**自适应逻辑**:
- `estimatedItemSize = CGSize(width: 40, height: 22)` — 给 layout 一个合理估计值
- `PackageCardCell` 实现 `UICollectionViewDelegateFlowLayout.sizeForItemAt`，调用 `BenefitTagCell.size(for:)` 用 `NSString.boundingRect` 精确计算每个 tag 文字宽度 + 左右 padding 8pt×2
- 固定高度 22pt（文字 11pt + 上下 padding 3pt×2）
- **不依赖 `automaticSize`** — 与自定义 `LeftAlignedFlowLayout` 直接兼容

**高度处理**:
- **弃用 `intrinsicContentSize` 方案**（自举死循环，见下方踩坑记录）
- **改用 `BenefitTagCell.totalHeight(for:maxWidth:)`** 提前模拟左对齐换行，算出最终高度
- `SelfSizingCollectionView` 保留 `fixedHeight` 属性 + 内部 height constraint，`configure` 时直接设定
- CV 从一开始就有正确高度 → layout 在完整 rect 内运行 → 所有 item 正常渲染

### ⚠️ 踩坑：intrinsicContentSize 自举循环

**现象**: 首次进入页面 BenefitTagCell 显示为一条横线。切换 Tab 后正常。

**尝试过程**:
1. `contentView.cornerRadius + masksToBounds` — 无效（后来发现是 UICollectionViewCell 限制）
2. `cell.layer.cornerRadius + masksToBounds` — 无效
3. `DispatchQueue.main.async { reloadData() }` 延迟加载 — 无效
4. `layoutSubviews` 中检测宽度变化后 `reloadData()` — 无效
5. **打 log 定位** — 发现根因

**日志关键发现**:
```
layoutSubviews: frame=(272, 0)           ← CV 高度为 0
layoutAttributesForElements: rect=(272, 2) ← layout 只查询前 2pt 可视区
attrs.count=2                           ← 5 个 item 只拿到 2 个
```
`UICollectionViewLayout.layoutAttributesForElements(in:)` 的 `rect` 参数被 clip 到 CV 的 `bounds`。CV 高度为 0 时只返回前 1-2 个 item，后续 item 永远不渲染。而 CV 高度靠 `intrinsicContentSize` 驱动，`intrinsicContentSize` 又靠 `contentSize`，`contentSize` 又来自 layout — 死循环。

**最终修复**: `BenefitTagCell.totalHeight(for:maxWidth:)` 用 `NSString.boundingRect` 获取每个 tag 宽度后模拟左对齐换行（x + itemWidth > maxWidth → 换行），提前算出最终高度，通过 `fixedHeight` 约束直接设置。

### 🔧 调试原则

参见全局 `project-architecture` spec § Debugging。

**理由**: 项目无第三方 tag 库；UICollectionView 原生支持自适应尺寸 + 自定义 layout 比 UIStackView 更灵活；展示全部 benefits（不截断为 3 个）。

---

### BenefitTagCell 样式

- 背景: `contentView.backgroundColor = .fdBg2`，**不带圆角**（`UICollectionViewCell` 上设 `cornerRadius` 与 UIKit 内部渲染机制冲突，无论设 cell.layer 还是 contentView.layer 均会导致不可见）
- 内边距: 上下 3pt, 左右 8pt

---

## 3. Service Detail (`/services/:id`) — Phase 2 Deferred

### Layout (TableView grouped)
```
tableHeaderView: Banner Swipe (3 slides, colored gradient)
Section 0: 标题+价格
Section 1: 服务权益 (check icon + text rows)
Section 2: 适用人群 (colored tag chips)
Section 3: 套餐详情 (text + 4 feature blocks)
Section 4: 用户评价 (score bar + review items)
Section 5: 服务承诺 (3 promise items)

底部 Fixed Bar: price + [咨询了解] [立即下单]
```

### Cells
| Cell | Reuse ID | Section | Rows |
|------|----------|---------|------|
| `DetailTitleCell` | `DetailTitleCell` | 0 | 1 |
| `BenefitRowCell` | `BenefitRowCell` | 1 | N |
| `AudienceTagsCell` | `AudienceTagsCell` | 2 | 1 |
| `FeatureBlockCell` | `FeatureBlockCell` | 3 | 4 |
| `ReviewItemCell` | `ReviewItemCell` | 4 | N |
| `PromiseBarCell` | `PromiseBarCell` | 5 | 1 |

---

## 4. Health Mall (`/mall`) — Phase 1

### Layout
```
┌──────────────────────────────────────────┐
│  导航栏: "富德优选" + back                 │
├──────────────────────────────────────────┤
│  SegmentedControl: [全部][营养补充][...]  │
├──────────────────────────────────────────┤
│  UICollectionView 2 列 grid              │
│  ┌──────────┐ ┌──────────┐              │
│  │ [商品图]  │ │ [商品图]  │              │
│  │ 商品名    │ │ 商品名    │              │
│  │ desc      │ │ desc      │              │
│  │ unit      │ │ unit      │              │
│  │ ¥128 [购] │ │ ¥98  [购] │              │
│  └──────────┘ └──────────┘              │
├──────────────────────────────────────────┤
│  🛡 正品保障 · 德好监制 · 7天无忧退换      │
└──────────────────────────────────────────┘
```

### Architecture
- `UISegmentedControl`: 4 Tab（全部/营养补充/功能食品/健康器械），fdPrimary 选中色
- `UICollectionViewCompositionalLayout`: `fractionalWidth(0.5)` × `estimated(260)`, 2 列等宽
- Cell: `MallProductCell`，register reuse identifier
- 底部固定 footer: `UICollectionReusableView` 或 tableFooterView 模式

### Why UICollectionView
- 2 列等宽网格天然适合，不需要 TableView 的 full-width cell
- `CompositionalLayout` 声明式 API，代码量少

### Cells
| Cell | Reuse ID | 内容 |
|------|----------|------|
| `MallProductCell` | `MallProductCell` | 商品封面 placeholder (90pt) + name + desc + unit + price(accent色) + 购买按钮 |

---

## Data Models (shared)

```swift
struct ServicePackage {
    let id: String; let productCode: String; let name: String
    let subtitle: String; let price: String; let priceUnit: String
    let tag: String; let status: String
    let benefits: [String]; let audience: [String]; let detail: String
}

struct ProductMatrixItem {
    let code: String; let name: String; let desc: String
    let tier: String; let accent: UIColor; let current: Bool
}

struct MallProduct {
    let id: String; let name: String; let desc: String
    let price: String; let unit: String; let tag: String
    let accent: UIColor; let category: String
}

struct FeaturedPackage {
    let id: String; let code: String; let tag: String; let desc: String
    let benefits: [String]; let price: String; let priceUnit: String
    let status: String; let highlight: Bool; let current: Bool
}

struct ServiceReview {
    let avatar: String; let avatarBg: UIColor; let avatarColor: UIColor
    let name: String; let stars: Int; let tags: [String]
    let content: String; let date: String
}
```

---

## Route Registration

| Route | Target | Phase | 参数 |
|-------|--------|-------|------|
| `/services` | `ServiceViewController` (Hub) | 1 | — |
| `/services/list` | `ServiceListViewController` | 1 | `code: String` |
| `/services/detail` | `ServiceDetailViewController` | 2 | `id: String` |
| `/mall` | `HealthMallViewController` | 2 | — |
| `/mall/detail` | Placeholder | 2 | `id: String` |

---

## Acceptance Checklist (Phase 1 — Hub)

- [ ] Custom Topbar "健康服务" + "德系健康管理 · 9 大产品线"
- [ ] Section 0: 2 张 featured 卡片（德好高亮渐变 + 德尊普通），code + name + badge + benefits + price + button
- [ ] Section 1: 就医协助引导卡 + 申请按钮
- [ ] Section 2: 德系产品矩阵 3×3 grid，每格 code + name + desc + tier
- [ ] Section 3: 富德优选 2×N grid（6 商品），image + name + desc + price
- [ ] 颜色通过 `UIColor.fd*` Token 引用
- [ ] 所有 section header 正确显示
- [ ] 矩阵 tile 点击 push `/services/list/:code`
- [ ] 富德优选 "查看全部 ›" push `/mall`
