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

> **Source of Truth**: `new/funde-code/funde/funde-client` → `prototype/src/views/services/ServicesView.vue`
> **PRD 参考**: `docs/page-specs/services-hub.page.yaml` + `docs/v0.1/pages/services/index.md`
> **Mock（仅推荐区/机构）**: `prototype/src/mock/services.json` — **轮播与 9 宫格已接 API，不再使用 Mock**
>
> **iOS 对齐决策（2026-07 修订）**: Hub 以用户指定的 **Vue 原型** 为准实现轮播 Banner、9 宫格、推荐区等；PRD 中标注「暂不做」的限时活动 Banner 在 Vue 已落地，iOS 同步实现 `van-swipe` 轮播（3.6s 自动播放）。

### Intent

服务 Tab 根页面。Vue 原型布局：

| 优先级 | Region | 说明 |
|--------|--------|------|
| P0 | service-banner-swipe | 运营 Banner 轮播（`GET columnContent/getByCode`） |
| P0 | product-matrix | 德系 9 宫格（`POST dictionary/getDictionaryByParentId2`）→ `/services/list` + `code` |
| P0 | recommend-section | 推荐服务健康包列表 + 类目筛选 |
| P0 | activate-banner | 三好卡兑换提示条（PRD 补充，Vue 暂未含）→ `/activate` |
| P1 | featured-packages | 精选服务包弱化卡（PRD 保留） |
| P1 | medical-assist | 就医协助引导卡 |
| P1 | mall-preview | 富德优选预览（≤6 件） |

**Phase 1 已实现**: 机构顶栏、Banner 轮播、9 宫格、推荐服务（类目筛选 + 健康包列表）、三好卡提示条。

### Layout（对齐 page-spec）

```
┌──────────────────────────────────────────┐
│  tableHeaderView: "健康服务"              │
│  "德系健康管理 · 9 大产品线"              │
├──────────────────────────────────────────┤
│  S0: ActivateBannerCell (条件显示)        │
├──────────────────────────────────────────┤
│  S1: ServiceBannerCarouselCell            │
│  van-swipe 3 张 Banner，高 172pt，3.6s 自动播放 │
├──────────────────────────────────────────┤
│  S2: FeaturedCardCell × N (弱化高度)    │
│  德好 [进行中] 查看进度 → /orders         │
│  德尊 [为您推荐] 了解详情 → /services/detail│
├──────────────────────────────────────────┤
│  S2: MedicalAssistCell                   │
│  🏥 就医协助  [了解详情] → medical-assist │
├──────────────────────────────────────────┤
│  S3: MatrixGridCell (3×3)                │
│  header: "德系产品矩阵"                   │
├──────────────────────────────────────────┤
│  S4: MallGridCell (2×N, max 6)          │
│  header: "富德优选" + "查看全部 ›" → /mall │
└──────────────────────────────────────────┘
```

### TableView Sections & Cells

| Section | Cell | Rows | 条件 |
|---------|------|------|------|
| 0 | `ActivateBannerCell` | 1 | `VoucherService.isCardActivated == false` |
| 1 | `ServiceBannerCarouselCell` | 1 | `banners` 非空 |
| 2 | `FeaturedCardCell` | `featured.count` | 始终 |
| 3 | `MedicalAssistCell` | 1 | 始终 |
| 4 | `MatrixGridCell` | 1 | 始终 |
| 5 | `MallGridCell` | 1 | `mallPreview` 非空 |

Section index 随 `showActivateBanner` 动态偏移；`numberOfSections` 固定 6。

### Business Rules

1. **三好卡提示条**: 与 `VoucherService.isCardActivated` 联动（对应 funde `stores/demo.ts cardActivated`）；已激活时隐藏整段 S0
2. **精选卡已购** (`current == true`): badge 展示 `status`（如「进行中 · 剩 45 天」）；按钮「查看进度」→ `Router.push("/orders")`
3. **精选卡未购**: badge「为您推荐」；按钮「了解详情」→ `Router.push("/services/detail", params: ["id": id])`
4. **弱化视觉**: 卡片内边距 12pt（原 16pt）、code 方块 40pt（原 48pt）、去掉 highlight 装饰 blob；高亮卡仍用 `fdPrimarySoft` 浅底
5. **就医协助**: 按钮文案「了解详情」（非「申请」）；跳转 `/services/medical-assist`（非自循环 `/services`）
6. **产品矩阵**: 9 格静态顺序；`current == true` 显示「使用中」角标；点击 → `/services/list` + `params: ["code": code]`
7. **富德优选**: 最多 6 件；「查看全部 ›」→ `/mall`；商品卡 → `/mall/detail` + `id`
8. **颜色**: 优先 `UIColor.fd*`；语义色 success 用 `fdSuccess` / `fdSuccessSoft`

### Architecture（Hub）

```
PL/Service/
├── ServiceViewController.swift      # 布局 + 导航
├── ViewModels/ServiceViewModel.swift
└── Components/
    ├── ActivateBannerCell.swift
    └── ServiceBannerCarouselCell.swift

BLL/Service/
├── ServiceModels.swift              # FeaturedPackage, ProductMatrixItem, MallProduct, ServiceHubSnapshot
├── ServiceCatalogService.swift      # Mock 数据（services.json 口径）
└── ServiceRoutes.swift
```

- `ServiceViewModel` 注入 `ServiceCatalogService` + `VoucherService`
- `loadHub()` 构建 `ServiceHubSnapshot` 并 `@Published`
- 导航保留在 ViewController（与 HomeViewModel 模式一致）

### Data Models (BLL)

```swift
struct FeaturedPackage {
    let id: String; let code: String; let tag: String; let desc: String
    let benefits: [String]; let price: String; let priceUnit: String
    let status: String; let highlight: Bool; let current: Bool
}

struct ProductMatrixItem {
    let code: String; let name: String; let desc: String
    let tier: String; let accentHex: String; let current: Bool
    var accent: UIColor { UIColor(hexString: accentHex) }
}

struct MallProduct {
    let id: String; let name: String; let desc: String
    let price: String; let unit: String; let tag: String
    let accentHex: String; let category: String
}

struct ServiceHubSnapshot {
    let showActivateBanner: Bool
    let featured: [FeaturedPackage]
    let matrix: [ProductMatrixItem]
    let mallPreview: [MallProduct]
}
```

Mock 数据来源：`services.json` 的 `matrix`、健康包列表；**轮播 Banner 已对接真实 API**（见下节）。

### Hub Banner API（轮播图）

> **Apifox**: [根据栏位 code 查询已绑定的展示位内容列表](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/484052032e0.md)

#### 接口

| 项 | 值 |
|----|-----|
| Method | `GET` |
| Path | `/v1/columnContent/getByCode` |
| Base | `APIManager.environment.baseURL`（即 `gateway + /mobile`） |
| Query | `code=wechat_hospital_banner` |
| Auth | Bearer Token（`APIManager.session`） |
| Response | `APIResponse<[ColumnContentDTO]>` |

#### DAL 模型

```swift
struct ColumnContentDTO: Decodable {
    let id: String          // 雪花 ID，JSON 可能为 String 或 Number
    let contentId: String
    let contentType: Int
    let name: String?
    let imageUrl: String?
    let categoryName: String?
    let status: Int?
}
```

#### BLL 映射

- `ColumnContentService.fetchHospitalBanners()` → `GET` 上述接口
- 过滤 `status == 1`（启用）
- 映射为 `ServiceHubBanner`（PL 层复用现有 `ServiceBannerCarouselCell`）
- `contentType` 跳转（来源 `c_advertisement.content_type`）：

| contentType | 含义 | iOS 路由 |
|-------------|------|----------|
| 1 | 广告/Banner | 无跳转（仅展示） |
| 2 | 商品单品 | `/mall/detail` + `id=contentId` |
| 3 | 商品套餐 | `/services/pkg` + `id=contentId` |
| 4 | 活动专题 | `/services/detail` + `id=contentId`（占位） |
| 5 | 资讯内容 | 暂不跳转（Phase 2 资讯详情） |

#### 加载策略

- `ServiceViewModel.load()` 使用 `async`：推荐区仍走 `ServiceCatalogService` Mock；Banner / Matrix **并行请求 API**
- API 失败或空列表 → Banner section `numberOfRows = 0`（隐藏轮播，不降级 Mock）
- 图片展示：`imageUrl` 非空时用 Kingfisher 加载；否则用文字占位（`name` + `categoryName`）

#### 架构

```
BLL/Service/
├── ColumnContentService.swift    # GET /v1/columnContent/getByCode
├── ColumnContentModels.swift     # ColumnContentDTO + 跳转映射
└── ServiceCatalogService.swift   # buildHubSnapshot(banners:)
```

### Hub Product Matrix API（德系 9 大产品线）

> **Apifox**: [查询字典信息，不分页](https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330853e0)

#### 接口

| 项 | 值 |
|----|-----|
| Method | `POST` |
| Path | `/v1/dictionary/getDictionaryByParentId2` |
| Base | `APIManager.environment.baseURL`（`gateway + /mobile`） |
| Body | `{ "parentIds": [2074711686115364864], "allStatus": true }` |
| Auth | Bearer Token |
| Response | `APIResponse<[SDictionary]>` — **顶层为父节点数组，产品线在 `children` 内** |

#### 实际响应结构

```json
{
  "data": [{
    "id": "2074711686115364864",
    "name": "商品套餐系列",
    "children": [
      { "name": "德康", "value": "1", "description": "健康基础", "sortId": 1, "status": 1 },
      { "name": "德好", "value": "2", "description": "向好逆转", "sortId": 2, "status": 1 }
    ]
  }]
}
```

> 解析时取 `children` 作为产品线列表，忽略父节点本身。

#### DAL / BLL 模型

```swift
struct DictionaryQueryBO: Encodable {
    let parentIds: [Int64]
    let allStatus: Bool
}

struct SDictionary: Decodable {
    let id: String
    let sortId: Int?
    let parentId: String?
    let name: String?
    let value: String?
    let description: String?
    let english: String?
    let status: Int?
}
```

> `id` / `parentId` 等雪花 ID 字段兼容 String / Number 解码（与 `ColumnContentDTO` 一致）。

#### 字段 → `ProductMatrixItem` 映射

| UI 字段 | 字典字段 | 规则 |
|---------|----------|------|
| `code` | `children[].name` | 产品线代码（如 `德康`、`德好`） |
| `name` | `children[].description` | 副标题（如 `健康基础`、`向好逆转`） |
| `desc` | — | API 无此字段，留空 |
| `tier` | `english` | API 有值时展示，否则留空 |
| `accentHex` | `value` | 仅 `value` 以 `#` 开头时使用；否则品牌色 `#FF7A50` |
| `current` | — | 暂固定 `false`（用户权益接口 Phase 2 补充「使用中」角标） |

- 先展开 `children`，再按 `sortId` 升序排列
- `status == 1` 才展示（启用）；`allStatus: true` 仅控制接口返回范围，UI 仍过滤禁用项

#### 加载策略

- `ServiceViewModel.load()` 并行请求 Banner + Matrix（`async let`）
- Matrix API 成功 → `MatrixGridCell` 展示接口数据；失败或空列表 → 隐藏矩阵 section（不降级 Mock）
- 点击格子 → `Router.push("/services/list", params: ["code": code])`（`code` 为产品线代码）

#### 架构

```
BLL/Service/
├── DictionaryService.swift       # POST getDictionaryByParentId2
├── DictionaryModels.swift      # SDictionary + ProductMatrixMapper
└── ServiceCatalogService.swift # buildHubSnapshot(banners:matrix:)
```

### Future API（其他模块仍 Mock）

| Endpoint | 用途 |
|----------|------|
| `GET /api/services/featured` | 精选包 + 用户已购状态 |
| ~~`GET /api/services/matrix`~~ | 已由字典接口替代 |
| `GET /api/mall/products?limit=6` | 商城预览 |

### Key Specs (UI)

- Featured card: 40pt code 方块 + name + status badge + benefits tags + mono price + footer button
- Highlight card: `fdPrimarySoft` 背景 + `fdPrimary` 边框（无大装饰 blob）
- Medical assist: `fdPrimarySoft` 卡片 + 3 功能标签 +「了解详情」primary 按钮
- Matrix tile: 44pt icon + name + desc + tier, 3 columns
- Mall card: 90pt placeholder + name + desc + mono price

### Empty / Loading States

- `cardActivated == true` → S0 隐藏
- Matrix 某产品线无套餐 → 列表页展示「套餐即将开放」（Hub 仍显示矩阵格）
- Mall 空 → 隐藏 S4（`numberOfRows = 0`）
- 加载失败（后续 API）→ 骨架屏 + 下拉刷新

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
| `/services/medical-assist` | `MedicalAssistViewController` (Placeholder) | 1 | — |
| `/activate` | `VoucherListViewController` | 1 | — |
| `/mall` | `HealthMallViewController` | 2 | — |
| `/mall/detail` | Placeholder | 2 | `id: String` |

---

## Acceptance Checklist (Phase 1 — Hub)

- [ ] Custom Topbar "健康服务" + "德系健康管理 · 9 大产品线"
- [ ] S0: 三好卡兑换提示条（未激活时显示），点击 → `/activate`；已激活隐藏
- [ ] S1: featured 卡片弱化高度；已购「查看进度」→ `/orders`；未购「了解详情」→ `/services/detail`
- [ ] S2: 就医协助卡「了解详情」→ `/services/medical-assist`
- [ ] S3: 德系产品矩阵 3×3，使用中角标，点击 → `/services/list` + code
- [ ] S4: 富德优选 ≤6 商品，「查看全部 ›」→ `/mall`，商品 → `/mall/detail`
- [ ] 数据来自 `ServiceCatalogService`（非 VC 内联 mock）
- [ ] `ServiceViewModel` + `VoucherService.isCardActivated` 驱动 S0 显隐
- [ ] 颜色通过 `UIColor.fd*` Token 引用
- [ ] 触摸目标 ≥ 44pt
