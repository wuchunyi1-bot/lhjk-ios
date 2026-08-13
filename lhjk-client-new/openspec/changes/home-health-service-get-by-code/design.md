## Context

Banner / 金刚区已走 `ColumnContentCacheService` + `getByCode`。推荐健康套餐仍为本地 mock + `HomeMembershipPackagesCell`「一主二副」布局与「更多套餐 ›」。

运营 code：`home_healthService_code`。

## Goals / Non-Goals

**Goals:**

- `code=home_healthService_code`，缓存/预拉/空态对齐 Banner
- 去掉「更多套餐」入口与 `onMoreTapped`
- 所有条目使用主卡（原 Featured）样式纵向排列
- 删除 `defaultMembershipPackages`

**Non-Goals:**

- 不新增独立 REST path
- 不强制本期展示套餐封面图（DTO 有 `imageUrl` 可后续扩展；主卡布局仍以价/名/简介/CTA 为主）
- 不改服务 Tab 套餐列表

## Decisions

### 1. Code

```swift
static let homeHealthServiceCode = "home_healthService_code"
```

### 2. 拉取

`knownPreloadCodes` 增加该 code；Home：`banners(for: homeHealthServiceCode)` → 映射为 `Package`。

### 3. 字段映射与展示

| 栏位 | 用途 |
|------|------|
| imageUrl | **唯一展示内容**（Kingfisher）；无图条目过滤不展示 |
| contentType+contentId | 点击跳转 routePath / routeParamId |

本期 UI：**仅展示图片纵向列表**（保留区块标题「推荐健康套餐」），MUST NOT 再自定义价/名/简介/CTA 主卡样式。

### 4. 布局

- 标题保留；**无**更多按钮
- 垂直 `UIStackView`，每项为一张通栏远程图
- 图片宽度跟随卡片内容区（与屏宽 inset 对齐），高度按宽高比缩放；`contentMode = scaleToFill`，**不定死绝对宽高像素**
- 展示全部有图条目

### 5. 空态

空/失败（含过滤后无图）→ 隐藏 `.membership` section。

## Risks

- [无价格字段] → 主卡左侧价格为空属预期，可弱化展示
- [跳转类型非 package] → 按 Mapper；无 path 则点击 no-op

## Migration Plan

1. OpenSpec
2. BLL code + 预拉 + inventory
3. VM 拉取映射 + Cell 改布局 + VC 去掉 more

## Open Questions

无。
